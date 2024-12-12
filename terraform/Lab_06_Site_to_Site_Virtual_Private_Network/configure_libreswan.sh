#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Site-to-Site Virtual Private Network: Connect OCI resources to on-premises via
# site-to-site VPN, using LibreSwan as the customer premises equipment
# 
# Configure LibreSwan on the On-premises VM (Ashburn)
#
# Download LibreSwan and configure IPSec files
# ------------------------------------------------------------------------------

mkdir -p .ssh
chmod 700 .ssh
sed -nre '/^---/,/^---/p' \
    <(terraform output -raw private_key_pem) \
    >.ssh/id_pem
chmod 600 .ssh/id_pem

cpe_ip_addr=$(terraform output -raw cpe_public_ip)

# ------------------------------------------------------------------------------
# Copy generated security files to CPE VM
# ------------------------------------------------------------------------------

sftp \
    -b - \
    -i .ssh/id_pem \
    -o StrictHostKeyChecking=accept-new \
    opc@${cpe_ip_addr} <<DONE
put oci-ipsec.conf
put oci-ipsec.secrets
put sysctl.conf
bye
DONE

# ------------------------------------------------------------------------------
# Update system configuration
# ------------------------------------------------------------------------------

ssh -i .ssh/id_pem \
    opc@${cpe_ip_addr} <<DONE
sudo yum -y install libreswan
grep -qf sysctl.conf /etc/sysctl.conf || \
    sudo sed -i -e '\$r sysctl.conf' /etc/sysctl.conf
sudo sysctl --load
cat oci-ipsec.secrets | \
    sudo tee /etc/ipsec.d/oci-ipsec.secrets >/dev/null
cat oci-ipsec.conf | \
    sudo tee /etc/ipsec.d/oci-ipsec.conf >/dev/null
sudo service ipsec restart
sudo ip route add 172.16.0.0/12 \
    nexthop dev vti1 \
    nexthop dev vti2
DONE
