#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Site-to-Site Virtual Private Network: Connect OCI resources to on-premises via
# site-to-site VPN, using LibreSwan as the customer premises equipment
# 
# Configure LibreSwan on the On-premises VM (Ashburn)
#
# Download LibreSwan and configure IPSec files
# ------------------------------------------------------------------------------

if [[ ! -d .ssh || ! -r .ssh/config ]]
then
    printf "%s: Missing SSH config file\n" >&2
    exit 1
fi 

# ------------------------------------------------------------------------------
# Copy generated security files to CPE VM
# ------------------------------------------------------------------------------

sftp -b - -F .ssh/config CPE <<DONE
put oci-ipsec.conf
put oci-ipsec.secrets
put sysctl.conf
bye
DONE

# ------------------------------------------------------------------------------
# Update system configuration
# ------------------------------------------------------------------------------

ssh -F .ssh/config CPE <<DONE
sudo yum -y install libreswan
grep -qf sysctl.conf /etc/sysctl.conf || \
    sudo sed -i -e '\$r sysctl.conf' /etc/sysctl.conf
sudo sysctl --load
cat oci-ipsec.secrets | \
    sudo tee /etc/ipsec.d/oci-ipsec.secrets >/dev/null
cat oci-ipsec.conf | \
    sudo tee /etc/ipsec.d/oci-ipsec.conf >/dev/null
sudo service ipsec restart
sleep 10
sudo ip route add 172.16.0.0/12 \
    nexthop dev vti1 \
    nexthop dev vti2
DONE
