SUMMARY = "Meta-networking packagegroups"

inherit packagegroup

PROVIDES = "${PACKAGES}"
PACKAGES = ' \
    packagegroup-meta-networking \
    packagegroup-meta-networking-connectivity \
    packagegroup-meta-networking-daemons  \
    packagegroup-meta-networking-devtools \
    packagegroup-meta-networking-extended \
    packagegroup-meta-networking-filter \
    packagegroup-meta-networking-irc \
    packagegroup-meta-networking-kernel \
    packagegroup-meta-networking-netkit \
    packagegroup-meta-networking-protocols \
    packagegroup-meta-networking-support \
'

RDEPENDS_packagegroup-meta-networking = "\
    packagegroup-meta-networking-connectivity \
    packagegroup-meta-networking-daemons  \
    packagegroup-meta-networking-devtools \
    packagegroup-meta-networking-extended \
    packagegroup-meta-networking-filter \
    packagegroup-meta-networking-irc \
    packagegroup-meta-networking-kernel \
    packagegroup-meta-networking-netkit \
    packagegroup-meta-networking-protocols \
    packagegroup-meta-networking-support \
    "

RDEPENDS_packagegroup-meta-networking-connectivity = "\
    openconnect ez-ipupdate mosquitto sethdlc crda \
    dibbler-server dibbler-client dibbler-requestor dibbler-relay \
    libdnet ufw civetweb freeradius kea daq \
    mbedtls relayd snort dhcpcd rdate vlan umip vpnc \
    inetutils wolfssl lftp miniupnpd networkmanager \
    networkmanager-openvpn rdist nanomsg python-networkmanager \
    wireless-regdb \
    ${@bb.utils.contains("DISTRO_FEATURE", "bluez5 x11", "blueman", "", d)} \
    ${@bb.utils.contains("DISTRO_FEATURE", "pam", "samba", "", d)} \
    "

RDEPENDS_packagegroup-meta-networking-daemons = "\
    ippool radvd autofs keepalived proftpd openhpi lldpd \
    ptpd igmpproxy opensaf squid \
    atftp postfix iscsi-initiator-utils vsftpd cyrus-sasl \
    pure-ftpd vblade tftp-hpa ncftp \
    ${@bb.utils.contains("DISTRO_FEATURE", "systemd", "networkd-dispatcher", "", d)} \
    "

RDEPENDS_packagegroup-meta-networking-devtools = "\
    python-ldap grpc \
    "

RDEPENDS_packagegroup-meta-networking-extended = "\
    corosync \
    ${@bb.utils.contains("DISTRO_FEATURE", "systemd", "dlm", "", d)} \
    "

RDEPENDS_packagegroup-meta-networking-filter = "\
    ebtables conntrack-tools libnetfilter-queue \
    libnetfilter-conntrack libnetfilter-cthelper libnetfilter-acct \
    libnetfilter-cttimeout libnetfilter-log nfacct \
    arno-iptables-firewall libnftnl nftables \
    libnfnetlink \
    " 

RDEPENDS_packagegroup-meta-networking-irc = "\
    znc \
    "

RDEPENDS_packagegroup-meta-networking-kernel = "\
    wireguard-module wireguard-tools \
    "

RDEPENDS_packagegroup-meta-networking-netkit = "\
    netkit-rwho-client netkit-rwho-server netkit-rsh-client netkit-rsh-server \
    netkit-telnet netkit-tftp-client netkit-tftp-server \
    netkit-ftp netkit-rusers-client netkit-rusers-server netkit-rpc \
    "

RDEPENDS_packagegroup-meta-networking-protocols = "\
    tsocks freediameter xl2tpd babeld mdns net-snmp \
    quagga pptp-linux zeroconf nopoll openflow rp-pppoe \
    radiusclient-ng openl2tp usrsctp \
    ${@bb.utils.contains("DISTRO_FEATURE", "pam", "dante", "", d)} \
    "

RDEPENDS_packagegroup-meta-networking-support = "\
    ncp ndisc6 mtr tinyproxy ssmping ntp \
    wpan-tools bridge-utils ifenslave celt051 pimd \
    nbd-client nbd-server nbd-trdump \
    phytool fwknop htpdate tcpreplay ipsec-tools \
    traceroute geoip-perl geoip geoipupdate esmtp \
    libtdb netcf dnsmasq curlpp openipmi drbd-utils \
    drbd tunctl dovecot ipvsadm stunnel chrony spice-protocol \
    usbredir ntop wireshark tnftp lksctp-tools \
    cim-schema-docs cim-schema-final cim-schema-exper \
    libmemcached smcroute libtevent ipcalc c-ares uftp \
    ntimed linux-atm ssmtp openvpn lowpan-tools rdma-core \
    iftop aoetools tcpslice tcpdump libtalloc memcached nuttcp netcat \
    netcat-openbsd fetchmail yp-tools ypbind-mt yp-tools \
    arptables macchanger nghttp2 strongswan fping \
    dnssec-conf libesmtp cifs-utils open-isns \
    ${@bb.utils.contains("DISTRO_FEATURE", "pam", "libldb", "", d)} \
    ${@bb.utils.contains("LICENSE_FLAGS_WHITELIST", "non-commercial", "netperf", "", d)} \
    ${@bb.utils.contains_any("TRANSLATED_TARGET_ARCH", "i586 x86-64", "spice", "", d)} \
    "


RDEPENDS_packagegroup-meta-networking-support_remove_mipsarch = "spice-protocol"
RDEPENDS_packagegroup-meta-networking-support_remove_mips64 = "spice-protocol"
RDEPENDS_packagegroup-meta-networking-support_remove_mips64el = "spice-protocol"
RDEPENDS_packagegroup-meta-networking-support_remove_powerpc = "spice-protocol"
RDEPENDS_packagegroup-meta-networking-support_remove_riscv64 = "spice-protocol"
RDEPENDS_packagegroup-meta-networking-support_remove_riscv32 = "spice-protocol"
RDEPENDS_packagegroup-meta-networking-support_remove_armv5 = "spice-protocol"
RDEPENDS_packagegroup-meta-networking-support_remove_aarch64 = "spice-protocol memcached"

EXCLUDE_FROM_WORLD = "1"
