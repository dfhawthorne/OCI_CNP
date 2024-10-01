# ------------------------------------------------------------------------------
# Terraform script for Retrieving OCI Data
# ------------------------------------------------------------------------------

# Warning: Additional provider information from registry
#
# The remote registry returned warnings for registry.terraform.io/hashicorp/oci:
# - For users on Terraform 0.13 or greater, this provider has moved to oracle/oci. Please update your
# source in required_providers.

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
    }
  }
}

# Configure the Oracle Cloud Infrastructure provider with an API Key
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# ------------------------------------------------------------------------------
# Sandbox Compartment
# ------------------------------------------------------------------------------

# Sandbox Compartment

data "oci_identity_compartments" "sandbox" {
    compartment_id          = var.tenancy_ocid
    name                    = "Sandbox"
}

locals {
    compartment_id          = data.oci_identity_compartments.sandbox.compartments[0].id
}

# Availability Domain

data "oci_identity_availability_domains" "ads" {
    compartment_id              = var.tenancy_ocid
}

locals {
    ad1                         = data.oci_identity_availability_domains.ads.availability_domains[0].name
}

# Sandbox VCN

data "oci_core_vcns" "sandbox" {
    compartment_id          = local.compartment_id
    display_name            = "Sandbox"
}

locals {
    vcn_id                  = data.oci_core_vcns.sandbox.virtual_networks[0].id
}

# Sandbox Public Subnet

data "oci_core_subnets" "sandbox" {
    compartment_id          = local.compartment_id
    display_name            = "public subnet-Sandbox"
    vcn_id                  = local.vcn_id
}

locals {
    public_subnet_id        = data.oci_core_subnets.sandbox.subnets[0].id
}

# OL8 Compute Images

data "oci_core_images" "ol8_images" {
    compartment_id          = local.compartment_id
    operating_system        = "Oracle Linux"
    operating_system_version = "8"
    shape                   = var.compute_shape
    state                   = "AVAILABLE"
    sort_by                 = "TIMECREATED"
    sort_order              = "DESC"
}

locals {
    latest_ol8_image_id     = data.oci_core_images.ol8_images.images[0].id
}

resource "oci_core_instance" "sandbox_vm01" {
  availability_domain           = local.ad1
  compartment_id                = local.compartment_id
  shape                         = var.compute_shape
  shape_config                  {
    ocpus                       = 1
    memory_in_gbs               = 6
    }
  create_vnic_details           {
    assign_public_ip            = true
    subnet_id                   = local.public_subnet_id
    hostname_label              = "vm01"
  }
  display_name                  = "Sandbox public VM"
  source_details                {
    source_id                   = local.latest_ol8_image_id
    source_type                 = "image"
  }
}

