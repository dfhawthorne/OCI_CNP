# Common variable for compartment
variable "compartment_id" {
  type          = string
  sensitive     = true
  description   = "OCID of OCI compartment"
}

variable "region" {
  type          = string
  description   = "OCI region name"
}

variable "tenancy_ocid" {
  type          = string
  sensitive     = true
  description   = "OCID of OCI Tenancy"
}

variable "user_ocid" {
  type          = string
  sensitive     = true
  description   = "OCID of OCI User"
}

variable "fingerprint" {
  type          = string
  sensitive     = true
  description   = "Cryptographic fingerprint of API private key for user to access OCI tenancy"
}

variable "private_key_path" {
  type          = string
  sensitive     = true
  description   = "Path to API private key for user to access OCI tenancy"
}

