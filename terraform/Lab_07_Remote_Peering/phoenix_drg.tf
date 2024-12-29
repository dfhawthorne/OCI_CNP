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

resource "oci_core_drg" "PHX-NP-LAB06-DRG-01" {
    provider                    = oci.phoenix
	compartment_id              = var.compartment_id
	display_name                = "PHX-NP-LAB06-DRG-01"
}

resource "oci_core_drg_attachment" "PHX-NP-LAB06-VCN-01-ATCH" {
    provider                    = oci.phoenix
	drg_id                      = oci_core_drg.PHX-NP-LAB06-DRG-01.id
	display_name                = "PHX-NP-LAB06-VCN-01-ATCH"
	network_details {
		id                      = oci_core_vcn.PHX-NP-LAB06-VCN-01.id
		type                    = "VCN"
	}
}

# The following resource fails with:
# │ Error: unknown type 'REMOTE_PEERING_CONNECTION' was specified
# │ 
# │   with oci_core_drg_attachment.PHX-NP-LAB06-RPC-01-ATCH,
# │   on phoenix_drg.tf line 35, in resource "oci_core_drg_attachment" "PHX-NP-LAB06-RPC-01-ATCH":
# │   35: resource "oci_core_drg_attachment" "PHX-NP-LAB06-RPC-01-ATCH" {
#resource "oci_core_drg_attachment" "PHX-NP-LAB06-RPC-01-ATCH" {
#    provider                    = oci.phoenix
#	drg_id                      = oci_core_drg.PHX-NP-LAB06-DRG-01.id
#	display_name                = "DRG Attachment for RPC: PHX-NP-LAB07-RPC-01"
#    drg_route_table_id          = oci_core_drg_route_table.PHX-NP-LAB07-RT-RPC-01.id
#	network_details {
#		id                      = oci_core_remote_peering_connection.PHX-NP-LAB07-RPC-01.id
#		type                    = "REMOTE_PEERING_CONNECTION"
#	}
#}

# ------------------------------------------------------------------------------
# Create Route Distributions for DRG
# ------------------------------------------------------------------------------

resource "oci_core_drg_route_distribution" "PHX-NP-LAB07-RD-RPC-01" {
    provider                    = oci.phoenix
	drg_id                      = oci_core_drg.PHX-NP-LAB06-DRG-01.id
    display_name      			= "PHX-NP-LAB07-RD-RPC-01"
    distribution_type 			= "IMPORT"
}

resource "oci_core_drg_route_distribution_statement" "PHX-NP-LAB07-RD-RPC-01-STMT-01" {
    provider                    = oci.phoenix
	drg_route_distribution_id 	= oci_core_drg_route_distribution.PHX-NP-LAB07-RD-RPC-01.id
    action						= "ACCEPT"
    match_criteria        		{
        attachment_type			= "REMOTE_PEERING_CONNECTION"
        match_type				= "DRG_ATTACHMENT_TYPE"
        }
    priority					= 2
}

resource "oci_core_drg_route_distribution" "PHX-NP-LAB07-RD-VPN-01" {
    provider                    = oci.phoenix
	drg_id                      = oci_core_drg.PHX-NP-LAB06-DRG-01.id
    display_name      			= "PHX-NP-LAB07-RD-VPN-01"
    distribution_type 			= "IMPORT"
}

resource "oci_core_drg_route_distribution_statement" "PHX-NP-LAB07-RD-VPN-01-STMT-01" {
    provider                    = oci.phoenix
	drg_route_distribution_id 	= oci_core_drg_route_distribution.PHX-NP-LAB07-RD-VPN-01.id
    action						= "ACCEPT"
    match_criteria        		{
        attachment_type			= "IPSEC_TUNNEL"
        match_type				= "DRG_ATTACHMENT_TYPE"
        }
    priority					= 1
}

# ------------------------------------------------------------------------------
# Create DRG Route Tables
# ------------------------------------------------------------------------------

resource "oci_core_drg_route_table" "PHX-NP-LAB07-RT-VPN-01" {
    provider                    = oci.phoenix
	drg_id                      = oci_core_drg.PHX-NP-LAB06-DRG-01.id
	display_name                = "PHX-NP-LAB07-RT-VPN-01"
	import_drg_route_distribution_id = oci_core_drg_route_distribution.PHX-NP-LAB07-RD-RPC-01.id
}

resource "oci_core_drg_route_table" "PHX-NP-LAB07-RT-RPC-01" {
    provider                    = oci.phoenix
	drg_id                      = oci_core_drg.PHX-NP-LAB06-DRG-01.id
	display_name                = "PHX-NP-LAB07-RT-RPC-01"
	import_drg_route_distribution_id = oci_core_drg_route_distribution.PHX-NP-LAB07-RD-VPN-01.id
}

# ------------------------------------------------------------------------------
# Update DRG Attachments with new route tables 
# ------------------------------------------------------------------------------

resource "oci_core_drg_attachment_management" "PHX-NP-LAB07-DA-RPC-01" {
    provider                    = oci.phoenix
    attachment_type             = "REMOTE_PEERING_CONNECTION"
    compartment_id              = var.compartment_id
    network_id                  = oci_core_remote_peering_connection.PHX-NP-LAB07-RPC-01.id
    drg_id                      = oci_core_drg.PHX-NP-LAB06-DRG-01.id
    display_name                = "PHX-NP-LAB07-DA-RPC-01"
  drg_route_table_id            = oci_core_drg_route_table.PHX-NP-LAB07-RT-RPC-01.id
}

resource "oci_core_drg_attachment_management" "PHX-NP-LAB07-DA-VPN-01" {
    provider                    = oci.phoenix
    attachment_type             = "IPSEC_TUNNEL"
    compartment_id              = var.compartment_id
    network_id                  = data.oci_core_ipsec_connection_tunnels.PHX-NP-LAB06-VPN-01.ip_sec_connection_tunnels[0].id
    drg_id                      = oci_core_drg.PHX-NP-LAB06-DRG-01.id
    display_name                = "PHX-NP-LAB07-DA-VPN-01"
    drg_route_table_id          = oci_core_drg_route_table.PHX-NP-LAB07-RT-RPC-01.id
}

resource "oci_core_drg_attachment_management" "PHX-NP-LAB07-DA-VPN-02" {
    provider                    = oci.phoenix
    attachment_type             = "IPSEC_TUNNEL"
    compartment_id              = var.compartment_id
    network_id                  = data.oci_core_ipsec_connection_tunnels.PHX-NP-LAB06-VPN-01.ip_sec_connection_tunnels[1].id
    drg_id                      = oci_core_drg.PHX-NP-LAB06-DRG-01.id
    display_name                = "PHX-NP-LAB07-DA-VPN-02"
    drg_route_table_id          = oci_core_drg_route_table.PHX-NP-LAB07-RT-RPC-01.id
}

