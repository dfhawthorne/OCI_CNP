# ------------------------------------------------------------------------------
# Lab 09:
# Instrastructure Security - Network: Create a Self-Signed Certificate and Perform
# SSL Termination on OCI Load Balancer
#
# Output variables
# ------------------------------------------------------------------------------

output "private_key_pem" {
    value                       = tls_private_key.ocinplab11vmkey.private_key_pem
    sensitive                   = true
}

output "public_key_pem" {
    value                       = tls_private_key.ocinplab11vmkey.public_key_pem
    sensitive                   = false
}

output "vm_01_public_ip" {
    value                       = oci_core_instance.IAD-NP-LAB11-VM-01.public_ip
    sensitive                   = false
}

output "vm_01_private_ip" {
    value                       = oci_core_instance.IAD-NP-LAB11-VM-01.private_ip
    sensitive                   = false
}

output "lb_public_ip" {
    value                       = oci_load_balancer_load_balancer.IAD-NP-LAB11-LB-01.ip_address_details[0].ip_address
}