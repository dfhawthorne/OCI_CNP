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

resource "oci_identity_compartment" "sandbox_comp" {
  compartment_id  = var.tenancy_ocid
  description     = "Sandbox"
  name            = "Sandbox"
}

data "oci_identity_availability_domains" "all_availability_domains" {
  compartment_id  = var.tenancy_ocid
}

locals {
  sandbox_comp_ocid = oci_identity_compartment.sandbox_comp.id
  ad_ocid           = data.oci_identity_availability_domains.all_availability_domains.id
}

# -------------------------------------------------------------------------------
# Sandbox Identity Domain
# -------------------------------------------------------------------------------

resource "oci_identity_domain" "sandbox_domain" {
    compartment_id              = local.sandbox_comp_ocid
    description                 = "Identity domain for Sandbox"
    display_name                = "Sandbox-Domain"
    home_region                 = var.region
    license_type                = "free"
    admin_email                 = var.sandbox_domain_admin_email
    admin_first_name            = var.sandbox_domain_admin_first_name
    admin_last_name             = var.sandbox_domain_admin_last_name
    admin_user_name             = "sandbox_admin"
    is_notification_bypassed    = false
    is_primary_email_required   = false
}

# -------------------------------------------------------------------------------
# Sandbox User and Group
# -------------------------------------------------------------------------------

resource "oci_identity_domains_user" "sandbox_user" {
  idcs_endpoint                 = oci_identity_domain.sandbox_domain.url
  schemas                       = ["urn:ietf:params:scim:schemas:core:2.0:User"]
  user_name                     = "sandbox-user"
  active                        = true
  emails {
    type                        = "work"
    value                       = var.sandbox_user_email
    primary                     = true
  }
}

#resource "oci_identity_group" "sandbox_common_group" {
#    compartment_id              = var.tenancy_ocid
#    description                 = "Common group for Sandbox"
#    name                        = "sandbox-common"
#}

# -------------------------------------------------------------------------------
# VCN
# -------------------------------------------------------------------------------

resource "oci_core_vcn" "sandbox_vcn" {
  compartment_id                = local.sandbox_comp_ocid
  cidr_blocks                   = ["10.0.0.0/16"]
  display_name                  = "sandbox-vcn"
  dns_label                     = "sandbox"
}

# -------------------------------------------------------------------------------
# Gateways
# -------------------------------------------------------------------------------

resource "oci_core_internet_gateway" "sandbox_internet_gateway" {
  compartment_id                = local.sandbox_comp_ocid
  vcn_id                        = oci_core_vcn.sandbox_vcn.id
  display_name                  = "Sandbox Internet Gateway"
}

# -------------------------------------------------------------------------------
# Route Tables
# -------------------------------------------------------------------------------

resource "oci_core_route_table" "internet_connectivity" {
  compartment_id                = local.sandbox_comp_ocid
  vcn_id                        = oci_core_vcn.sandbox_vcn.id
  display_name                  = "Sandbox internet connectivity"
  route_rules {
    network_entity_id           = oci_core_internet_gateway.sandbox_internet_gateway.id
    description                 = "Connection to Internet"
    destination                 = "0.0.0.0/0"
    destination_type            = "CIDR_BLOCK"
    }
}

# -------------------------------------------------------------------------------
# Subnets
# -------------------------------------------------------------------------------

resource "oci_core_subnet" "sandbox_public_subnet" {
  cidr_block                    = "10.0.1.0/24"
  compartment_id                = local.sandbox_comp_ocid
  vcn_id                        = oci_core_vcn.sandbox_vcn.id
  display_name	                = "public subnet-sandbox-vcn"
  dns_label                     = "public"
  prohibit_internet_ingress     = false
  prohibit_public_ip_on_vnic    = false
}

resource "oci_core_subnet" "sandbox_private_subnet" {
  cidr_block                    = "10.0.2.0/24"
  compartment_id                = local.sandbox_comp_ocid
  vcn_id                        = oci_core_vcn.sandbox_vcn.id
  display_name	                = "private subnet-sandbox-vcn"
  dns_label                     = "private"
  prohibit_internet_ingress     = true
  prohibit_public_ip_on_vnic    = true
}

resource "oci_core_subnet" "sandbox_example_subnet" {
  cidr_block                    = "10.0.3.0/24"
  compartment_id                = local.sandbox_comp_ocid
  vcn_id                        = oci_core_vcn.sandbox_vcn.id
  display_name	                = "example_subnet"
  dns_label                     = "example"
  prohibit_internet_ingress     = true
  prohibit_public_ip_on_vnic    = true
}

