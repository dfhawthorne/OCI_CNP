#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Lab 06:
# Site-to-Site Virtual Private Network: Connect OCI resources to on-premises via
# site-to-site VPN, using LibreSwan as the customer premises equipment
# 
# Prepare IPSec Configuration Files
# ---------------------------------
#
# The IPSec tunnel needs to be configured. Three (3) files are necessary for
# establishing the OCI to On_premises connection. The files are:
#
# - sysdtl.conf. Contains information regarding the virtual interface of the VM
#   (ENP0Sx)
# - oci-ipsec.secrets. Contains the shared secrets information/
# - oci-ipsec.conf. Contains the IPSec information.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Configure VM VNIC (ENP0Sx)
#
# Note: x is a value that will be replaced with the output of the `ip a`
# command.
# ------------------------------------------------------------------------------

cat >sysctl.conf <<DONE
net.ipv4.ip_forward=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.enp0sx.send_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.enp0sx.accept_redirects=0
DONE

# ------------------------------------------------------------------------------
# Create the shared secrets file
# ------------------------------------------------------------------------------

cpe_public_ip=$(terraform output -raw cpe_public_ip)
cpe_private_ip=$(terraform output -raw cpe_private_ip)
vpn_1_public_ip=$(terraform output -raw vpn_1_public_ip)
vpn_1_secret=$(terraform output -raw vpn_1_secret)
vpn_2_public_ip=$(terraform output -raw vpn_2_public_ip)
vpn_2_secret=$(terraform output -raw vpn_2_secret)

cat >oci-ipsec.secrets <<DONE
${cpe_public_ip} ${vpn_1_public_ip}: PSK '${vpn_1_secret}'
${cpe_public_ip} ${vpn_2_public_ip}: PSK '${vpn_2_secret}'
DONE

# ------------------------------------------------------------------------------
# Create the IPSec configuration file
# ------------------------------------------------------------------------------

cp /dev/null oci-ipsec.conf

for intf in 1..2
do  case ${intf}
        1)  tunnel_ip=${vpn_1_public_ip}
            mark="5/0xffffffff"
            ;;
        2)  tunnel_ip=${vpn_2_public_ip}
            mark="6/0xffffffff"
            ;;
        *)  tunnel_ip="Missing"
            mark="Missing"
            ;;
    esac
    cat >>oci-ipsec.conf <<DONE
conn oracle-tunnel-${intf}
    left=${cpe_private_ip}
    leftid=${cpe_public_ip}
    right=${tunnel_ip}
    authby=secret
    leftsubnet=0.0.0.0/0
    rightsubnet=0.0.0.0/0
    auto=start
    mark=${mark}
    vti-interface=vti${intf}
    vti-routing=no
    ikev2=no
    ike=aes_cbc256-sha2_384;modp1536
    phase2alg=aes_gcm256;modp1536
    encapsulation=yes
    ikelifetime=28800s
    salifetime=3600s
DONE
done
