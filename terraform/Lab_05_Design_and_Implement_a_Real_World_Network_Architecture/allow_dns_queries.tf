# ------------------------------------------------------------------------------
# Lab 05:
# Design and Implement a Real-Network Architecture: Configuring private DNS
# Zones, views, resolvers, listeners and forwarder
#
# Allow DNS queries from VCN 01 to VCN 02
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Network Security Group for DNS queries originating in VCN 01
# ------------------------------------------------------------------------------

resource "oci_core_network_security_group" "DNS_queries_from_VCN01" {
	compartment_id              = var.compartment_id
	vcn_id                      = oci_core_vcn.IAD-NP-LAB05-VCN-02.id
	display_name                = "DNS-queries-from-VCN01"
}

resource "oci_core_network_security_group_security_rule" "DNS_queries_from_VCN01_security_rule" {
	network_security_group_id   = oci_core_network_security_group.DNS_queries_from_VCN01.id
    direction                   = "INGRESS"
    protocol                    = "17"
    description                 = "Allow DNS queries from VCN 01 to VCN 02"
    source                      = "10.0.0.53/32"
    source_type                 = "CIDR_BLOCK"
    stateless                   = true
    udp_options {
        destination_port_range {
            max = 53
            min = 53
        }
    }
}

# ------------------------------------------------------------------------------
# Create DNS Resolver Listener
# ------------------------------------------------------------------------------

data "oci_core_vcn_dns_resolver_association" "IAD-NP-LAB05-VCN-02-RESOLVER" {
	vcn_id                      = oci_core_vcn.IAD-NP-LAB05-VCN-02.id
}

resource "oci_dns_resolver_endpoint" "LAB05_VCN02_LISTENER" {
	is_forwarding               = false
	is_listening                = true
	name                        = "LAB05_VCN02_LISTENER"
	resolver_id                 = data.oci_core_vcn_dns_resolver_association.IAD-NP-LAB05-VCN-02-RESOLVER.dns_resolver_id
	subnet_id                   = oci_core_subnet.IAD-NP-LAB05-SNET-02.id
	scope                       = "PRIVATE"
	endpoint_type               = "VNIC"
	listening_address           = "172.16.0.53"
	nsg_ids                     = [oci_core_network_security_group.DNS_queries_from_VCN01.id]
}

# ------------------------------------------------------------------------------
# Adding a forwarder
#
# After adding the listener, it is accessible when specified as a query 
# parameter. Now you will add a forwarder and the clients on VCN01 will be able
# to query without having to add the DNS server as a parameter.
# ------------------------------------------------------------------------------

data "oci_core_vcn_dns_resolver_association" "IAD-NP-LAB05-VCN-01-RESOLVER" {
	vcn_id                      = oci_core_vcn.IAD-NP-LAB05-VCN-01.id
}

resource "oci_dns_resolver_endpoint" "LAB05_VCN01_FORWARDER" {
	is_forwarding               = true
	is_listening                = false
	name                        = "LAB05_VCN01_FORWARDER"
	resolver_id                 = data.oci_core_vcn_dns_resolver_association.IAD-NP-LAB05-VCN-01-RESOLVER.dns_resolver_id
	subnet_id                   = oci_core_subnet.IAD-NP-LAB05-SNET-01.id
	scope                       = "PRIVATE"
	endpoint_type               = "VNIC"
	forwarding_address          = "10.0.0.53"
}

resource "oci_dns_resolver" "LAB05_VCN01_DNS_RESOLVER" {
	resolver_id 				= data.oci_core_vcn_dns_resolver_association.IAD-NP-LAB05-VCN-01-RESOLVER.dns_resolver_id
	scope 						= "PRIVATE"
	rules {
		action 					= "FORWARD"
		destination_addresses 	= [
			oci_dns_resolver_endpoint.LAB05_VCN02_LISTENER.listening_address
		]
		source_endpoint_name 	= oci_dns_resolver_endpoint.LAB05_VCN01_FORWARDER.name
	}
}
