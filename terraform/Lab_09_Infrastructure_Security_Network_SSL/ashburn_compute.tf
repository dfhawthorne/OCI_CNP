# ------------------------------------------------------------------------------------
# Lab 09:
# Instrastructure Security - Network: Create a Self-Signed Certificate and Perform
# SSL Termination on OCI Load Balancer
#
# In this practice, you will provision two compute instances, install an
# Apache web server, and connect to it over teh public Internet
# ------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Get Availability Domains, and OL8 Images
# ------------------------------------------------------------------------------

data "oci_identity_availability_domains" "ads" {
    provider                    = oci.ashburn
    compartment_id              = var.provider_details.tenancy_ocid
}

data "oci_core_images" "ol8_images" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    operating_system            = "Oracle Linux"
    operating_system_version    = "8"
    shape                       = "VM.Standard.A1.Flex"
    sort_by                     = "TIMECREATED"
    sort_order                  = "DESC"
}

locals {
    ad1                         = data.oci_identity_availability_domains.ads.availability_domains[0].name
    latest_ol8_image_id         = data.oci_core_images.ol8_images.images[0].id
    latest_ol8_image_name       = data.oci_core_images.ol8_images.images[0].display_name
}

# ------------------------------------------------------------------------------
# Generate SSH Key Pair 
# ------------------------------------------------------------------------------

resource "tls_private_key" "ocinplab09cpekey" {
    algorithm                   = "RSA"
    rsa_bits                    = 2048
}

# -----------------------------------------------------------------------------
# Create Compute instance 01
# -----------------------------------------------------------------------------

resource "oci_core_instance" "IAD-NP-LAB09-VM-01" {
    provider                    = oci.ashburn
    availability_domain         = local.ad1
    compartment_id              = var.compartment_id
    shape                       = "VM.Standard.A1.Flex"

    create_vnic_details {
        subnet_id               = oci_core_subnet.IAD-NP-LAB09-SNET-01.id
        assign_public_ip        = true
        skip_source_dest_check  = true
    }

    source_details {
        source_type                 = "image"
        source_id                   = local.latest_ol8_image_id
    }

    shape_config                {
        ocpus                       = 1
        memory_in_gbs               = 6
    }

    metadata = {
        ssh_authorized_keys         = tls_private_key.ocinplab09cpekey.public_key_openssh
    }
}

# -----------------------------------------------------------------------------
# Create Compute instance 02
# -----------------------------------------------------------------------------

resource "oci_core_instance" "IAD-NP-LAB09-VM-02" {
    provider                    = oci.ashburn
    availability_domain         = local.ad1
    compartment_id              = var.compartment_id
    shape                       = "VM.Standard.A1.Flex"

    create_vnic_details {
        subnet_id               = oci_core_subnet.IAD-NP-LAB09-SNET-01.id
        assign_public_ip        = true
        skip_source_dest_check  = true
    }

    source_details {
        source_type                 = "image"
        source_id                   = local.latest_ol8_image_id
    }

    shape_config                {
        ocpus                       = 1
        memory_in_gbs               = 6
    }

    metadata = {
        ssh_authorized_keys         = tls_private_key.ocinplab09cpekey.public_key_openssh
    }
}
