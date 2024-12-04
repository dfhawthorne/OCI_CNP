# ------------------------------------------------------------------------------
# Lab 11:
# Application Security: Create and Configure Web Access Firewall
#
# Create a Web Application Firewall (WAF) Policy
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# WAF
# ------------------------------------------------------------------------------

resource "oci_waf_web_app_firewall" "IAD-NP-LAB11-WAF-01" {
    provider                            = oci.ashburn
    backend_type                        = "LOAD_BALANCER"
    compartment_id                      = var.compartment_id
    display_name                        = "webappfirewall20241204182034"
    load_balancer_id                    = oci_load_balancer_load_balancer.IAD-NP-LAB11-LB-01.id
    web_app_firewall_policy_id          = oci_waf_web_app_firewall_policy.IAD-NP-LAB11-WAF-01.id
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
        name = "WAF-LAB11-XSS_Proection"
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

    request_access_control {
        default_action_name = "WAF-LAB11-1-Rate-Limit-Action"

        rules {
            action_name        = "WAF-LAB11-Access-Action"
            condition          = "i_contains(['AU'], connection.source.geo.countryCode)"
            condition_language = "JMESPATH"
            name               = "WAF-LAB11-Access-Control"
            type               = "ACCESS_CONTROL"
        }
    }

    request_protection {
        body_inspection_size_limit_exceeded_action_name = null
        body_inspection_size_limit_in_bytes             = 8192

        rules {
            action_name                = "WAF-LAB11-XSS_Proection"
            condition                  = null
            condition_language         = "JMESPATH"
            is_body_inspection_enabled = false
            name                       = "IAD-NP-LAB11-WAF-01"
            type                       = "PROTECTION"

            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "942270"
                version                        = 1
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "9420000"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941380"
                version                        = 1
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941370"
                version                        = 1
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941360"
                version                        = 1
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941350"
                version                        = 3
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941340"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941330"
                version                        = 3
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941320"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941310"
                version                        = 3
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941300"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941290"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941280"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941270"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941260"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941250"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941240"
                version                        = 3
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941230"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941220"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941210"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941200"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941190"
                version                        = 3
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941181"
                version                        = 1
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941180"
                version                        = 3
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941170"
                version                        = 3
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941160"
                version                        = 3
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941150"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941140"
                version                        = 3
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941130"
                version                        = 4
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941120"
                version                        = 4
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941110"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941101"
                version                        = 3
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "941100"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "9410000"
                version                        = 3
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "9330000"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "9320001"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "9320000"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "930120"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "9300000"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "920390"
                version                        = 1
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "920380"
                version                        = 1
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "920370"
                version                        = 1
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "920320"
                version                        = 1
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "920300"
                version                        = 2
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "920280"
                version                        = 1
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "911100"
                version                        = 1
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "202156846"
                version                        = 1
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "202156845"
                version                        = 1
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "201950708"
                version                        = 1
            }
            protection_capabilities {
                action_name                    = null
                collaborative_action_threshold = 0
                key                            = "200003"
                version                        = 1
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

