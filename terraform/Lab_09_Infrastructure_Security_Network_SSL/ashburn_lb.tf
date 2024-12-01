# ------------------------------------------------------------------------------
# Lab 09:
# Instrastructure Security - Network: Create a Self-Signed Certificate and Perform
# SSL Termination on OCI Load Balancer
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Load Balancer
# ------------------------------------------------------------------------------

resource "oci_load_balancer_load_balancer" "IAD-NP-LAB09-LB-01" {
    provider                    = oci.ashburn
    compartment_id              = var.compartment_id
    display_name                = "IAD-NP-LAB09-LB-01"
    shape                       = "flexible"
    subnet_ids                  = [oci_core_subnet.IAD-NP-LAB09-SNET-01.id]
    is_private                  = false
    shape_details {
        maximum_bandwidth_in_mbps = 20
        minimum_bandwidth_in_mbps = 10
    }
}

resource "oci_load_balancer_backend_set" "IAD-NP-LAB09-BS-01" {
    provider                    = oci.ashburn
    name                        = "IAD-NP-LAB09-BS-01"
    load_balancer_id            = oci_load_balancer_load_balancer.IAD-NP-LAB09-LB-01.id
    policy                      = "ROUND_ROBIN"
    health_checker              {
        port                    = "80"
        protocol                = "HTTP"
        response_body_regex     = ".*"
        url_path                = "/"
    }
}

resource "oci_load_balancer_backend" "IAD-NP-LAB09-BE-01" {
    provider                    = oci.ashburn
    load_balancer_id            = oci_load_balancer_load_balancer.IAD-NP-LAB09-LB-01.id
    backendset_name             = oci_load_balancer_backend_set.IAD-NP-LAB09-BS-01.name
    ip_address                  = oci_core_instance.IAD-NP-LAB09-VM-01.private_ip
    port                        = "80"
}

resource "oci_load_balancer_backend" "IAD-NP-LAB09-BE-02" {
    provider                    = oci.ashburn
    load_balancer_id            = oci_load_balancer_load_balancer.IAD-NP-LAB09-LB-01.id
    backendset_name             = oci_load_balancer_backend_set.IAD-NP-LAB09-BS-01.name
    ip_address                  = oci_core_instance.IAD-NP-LAB09-VM-02.private_ip
    port                        = "80"
}

resource "oci_load_balancer_listener" "IAD-NP-LAB09-LISN-01" {
    provider                    = oci.ashburn
    load_balancer_id            = oci_load_balancer_load_balancer.IAD-NP-LAB09-LB-01.id
    name                        = "IAD-NP-LAB09-LISN-01"
    default_backend_set_name    = oci_load_balancer_backend_set.IAD-NP-LAB09-BS-01.name
    port                        = 443
    protocol                    = "HTTPS"
}

resource "oci_load_balancer_certificate" "IAD-NP-LAB09-CERT-01" {
    provider                    = oci.ashburn
	certificate_name            = "IAD-NP-LAB09-CERT-01"
	load_balancer_id            = oci_load_balancer_load_balancer.IAD-NP-LAB09-LB-01.id
    private_key                 = file("ocilb.key")
	public_certificate          = file("ocilb.crt")
} 
