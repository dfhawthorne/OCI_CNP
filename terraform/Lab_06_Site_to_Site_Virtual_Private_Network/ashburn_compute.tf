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

data "oci_identity_availability_domains" "iad_ads" {
    provider                    = oci.ashburn
    compartment_id              = var.provider_details.tenancy_ocid
}

data "oci_core_images" "iad_ol9_images" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    operating_system            = "Oracle Linux"
    operating_system_version    = "9"
    shape                       = "VM.Standard.A1.Flex"
    sort_by                     = "TIMECREATED"
    sort_order                  = "DESC"
}

locals {
    iad_ad1                     = data.oci_identity_availability_domains.iad_ads.availability_domains[0].name
    latest_iad_ol9_image_id     = data.oci_core_images.iad_ol9_images.images[0].id
}

# -----------------------------------------------------------------------------
# Create CPE instance
# -----------------------------------------------------------------------------

resource "oci_core_instance" "IAD-NP-LAB06-VMCPE-01" {
    provider                    = oci.ashburn
    availability_domain         = local.iad_ad1
    compartment_id              = var.compartment_id
    shape                       = "VM.Standard.A1.Flex"
    display_name                = "IAD-NP-LAB06-VMCPE-01"

    create_vnic_details {
        subnet_id               = oci_core_subnet.IAD-NP-LAB06-SNET-01.id
        assign_public_ip        = true
        skip_source_dest_check  = true
    }

    source_details {
        source_type             = "image"
        source_id               = local.latest_iad_ol9_image_id
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

data "oci_core_vnic_attachments" "IAD-NP-LAB06-VMCPE-vnic-attachments" {
    provider                    = oci.ashburn
	compartment_id              = var.compartment_id
	instance_id                 = oci_core_instance.IAD-NP-LAB06-VMCPE-01.id
}

# ------------------------------------------------------------------------------
# Cannot use ip_address and subnet_id to look up the generated private IP OCID 
# as this combination generates the following error message:
# Error: Cycle: data.oci_core_private_ips.IAD-NP-LAB06-VMCPE-Private-IP, 
# oci_core_route_table.IAD-NP-LAB06-SNET-02-route-table, 
# oci_core_subnet.IAD-NP-LAB06-SNET-02
# ------------------------------------------------------------------------------

data "oci_core_private_ips" "IAD-NP-LAB06-VMCPE-Private-IP" {
    provider                    = oci.ashburn
    vnic_id                     = data.oci_core_vnic_attachments.IAD-NP-LAB06-VMCPE-vnic-attachments.vnic_attachments[0].vnic_id
}

# -----------------------------------------------------------------------------
# Create PING instance
# -----------------------------------------------------------------------------

resource "oci_core_instance" "IAD-NP-LAB06-PingVM-01" {
    provider                    = oci.ashburn
    availability_domain         = local.iad_ad1
    compartment_id              = var.compartment_id
    shape                       = "VM.Standard.A1.Flex"
    display_name                = "IAD-NP-LAB06-PingVM-01"

    create_vnic_details {
        subnet_id               = oci_core_subnet.IAD-NP-LAB06-SNET-02.id
        assign_public_ip        = false
    }

    source_details {
        source_type             = "image"
        source_id               = local.latest_iad_ol9_image_id
        boot_volume_size_in_gbs = 50
    }

    shape_config                {
        ocpus                   = 1
        memory_in_gbs           = 6
    }
}
