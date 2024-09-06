# ------------------------------------------------------------------------------
# Module to create a VCN with Internet Connectivity
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Providers 
# ------------------------------------------------------------------------------

terraform {
    required_providers {
        oci = {
            source = "oracle/oci"
        }
    }
}

# ------------------------------------------------------------------------------
# Virtual Cloud Network resource block
# ------------------------------------------------------------------------------

resource "oci_core_vcn" "vcn" {
    compartment_id              = var.compartment_id
    display_name                = var.vcn_details.name
    cidr_blocks                 = var.vcn_details.cidr_blocks
    dns_label                   = var.vcn_details.dns_label
}

# ------------------------------------------------------------------------------
# Attach Gateways to VCN
# ------------------------------------------------------------------------------

resource "oci_core_nat_gateway" "NAT-gateway" {
    block_traffic               = "false"
    compartment_id              = var.compartment_id
    display_name                = "NAT gateway-${var.vcn_details.name}"
    vcn_id                      = oci_core_vcn.vcn.id
}

resource "oci_core_internet_gateway" "Internet-gateway" {
    compartment_id              = var.compartment_id
    display_name                = "Internet gateway-${var.vcn_details.name}"
    enabled                     = "true"
    vcn_id                      = oci_core_vcn.vcn.id
}

resource "oci_core_service_gateway" "Service-gateway" {
    compartment_id              = var.compartment_id
    display_name                = "Service gateway-${var.vcn_details.name}"
    services {
        service_id              = var.services_details.service_id
    }
    vcn_id                      = oci_core_vcn.vcn.id
}

# ------------------------------------------------------------------------------
# DHCP Options
# ------------------------------------------------------------------------------

resource "oci_core_dhcp_options" "DHCP-Options" {
    vcn_id                      = oci_core_vcn.vcn.id
    compartment_id              = var.compartment_id
    display_name                = "DHCP Options for ${var.vcn_details.name}"
    domain_name_type            = "CUSTOM_DOMAIN"
    options {
        custom_dns_servers      = [
        ]
        server_type             = "VcnLocalPlusInternet"
        type                    = "DomainNameServer"
    }
    options {
        search_domain_names     = [
            "${var.vcn_details.dns_label}.oraclevcn.com",
        ]
        type = "SearchDomain"
    }
}

# ------------------------------------------------------------------------------
# Subnets
# ------------------------------------------------------------------------------

resource "oci_core_subnet" "public-subnet" {
    cidr_block                  = var.public_subnet_details.cidr_block
    compartment_id              = var.compartment_id
    dhcp_options_id             = oci_core_dhcp_options.DHCP-Options.id
    display_name                = "public subnet-${var.vcn_details.name}"
    dns_label                   = var.public_subnet_details.dns_label
    prohibit_internet_ingress   = "false"
    prohibit_public_ip_on_vnic  = "false"
    route_table_id              = oci_core_route_table.default-route-table.id
    security_list_ids           = [
        oci_core_vcn.vcn.default_security_list_id,
    ]
    vcn_id                      = oci_core_vcn.vcn.id
}

resource "oci_core_subnet" "private-subnet" {
    cidr_block                  = var.private_subnet_details.cidr_block
    compartment_id              = var.compartment_id
    dhcp_options_id             = oci_core_dhcp_options.DHCP-Options.id
    display_name                = "private subnet-${var.vcn_details.name}"
    dns_label                   = var.private_subnet_details.dns_label
    prohibit_internet_ingress   = "true"
    prohibit_public_ip_on_vnic  = "true"
    route_table_id              = oci_core_route_table.route-table-for-private-subnet.id
    security_list_ids           = [
        oci_core_security_list.security-list-for-private-subnet.id,
    ]
    vcn_id                      = oci_core_vcn.vcn.id
}

# ------------------------------------------------------------------------------
# Route tables
# ------------------------------------------------------------------------------

resource "oci_core_route_table" "route-table-for-private-subnet" {
    compartment_id              = var.compartment_id
    display_name                = "route table for private subnet-${var.vcn_details.name}"
    route_rules {
        destination             = "0.0.0.0/0"
        destination_type        = "CIDR_BLOCK"
        network_entity_id       = oci_core_nat_gateway.NAT-gateway.id
    }
    route_rules {
        destination             = var.services_details.destination
        destination_type        = "SERVICE_CIDR_BLOCK"
        network_entity_id       = oci_core_service_gateway.Service-gateway.id
    }
    vcn_id                      = oci_core_vcn.vcn.id
}

resource "oci_core_route_table" "default-route-table" {
    compartment_id              = var.compartment_id
    display_name                = "default route table for ${var.vcn_details.name}"
    route_rules {
        destination             = "0.0.0.0/0"
        destination_type        = "CIDR_BLOCK"
        network_entity_id       = oci_core_internet_gateway.Internet-gateway.id
    }
    dynamic "route_rules" {
        for_each                = var.default_route_rules
        content {
            destination         = route_rules.value.destination
            destination_type    = route_rules.value.destination_type
            network_entity_id   = route_rules.value.network_entity_id
        }
    }
    vcn_id                      = oci_core_vcn.vcn.id
}

# ------------------------------------------------------------------------------
# Security lists (aka Firewall Rules)
# ------------------------------------------------------------------------------

resource "oci_core_security_list" "security-list-for-private-subnet" {
    compartment_id              = var.compartment_id
    display_name                = "security list for private subnet-${var.vcn_details.name}"
    egress_security_rules {
        destination             = "0.0.0.0/0"
        destination_type        = "CIDR_BLOCK"
        protocol                = "all"
        stateless               = "false"
    }
    ingress_security_rules {
        protocol                = "6"
        source                  = var.vcn_details.cidr_blocks[0]
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
        tcp_options {
            max                 = "22"
            min                 = "22"
        }
    }
    ingress_security_rules {
        icmp_options {
            code                = "4"
            type                = "3"
        }
        protocol                = "1"
        source                  = "0.0.0.0/0"
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
    }
    ingress_security_rules {
        icmp_options {
            code                = "-1"
            type                = "3"
        }
        protocol                = "1"
        source                  = var.vcn_details.cidr_blocks[0]
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
    }
    vcn_id                      = oci_core_vcn.vcn.id
}

resource "oci_core_default_security_list" "Default-Security-List" {
    compartment_id              = var.compartment_id
    display_name                = "Default Security List for ${var.vcn_details.name}"
    egress_security_rules {
        destination             = "0.0.0.0/0"
        destination_type        = "CIDR_BLOCK"
        protocol                = "all"
        stateless               = "false"
    }
    ingress_security_rules {
        protocol                = "6"
        source                  = "0.0.0.0/0"
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
        tcp_options {
            max                 = "22"
            min                 = "22"
        }
    }
    ingress_security_rules {
        icmp_options {
            code                = "4"
            type                = "3"
        }
        protocol                = "1"
        source                  = "0.0.0.0/0"
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
    }
    ingress_security_rules {
        icmp_options {
            code                = "-1"
            type                = "3"
        }
        protocol                = "1"
        source                  = var.vcn_details.cidr_blocks[0]
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
    }
    dynamic "ingress_security_rules" {
        for_each                = var.allowable_sources_for_pings
        content {
            icmp_options {
                type            = "8"
            }
            protocol            = "1"
            source              = ingress_security_rules.value
            source_type         = "CIDR_BLOCK"
            stateless           = "false"
        }
    }
    manage_default_resource_id  = oci_core_vcn.vcn.default_security_list_id
}

