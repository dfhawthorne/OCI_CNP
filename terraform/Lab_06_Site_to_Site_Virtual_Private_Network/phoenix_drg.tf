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
