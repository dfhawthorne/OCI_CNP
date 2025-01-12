# ------------------------------------------------------------------------------
# Lab 05:
# Design and Implement a Real-Network Architecture: Configuring private DNS
# Zones, views, resolvers, listeners and forwarder
#
# Launch a Compute Instance into VCN 01
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Get Availability Domains, and OL8 Images
# ------------------------------------------------------------------------------

data "oci_identity_availability_domains" "ads" {
    compartment_id              = var.provider_details.tenancy_ocid
}

data "oci_core_images" "ol8_images" {
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

resource "tls_private_key" "ocinplab05key" {
    algorithm                   = "RSA"
    rsa_bits                    = 2048
}

# -----------------------------------------------------------------------------
# Create instance
# -----------------------------------------------------------------------------

resource "oci_core_instance" "IAD-NP-LAB05-VM-01" {
    availability_domain             = local.ad1
    compartment_id                  = var.compartment_id
    display_name                    = "IAD-NP-LAB05-VM-01"
    shape                           = "VM.Standard.A1.Flex"

    create_vnic_details {
        subnet_id                   = oci_core_subnet.IAD-NP-LAB05-SNET-01.id
        assign_public_ip            = true
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
        ssh_authorized_keys         = tls_private_key.ocinplab05key.public_key_openssh
    }
}