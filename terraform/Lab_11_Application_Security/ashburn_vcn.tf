# ------------------------------------------------------------------------------
# Lab 11:
# Application Security: Create and Configure Web Access Firewall
#
# Create a Virtual Cloud Network
#
# Create a VCN with a public and private subnets. The compute instance will be 
# hosted in the public subnet.
# ------------------------------------------------------------------------------

data "oci_core_services" "ashburn" {
    provider                    = oci.ashburn
}

# ------------------------------------------------------------------------------
# VCN and associated sub-nets
# ------------------------------------------------------------------------------

resource "oci_core_vcn" "IAD-NP-LAB11-VCN-01" {
    provider                        = oci.ashburn
    compartment_id                  = var.compartment_id
    display_name                    = "IAD-NP-LAB11-VCN-01"
    dns_label                       = "iadnplab11vcn01"
    cidr_blocks                     = ["10.0.0.0/16"]
}

resource "oci_core_subnet" "IAD-NP-LAB11-SNET-01" {
	provider                        = oci.ashburn
	cidr_block                      = "10.0.1.0/24"
	compartment_id                  = var.compartment_id
	vcn_id                          = oci_core_vcn.IAD-NP-LAB11-VCN-01.id
	display_name                    = "IAD-NP-LAB11-SNET-01"
	dns_label                       = "public"
	prohibit_internet_ingress       = false
	prohibit_public_ip_on_vnic      = false
}

resource "oci_core_subnet" "IAD-NP-LAB11-SNET-02" {
	provider                        = oci.ashburn
	cidr_block                      = "10.0.2.0/24"
	compartment_id                  = var.compartment_id
	vcn_id                          = oci_core_vcn.IAD-NP-LAB11-VCN-01.id
	display_name                    = "IAD-NP-LAB11-SNET-02"
	dns_label                       = "private"
	prohibit_internet_ingress       = true
	prohibit_public_ip_on_vnic      = true
    route_table_id                  = oci_core_route_table.private-route-table-for-IAD-NP-LAB11-VCN-01.id
}

# ------------------------------------------------------------------------------
# Gateways
# ------------------------------------------------------------------------------

resource "oci_core_internet_gateway" "IAD-NP-LAB11-IG-01" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "IAD-NP-LAB11-IG-01"
    enabled                     = true
    vcn_id                      = oci_core_vcn.IAD-NP-LAB11-VCN-01.id
}

resource "oci_core_nat_gateway" "IAD-NP-LAB11-NATG-01" {
    provider                    = oci.ashburn
    block_traffic               = "false"
    compartment_id              = var.compartment_id
    display_name                = "IAD-NP-LAB11-NATG-01"
    vcn_id                      = oci_core_vcn.IAD-NP-LAB11-VCN-01.id
}

resource "oci_core_service_gateway" "IAD-NP-LAB11-SG-01" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "IAD-NP-LAB11-SG-01"
    services {
        service_id              = data.oci_core_services.ashburn.services[0].id
    }
    vcn_id                      = oci_core_vcn.IAD-NP-LAB11-VCN-01.id
}


# ------------------------------------------------------------------------------
# Route Tables
# ------------------------------------------------------------------------------

resource oci_core_default_route_table default-route-table-for-IAD-NP-LAB11-VCN-01 {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    manage_default_resource_id  = oci_core_vcn.IAD-NP-LAB11-VCN-01.default_route_table_id
    route_rules {
        destination             = "0.0.0.0/0"
        destination_type        = "CIDR_BLOCK"
        network_entity_id       = oci_core_internet_gateway.IAD-NP-LAB11-IG-01.id
    }
    route_rules {
        destination             = data.oci_core_services.ashburn.services[0].cidr_block
        destination_type        = "SERVICE_CIDR_BLOCK"
        network_entity_id       = oci_core_service_gateway.IAD-NP-LAB11-SG-01.id
    }
}

resource oci_core_route_table private-route-table-for-IAD-NP-LAB11-VCN-01 {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
	vcn_id                      = oci_core_vcn.IAD-NP-LAB11-VCN-01.id
    route_rules {
        destination             = "10.0.0.0/0"
        destination_type        = "CIDR_BLOCK"
        network_entity_id       = oci_core_nat_gateway.IAD-NP-LAB11-NATG-01.id
    }
    route_rules {
        destination             = "0.0.0.0/0"
        destination_type        = "CIDR_BLOCK"
        network_entity_id       = oci_core_nat_gateway.IAD-NP-LAB11-NATG-01.id
    }
}
