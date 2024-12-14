# ------------------------------------------------------------------------------
# Lab 07:
# Remote Peering: InterConnect OCI resources between regions and extend to on-premises
# 
# Create Resources in UK South (London) Region
# 
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Create a Dynamic Routing Gateway and Attach VCN
# ------------------------------------------------------------------------------

resource "oci_core_drg" "LHR-NP-LAB07-DRG-01" {
    provider                    = oci.london
	compartment_id              = var.compartment_id
	display_name                = "LHR-NP-LAB07-DRG-01"
}

resource "oci_core_drg_attachment" "LHR-NP-LAB07-VCN-01-ATCH" {
    provider                    = oci.london
	drg_id                      = oci_core_drg.LHR-NP-LAB07-DRG-01.id
	display_name                = "LHR-NP-LAB07-VCN-01-ATCH"
	network_details {
		id                      = oci_core_vcn.LHR-NP-LAB07-VCN-01.id
		type                    = "VCN"
	}
}

# ------------------------------------------------------------------------------
# Create Remote Peering Connection 
# ------------------------------------------------------------------------------

resource "oci_core_remote_peering_connection" "PHX-NP-LAB07-RPC-01" {
	provider 					= oci.phoenix
	compartment_id 				= var.compartment_id
	drg_id 						= oci_core_drg.PHX-NP-LAB06-DRG-01.id
	display_name 				= "PHX-NP-LAB07-RPC-01"
}

resource "oci_core_remote_peering_connection" "LHR-NP-LAB07-RPC-01" {
	provider 					= oci.london
	compartment_id 				= var.compartment_id
	drg_id 						= oci_core_drg.LHR-NP-LAB07-DRG-01.id
	display_name 				= "LHR-NP-LAB07-RPC-01"
	peer_id 					= oci_core_remote_peering_connection.PHX-NP-LAB07-RPC-01.id
	peer_region_name 			= "us-phoenix-1"
}

