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
    drg_route_table_id      = oci_core_drg_route_table.drg_route_table.id
    network_details         {
        id                  = oci_core_vcn.vcn_01.id
        type                = "VCN"
    }
}

resource "oci_core_drg_attachment" "drg_atch_02" {
    provider                = oci.ashburn
    drg_id                  = oci_core_drg.drg.id
    display_name            = "IAD-NP-LAB04-VCN-02-ATCH"
    drg_route_table_id      = oci_core_drg_route_table.drg_route_table.id
    network_details         {
        id                  = oci_core_vcn.vcn_02.id
        type                = "VCN"
    }
}

resource "oci_core_drg_route_table" "drg_route_table" {
    provider                = oci.ashburn
    drg_id                  = oci_core_drg.drg.id
    import_drg_route_distribution_id = oci_core_drg_route_distribution.drg_route_distribution.id
}

resource "oci_core_drg_route_distribution" "drg_route_distribution" {
    provider                            = oci.ashburn
    distribution_type                   = "IMPORT"
    drg_id                              = oci_core_drg.drg.id
}

resource "oci_core_drg_route_distribution_statement" "rd_stmt_01" {
    provider                            = oci.ashburn
    drg_route_distribution_id           = oci_core_drg_route_distribution.drg_route_distribution.id
    action                              = "ACCEPT"
    match_criteria                      {
        match_type                      = "MATCH_ALL"
        }
    priority                            = 1
}

