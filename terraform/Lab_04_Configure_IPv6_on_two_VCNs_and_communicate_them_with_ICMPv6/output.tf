# ------------------------------------------------------------------------------
# Lab 04: Output Variables
# ------------------------------------------------------------------------------

output "vm_01_public_ipv4_addr" {
    value                           = oci_core_instance.vm_01.public_ip
    description                     = "Public IPV4 Address of VM 01"
    sensitive                       = false
    }

output "vm_01_private_ipv4_addr" {
    value                           = oci_core_instance.vm_01.private_ip
    description                     = "Private IPV4 Address of VM 01"
    sensitive                       = false
    }

output "vm_01_ipv6_addr" {
    value                           = data.oci_core_ipv6s.vm_01_ipv6s.ipv6s[0].ip_address
    description                     = "Public IPV6 Address of VM 01"
    sensitive                       = false
}

output "vm_02_public_ipv4_addr" {
    value                           = oci_core_instance.vm_02.public_ip
    description                     = "Public IPV4 Address of VM 02"
    sensitive                       = false
    }

output "vm_02_private_ipv4_addr" {
    value                           = oci_core_instance.vm_02.private_ip
    description                     = "Private IPV4 Address of VM 02"
    sensitive                       = false
    }

output "vm_02_ipv6_addr" {
    value                           = data.oci_core_ipv6s.vm_02_ipv6s.ipv6s[0].ip_address
    description                     = "Public IPV6 Address of VM 02"
    sensitive                       = false
}
