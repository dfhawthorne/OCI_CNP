# ------------------------------------------------------------------------------
# Lab 06:
# Site-to-Site Virtual Private Network: Connect OCI resources to on-premises via
# site-to-site VPN, using LibreSwan as the customer premises equipment
#
# Output variables
# ------------------------------------------------------------------------------

output "private_key_pem" {
    value                       = tls_private_key.ocinplab06cpekey.private_key_pem
    sensitive                   = true
}

output "public_key_pem" {
    value                       = tls_private_key.ocinplab06cpekey.public_key_pem
    sensitive                   = false
}

output "cpe_public_ip" {
    value                       = oci_core_instance.IAD-NP-LAB06-VMCPE-01.public_ip
    sensitive                   = false
}

output "cpe_private_ip" {
    value                       = oci_core_instance.IAD-NP-LAB06-VMCPE-01.private_ip
    sensitive                   = false
}

output "pingvm_private_ip" {
    value                       = oci_core_instance.IAD-NP-LAB06-PingVM-01.private_ip
    sensitive                   = false
}

output "testvm_public_ip" {
    value                       = oci_core_instance.PHX-NP-LAB06-VM-01.public_ip
    sensitive                   = false
}

output "vpn_1_public_ip" {
    value                       = data.oci_core_ipsec_connection_tunnels.PHX-NP-LAB06-VPN-01.ip_sec_connection_tunnels[0].vpn_ip
    sensitive                   = false
}

output "vpn_1_secret" {
    value                       = local.vpn_1_secret
    sensitive                   = true
}

output "vpn_2_public_ip" {
    value                       = data.oci_core_ipsec_connection_tunnels.PHX-NP-LAB06-VPN-01.ip_sec_connection_tunnels[1].vpn_ip
    sensitive                   = false
}

output "vpn_2_secret" {
    value                       = local.vpn_2_secret
    sensitive                   = true
}
