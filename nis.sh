#!/bin/bash

#-------------------------------------------------------------------------------
#
# nis.sh - Set up NIS client
#
#-------------------------------------------------------------------------------

dnf -y install autofs nfs-utils rpcbind yp-tools

authselect select nis
authselect apply-changes

echo 'domain structbio server nis' >> /etc/yp.conf

cat > /etc/securenets <<EOI
host 127.0.0.1
255.255.0.0   129.59.0.0
255.255.0.0   160.129.0.0
255.0.0.0     10.0.0.0
EOI

cat > /etc/security/access.netgroup.conf <<EOI
+ : sbio root ansible : ALL
- : ALL : ALL
EOI

echo 'NISDOMAIN=structbio' > /etc/sysconfig/network

systemctl enable autofs rpcbind ypbind
systemctl start autofs rpcbind ypbind
