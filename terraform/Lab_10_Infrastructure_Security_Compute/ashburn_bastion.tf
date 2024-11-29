# ------------------------------------------------------------------------------
# Lab 10:
# Infrastructure Security - Compute: Set Up a Bastion Host
#
# Create a Bastion
# ------------------------------------------------------------------------------

resource "oci_bastion_bastion" "NPLAB10BASTION01" {
    provider                        = oci.ashburn
	bastion_type                    = "STANDARD"
	compartment_id                  = var.compartment_id
	target_subnet_id                = oci_core_subnet.IAD-NP-LAB10-SNET-01.id
	client_cidr_block_allow_list    = ["0.0.0.0/0"]
	name                            = "NPLAB10BASTION01"
}