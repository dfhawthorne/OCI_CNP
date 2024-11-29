# ------------------------------------------------------------------------------
# Lab 10:
# Infrastructure Security - Compute: Set Up a Bastion Host
# ------------------------------------------------------------------------------

output bastion_id {
    value                   = oci_bastion_bastion.NPLAB10BASTION01.id
    sensitive               = false
}

output vm_id {
    value                   = oci_core_instance.IAD-NP-LAB10-1-VM-01.id
    sensitive               = false
}

output private_ip {
    value                   = oci_core_instance.IAD-NP-LAB10-1-VM-01.private_ip
    sensitive               = false
}
