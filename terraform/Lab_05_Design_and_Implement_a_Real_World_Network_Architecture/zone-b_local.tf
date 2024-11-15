# ------------------------------------------------------------------------------
# Lab 05:
# Design and Implement a Real-Network Architecture: Configuring private DNS
# Zones, views, resolvers, listeners and forwarder
#
# Virtual Cloud Network 02
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Private DNS Zone
# ------------------------------------------------------------------------------

data "oci_dns_views" "VCN-02-views" {
	compartment_id          = var.compartment_id
	scope                   = "PRIVATE"
	display_name            = oci_core_vcn.IAD-NP-LAB05-VCN-02.display_name 
}

locals {
    VCN-02-View-id          = data.oci_dns_views.VCN-02-views.views[0].id
}

resource "oci_dns_zone" "zone_b_local" {
    compartment_id        = var.compartment_id
    dnssec_state          = "DISABLED"
    name                  = "zone-b.local"
    scope                 = "PRIVATE"
    view_id               = local.VCN-02-View-id
    zone_type             = "PRIMARY"
}

resource "oci_dns_rrset" "zone_b_local_server01" {
    domain          = "server01.zone-b.local"
    rtype           = "A"
    scope           = "PRIVATE"
    view_id         = local.VCN-02-View-id
    zone_name_or_id = oci_dns_zone.zone_b_local.id

    items {
        domain        = "server01.zone-b.local"
        rdata         = "172.16.0.123"
        rtype         = "A"
        ttl           = 60
    }
}

