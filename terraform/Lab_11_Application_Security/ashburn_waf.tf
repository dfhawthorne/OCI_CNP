# ------------------------------------------------------------------------------
# Lab 11:
# Application Security: Create and Configure Web Access Firewall
#
# Create a Web Application Firewall (WAF) Policy
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# XSS policies
#
# The group tag is obtained as follows:
# oci waf protection-capability list-protection-capability-group-tags \
#     --all \
#     --query "data.items[?contains(name,'XSS')].name | [0]"
# ------------------------------------------------------------------------------

data "oci_waf_protection_capabilities" "xss_protection_capabilities" {
    provider                            = oci.ashburn
	compartment_id                      = var.compartment_id
	group_tag                           = ["Cross-Site Scripting (XSS)"]
	is_latest_version                   = [true]
}

# ------------------------------------------------------------------------------
# WAF
# ------------------------------------------------------------------------------

resource "oci_waf_web_app_firewall" "IAD-NP-LAB11-WAF-01" {
    provider                            = oci.ashburn
    backend_type                        = "LOAD_BALANCER"
    compartment_id                      = var.compartment_id
    display_name                        = "IAD-NP-LAB11-WAF-01"
    load_balancer_id                    = oci_load_balancer_load_balancer.IAD-NP-LAB11-LB-01.id
    web_app_firewall_policy_id          = oci_waf_web_app_firewall_policy.IAD-NP-LAB11-WAF-01.id
}

locals {
	xss_items = [
        for item in data.oci_waf_protection_capabilities.xss_protection_capabilities.protection_capability_collection[0].items:
            {
                collaborative_action_threshold	= item.collaborative_action_threshold
                version 						= item.version
                key 							= item.key
            }
        ]
		
}

# ------------------------------------------------------------------------------
# WAF Policy
# ------------------------------------------------------------------------------

resource "oci_waf_web_app_firewall_policy" "IAD-NP-LAB11-WAF-01" {
    provider                            = oci.ashburn
	compartment_id                      = var.compartment_id
    display_name                        = "IAD-NP-LAB11-WAF-01"
    actions {
        code = 503
        name = "WAF-LAB11-1-Rate-Limit-Action"
        type = "RETURN_HTTP_RESPONSE"

        body {
            template = <<-EOT
                Too many requests are being sent to Web Server-1.
            EOT
            text     = null
            type     = "DYNAMIC"
        }
    }
    actions {
        code = 503
        name = "WAF-LAB11-XSS_Protection"
        type = "RETURN_HTTP_RESPONSE"

        body {
            template = <<-EOT
                Service Unavailable; web Server is secured against XSS attacks.
            EOT
            text     = null
            type     = "DYNAMIC"
        }
    }
    actions {
        code = 503
        name = "WAF-LAB11-Access-Action"
        type = "RETURN_HTTP_RESPONSE"

        body {
            template = <<-EOT
                Service Unavailable: the web server cannot be accessed by the requested source region.
            EOT
            text     = null
            type     = "DYNAMIC"
        }
    }
    actions {
        name = "WAF-LAB11-Pass-Through-Action"
        type = "ALLOW"
    }

    request_access_control {
        default_action_name = "WAF-LAB11-Pass-Through-Action"

        rules {
            action_name        = "WAF-LAB11-Access-Action"
            condition          = join("", ["i_contains(['", var.country_of_origin, "'], connection.source.geo.countryCode)"])
            condition_language = "JMESPATH"
            name               = "WAF-LAB11-Access-Control"
            type               = "ACCESS_CONTROL"
        }
    }

    request_protection {
        body_inspection_size_limit_exceeded_action_name = null
        body_inspection_size_limit_in_bytes             = 8192

        rules {
            action_name                = "WAF-LAB11-XSS_Protection"
            condition                  = null
            condition_language         = "JMESPATH"
            is_body_inspection_enabled = false
            name                       = "IAD-NP-LAB11-XSS-01"
            type                       = "PROTECTION"

            dynamic "protection_capabilities" {
                for_each               = local.xss_items
                content {
                    action_name                    = null
                    collaborative_action_threshold = coalesce(protection_capabilities.value["collaborative_action_threshold"],0)
                    key                            = coalesce(protection_capabilities.value["key"],"missing")
                    version                        = coalesce(protection_capabilities.value["version"],1)
                }
            }
        }
    }

    request_rate_limiting {
        rules {
            action_name        = "WAF-LAB11-1-Rate-Limit-Action"
            condition          = null
            condition_language = "JMESPATH"
            name               = "IAD-NP-LAB11-RLP-01"
            type               = "REQUEST_RATE_LIMITING"

            configurations {
                action_duration_in_seconds = 0
                period_in_seconds          = 5
                requests_limit             = 3
            }
        }
    }
}

