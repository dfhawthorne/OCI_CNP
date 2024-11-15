# ------------------------------------------------------------------------------
# Lab 05:
# Design and Implement a Real-Network Architecture: Configuring private DNS
# Zones, views, resolvers, listeners and forwarder
#
# Virtual Cloud Network 02
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Virtual Cloud Network resource block
# ------------------------------------------------------------------------------

resource "oci_core_vcn" "IAD-NP-LAB05-VCN-02" {
    compartment_id              = var.compartment_id
    display_name                = "IAD-NP-LAB05-VCN-02"
    cidr_blocks                 = ["172.0.0.0/16"]
    dns_label                   = "iadlab05vcn02"
}

# ------------------------------------------------------------------------------
# Attach Gateways to VCN
# ------------------------------------------------------------------------------

resource "oci_core_internet_gateway" "IAD-NP-LAB05-IG-02" {
    compartment_id              = var.compartment_id
    display_name                = "LPG gateway-IAD-NP-LAB05-VCN-02"
    vcn_id                      = oci_core_vcn.IAD-NP-LAB05-VCN-02.id
}

resource "oci_core_local_peering_gateway" "IAD-NP-LAB05-LPG-02" {
    compartment_id              = var.compartment_id
    display_name                = "LPG gateway-IAD-NP-LAB05-VCN-02"
    vcn_id                      = oci_core_vcn.IAD-NP-LAB05-VCN-02.id
    peer_id                     = oci_core_local_peering_gateway.IAD-NP-LAB05-LPG-01.id
}

# ------------------------------------------------------------------------------
# DHCP Options
# ------------------------------------------------------------------------------

resource "oci_core_default_dhcp_options" "DHCP-Options-VCN-02" {
    manage_default_resource_id  = oci_core_vcn.IAD-NP-LAB05-VCN-02.default_dhcp_options_id
    compartment_id              = var.compartment_id
    display_name                = "DHCP Options for IAD-NP-LAB05-VCN-02"
    domain_name_type            = "CUSTOM_DOMAIN"
    options {
        custom_dns_servers      = [
        ]
        server_type             = "VcnLocalPlusInternet"
        type                    = "DomainNameServer"
    }
    options {
        search_domain_names     = [
            "iadlab05vcn02.oraclevcn.com",
        ]
        type = "SearchDomain"
    }
}

# ------------------------------------------------------------------------------
# Route tables
# ------------------------------------------------------------------------------

resource "oci_core_default_route_table" "IAD-NP-LAB05-VCN-02-default-route-table" {
    compartment_id              = var.compartment_id
    display_name                = "default route table for IAD-NP-LAB05-VCN-02"
    route_rules {
        destination             = "0.0.0.0/0"
        destination_type        = "CIDR_BLOCK"
        network_entity_id       = oci_core_internet_gateway.IAD-NP-LAB05-IG-02.id
    }
    route_rules {
        destination             = "10.0.0.0/16"
        destination_type        = "CIDR_BLOCK"
        network_entity_id       = oci_core_local_peering_gateway.IAD-NP-LAB05-LPG-02.id
    }
    manage_default_resource_id  = oci_core_vcn.IAD-NP-LAB05-VCN-02.default_route_table_id
}

# ------------------------------------------------------------------------------
# Security lists (aka Firewall Rules)
# ------------------------------------------------------------------------------

resource "oci_core_default_security_list" "Default-Security-List-VCN-02" {
    compartment_id              = var.compartment_id
    display_name                = "Default Security List for IAD-NP-LAB05-VCN-02"
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
        source                  = "10.0.0.0/16"
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
    }
    ingress_security_rules {
        source                  = "10.0.0.0/16"
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
        protocol                = "all"
    }
    manage_default_resource_id  = oci_core_vcn.IAD-NP-LAB05-VCN-02.default_security_list_id
}

