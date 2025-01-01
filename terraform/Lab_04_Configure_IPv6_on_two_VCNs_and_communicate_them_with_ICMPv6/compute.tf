# ------------------------------------------------------------------------------
# Lab 04: Virtual Cloud Network (VCN): Configure IPv6 on two VCNs and
#         communicate between them with ICMPv6
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Availability Domains 
# ------------------------------------------------------------------------------

data "oci_identity_availability_domains" "ad" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
}

# ------------------------------------------------------------------------------
# Get the latest OL8 image
# ------------------------------------------------------------------------------

data "oci_core_images" "oracle_linux" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    operating_system            = "Oracle Linux"
    operating_system_version    = "8"
    shape                       = "VM.Standard.A1.Flex"
    sort_by                     = "TIMECREATED"
    sort_order                  = "DESC"
}

# ------------------------------------------------------------------------------
# Create simple VMs in the first availability domain
# ------------------------------------------------------------------------------

resource "oci_core_instance" "vm_01" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    availability_domain         = data.oci_identity_availability_domains.ad.availability_domains[0].name
    display_name                = "IAD-NP-LAB04-VM-01"
    shape                       = "VM.Standard.A1.Flex"
    shape_config                {
        ocpus                   = 1
        memory_in_gbs           = 6
    }
    source_details              {
        source_type             = "image"
        source_id               = data.oci_core_images.oracle_linux.images[0].id
    }
    create_vnic_details         {
        subnet_id               = oci_core_subnet.public-subnet-01.id
        assign_public_ip        = true
        assign_ipv6ip           = true
    }
    metadata                    = {
        ssh_authorized_keys     = file("~/.ssh/id_rsa.pub")
    }
}

resource "oci_core_instance" "vm_02" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    availability_domain         = data.oci_identity_availability_domains.ad.availability_domains[0].name
    display_name                = "IAD-NP-LAB04-VM-02"
    shape                       = "VM.Standard.A1.Flex"
    shape_config                {
        ocpus                   = 1
        memory_in_gbs           = 6
    }
    source_details              {
        source_type             = "image"
        source_id               = data.oci_core_images.oracle_linux.images[0].id
    }
    create_vnic_details         {
        subnet_id               = oci_core_subnet.public-subnet-02.id
        assign_public_ip        = true
        assign_ipv6ip           = true
    }
    metadata                    = {
        ssh_authorized_keys     = file("~/.ssh/id_rsa.pub")
    }
}

# ------------------------------------------------------------------------------
# Retrieve generated IPV6 Addresses
# ------------------------------------------------------------------------------

data "oci_core_vnic_attachments" "vm_01_vnic_attachments" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    instance_id                 = oci_core_instance.vm_01.id
}

data "oci_core_ipv6s" "vm_01_ipv6s" {
    provider                    = oci.ashburn
    subnet_id                   = oci_core_subnet.public-subnet-01.id
    vnic_id                     = data.oci_core_vnic_attachments.vm_01_vnic_attachments.vnic_attachments[0].vnic_id
}

data "oci_core_vnic_attachments" "vm_02_vnic_attachments" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    instance_id                 = oci_core_instance.vm_02.id
}

data "oci_core_ipv6s" "vm_02_ipv6s" {
    provider                    = oci.ashburn
    subnet_id                   = oci_core_subnet.public-subnet-02.id
    vnic_id                     = data.oci_core_vnic_attachments.vm_02_vnic_attachments.vnic_attachments[0].vnic_id
}
