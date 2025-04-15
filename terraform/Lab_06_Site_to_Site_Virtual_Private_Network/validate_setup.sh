#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Site-to-Site Virtual Private Network: Connect OCI resources to on-premises via
# site-to-site VPN, using LibreSwan as the customer premises equipment
# 
# Configure LibreSwan on the On-premises VM (Ashburn)
#
# Validate Lab setup by pinging 
# ------------------------------------------------------------------------------

pingvm_private_ip=$(terraform output -raw pingvm_private_ip)
phx_vm_01_public_ip=$(terraform output -raw phx_vm_01_public_ip)

# ------------------------------------------------------------------------------
# Ping the host on the private subnet on the simulated on-premises environment
# ------------------------------------------------------------------------------

ssh -o StrictHostKeyChecking=accept-new \
    opc@${phx_vm_01_public_ip} <<DONE
ping -c 10 ${pingvm_private_ip}
DONE
