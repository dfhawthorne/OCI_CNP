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
# Get OCI Data 
# ------------------------------------------------------------------------------

# -------------------------------------------------------------------------------
# VCN
# -------------------------------------------------------------------------------

data "oci_core_vcn" "mastadon_vcn" {
    vcn_id         = "ocid1.vcn.oc1.ap-sydney-1.amaaaaaa63mv4jya75cfieoatbehnc3rn4q6abdcjmwxa5pdqddhic464n4q"
}

output "mastadon_vcn" {
  value = data.oci_core_vcn.mastadon_vcn
}

# -------------------------------------------------------------------------------
# Subnet
# -------------------------------------------------------------------------------

data "oci_core_subnet" "mastadon_subnet" {
    subnet_id         = "ocid1.subnet.oc1.ap-sydney-1.aaaaaaaazjblkfk54cu4gpm2d2axvzvvoj4rpimbm2qyusqop7l6lv2fnefq"
}

output "mastadon_subnet" {
  value = data.oci_core_subnet.mastadon_subnet
}
