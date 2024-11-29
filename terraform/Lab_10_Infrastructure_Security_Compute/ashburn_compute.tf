# ------------------------------------------------------------------------------
# Lab 10:
# Infrastructure Security - Compute: Set Up a Bastion Host
#
# Enable Bastion Plug-in on a Compute Instance
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Get Availability Domains, and OL8 Images
# ------------------------------------------------------------------------------

locals {
    compute_shape               = "VM.Standard.A1.Flex"
}

data "oci_identity_availability_domains" "ads" {
    provider                    = oci.ashburn
    compartment_id              = var.provider_details.tenancy_ocid
}

data "oci_core_images" "ol8_images" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    operating_system            = "Oracle Linux"
    operating_system_version    = "8"
    shape                       = local.compute_shape
    sort_by                     = "TIMECREATED"
    sort_order                  = "DESC"
}

locals {
    ad1                         = data.oci_identity_availability_domains.ads.availability_domains[0].name
    latest_ol8_image_id         = data.oci_core_images.ol8_images.images[0].id
    latest_ol8_image_name       = data.oci_core_images.ol8_images.images[0].display_name
}

# -----------------------------------------------------------------------------
# Create instance
# -----------------------------------------------------------------------------

resource "oci_core_instance" "IAD-NP-LAB10-1-VM-01" {
    provider                        = oci.ashburn
    availability_domain             = local.ad1
    compartment_id                  = var.compartment_id
    shape                           = local.compute_shape

    create_vnic_details {
        subnet_id                   = oci_core_subnet.IAD-NP-LAB10-SNET-01.id
        assign_public_ip            = false
    }

    source_details {
        source_type                 = "image"
        source_id                   = local.latest_ol8_image_id
    }

    shape_config                {
        ocpus                       = 1
        memory_in_gbs               = 6
    }

    agent_config {
		are_all_plugins_disabled    = false
        plugins_config {
            desired_state           = "ENABLED"
            name                    = "Bastion"
        }
	}
}

