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

resource "tls_private_key" "ocinplab06cpekey" {
    algorithm                   = "RSA"
    rsa_bits                    = 2048
}

# -----------------------------------------------------------------------------
# Create CPE instance
# -----------------------------------------------------------------------------

resource "oci_core_instance" "IAD-NP-LAB06-VMCPE-01" {
    provider                    = oci.ashburn
    availability_domain         = local.ad1
    compartment_id              = var.compartment_id
    shape                       = "VM.Standard.A1.Flex"

    create_vnic_details {
        subnet_id               = oci_core_subnet.IAD-NP-LAB06-SNET-01.id
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
        ssh_authorized_keys         = tls_private_key.ocinplab06cpekey.public_key_openssh
    }
}

# -----------------------------------------------------------------------------
# Create PING instance
# -----------------------------------------------------------------------------

resource "oci_core_instance" "IAD-NP-LAB06-PingVM-01" {
    provider                    = oci.ashburn
    availability_domain         = local.ad1
    compartment_id              = var.compartment_id
    shape                       = "VM.Standard.A1.Flex"

    create_vnic_details {
        subnet_id               = oci_core_subnet.IAD-NP-LAB06-SNET-02.id
        assign_public_ip        = false
    }

    source_details {
        source_type                 = "image"
        source_id                   = local.latest_ol8_image_id
    }

    shape_config                {
        ocpus                       = 1
        memory_in_gbs               = 6
    }
}