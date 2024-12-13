# ------------------------------------------------------------------------------------
# Lab 06:
# Site-to-Site Virtual Private Network: Connect OCI resources to on-premises via
# site-to-site VPN, using LibreSwan as the customer premises equipment
# 
# Launch On-Premises Network and CPE VM in Ashburn Region
#
# In this practice, you will simulate an on-premises network (OPN) in the Ashburn
# region with a VCN, and a compute instance that will run LibreSwan for the CPE
# router. There will be a second VM for pinging purposes.
# ------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Virtual Cloud Network resource block
# ------------------------------------------------------------------------------

resource "oci_core_vcn" "IAD-NP-LAB06-OPN-01" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "IAD-NP-LAB06-OPN-01"
    cidr_blocks                 = ["192.168.20.0/24"]
    dns_label                   = "iadlab06opn01"
}

# ------------------------------------------------------------------------------
# Attach Gateways to VCN
# ------------------------------------------------------------------------------

resource "oci_core_internet_gateway" "IAD-NP-LAB06-IG-01" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "LPG gateway-IAD-NP-LAB06-OPN-01"
    vcn_id                      = oci_core_vcn.IAD-NP-LAB06-OPN-01.id
}

# ------------------------------------------------------------------------------
# DHCP Options
# ------------------------------------------------------------------------------

resource "oci_core_default_dhcp_options" "DHCP-Options-OPN-01" {
    provider                    = oci.ashburn
    manage_default_resource_id  = oci_core_vcn.IAD-NP-LAB06-OPN-01.default_dhcp_options_id
    compartment_id              = var.compartment_id
    display_name                = "DHCP Options for IAD-NP-LAB06-OPN-01"
    domain_name_type            = "CUSTOM_DOMAIN"
    options {
        custom_dns_servers      = [
        ]
        server_type             = "VcnLocalPlusInternet"
        type                    = "DomainNameServer"
    }
    options {
        search_domain_names     = [
            "iadlab06opn01.oraclevcn.com",
        ]
        type = "SearchDomain"
    }
}

# ------------------------------------------------------------------------------
# Subnets
# ------------------------------------------------------------------------------

resource "oci_core_subnet" "IAD-NP-LAB06-SNET-01" {
    provider                    = oci.ashburn
    cidr_block                  = "192.168.20.0/25"
    compartment_id              = var.compartment_id
    display_name                = "public subnet-IAD-NP-LAB06-OPN-01"
    dns_label                   = "public"
    prohibit_internet_ingress   = "false"
    prohibit_public_ip_on_vnic  = "false"
    vcn_id                      = oci_core_vcn.IAD-NP-LAB06-OPN-01.id
}

resource "oci_core_subnet" "IAD-NP-LAB06-SNET-02" {
    provider                    = oci.ashburn
    cidr_block                  = "192.168.20.128/25"
    compartment_id              = var.compartment_id
    display_name                = "private subnet-IAD-NP-LAB06-OPN-01"
    dns_label                   = "private"
    prohibit_internet_ingress   = "true"
    prohibit_public_ip_on_vnic  = "true"
    vcn_id                      = oci_core_vcn.IAD-NP-LAB06-OPN-01.id
    security_list_ids           = [
        oci_core_security_list.Private-Security-List-OPN-01.id
    ]
    route_table_id              = oci_core_route_table.IAD-NP-LAB06-SNET-02-route-table.id
}

# ------------------------------------------------------------------------------
# Route tables
# ------------------------------------------------------------------------------

resource "oci_core_default_route_table" "IAD-NP-LAB06-OPN-01-default-route-table" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "default route table for IAD-NP-LAB06-OPN-01"
    route_rules {
        destination             = "0.0.0.0/0"
        destination_type        = "CIDR_BLOCK"
        network_entity_id       = oci_core_internet_gateway.IAD-NP-LAB06-IG-01.id
    }
    manage_default_resource_id  = oci_core_vcn.IAD-NP-LAB06-OPN-01.default_route_table_id
}

resource "oci_core_route_table" "IAD-NP-LAB06-SNET-02-route-table" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "IAD-NP-LAB06-SNET-02-route-table"
    route_rules {
        destination             = "172.16.0.0/12"
        destination_type        = "CIDR_BLOCK"
        network_entity_id       = data.oci_core_private_ips.IAD-NP-LAB06-VMCPE-Private-IP.private_ips[0].id
    }
    vcn_id                      = oci_core_vcn.IAD-NP-LAB06-OPN-01.id
}

# ------------------------------------------------------------------------------
# Security lists (aka Firewall Rules)
# ------------------------------------------------------------------------------

resource "oci_core_default_security_list" "Default-Security-List-OPN-01" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "Default Security List for IAD-NP-LAB06-OPN-01"
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
        source                  = "192.168.20.0/24"
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
    }
    ingress_security_rules {
        icmp_options {
            code                = "-1"
            type                = "8"
        }
        source                  = "172.16.0.0/12"
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
        protocol                = "1"
    }
    manage_default_resource_id  = oci_core_vcn.IAD-NP-LAB06-OPN-01.default_security_list_id
}

resource "oci_core_security_list" "Private-Security-List-OPN-01" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "Security List for IAD-NP-LAB06-SNET-02"
    vcn_id                      = oci_core_vcn.IAD-NP-LAB06-OPN-01.id
    ingress_security_rules {
        icmp_options {
            code                = "-1"
            type                = "8"
        }
        source                  = "172.16.0.0/12"
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
        protocol                = "1"
    }
}
