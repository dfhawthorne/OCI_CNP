#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Validate Lab setup by pinging 
# ------------------------------------------------------------------------------

vm_01_private_ipv4_addr=$(terraform output -raw vm_01_private_ipv4_addr) || exit 1
vm_01_ipv6_addr=$(terraform output -raw vm_01_ipv6_addr) || exit 1
vm_02_private_ipv4_addr=$(terraform output -raw vm_02_private_ipv4_addr) || exit 1
vm_02_ipv6_addr=$(terraform output -raw vm_02_ipv6_addr) || exit 1

printf "\nPinging from VM01\n\n"

ssh -F .ssh/config VM01 <<DONE
printf "\nPinging VM02\n\n"
ping -c 10 -4 ${vm_02_private_ipv4_addr}
ping -c 10 -6 ${vm_02_ipv6_addr}
DONE

printf "\nPinging from VM02\n\n"

ssh -F .ssh/config VM02 <<DONE
printf "\nPinging VM01\n\n"
ping -c 10 -4 ${vm_01_private_ipv4_addr}
ping -c 10 -6 ${vm_01_ipv6_addr}
DONE
