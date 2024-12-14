# ------------------------------------------------------------------------------------
# Lab 07:
# Remote Peering: InterConnect OCI resources between regions and extend to on-premises
# 
# Create Resources in UK South (London) Region
# 
# ------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Get Availability Domains, and OL8 Images
# ------------------------------------------------------------------------------

data "oci_identity_availability_domains" "lhr_ads" {
    provider                    = oci.london
    compartment_id              = var.provider_details.tenancy_ocid
}

data "oci_core_images" "lhr_ol8_images" {
    provider                    = oci.london
    compartment_id              = var.compartment_id
    operating_system            = "Oracle Linux"
    operating_system_version    = "8"
    shape                       = "VM.Standard.A1.Flex"
    sort_by                     = "TIMECREATED"
    sort_order                  = "DESC"
}

locals {
    lhr_ad1                     = data.oci_identity_availability_domains.lhr_ads.availability_domains[0].name
    latest_lhr_ol8_image_id     = data.oci_core_images.lhr_ol8_images.images[0].id
}

# ------------------------------------------------------------------------------
# Generate SSH Key Pair 
# ------------------------------------------------------------------------------

resource "tls_private_key" "ocinplab07vmkey" {
    algorithm                   = "RSA"
    rsa_bits                    = 2048
}

# -----------------------------------------------------------------------------
# Create CPE instance
# -----------------------------------------------------------------------------

resource "oci_core_instance" "LHR-NP-LAB07-VM-01" {
    provider                    = oci.london
    availability_domain         = local.lhr_ad1
    compartment_id              = var.compartment_id
    shape                       = "VM.Standard.A1.Flex"

    create_vnic_details {
        subnet_id               = oci_core_subnet.LHR-NP-LAB07-SNET-01.id
        assign_public_ip        = true
        skip_source_dest_check  = true
    }

    source_details {
        source_type             = "image"
        source_id               = local.latest_lhr_ol8_image_id
    }

    shape_config                {
        ocpus                   = 1
        memory_in_gbs           = 6
    }

    metadata = {
        ssh_authorized_keys     = tls_private_key.ocinplab07vmkey.public_key_openssh
    }
}
