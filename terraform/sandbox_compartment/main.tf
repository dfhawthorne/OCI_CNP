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
# VCN
# -------------------------------------------------------------------------------

resource "oci_core_vcn" "sandbox_vcn" {
  compartment_id  = local.sandbox_comp_ocid
  cidr_blocks     = ["10.0.0.0/16"]
  display_name    = "sandbox-vcn"
  dns_label       = "sandbox"
}

# -------------------------------------------------------------------------------
# Gateways
# -------------------------------------------------------------------------------

resource "oci_core_internet_gateway" "sandbox_internet_gateway" {
  compartment_id  = local.sandbox_comp_ocid
  vcn_id          = oci_core_vcn.sandbox_vcn.id
  display_name    = "Sandbox Internet Gateway"
}

data "oci_core_services" "sandbox_services" {
}

resource "oci_core_service_gateway" "test_service_gateway" {
  compartment_id  = local.sandbox_comp_ocid
  vcn_id          = oci_core_vcn.sandbox_vcn.id
  display_name    = "Sandbox Service Gateway"
  services        {
    service_id = data.oci_core_services.sandbox_services.services.0.id
  }
}

resource "oci_core_nat_gateway" "sandbox_nat_gateway" {
  compartment_id  = local.sandbox_comp_ocid
  vcn_id          = oci_core_vcn.sandbox_vcn.id
  display_name    = "Sandbox NAT Gateway"
}

# -------------------------------------------------------------------------------
# Route Tables
# -------------------------------------------------------------------------------

resource "oci_core_route_table" "internet_connectivity" {
  compartment_id  = local.sandbox_comp_ocid
  vcn_id          = oci_core_vcn.sandbox_vcn.id
  display_name    = "Sandbox internet connectivity"
  route_rules {
    network_entity_id = oci_core_internet_gateway.sandbox_internet_gateway.id
    description       = "Connection to Internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    }
}

# -------------------------------------------------------------------------------
# Subnets
# -------------------------------------------------------------------------------

resource "oci_core_subnet" "sandbox_public_subnet" {
  cidr_block                  = "10.0.1.0/24"
  compartment_id              = local.sandbox_comp_ocid
  vcn_id                      = oci_core_vcn.sandbox_vcn.id
  display_name	              = "public subnet-sandbox-vcn"
  dns_label                   = "public"
  prohibit_internet_ingress   = false
  prohibit_public_ip_on_vnic  = false
}

resource "oci_core_subnet" "sandbox_private_subnet" {
  cidr_block                  = "10.0.2.0/24"
  compartment_id              = local.sandbox_comp_ocid
  vcn_id                      = oci_core_vcn.sandbox_vcn.id
  display_name	              = "private subnet-sandbox-vcn"
  dns_label                   = "private"
  prohibit_internet_ingress   = true
  prohibit_public_ip_on_vnic  = true
}

resource "oci_core_subnet" "sandbox_example_subnet" {
  cidr_block                  = "10.0.3.0/24"
  compartment_id              = local.sandbox_comp_ocid
  vcn_id                      = oci_core_vcn.sandbox_vcn.id
  display_name	              = "example_subnet"
  dns_label                   = "example"
  prohibit_internet_ingress   = true
  prohibit_public_ip_on_vnic  = true
}

# -------------------------------------------------------------------------------
# Compute instances
# -------------------------------------------------------------------------------

data "oci_core_images" "centos_8_images" {
    compartment_id            = local.sandbox_comp_ocid
    operating_system          = "CentOS"
    operating_system_version  = "8 Stream"
    shape                     = "VM.Standard.E2.1.Micro"
    state                     = "AVAILABLE"
    sort_by                   = "TIMECREATED"
    sort_order                = "DESC"
}

resource "oci_core_instance" "sandbox_vm01" {
  availability_domain = local.ad_ocid
  compartment_id      = local.sandbox_comp_ocid
  shape               = "VM.Standard.E2.1.Micro"
  create_vnic_details {
    assign_public_ip  = true
    subnet_id         = oci_core_subnet.sandbox_public_subnet.id
    hostname_label    = "vm01"
  }
  display_name        = "Sandbox public VM"
  source_details {
    source_id         = data.oci_core_images.centos_8_images.id
    source_type       = "image"
  }
}