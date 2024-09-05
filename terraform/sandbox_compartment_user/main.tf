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

data "oci_identity_compartment" "sandbox_comp" {
  compartment_id  = var.tenancy_ocid
  description     = "Sandbox"
  name            = "Sandbox"
}

data "oci_identity_availability_domains" "all_availability_domains" {
  compartment_id  = var.tenancy_ocid
}

locals {
  sandbox_comp_ocid = data.oci_identity_compartment.sandbox_comp.id
  ad_name           = data.oci_identity_availability_domains.all_availability_domains.name
}

# -------------------------------------------------------------------------------
# VCN
# -------------------------------------------------------------------------------

data "oci_core_vcn" "sandbox_vcn" {
  compartment_id                = local.sandbox_comp_ocid
  display_name                  = "sandbox-vcn"
}

# -------------------------------------------------------------------------------
# Subnets
# -------------------------------------------------------------------------------

data "oci_core_subnet" "sandbox_public_subnet" {
  compartment_id                = local.sandbox_comp_ocid
  vcn_id                        = data.oci_core_vcn.sandbox_vcn.id
  display_name	                = "public subnet-sandbox-vcn"
}

data "oci_core_subnet" "sandbox_private_subnet" {
  compartment_id                = local.sandbox_comp_ocid
  vcn_id                        = data.oci_core_vcn.sandbox_vcn.id
  display_name	                = "private subnet-sandbox-vcn"
}

# -------------------------------------------------------------------------------
# Compute instances
# -------------------------------------------------------------------------------

data "oci_core_images" "centos_8_images" {
    compartment_id              = local.sandbox_comp_ocid
    operating_system            = "CentOS"
    operating_system_version    = "8 Stream"
    shape                       = "VM.Standard.E2.1.Micro"
    state                       = "AVAILABLE"
    sort_by                     = "TIMECREATED"
    sort_order                  = "DESC"
}

resource "oci_core_instance" "sandbox_vm01" {
  availability_domain           = local.ad_name
  compartment_id                = local.sandbox_comp_ocid
  shape                         = "VM.Standard.E2.1.Micro"
  shape_config                  {
    ocpus                       = 1
    memory_in_gbs               = 6
    }
  create_vnic_details           {
    assign_public_ip            = true
    subnet_id                   = data.oci_core_subnet.sandbox_public_subnet.id
    hostname_label              = "vm01"
  }
  display_name                  = "Sandbox public VM"
  source_details                {
    source_id                   = data.oci_core_images.centos_8_images.id
    source_type                 = "image"
  }
}

