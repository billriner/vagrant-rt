#!/bin/bash

#-------------------------------------------------------------------------------
#
# provision.sh - Provision the VirtualBox VM
#
#-------------------------------------------------------------------------------

# Set the hostname
hostnamectl set-hostname support.csb.vanderbilt.edu

# Delete the default route on the vagrant interface
#ip route del default dev eth0

# Disable SELinux
setenforce 0
cat > /etc/selinux/config <<-EOI
        SELINUX=disabled
        SELINUXTYPE=targeted
EOI

# Set up /etc/motd
cat > /etc/motd <<EOI

                 *** Welcome to support ***

This system is managed by Vanderbilt CSB. Access is monitored.
           Unauthorized access is strictly prohibited.
      For support, send email to support@csb.vanderbilt.edu.

EOI

# Configure /etc/resolv.conf
cat > /etc/resolv.conf <<EOI
search csb.vanderbilt.edu its.vanderbilt.edu vanderbilt.edu
nameserver 10.2.189.78
nameserver 10.4.162.82
EOI

# Update all of the packages
dnf -y update

# Install the EPEL repo
dnf -y install https://mirror.umd.edu/fedora/epel/epel-release-latest-8.noarch.rpm
