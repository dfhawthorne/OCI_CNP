# ------------------------------------------------------------------------------
# Lab 11:
# Application Security: Create and Configure Web Access Firewall
#
# Create a Load Balancer and Update the Security List
#
# Create a load balancer with SSL Termination configuration
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Load Balancer
# ------------------------------------------------------------------------------

resource "oci_load_balancer_load_balancer" "IAD-NP-LAB11-LB-01" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "IAD-NP-LAB11-LB-01"
    shape                       = "flexible"
    subnet_ids                  = [oci_core_subnet.IAD-NP-LAB11-LB-SNET-02.id]
    is_private                  = false
    shape_details {
        maximum_bandwidth_in_mbps = 10
        minimum_bandwidth_in_mbps = 10
    }
}

resource "oci_load_balancer_backend_set" "IAD-NP-LAB11-BS-01" {
    provider                    = oci.ashburn
    name                        = "IAD-NP-LAB11-BS-01"
    load_balancer_id            = oci_load_balancer_load_balancer.IAD-NP-LAB11-LB-01.id
    policy                      = "ROUND_ROBIN"
    health_checker              {
        port                    = "80"
        protocol                = "HTTP"
        response_body_regex     = ".*"
        url_path                = "/"
    }
}

resource "oci_load_balancer_backend" "IAD-NP-LAB11-BE-01" {
    provider                    = oci.ashburn
    load_balancer_id            = oci_load_balancer_load_balancer.IAD-NP-LAB11-LB-01.id
    backendset_name             = oci_load_balancer_backend_set.IAD-NP-LAB11-BS-01.name
    ip_address                  = oci_core_instance.IAD-NP-LAB11-VM-01.private_ip
    port                        = "80"
}

resource "oci_load_balancer_listener" "IAD-NP-LAB11-LB-LISN-01" {
    provider                    = oci.ashburn
    load_balancer_id            = oci_load_balancer_load_balancer.IAD-NP-LAB11-LB-01.id
    name                        = "IAD-NP-LAB11-LB-LISN-01"
    default_backend_set_name    = oci_load_balancer_backend_set.IAD-NP-LAB11-BS-01.name
    port                        = 80
    protocol                    = "HTTP"
}
