# ------------------------------------------------------------------------------------
# Lab 06:
# Site-to-Site Virtual Private Network: Connect OCI resources to on-premises via
# site-to-site VPN, using LibreSwan as the customer premises equipment
# 
# Launch On-Premises Network and CPE VM in Ashburn Region
#
# In this practice, you will simulate an on-premises network (OPN) in the Ashburn
# region with a VCN, and a compute instance that will run LibreSwan for the CPE
# router. There will be a second VM for pinging purposes.
# ------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Get Availability Domains, and OL9 Images
# ------------------------------------------------------------------------------

data "oci_identity_availability_domains" "phx_ads" {
    provider                    = oci.phoenix
    compartment_id              = var.provider_details.tenancy_ocid
}

data "oci_core_images" "phx_ol9_images" {
    provider                    = oci.phoenix
    compartment_id              = var.compartment_id
    operating_system            = "Oracle Linux"
    operating_system_version    = "9"
    shape                       = "VM.Standard.A1.Flex"
    sort_by                     = "TIMECREATED"
    sort_order                  = "DESC"
}

locals {
    phx_ad1                     = data.oci_identity_availability_domains.phx_ads.availability_domains[0].name
    latest_phx_ol9_image_id     = data.oci_core_images.phx_ol9_images.images[0].id
}

# -----------------------------------------------------------------------------
# Create TEST instance
# -----------------------------------------------------------------------------

resource "oci_core_instance" "PHX-NP-LAB06-VM-01" {
    provider                    = oci.phoenix
    availability_domain         = local.phx_ad1
    compartment_id              = var.compartment_id
    shape                       = "VM.Standard.A1.Flex"
    display_name                = "PHX-NP-LAB06-VM-01"

    create_vnic_details {
        subnet_id               = oci_core_subnet.PHX-NP-LAB06-SNET-01.id
        assign_public_ip        = true
        skip_source_dest_check  = true
    }

    source_details {
        source_type             = "image"
        source_id               = local.latest_phx_ol9_image_id
        boot_volume_size_in_gbs = 50
    }

    shape_config                {
        ocpus                   = 1
        memory_in_gbs           = 6
    }

    metadata = {
        ssh_authorized_keys     = file("~/.ssh/id_rsa.pub")
    }
}
