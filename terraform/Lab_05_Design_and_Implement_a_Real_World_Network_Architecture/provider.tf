# ------------------------------------------------------------------------------
# Lab 05:
# Design and Implement a Real-Network Architecture: Configuring private DNS
# Zones, views, resolvers, listeners and forwarder
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Set up OCI Provider
# ------------------------------------------------------------------------------

terraform {
    required_providers {
        oci                     = {
            source              = "oracle/oci"
        }
    }
}

# ------------------------------------------------------------------------------
# Configure the Oracle Cloud Infrastructure provider with an API Key
# ------------------------------------------------------------------------------

provider "oci" {
    tenancy_ocid                = var.provider_details.tenancy_ocid
    user_ocid                   = var.provider_details.user_ocid
    fingerprint                 = var.provider_details.fingerprint
    private_key_path            = var.provider_details.private_key_path
    region                      = "us-ashburn-1"
}
