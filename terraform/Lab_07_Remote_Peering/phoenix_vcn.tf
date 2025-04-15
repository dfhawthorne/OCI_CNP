# ------------------------------------------------------------------------------------
# Lab 06:
# Site-to-Site Virtual Private Network: Connect OCI resources to on-premises via
# site-to-site VPN, using LibreSwan as the customer premises equipment
# 
# Create Site-to-Site VPN Resources in Phoenix Region
#
# Next, you will create in the OCI Phoenix region all the resources required to 
# configure a site-to-site VPN (VPN): customer premises equipment (CPE) dynamic
# routing gateway (DRG), VPN tunnels, virtual cloud network (VCN); compute virtutual
# machine (VM) for testing the connectivity.
#
# Updated for Lab 07
# ------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Virtual Cloud Network resource block
# ------------------------------------------------------------------------------

resource "oci_core_vcn" "PHX-NP-LAB06-VCN-01" {
    provider                    = oci.phoenix
    compartment_id              = var.compartment_id
    display_name                = "PHX-NP-LAB06-VCN-01"
    cidr_blocks                 = ["172.31.0.0/16"]
    dns_label                   = "phxlab06vcn01"
}

# ------------------------------------------------------------------------------
# Attach Gateways to VCN
# ------------------------------------------------------------------------------

resource "oci_core_internet_gateway" "PHX-NP-LAB06-IG-01" {
    provider                    = oci.phoenix
    compartment_id              = var.compartment_id
    display_name                = "PHX-NP-LAB06-IG-01"
    vcn_id                      = oci_core_vcn.PHX-NP-LAB06-VCN-01.id
}

# ------------------------------------------------------------------------------
# DHCP Options
# ------------------------------------------------------------------------------

resource "oci_core_default_dhcp_options" "DHCP-Options-VCN-01" {
    provider                    = oci.phoenix
    manage_default_resource_id  = oci_core_vcn.PHX-NP-LAB06-VCN-01.default_dhcp_options_id
    compartment_id              = var.compartment_id
    display_name                = "PHX-NP-LAB06-DHCP-01"
    domain_name_type            = "CUSTOM_DOMAIN"
    options {
        custom_dns_servers      = [
        ]
        server_type             = "VcnLocalPlusInternet"
        type                    = "DomainNameServer"
    }
    options {
        search_domain_names     = [
            "phxlab06vcn01.oraclevcn.com",
        ]
        type = "SearchDomain"
    }
}

# ------------------------------------------------------------------------------
# Subnets
# ------------------------------------------------------------------------------

resource "oci_core_subnet" "PHX-NP-LAB06-SNET-01" {
    provider                    = oci.phoenix
    cidr_block                  = "172.31.0.0/24"
    compartment_id              = var.compartment_id
    display_name                = "PHX-NP-LAB06-SNET-01"
    dns_label                   = "public"
    prohibit_internet_ingress   = "false"
    prohibit_public_ip_on_vnic  = "false"
    vcn_id                      = oci_core_vcn.PHX-NP-LAB06-VCN-01.id
}

resource "oci_core_subnet" "PHX-NP-LAB06-SNET-02" {
    provider                    = oci.phoenix
    cidr_block                  = "172.31.1.0/24"
    compartment_id              = var.compartment_id
    display_name                = "PHX-NP-LAB06-SNET-02"
    dns_label                   = "private"
    prohibit_internet_ingress   = "true"
    prohibit_public_ip_on_vnic  = "true"
    vcn_id                      = oci_core_vcn.PHX-NP-LAB06-VCN-01.id
}

# ------------------------------------------------------------------------------
# Route tables
# ------------------------------------------------------------------------------

resource "oci_core_default_route_table" "PHX-NP-LAB06-VCN-01-default-route-table" {
    provider                    = oci.phoenix
    compartment_id              = var.compartment_id
    display_name                = "PHX-NP-LAB06-RT-01"
    route_rules {
        destination             = "0.0.0.0/0"
        destination_type        = "CIDR_BLOCK"
        network_entity_id       = oci_core_internet_gateway.PHX-NP-LAB06-IG-01.id
    }
    route_rules {
        destination             = "192.168.20.0/24"
        destination_type        = "CIDR_BLOCK"
        network_entity_id       = oci_core_drg.PHX-NP-LAB06-DRG-01.id
    }
    route_rules {
        destination             = "172.17.0.0/16"
        destination_type        = "CIDR_BLOCK"
        network_entity_id       = oci_core_drg.PHX-NP-LAB06-DRG-01.id
    }
    manage_default_resource_id  = oci_core_vcn.PHX-NP-LAB06-VCN-01.default_route_table_id
}

# ------------------------------------------------------------------------------
# Security lists (aka Firewall Rules)
# ------------------------------------------------------------------------------

resource "oci_core_default_security_list" "PHX_Default-Security-List-VCN-01" {
    provider                    = oci.phoenix
    compartment_id              = var.compartment_id
    display_name                = "PHX-NP-LAB06-SL-01"
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
        source                  = "172.31.0.0/16"
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
    }
    ingress_security_rules {
        icmp_options {
            code                = "-1"
            type                = "8"
        }
        protocol                = "1"
        source                  = "192.168.20.0/24"
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
    }
    ingress_security_rules {
        icmp_options {
            code                = "-1"
            type                = "8"
        }
        protocol                = "1"
        source                  = "172.17.0.0/16"
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
    }
    manage_default_resource_id  = oci_core_vcn.PHX-NP-LAB06-VCN-01.default_security_list_id
}
