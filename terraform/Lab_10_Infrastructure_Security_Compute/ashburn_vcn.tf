# ------------------------------------------------------------------------------
# Lab 10:
# Infrastructure Security - Compute: Set Up a Bastion Host
#
# Create and Configure a Virtual Cloud Network
# ------------------------------------------------------------------------------

data "oci_core_services" "ashburn" {
    provider                    = oci.ashburn
}


resource "oci_core_vcn" "IAD-NP-LAB10-VCN-01" {
    provider                    = oci.ashburn
	compartment_id              = var.compartment_id
	cidr_blocks                 = ["10.0.0.0/16"]
	display_name                = "IAD-NP-LAB10-VCN-01"
	dns_label                   = "iadnplab10vcn01"
}

resource "oci_core_subnet" "IAD-NP-LAB10-SNET-01" {
    provider                    = oci.ashburn
	cidr_block                  = "10.0.1.0/24"
	compartment_id              = var.compartment_id
	vcn_id                      = oci_core_vcn.IAD-NP-LAB10-VCN-01.id
	display_name                = "IAD-NP-LAB10-SNET-01"
	dns_label                   = "private"
	prohibit_internet_ingress   = true
	prohibit_public_ip_on_vnic  = true
}

# ------------------------------------------------------------------------------
# Gateways
# ------------------------------------------------------------------------------

resource "oci_core_nat_gateway" "IAD-NP-LAB10-NATG-01" {
    provider                    = oci.ashburn
    block_traffic               = "false"
    compartment_id              = var.compartment_id
    display_name                = "IAD-NP-LAB10-NATG-01"
    vcn_id                      = oci_core_vcn.IAD-NP-LAB10-VCN-01.id
}

resource "oci_core_service_gateway" "IAD-NP-LAB10-SG-01" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "IAD-NP-LAB10-SG-01"
    services {
        service_id              = data.oci_core_services.ashburn.services[0].id
    }
    vcn_id                      = oci_core_vcn.IAD-NP-LAB10-VCN-01.id
}

# ------------------------------------------------------------------------------
# Route Tables
# ------------------------------------------------------------------------------

resource oci_core_default_route_table default-route-table-for-IAD-NP-LAB10-VCN-01 {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    manage_default_resource_id  = oci_core_vcn.IAD-NP-LAB10-VCN-01.default_route_table_id
    route_rules {
        destination             = "0.0.0.0/0"
        destination_type        = "CIDR_BLOCK"
        network_entity_id       = oci_core_nat_gateway.IAD-NP-LAB10-NATG-01.id
    }
    route_rules {
        destination             = data.oci_core_services.ashburn.services[0].cidr_block
        destination_type        = "SERVICE_CIDR_BLOCK"
        network_entity_id       = oci_core_service_gateway.IAD-NP-LAB10-SG-01.id
    }
}

