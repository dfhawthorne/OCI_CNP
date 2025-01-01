#!/usr/bin/bash
# ------------------------------------------------------------------------------
# Lab 04: Virtual Cloud Network (VCN): Configure IPv6 on two VCNs and
#         communicate between them with ICMPv6
# Enable IPv6 on the Lab 04 VMs
# ------------------------------------------------------------------------------

[[ ! -r .ssh/config ]] && exit 1

for vm in VM01 VM02
do
    ssh -F .ssh/config ${vm} <<DONE
    sudo dhclient -6 enp0s6
DONE
done 
