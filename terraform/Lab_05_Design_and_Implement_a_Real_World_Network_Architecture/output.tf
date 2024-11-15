# ------------------------------------------------------------------------------
# Lab 05:
# Design and Implement a Real-Network Architecture: Configuring private DNS
# Zones, views, resolvers, listeners and forwarder
#
# Output variables
# ------------------------------------------------------------------------------

output "private_key_pem" {
    value                       = tls_private_key.ocinplab05key.private_key_pem
    sensitive                   = true
}

output "public_key_pem" {
    value                       = tls_private_key.ocinplab05key.public_key_pem
    sensitive                   = false
}

output "public_ip" {
    value                       = oci_core_instance.IAD-NP-LAB05-VM-01.public_ip
    sensitive                   = false
}
