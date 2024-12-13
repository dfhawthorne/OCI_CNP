#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Site-to-Site Virtual Private Network: Connect OCI resources to on-premises via
# site-to-site VPN, using LibreSwan as the customer premises equipment
# 
# Configure LibreSwan on the On-premises VM (Ashburn)
#
# Validate Lab setup by pinging 
# ------------------------------------------------------------------------------

mkdir -p .ssh
chmod 700 .ssh
sed -nre '/^---/,/^---/p' \
    <(terraform output -raw private_key_pem) \
    >.ssh/id_pem
chmod 600 .ssh/id_pem

pingvm_private_ip=$(terraform output -raw pingvm_private_ip)
testvm_public_ip=$(terraform output -raw testvm_public_ip)

# ------------------------------------------------------------------------------
# Ping the host on the private subnet on the simulated on-premises environment
# ------------------------------------------------------------------------------

ssh -i .ssh/id_pem \
    -o StrictHostKeyChecking=accept-new \
    opc@${testvm_public_ip} <<DONE
ping -c 10 ${pingvm_private_ip}
DONE
