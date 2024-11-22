# ------------------------------------------------------------------------------
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
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Create a Dynamic Routing Gateway and Attach VCN
# ------------------------------------------------------------------------------

resource "oci_core_drg" "PHX-NP-LAB06-1-DRG-01" {
    provider                    = oci.phoenix
	compartment_id              = var.compartment_id
	display_name                = "PHX-NP-LAB06-1-DRG-01"
}

resource "oci_core_drg_attachment" "PHX-NP-LAB06-VCN-01-ATCH" {
    provider                    = oci.phoenix
	drg_id                      = oci_core_drg.PHX-NP-LAB06-1-DRG-01.id
	display_name                = "PHX-NP-LAB06-VCN-01-ATCH"
	network_details {
		id                      = oci_core_vcn.PHX-NP-LAB06-VCN-01.id
		type                    = "VCN"
	}
}

# ------------------------------------------------------------------------------
# Create a Site-to-Site VPN IPSec Connection
# ------------------------------------------------------------------------------

locals {
    vpn_1_secret                = "PHX NP LAB 06 1 Secret 01"
    vpn_2_secret                = "PHX NP LAB 06 1 Secret 02"
}

resource "oci_core_virtual_circuit" "PHX-NP-LAB06-Tunnel-01" {
    provider                    = oci.phoenix
	compartment_id              = var.compartment_id
	gateway_id					= oci_core_drg.PHX-NP-LAB06-1-DRG-01.id
	customer_asn 				= 31899
	type                        = "PRIVATE"
	display_name                = "PHX-NP-LAB06-Tunnel-01"
	is_transport_mode			= true
	public_prefixes {
		cidr_block 				= "192.168.20.0/24"
	}
}

resource "oci_core_virtual_circuit" "PHX-NP-LAB06-Tunnel-02" {
    provider                    = oci.phoenix
	compartment_id              = var.compartment_id
	gateway_id					= oci_core_drg.PHX-NP-LAB06-1-DRG-01.id
	customer_asn 				= 31899
	type                        = "PRIVATE"
	display_name                = "PHX-NP-LAB06-Tunnel-02"
	is_transport_mode			= true
	public_prefixes {
		cidr_block 				= "192.168.20.0/24"
	}
}

data "oci_core_ipsec_connection_tunnels" "PHX-NP-LAB06-VPN-01" {
    ipsec_id                    = oci_core_ipsec.PHX-NP-LAB06-VPN-01.id
}

resource "oci_core_ipsec_connection_tunnel_management" "PHX-NP-LAB06-Tunnel-01-MGT" {
    provider                    = oci.phoenix
	ipsec_id                    = oci_core_ipsec.PHX-NP-LAB06-VPN-01.id
	tunnel_id                   = data.oci_core_ipsec_connection_tunnels.PHX-NP-LAB06-VPN-01.ip_sec_connection_tunnels[0].id
	routing                     = "STATIC"
	display_name                = "PHX-NP-LAB06-Tunnel-01-MGT"
    shared_secret               = local.vpn_1_secret
    ike_version                 = "V1"
}

resource "oci_core_ipsec_connection_tunnel_management" "PHX-NP-LAB06-Tunnel-02-MGT" {
    provider                    = oci.phoenix
	ipsec_id                    = oci_core_ipsec.PHX-NP-LAB06-VPN-01.id
	tunnel_id                   = data.oci_core_ipsec_connection_tunnels.PHX-NP-LAB06-VPN-01.ip_sec_connection_tunnels[1].id
	routing                     = "STATIC"
	display_name                = "PHX-NP-LAB06-Tunnel-02-MGT"
    shared_secret               = local.vpn_2_secret
    ike_version                 = "V1"
}

resource "oci_core_ipsec" "PHX-NP-LAB06-VPN-01" {
    provider                    = oci.phoenix
	compartment_id              = var.compartment_id
	cpe_id                      = oci_core_cpe.PHX-NP-LAB06-CPE-01.id
	drg_id                      = oci_core_drg.PHX-NP-LAB06-1-DRG-01.id
	static_routes               = [
            "192.168.20.0/24"
        ]
	display_name                = "PHX-NP-LAB06-VPN-01"
    tunnel_configuration {
		associated_virtual_circuits = [
            oci_core_virtual_circuit.PHX-NP-LAB06-Tunnel-01.id
            ]
	}
	tunnel_configuration {
		associated_virtual_circuits = [
            oci_core_virtual_circuit.PHX-NP-LAB06-Tunnel-02.id
            ]
	}
}


