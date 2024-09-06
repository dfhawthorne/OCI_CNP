# ------------------------------------------------------------------------------
# Lab 04: Virtual Cloud Network (VCN): Configure IPv6 on two VCNs and
#         communicate between them with ICMPv6
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Create a dynamic routing gateway and attach the VCNs
# ------------------------------------------------------------------------------

resource "oci_core_drg" "drg" {
    provider                = oci.ashburn
    compartment_id          = var.compartment_id
    display_name            = "IAD-NP-LAB04-DRG-01"
}

resource "oci_core_drg_attachment" "drg_atch_01" {
    provider                = oci.ashburn
    drg_id                  = oci_core_drg.drg.id
    display_name            = "IAD-NP-LAB04-VCN-01-ATCH"
    network_details         {
        id                  = oci_core_vcn.vcn_01.id
        type                = "VCN"
    }
}

resource "oci_core_drg_attachment" "drg_atch_02" {
    provider                = oci.ashburn
    drg_id                  = oci_core_drg.drg.id
    display_name            = "IAD-NP-LAB04-VCN-02-ATCH"
    network_details         {
        id                  = oci_core_vcn.vcn_02.id
        type                = "VCN"
    }
}

resource "oci_core_route_table" "route_table_01" {
    provider                = oci.ashburn
    compartment_id          = var.compartment_id
    vcn_id                  = oci_core_vcn.vcn_01.id
    display_name            = "route-table-vcn_01"

    route_rules {
        destination_type    = "CIDR_BLOCK"
        destination         = oci_core_vcn.vcn_02.ipv6cidr_blocks[0]
        network_entity_id   = oci_core_drg.drg.id
    }
}

resource "oci_core_route_table" "route_table_02" {
    provider                = oci.ashburn
    compartment_id          = var.compartment_id
    vcn_id                  = oci_core_vcn.vcn_02.id
    display_name            = "route-table-vcn_02"

    route_rules {
        destination_type    = "CIDR_BLOCK"
        destination         = oci_core_vcn.vcn_01.ipv6cidr_blocks[0]
        network_entity_id   = oci_core_drg.drg.id
    }
}

