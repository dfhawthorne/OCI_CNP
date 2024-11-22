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
# Run the following command to get the CPE Device Shape OCID:
# oci network cpe-device-shape list --region="US-PHOENIX-1" | \
#     jq '.data[] | select(."cpe-device-info".vendor=="Libreswan").id'
# ------------------------------------------------------------------------------

resource "oci_core_cpe" "PHX-NP-LAB06-CPE-01" {
    provider                        = oci.phoenix
	compartment_id                  = var.compartment_id
	ip_address                      = oci_core_instance.IAD-NP-LAB06-VMCPE-01.public_ip
	cpe_device_shape_id             = "c4be89f9-3d73-41db-a64d-40d244b1b6f3"
	display_name                    = "PHX-NP-LAB06-CPE-01"
}
