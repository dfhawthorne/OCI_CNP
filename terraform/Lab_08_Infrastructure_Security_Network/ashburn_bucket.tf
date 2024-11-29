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
# Get OS namespace and User name for OS bucket
# ------------------------------------------------------------------------------

data "oci_objectstorage_namespace" "IAD-NP-LAB08-namespace" {
    provider                = oci.ashburn
	compartment_id			= var.compartment_id
}

data "oci_identity_user" "MyLearn-user" {
    provider                = oci.ashburn
	user_id                 = var.provider_details.user_ocid
}

# ------------------------------------------------------------------------------
# Generate a random number for bucket name
# ------------------------------------------------------------------------------

resource "random_integer" "bucket_number" {
	min 							=    1
	max 							= 1000
}

# ------------------------------------------------------------------------------
# Create Object Storage Bucket
# ------------------------------------------------------------------------------

locals {
    user_name               = data.oci_identity_user.MyLearn-user.name
	bucket_number			= random_integer.bucket_number.result
}

resource "oci_objectstorage_bucket" "IAD-NP-LAB08-BUCKET" {
    provider                = oci.ashburn
	compartment_id          = var.compartment_id
	name                    = "IAD-NP-LAB08-BUCKET-${local.user_name}-${local.bucket_number}"
	namespace               = data.oci_objectstorage_namespace.IAD-NP-LAB08-namespace.namespace
}
