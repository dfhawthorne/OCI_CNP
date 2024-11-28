# ------------------------------------------------------------------------------
# Providers in three (3) different OCI regions.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Set up OCI Provider
# ------------------------------------------------------------------------------

terraform {
    required_providers {
        oci                     = {
            source              = "oracle/oci"
        }
		random 					= {
			source  			= "hashicorp/random"
			version 			= "~> 3.0"
		}
    }
}

# ------------------------------------------------------------------------------
# Configure the Oracle Cloud Infrastructure provider with an API Key
# ------------------------------------------------------------------------------

provider "oci" {
    alias                       = "ashburn"
    tenancy_ocid                = var.provider_details.tenancy_ocid
    user_ocid                   = var.provider_details.user_ocid
    fingerprint                 = var.provider_details.fingerprint
    private_key_path            = var.provider_details.private_key_path
    region                      = "us-ashburn-1"
}

provider "oci" {
    alias                       = "phoenix"
    tenancy_ocid                = var.provider_details.tenancy_ocid
    user_ocid                   = var.provider_details.user_ocid
    fingerprint                 = var.provider_details.fingerprint
    private_key_path            = var.provider_details.private_key_path
    region                      = "us-phoenix-1"
}

provider "oci" {
    alias                       = "london"
    tenancy_ocid                = var.provider_details.tenancy_ocid
    user_ocid                   = var.provider_details.user_ocid
    fingerprint                 = var.provider_details.fingerprint
    private_key_path            = var.provider_details.private_key_path
    region                      = "uk-london-1"
}
