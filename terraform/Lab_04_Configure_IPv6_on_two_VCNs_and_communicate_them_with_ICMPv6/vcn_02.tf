# ------------------------------------------------------------------------------
# Lab 04: Virtual Cloud Network (VCN): Configure IPv6 on two VCNs and
#         communicate between them with ICMPv6
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Virtual Cloud Network resource block for VCN 02
# ------------------------------------------------------------------------------

resource "oci_core_vcn" "vcn_02" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "IAD-NP-LAB04-VCN-02"
    cidr_blocks                 = ["10.2.0.0/16"]
    dns_label                   = "iadnplab04vcn02"
    is_ipv6enabled              = true
}

# ------------------------------------------------------------------------------
# Attach Gateways to VCN
# ------------------------------------------------------------------------------

resource "oci_core_internet_gateway" "Internet-gateway-02" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "IAD-NP-LAB04-VCN-02-IG-01"
    enabled                     = "true"
    vcn_id                      = oci_core_vcn.vcn_02.id
}

# ------------------------------------------------------------------------------
# DHCP Options
# ------------------------------------------------------------------------------

resource "oci_core_dhcp_options" "DHCP-Options-02" {
    provider                    = oci.ashburn
    vcn_id                      = oci_core_vcn.vcn_02.id
    compartment_id              = var.compartment_id
    display_name                = "DHCP Options for IAD-NP-LAB04-VCN-02"
    domain_name_type            = "CUSTOM_DOMAIN"
    options {
        custom_dns_servers      = [
        ]
        server_type             = "VcnLocalPlusInternet"
        type                    = "DomainNameServer"
    }
    options {
        search_domain_names     = [
            "iadnplab04vcn02.oraclevcn.com",
        ]
        type = "SearchDomain"
    }
}

# ------------------------------------------------------------------------------
# Subnets
# ------------------------------------------------------------------------------

resource "oci_core_subnet" "public-subnet-02" {
    provider                    = oci.ashburn
    cidr_block                  = "10.2.0.0/24"
    compartment_id              = var.compartment_id
    dhcp_options_id             = oci_core_dhcp_options.DHCP-Options-02.id
    display_name                = "IAD-NP-LAB04-VCN-02-SNT-01"
    dns_label                   = "public02"
    ipv6cidr_block              = cidrsubnet(oci_core_vcn.vcn_02.ipv6cidr_blocks[0], 8, parseint("7e",16))
    prohibit_internet_ingress   = "false"
    prohibit_public_ip_on_vnic  = "false"
    route_table_id              = oci_core_route_table.default-route-table-02.id
    security_list_ids           = [
        oci_core_vcn.vcn_02.default_security_list_id,
    ]
    vcn_id                      = oci_core_vcn.vcn_02.id
}

# ------------------------------------------------------------------------------
# Route tables
# ------------------------------------------------------------------------------

resource "oci_core_route_table" "default-route-table-02" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "default route table for IAD-NP-LAB04-VCN-02"
    route_rules {
        destination             = "0.0.0.0/0"
        destination_type        = "CIDR_BLOCK"
        network_entity_id       = oci_core_internet_gateway.Internet-gateway-02.id
    }
    vcn_id                      = oci_core_vcn.vcn_02.id
}

# ------------------------------------------------------------------------------
# Security lists (aka Firewall Rules)
# ------------------------------------------------------------------------------

resource "oci_core_default_security_list" "Default-Security-List-02" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "Default Security List for IAD-NP-LAB04-VCN-02"
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
        source                  = "10.2.0.0/16"
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
    }
    manage_default_resource_id  = oci_core_vcn.vcn_02.default_security_list_id
}

