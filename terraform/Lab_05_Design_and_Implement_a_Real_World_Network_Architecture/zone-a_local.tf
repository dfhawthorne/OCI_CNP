# ------------------------------------------------------------------------------
# Lab 05:
# Design and Implement a Real-Network Architecture: Configuring private DNS
# Zones, views, resolvers, listeners and forwarder
#
# Virtual Cloud Network 01
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Private DNS Zone
# ------------------------------------------------------------------------------

data "oci_dns_views" "VCN-01-views" {
	compartment_id          = var.compartment_id
	scope                   = "PRIVATE"
	display_name            = oci_core_vcn.IAD-NP-LAB05-VCN-01.display_name 
}

locals {
    VCN-01-View-id          = data.oci_dns_views.VCN-01-views.views[0].id
}

resource "oci_dns_zone" "zone_a_local" {
    compartment_id        = var.compartment_id
    dnssec_state          = "DISABLED"
    name                  = "zone-a.local"
    scope                 = "PRIVATE"
    view_id               = local.VCN-01-View-id
    zone_type             = "PRIMARY"
}

resource "oci_dns_rrset" "zone_a_local_server01" {
    domain          = "server01.zone-a.local"
    rtype           = "A"
    scope           = "PRIVATE"
    view_id         = local.VCN-01-View-id
    zone_name_or_id = oci_dns_zone.zone_a_local.id

    items {
        domain        = "server01.zone-a.local"
        rdata         = "10.0.0.2"
        rtype         = "A"
        ttl           = 30
    }
}

