variable "tenancy_ocid" {
    type = string
    default = "ocid1.tenancy.oc1..aaaaaaaa7ilqdzmkbqduujc3tt6zrl2n2ytcughcjoidozg4memj2k4cm7na"
    }
variable "region" {
    type = string
    default = "ap-sydney-1"
    }
variable "user_ocid" {
    type = string
    default = "ocid1.user.oc1..aaaaaaaab6dmoec6utwsmvueyko32h6vvhmptr3yeaunitxj6733jpo6hsca"
    }
variable "fingerprint" {
    type   = string
    default = "7b:e0:07:a7:dc:a6:96:47:65:39:04:6b:aa:71:b0:76"
    }
variable "private_key_path" {
    type    = string
    default = "/home/douglas/.oci/tenancy_admin_private.pem"
    }
