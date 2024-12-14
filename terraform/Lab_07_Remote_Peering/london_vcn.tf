# ------------------------------------------------------------------------------
# Lab 07:
# Remote Peering: InterConnect OCI resources between regions and extend to on-premises
# 
# Create Resources in UK South (London) Region
# ------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Virtual Cloud Network resource block
# ------------------------------------------------------------------------------

resource "oci_core_vcn" "LHR-NP-LAB07-VCN-01" {
    provider                    = oci.london
    compartment_id              = var.compartment_id
    display_name                = "LHR-NP-LAB07-VCN-01"
    cidr_blocks                 = ["172.17.0.0/16"]
    dns_label                   = "lhrlab07vcn01"
}

# ------------------------------------------------------------------------------
# Attach Gateways to VCN
# ------------------------------------------------------------------------------

resource "oci_core_internet_gateway" "LHR-NP-LAB07-IG-01" {
    provider                    = oci.london
    compartment_id              = var.compartment_id
    display_name                = "Internet gateway-LHR-NP-LAB07-VCN-01"
    vcn_id                      = oci_core_vcn.LHR-NP-LAB07-VCN-01.id
}

# ------------------------------------------------------------------------------
# DHCP Options
# ------------------------------------------------------------------------------

resource "oci_core_default_dhcp_options" "LHR-DHCP-Options-VCN-01" {
    provider                    = oci.london
    manage_default_resource_id  = oci_core_vcn.LHR-NP-LAB07-VCN-01.default_dhcp_options_id
    compartment_id              = var.compartment_id
    display_name                = "DHCP Options for LHR-NP-LAB07-VCN-01"
    domain_name_type            = "CUSTOM_DOMAIN"
    options {
        custom_dns_servers      = [
        ]
        server_type             = "VcnLocalPlusInternet"
        type                    = "DomainNameServer"
    }
    options {
        search_domain_names     = [
            "lhrlab07vcn01.oraclevcn.com",
        ]
        type = "SearchDomain"
    }
}

# ------------------------------------------------------------------------------
# Subnets
# ------------------------------------------------------------------------------

resource "oci_core_subnet" "LHR-NP-LAB07-SNET-01" {
    provider                    = oci.london
    cidr_block                  = "172.17.0.0/24"
    compartment_id              = var.compartment_id
    display_name                = "public subnet-LHR-NP-LAB07-VCN-01"
    dns_label                   = "public"
    prohibit_internet_ingress   = "false"
    prohibit_public_ip_on_vnic  = "false"
    vcn_id                      = oci_core_vcn.LHR-NP-LAB07-VCN-01.id
}

resource "oci_core_subnet" "LHR-NP-LAB07-SNET-02" {
    provider                    = oci.london
    cidr_block                  = "172.17.1.0/24"
    compartment_id              = var.compartment_id
    display_name                = "private subnet-LHR-NP-LAB07-VCN-01"
    dns_label                   = "private"
    prohibit_internet_ingress   = "true"
    prohibit_public_ip_on_vnic  = "true"
    vcn_id                      = oci_core_vcn.LHR-NP-LAB07-VCN-01.id
}

# ------------------------------------------------------------------------------
# Route tables
# ------------------------------------------------------------------------------

resource "oci_core_default_route_table" "LHR-NP-LAB07-VCN-01-default-route-table" {
    provider                    = oci.london
    compartment_id              = var.compartment_id
    display_name                = "default route table for LHR-NP-LAB07-VCN-01"
    route_rules {
        destination             = "0.0.0.0/0"
        destination_type        = "CIDR_BLOCK"
        network_entity_id       = oci_core_internet_gateway.LHR-NP-LAB07-IG-01.id
    }
    route_rules {
        destination             = "172.31.0.0/16"
        destination_type        = "CIDR_BLOCK"
        network_entity_id       = oci_core_drg.LHR-NP-LAB07-DRG-01.id
    }
    manage_default_resource_id  = oci_core_vcn.LHR-NP-LAB07-VCN-01.default_route_table_id
}

# ------------------------------------------------------------------------------
# Security lists (aka Firewall Rules)
# ------------------------------------------------------------------------------

resource "oci_core_default_security_list" "LHR-Default-Security-List-VCN-01" {
    provider                    = oci.london
    compartment_id              = var.compartment_id
    display_name                = "Default Security List for LHR-NP-LAB07-VCN-01"
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
            type                = "8"
        }
        protocol                = "1"
        source                  = "172.31.0.0/16"
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
    }
    manage_default_resource_id  = oci_core_vcn.LHR-NP-LAB07-VCN-01.default_security_list_id
}
