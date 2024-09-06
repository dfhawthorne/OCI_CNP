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

# ------------------------------------------------------------------------------
# Create first VCN in Ashburn
# ------------------------------------------------------------------------------

module "create_vcn" {
    source                      = "../create_vcn"
    providers                   = {
        oci                     = oci.ashburn
    }
    compartment_id              = var.compartment_id
    vcn_details                 = {
        name                    = "IAD-NP-LAB02-VCN-01"
        cidr_blocks             = ["172.16.0.0/16"]
        dns_label               = "iadnplab02vcn01"
    }
    public_subnet_details       = {
        cidr_block              = "172.16.0.0/24"
        dns_label               = "public"
    }
    private_subnet_details      = {
        cidr_block              = "172.16.1.0/24"
        dns_label               = "private"
    }
    services_details            = {
        destination             = "all-iad-services-in-oracle-services-network"
        service_id              = "ocid1.service.oc1.iad.aaaaaaaam4zfmy2rjue6fmglumm3czgisxzrnvrwqeodtztg7hwa272mlfna"
    }
    default_route_rules         = [
        {
            destination         = "192.168.0.0/24"
            network_entity_id   = oci_core_local_peering_gateway.lpg_vcn_01.id
        }
    ]
    allowable_sources_for_pings = ["192.168.0.0/24"]
    provider_details            = var.provider_details
}

# ------------------------------------------------------------------------------
# Create second VCN in Ashburn
# ------------------------------------------------------------------------------

module "create_vcn_02" {
    source                      = "../create_vcn"
    providers                   = {
        oci                     = oci.ashburn
    }
    compartment_id              = var.compartment_id
    vcn_details                 = {
        name                    = "IAD-NP-LAB02-VCN-02"
        cidr_blocks             = ["192.168.0.0/16"]
        dns_label               = "iadnplab02vcn02"
    }
    public_subnet_details       = {
        cidr_block              = "192.168.0.0/24"
        dns_label               = "public"
    }
    private_subnet_details      = {
        cidr_block              = "192.168.1.0/24"
        dns_label               = "private"
    }
    services_details            = {
        destination             = "all-iad-services-in-oracle-services-network"
        service_id              = "ocid1.service.oc1.iad.aaaaaaaam4zfmy2rjue6fmglumm3czgisxzrnvrwqeodtztg7hwa272mlfna"
    }
    default_route_rules         = [
        {
            destination         = "172.16.0.0/24"
            network_entity_id   = oci_core_local_peering_gateway.lpg_vcn_02.id
        }
    ]
    allowable_sources_for_pings = ["172.16.0.0/24"]
    provider_details            = var.provider_details
}

# ------------------------------------------------------------------------------
# Create Local Peering Gateways
# ------------------------------------------------------------------------------

resource "oci_core_local_peering_gateway" "lpg_vcn_01" {
    provider                = oci.ashburn
    compartment_id          = var.compartment_id
    vcn_id                  = module.create_vcn.vcn_id
    display_name            = "IAD-NP-LAB02-LPG-01"
    peer_id                 = oci_core_local_peering_gateway.lpg_vcn_02.id
}

resource "oci_core_local_peering_gateway" "lpg_vcn_02" {
    provider                = oci.ashburn
    compartment_id          = var.compartment_id
    vcn_id                  = module.create_vcn_02.vcn_id
    display_name            = "IAD-NP-LAB02-LPG-02"
}
