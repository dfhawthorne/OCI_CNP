# ------------------------------------------------------------------------------
# OCI CNP Lab 01:
# Create and Configure a Virtual Cloud Network (VCN)
# ------------------------------------------------------------------------------

terraform {
    required_providers {
        oci = {
            source = "oracle/oci"
        }
    }
}

# ------------------------------------------------------------------------------
# Configure the Oracle Cloud Infrastructure provider with an API Key
# ------------------------------------------------------------------------------

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Virtual Cloud Network resource block
resource "oci_core_vcn" "IAD-NP-LAB01-VCN-01" {
    compartment_id  = var.compartment_id
    display_name    = "IAD-NP-LAB01-VCN-01"
    cidr_blocks     = ["10.0.0.0/16"]
    dns_label       = "iadnplab01vcn01"
}

resource "oci_core_nat_gateway" "NAT-gateway-IAD-NP-LAB01-VCN-01" {
  block_traffic     = "false"
  compartment_id    = var.compartment_id
  display_name      = "NAT gateway-IAD-NP-LAB01-VCN-01"
  vcn_id            = oci_core_vcn.IAD-NP-LAB01-VCN-01.id
}

resource "oci_core_internet_gateway" "Internet-gateway-IAD-NP-LAB01-VCN-01" {
  compartment_id    = var.compartment_id
  display_name      = "Internet gateway-IAD-NP-LAB01-VCN-01"
  enabled           = "true"
  vcn_id            = oci_core_vcn.IAD-NP-LAB01-VCN-01.id
}

resource "oci_core_dhcp_options" "DHCP-Options-for-IAD-NP-LAB01-VCN-01" {
  vcn_id            = oci_core_vcn.IAD-NP-LAB01-VCN-01.id
  compartment_id    = var.compartment_id
  display_name      = "DHCP Options for IAD-NP-LAB01-VCN-01"
  domain_name_type  = "CUSTOM_DOMAIN"
  options {
    custom_dns_servers  = [
    ]
    server_type         = "VcnLocalPlusInternet"
    type                = "DomainNameServer"
  }
  options {
    search_domain_names = [
      "iadnplab01vcn01.oraclevcn.com",
    ]
    type = "SearchDomain"
  }
}

resource "oci_core_subnet" "public-subnet-IAD-NP-LAB01-VCN-01" {
  cidr_block     = "10.0.0.0/24"
  compartment_id = var.compartment_id
  dhcp_options_id = oci_core_dhcp_options.DHCP-Options-for-IAD-NP-LAB01-VCN-01.id
  display_name    = "public subnet-IAD-NP-LAB01-VCN-01"
  dns_label       = "sub07051559030"
  ipv6cidr_blocks = [
  ]
  prohibit_internet_ingress  = "false"
  prohibit_public_ip_on_vnic = "false"
  route_table_id             = oci_core_route_table.default-route-table-for-IAD-NP-LAB01-VCN-01.id
  security_list_ids = [
    oci_core_vcn.IAD-NP-LAB01-VCN-01.default_security_list_id,
  ]
  vcn_id = oci_core_vcn.IAD-NP-LAB01-VCN-01.id
}

resource oci_core_subnet private-subnet-IAD-NP-LAB01-VCN-01 {
  cidr_block     = "10.0.1.0/24"
  compartment_id = var.compartment_id
  dhcp_options_id = oci_core_dhcp_options.DHCP-Options-for-IAD-NP-LAB01-VCN-01.id
  display_name    = "private subnet-IAD-NP-LAB01-VCN-01"
  dns_label       = "sub07051559031"
  ipv6cidr_blocks = [
  ]
  prohibit_internet_ingress  = "true"
  prohibit_public_ip_on_vnic = "true"
  route_table_id             = oci_core_route_table.route-table-for-private-subnet-IAD-NP-LAB01-VCN-01.id
  security_list_ids = [
    oci_core_security_list.security-list-for-private-subnet-IAD-NP-LAB01-VCN-01.id,
  ]
  vcn_id = oci_core_vcn.IAD-NP-LAB01-VCN-01.id
}

resource oci_core_route_table route-table-for-private-subnet-IAD-NP-LAB01-VCN-01 {
  compartment_id = var.compartment_id
  display_name = "route table for private subnet-IAD-NP-LAB01-VCN-01"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.NAT-gateway-IAD-NP-LAB01-VCN-01.id
  }
  route_rules {
    destination       = "all-iad-services-in-oracle-services-network"
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.Service-gateway-IAD-NP-LAB01-VCN-01.id
  }
  vcn_id = oci_core_vcn.IAD-NP-LAB01-VCN-01.id
}

resource oci_core_route_table default-route-table-for-IAD-NP-LAB01-VCN-01 {
  compartment_id = var.compartment_id
  display_name = "default route table for IAD-NP-LAB01-VCN-01"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.Internet-gateway-IAD-NP-LAB01-VCN-01.id
  }
  vcn_id = oci_core_vcn.IAD-NP-LAB01-VCN-01.id
}


resource oci_core_security_list security-list-for-private-subnet-IAD-NP-LAB01-VCN-01 {
  compartment_id = var.compartment_id
  display_name = "security list for private subnet-IAD-NP-LAB01-VCN-01"
  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol  = "all"
    stateless = "false"
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    icmp_options {
      code = "-1"
      type = "3"
    }
    protocol    = "1"
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  vcn_id = oci_core_vcn.IAD-NP-LAB01-VCN-01.id
}

resource oci_core_default_security_list Default-Security-List-for-IAD-NP-LAB01-VCN-01 {
  compartment_id = var.compartment_id
  display_name = "Default Security List for IAD-NP-LAB01-VCN-01"
  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol  = "all"
    stateless = "false"
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    icmp_options {
      code = "-1"
      type = "3"
    }
    protocol    = "1"
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  manage_default_resource_id = oci_core_vcn.IAD-NP-LAB01-VCN-01.default_security_list_id
}

resource oci_core_service_gateway Service-gateway-IAD-NP-LAB01-VCN-01 {
  compartment_id = var.compartment_id
  display_name = "Service gateway-IAD-NP-LAB01-VCN-01"
  services {
    service_id = "ocid1.service.oc1.iad.aaaaaaaam4zfmy2rjue6fmglumm3czgisxzrnvrwqeodtztg7hwa272mlfna"
  }
  vcn_id = oci_core_vcn.IAD-NP-LAB01-VCN-01.id
}

