# ------------------------------------------------------------------------------
# Parameters for create_vcn module
# ------------------------------------------------------------------------------

variable provider_details {
    type                    = object({
        tenancy_ocid        = string
        user_ocid           = string
        fingerprint         = string
        private_key_path    = string
        region              = string
    })
    description             = "OCI provider details"
}

variable compartment_id {
    type                    = string
    description             = "OCID of compartment to contain VCN and associated resources"
    validation {
        condition           = can(regex("^ocid1.compartment.oc1.*$", var.compartment_id))
        error_message       = "The compartment_id value must be a valid OCID starting with 'ocid1.compartment.oc1.'."
    }
}

variable vcn_details {
    type                    = object({
        name                = string
        cidr_blocks         = list(string)
        dns_label           = string
    })
    description             = "Required details for creating a VCN"
    validation {
        condition           = can(cidrhost(var.vcn_details.cidr_blocks[0], 0))
        error_message       = "Must be a valid CIDR block"
    }
}

variable public_subnet_details {
    type                    = object({
        cidr_block          = string
        dns_label           = string
    })
    description             = "Required details for creating a public subnet within a VCN"
    validation {
        condition           = can(cidrhost(var.public_subnet_details.cidr_block, 0))
        error_message       = "Must be a valid CIDR block"
    }
}

variable private_subnet_details {
    type                    = object({
        cidr_block          = string
        dns_label           = string
    })
    description             = "Required details for creating a public subnet within a VCN"
    validation {
        condition           = can(cidrhost(var.private_subnet_details.cidr_block, 0))
        error_message       = "Must be a valid CIDR block"
    }
}

variable services_details {
    type                    = object({
        destination         = string
        service_id          = string
    })
    description             = "Required details for accessing OCI services"
    validation {
        condition           = can(regex("^ocid1.service.oc1.*$", var.services_details.service_id))
        error_message       = "The service_id value must be a valid OCID starting with 'ocid1.service.oc1.'."
    }
    validation {
        condition           = can(regex("^all-...-services-in-oracle-services-network$", var.services_details.destination))
        error_message       = "The services destination value must be a valid string of the form, 'all-...-services-in-oracle-services-network'."
    }
}

variable default_route_rules {
    type                    = list(
        object({
            destination         = string
            destination_type    = optional(string, "CIDR_BLOCK")
            network_entity_id   = string
        })
    )
    default                 = []
    description             = "Additional egress rules for default route table"
}

variable allowable_sources_for_pings {
    type                    = list(string)
    default                 = []
    description             = "List of CIDR blocks that can issue PINGs"
}
