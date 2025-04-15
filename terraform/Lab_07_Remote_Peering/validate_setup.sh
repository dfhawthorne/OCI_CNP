#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Site-to-Site Virtual Private Network: Connect OCI resources to on-premises via
# site-to-site VPN, using LibreSwan as the customer premises equipment
# 
# Configure LibreSwan on the On-premises VM (Ashburn)
#
# Validate Lab setup by pinging 
# ------------------------------------------------------------------------------

pingvm_private_ip=$(terraform output -raw pingvm_private_ip) || exit 1
lhr_vm_public_ip=$(terraform output -raw lhr_vm_01_public_ip) || exit 1
lhr_vm_private_ip=$(terraform output -raw lhr_vm_01_private_ip) || exit 1
phx_vm_public_ip=$(terraform output -raw phx_vm_01_public_ip) || exit 1
phx_vm_private_ip=$(terraform output -raw phx_vm_01_private_ip) || exit 1

# ------------------------------------------------------------------------------
# Ping the host on the private subnet on the simulated on-premises environment
# ------------------------------------------------------------------------------

printf "\nPinging from Phoenix\n\n"

ssh -o StrictHostKeyChecking=accept-new \
    opc@${phx_vm_public_ip} <<DONE
printf "\nPinging On-Premises\n\n"
ping -c 10 ${pingvm_private_ip}
printf "\nPinging London\n\n"
ping -c 10 ${lhr_vm_private_ip}
DONE

printf "\nPinging from London\n\n"

ssh -o StrictHostKeyChecking=accept-new \
    opc@${lhr_vm_public_ip} <<DONE
printf "\nPinging On-Premises\n\n"
ping -c 10 ${pingvm_private_ip}
printf "\nPinging Phoenix\n\n"
ping -c 10 ${phx_vm_private_ip}
DONE
