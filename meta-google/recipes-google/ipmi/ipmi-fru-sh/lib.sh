#!/bin/bash
# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[ -n "${ipmi_fru_init-}" ] && return

IPMI_FRU_COMMON_HEADER_INTERNAL_OFFSET_IDX=1
IPMI_FRU_COMMON_HEADER_CHASSIS_OFFSET_IDX=2
IPMI_FRU_COMMON_HEADER_BOARD_OFFSET_IDX=3
IPMI_FRU_COMMON_HEADER_PRODUCT_OFFSET_IDX=4
IPMI_FRU_COMMON_HEADER_MULTI_RECORD_OFFSET_IDX=5
IPMI_FRU_AREA_HEADER_SIZE_IDX=1
IPMI_FRU_CHECKSUM_IDX=-1

of_name_to_eeproms() {
  local names
  if ! names="$(grep -xl "$1" /sys/bus/i2c/devices/*/of_node/name)"; then
    echo "Failed to find eeproms with of_name '$1'" >&2
    return 1
  fi
  echo "$names" | sed 's,/of_node/name$,/eeprom,'
}

of_name_to_eeprom() {
  local eeproms
  eeproms="$(of_name_to_eeproms "$1")" || return
  if (( "$(echo "$eeproms" | wc -l)" != 1 )); then
    echo "Got more than one eeprom for '$1':" $eeproms >&2
    return 1
  fi
  echo "$eeproms"
}

declare -A IPMI_FRU_EEPROM_FILE=()

ipmi_fru_device_to_file() {
  local fdn="$1"

  local json
  json="$(busctl -j call xyz.openbmc_project.FruDevice \
    /xyz/openbmc_project/FruDevice/"$fdn" org.freedesktop.DBus.Properties \
    GetAll s xyz.openbmc_project.FruDevice)" || return 80

  local jqq='.data[0] | (.BUS.data | tostring) + " " + (.ADDRESS.data | tostring)'
  local busaddr
  busaddr="$(echo "$json" | jq -r "$jqq")" || return

  # FRU 0 is hardcoded and FruDevice does not report the correct bus for it
  # Hardcode a workaround for this specifically known bus
  if [ "$busaddr" = '0 0' ]; then
    echo "/etc/fru/baseboard.fru.bin"
  else
    local dev="$(printf '%d-%04x' $busaddr)"
    local efile="/sys/bus/i2c/devices/$dev/eeprom"
    # The at24 eeprom driver is not guaranteed to be bound
    if [ ! -e "$efile" ]; then
      echo "$dev" >/sys/bus/i2c/drivers/at24/bind || return
    fi
    echo "$efile"
  fi
}

ipmi_fru_alloc() {
  local name="$1"
  local -n ret="$2"

  # Pick the first free index to return as the allocated entry
  for (( ret = 0; ret < "${#IPMI_FRU_EEPROM_FILE[@]}"; ++ret )); do
    [ -n "${IPMI_FRU_EEPROM_FILE[@]+1}" ] || break
  done

  if [[ "$name" =~ ^of-name:(.*)$ || "$name" =~ ^([^:]*)$ ]]; then
    local ofn="${BASH_REMATCH[1]}"
    local file
    file="$(of_name_to_eeprom "$ofn")" || return
    IPMI_FRU_EEPROM_FILE["$ret"]="$file"
  elif [[ "$name" =~ ^frudev-name:(.*)$ ]]; then
    local fdn="${BASH_REMATCH[1]}"
    local start=$SECONDS
    local file
    while (( SECONDS - start < 60 )); do
      local rc=0
      file="$(ipmi_fru_device_to_file "$fdn")" || rc=$?
      (( rc == 0 )) && break
      # Immediately return any errors, 80 is special to signify retry
      (( rc != 80 )) && return $rc
      sleep 1
    done
    IPMI_FRU_EEPROM_FILE["$ret"]="$file"
  else
    echo "Invalid IPMI FRU eeprom specification: $name" >&2
    return 1
  fi
}

ipmi_fru_free() {
  unset 'IPMI_FRU_EEPROM_FILE[$1]'
}

checksum() {
  local -n checksum_arr="$1"
  local checksum=0
  for byte in "${checksum_arr[@]}"; do
    checksum=$((checksum + byte))
  done
  echo $((checksum & 0xff))
}

fix_checksum() {
  local -n fix_checksum_arr="$1"
  old_cksum=${fix_checksum_arr[$IPMI_FRU_CHECKSUM_IDX]}
  ((fix_checksum_arr[$IPMI_FRU_CHECKSUM_IDX]-=$(checksum fix_checksum_arr)))
  ((fix_checksum_arr[$IPMI_FRU_CHECKSUM_IDX]&=0xff))
  printf 'Corrected %s checksum from 0x%02X -> 0x%02X\n' \
    "$1" "${old_cksum}" "${fix_checksum_arr[$IPMI_FRU_CHECKSUM_IDX]}" >&2
}

read_bytes() {
  local file="${IPMI_FRU_EEPROM_FILE["$1"]-$1}"
  local offset="$2"
  local size="$3"

  echo "Reading $file at $offset for $size" >&2
  dd if="$file" bs=1 count="$size" skip="$offset" 2>/dev/null | \
    hexdump -v -e '1/1 "%d "'
}

write_bytes() {
  local file="${IPMI_FRU_EEPROM_FILE["$1"]-$1}"
  local offset="$2"
  local -n bytes_arr="$3"

  local hexstr
  hexstr="$(printf '\\x%x' "${bytes_arr[@]}")" || return
  echo "Writing $file at $offset for ${#bytes_arr[@]}" >&2
  printf "$hexstr" | dd of="$file" bs=1 seek=$offset 2>/dev/null
}

read_header() {
  local eeprom="$1"
  local -n header_arr="$2"

  header_arr=($(read_bytes "$eeprom" 0 8)) || return
  echo "Checking $eeprom FRU Header version" >&2
  # FRU header is always version 1
  (( header_arr[0] == 1 )) || return
  echo "Checking $eeprom FRU Header checksum" >&2
  local sum
  sum="$(checksum header_arr)" || return
  # Checksums should be valid
  (( sum == 0 )) || return 10
}

read_area() {
  local eeprom="$1"
  local offset="$2"
  local -n area_arr="$3"
  local area_size="${4-0}"

  offset=$((offset*8))
  area_arr=($(read_bytes "$eeprom" "$offset" 8)) || return
  echo "Checking $eeprom $offset FRU Area version" >&2
  # FRU Area is always version 1
  (( area_arr[0] == 1 )) || return
  if (( area_size == 0 )); then
    area_size=${area_arr[$IPMI_FRU_AREA_HEADER_SIZE_IDX]}
  fi
  area_arr=($(read_bytes "$eeprom" "$offset" $((area_size*8)))) || return
  echo "Checking $eeprom $offset FRU Area checksum" >&2
  local sum
  sum="$(checksum area_arr)" || return
  # Checksums should be valid
  (( sum == 0 )) || return 10
}

ipmi_fru_init=1
return 0 2>/dev/null
echo "ipmi-fru is a library, not executed directly" >&2
exit 1
