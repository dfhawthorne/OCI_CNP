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
# Find the desired CPE device shape
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Create CPE Object in Phoenix Region
#
# Note: The CPE Shape is chosen from the first one that matches the vendor
#       without considering the platform/version field.
# ------------------------------------------------------------------------------

data "oci_core_cpe_device_shapes" "PHX-NP-LAB06-CPE-DEV-SHAPES" {
	provider						= oci.phoenix
}

locals {
	available_shapes 				= data.oci_core_cpe_device_shapes.PHX-NP-LAB06-CPE-DEV-SHAPES.cpe_device_shapes
	cpe_shape_ocid					= lookup(
										zipmap(
											local.available_shapes[*].cpe_device_info[0].vendor,
											local.available_shapes[*].cpe_device_shape_id
											),
										"Libreswan"
										)
}

resource "oci_core_cpe" "PHX-NP-LAB06-CPE-01" {
    provider                        = oci.phoenix
	compartment_id                  = var.compartment_id
	ip_address                      = oci_core_instance.IAD-NP-LAB06-VMCPE-01.public_ip
	cpe_device_shape_id             = local.cpe_shape_ocid
	display_name                    = "PHX-NP-LAB06-CPE-01"
}
