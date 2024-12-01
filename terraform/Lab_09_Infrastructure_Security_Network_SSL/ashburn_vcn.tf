# ------------------------------------------------------------------------------------
# Lab 09:
# Instrastructure Security - Network: Create a Self-Signed Certificate and Perform
# SSL Termination on OCI Load Balancer
# 
# Create a Virtual Cload Network------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Virtual Cloud Network resource block
# ------------------------------------------------------------------------------

resource "oci_core_vcn" "IAD-NP-LAB09-VCN-01" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "IAD-NP-LAB09-VCN-01"
    cidr_blocks                 = ["10.0.0.0/24"]
    dns_label                   = "iadlab09vcn01"
}

# ------------------------------------------------------------------------------
# Attach Gateways to VCN
# ------------------------------------------------------------------------------

resource "oci_core_internet_gateway" "IAD-NP-LAB09-IG-01" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "Internet Gateway IAD-NP-LAB09-VCN-01"
    vcn_id                      = oci_core_vcn.IAD-NP-LAB09-VCN-01.id
}


resource "oci_core_nat_gateway" "NAT-gateway-IAD-NP-LAB09-VCN-01" {
    provider                    = oci.ashburn
    block_traffic               = "false"
    compartment_id              = var.compartment_id
    display_name                = "NAT gateway-IAD-NP-LAB09-VCN-01"
    vcn_id                      = oci_core_vcn.IAD-NP-LAB09-VCN-01.id
}


# ------------------------------------------------------------------------------
# DHCP Options
# ------------------------------------------------------------------------------

resource "oci_core_default_dhcp_options" "DHCP-Options-VCN-01" {
    provider                    = oci.ashburn
    manage_default_resource_id  = oci_core_vcn.IAD-NP-LAB09-VCN-01.default_dhcp_options_id
    compartment_id              = var.compartment_id
    display_name                = "DHCP Options for IAD-NP-LAB09-VCN-01"
    domain_name_type            = "CUSTOM_DOMAIN"
    options {
        custom_dns_servers      = [
        ]
        server_type             = "VcnLocalPlusInternet"
        type                    = "DomainNameServer"
    }
    options {
        search_domain_names     = [
            "iadlab09vcn01.oraclevcn.com",
        ]
        type = "SearchDomain"
    }
}

# ------------------------------------------------------------------------------
# Subnets
# ------------------------------------------------------------------------------

resource "oci_core_subnet" "IAD-NP-LAB09-SNET-01" {
    provider                    = oci.ashburn
    cidr_block                  = "10.0.0.0/24"
    compartment_id              = var.compartment_id
    display_name                = "public subnet-IAD-NP-LAB09-VCN-01"
    dns_label                   = "public"
    prohibit_internet_ingress   = "false"
    prohibit_public_ip_on_vnic  = "false"
    vcn_id                      = oci_core_vcn.IAD-NP-LAB09-VCN-01.id
}

resource "oci_core_subnet" "IAD-NP-LAB09-SNET-02" {
    provider                    = oci.ashburn
    cidr_block                  = "10.0.4.0/24"
    compartment_id              = var.compartment_id
    display_name                = "load balancer subnet-IAD-NP-LAB09-VCN-01"
    dns_label                   = "lb"
    prohibit_internet_ingress   = "false"
    prohibit_public_ip_on_vnic  = "false"
    vcn_id                      = oci_core_vcn.IAD-NP-LAB09-VCN-01.id
    security_list_ids           = [oci_core_security_list.IAD-NP-LAB09-LB-SL-01.id]
}

# ------------------------------------------------------------------------------
# Route tables
# ------------------------------------------------------------------------------

resource "oci_core_default_route_table" "IAD-NP-LAB09-VCN-01-default-route-table" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "default route table for IAD-NP-LAB09-VCN-01"
    route_rules {
        destination             = "0.0.0.0/0"
        destination_type        = "CIDR_BLOCK"
        network_entity_id       = oci_core_internet_gateway.IAD-NP-LAB09-IG-01.id
    }
    manage_default_resource_id  = oci_core_vcn.IAD-NP-LAB09-VCN-01.default_route_table_id
}

# ------------------------------------------------------------------------------
# Security lists (aka Firewall Rules)
# ------------------------------------------------------------------------------

resource "oci_core_default_security_list" "Default-Security-List-VCN-01" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "Default Security List for IAD-NP-LAB09-VCN-01"
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
        source                  = "10.0.0.0/24"
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
    }
    manage_default_resource_id  = oci_core_vcn.IAD-NP-LAB09-VCN-01.default_security_list_id
}

resource "oci_core_security_list" "IAD-NP-LAB09-LB-SL-01" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "Load Balancer Security List for IAD-NP-LAB09-VCN-01"
    ingress_security_rules {
        protocol                = "6"
        source                  = "0.0.0.0/0"
        source_type             = "CIDR_BLOCK"
        stateless               = "false"
        tcp_options {
            max                 = "80"
            min                 = "80"
        }
    }
    vcn_id                      = oci_core_vcn.IAD-NP-LAB09-VCN-01.id
}
