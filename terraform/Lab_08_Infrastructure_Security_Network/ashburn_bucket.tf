# ------------------------------------------------------------------------------
# Lab 08:
# Infrastructure Security - Network: Create a Network Source to Restrict Access
# to Object Storage Service
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Create Network Source
# ------------------------------------------------------------------------------

resource "oci_identity_network_source" "IAD-NP-LAB08-NS-01" {
	provider				= oci.ashburn
	compartment_id			= var.provider_details.tenancy_ocid
    description 			= "Network Source for Networking PRO"
    name 					= "IAD-NP-LAB08-1-NS-01"
    public_source_list 		= [
								var.my_ip_address
    							]
    services				= [
      							"all"
    							]
}


# ------------------------------------------------------------------------------
# Create Object Storage Bucket
# ------------------------------------------------------------------------------

data "oci_objectstorage_namespace" "IAD-NP-LAB08-namespace" {
    provider                = oci.ashburn
	compartment_id			= var.compartment_id
}

data "oci_identity_user" "MyLearn-user" {
    provider                = oci.ashburn
	user_id                 = var.provider_details.user_ocid
}

locals {
    user_name               = data.oci_identity_user.MyLearn-user.name
}

resource "oci_objectstorage_bucket" "IAD-NP-LAB08-BUCKET" {
    provider                = oci.ashburn
	compartment_id          = var.compartment_id
	name                    = "IAD-NP-LAB08-BUCKET-${local.user_name}"
	namespace               = data.oci_objectstorage_namespace.IAD-NP-LAB08-namespace.namespace
}
