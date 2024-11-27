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

