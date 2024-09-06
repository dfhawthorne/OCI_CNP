# ------------------------------------------------------------------------------
# OCI CNP Lab 02:
# Configure Local Virtual Cloud Network (VCN) Peering
# ------------------------------------------------------------------------------

terraform {
    required_providers {
        oci                     = {
            source              = "oracle/oci"
        }
    }
}

# ------------------------------------------------------------------------------
# Configure the Oracle Cloud Infrastructure provider with an API Key
# ------------------------------------------------------------------------------

provider "oci" {
    alias                       = "ashburn"
    tenancy_ocid                = var.provider_details.tenancy_ocid
    user_ocid                   = var.provider_details.user_ocid
    fingerprint                 = var.provider_details.fingerprint
    private_key_path            = var.provider_details.private_key_path
    region                      = "us-ashburn-1"
}

provider "oci" {
    alias                       = "london"
    tenancy_ocid                = var.provider_details.tenancy_ocid
    user_ocid                   = var.provider_details.user_ocid
    fingerprint                 = var.provider_details.fingerprint
    private_key_path            = var.provider_details.private_key_path
    region                      = "uk-london-1"
}

# ------------------------------------------------------------------------------
# Create first VCN in Ashburn
# ------------------------------------------------------------------------------

module "vcn_01" {
    source                      = "../create_vcn"
    providers                   = {
        oci                     = oci.ashburn
    }
    compartment_id              = var.compartment_id
    vcn_details                 = {
        name                    = "IAD-NP-LAB03-VCN-01"
        cidr_blocks             = ["172.17.0.0/16"]
        dns_label               = "iadnpLAB03vcn01"
    }
    public_subnet_details       = {
        cidr_block              = "172.17.0.0/24"
        dns_label               = "public"
    }
    private_subnet_details      = {
        cidr_block              = "172.17.1.0/24"
        dns_label               = "private"
    }
    services_details            = {
        destination             = "all-iad-services-in-oracle-services-network"
        service_id              = "ocid1.service.oc1.iad.aaaaaaaam4zfmy2rjue6fmglumm3czgisxzrnvrwqeodtztg7hwa272mlfna"
    }
    default_route_rules         = [
        {
            destination         = "10.0.0.0/24"
            network_entity_id   = oci_core_drg.drg_vcn_01.id
        }
    ]
    allowable_sources_for_pings = ["10.0.0.0/24"]
    provider_details            = var.provider_details
}

# ------------------------------------------------------------------------------
# Create second VCN in London
# ------------------------------------------------------------------------------

module "vcn_02" {
    source                      = "../create_vcn"
    providers                   = {
        oci                     = oci.london
    }
    compartment_id              = var.compartment_id
    vcn_details                 = {
        name                    = "LHR-NP-LAB03-VCN-01"
        cidr_blocks             = ["10.0.0.0/16"]
        dns_label               = "lhrnpLAB03vcn02"
    }
    public_subnet_details       = {
        cidr_block              = "10.0.0.0/24"
        dns_label               = "public"
    }
    private_subnet_details      = {
        cidr_block              = "10.0.1.0/24"
        dns_label               = "private"
    }
    services_details            = {
        destination             = "all-lhr-services-in-oracle-services-network"
        service_id              = "ocid1.service.oc1.uk-london-1.aaaaaaaatwg7f5mnzoapfunl66n2qkp4ormiykqk3hiwksum63gcyjk7ysla"
    }
    default_route_rules         = [
        {
            destination         = "172.17.0.0/24"
            network_entity_id   = oci_core_drg.drg_vcn_02.id
        }
    ]
    allowable_sources_for_pings = ["172.17.0.0/24"]
    provider_details            = var.provider_details
}

# ------------------------------------------------------------------------------
# Create Remote Peering Gateways
# ------------------------------------------------------------------------------

resource "oci_core_drg" "drg_vcn_01" {
    provider                = oci.ashburn
    compartment_id          = var.compartment_id
    display_name            = "IAD-NP-LAB03-DRG-01"
}

resource "oci_core_drg" "drg_vcn_02" {
    provider                = oci.london
    compartment_id          = var.compartment_id
    display_name            = "LHR-NP-LAB03-DRG-01"
}

resource "oci_core_remote_peering_connection" "rpc_vcn_01" {
    provider                = oci.ashburn
    compartment_id          = var.compartment_id
    drg_id                  = oci_core_drg.drg_vcn_01.id
    display_name            = "IAD-NP-LAB03-RPC-01"
    peer_id                 = oci_core_remote_peering_connection.rpc_vcn_02.id
    peer_region_name        = "UK-LONDON-1"
}

resource "oci_core_remote_peering_connection" "rpc_vcn_02" {
    provider                = oci.london
    compartment_id          = var.compartment_id
    drg_id                  = oci_core_drg.drg_vcn_02.id
    display_name            = "LHR-NP-LAB03-RPC-01"
}

