# Phoenix VPN Investigation Notes

## Summary

These are my notes taken while investigating VPN connectivity issues in the Phoenix region.

## OCI Network Topics

The relevant OCI CLI help topics for IPSEC are:

- ip-sec-connection
  - get
  - get-config (deprecated) Use either instead
    - ip-sec-tunnel get
    - ip-sec-psk get
  - get-ipsec-cpe-device-config-content
  - get-status
  - list
- ip-sec-connection-tunnel-error-details
  - get-ip-sec-connection-tunnel-error
- ip-sec-psk
  - get
- ip-sec-tunnel
  - get
  - list

## IPSEC Connection Help Text

The help text for `oci network ip-sec-connection` says:

> A connection between a DRG and CPE. This connection consists of multiple IPSec tunnels. Creating this connection is one of the steps required when setting up a Site-to-Site VPN.
>
> __Important:__  Each tunnel in an IPSec connection can use either static routing or BGP dynamic routing (see the [IPSecConnectionTunnel](https://docs.cloud.oracle.com/api/#/en/iaas/latest/IPSecConnectionTunnel/)  object’s routing attribute). Originally only static routing was supported and every IPSec connection was required to  have at least one static route configured. To maintain backward compatibility in the API when support for BPG dynamic routing was introduced, the API accepts an empty list of static routes if you configure both of the IPSec tunnels to use BGP dynamic routing. If you switch a tunnel’s routing from BGP to STATIC, you must first ensure that the IPSec connection is configured with at least one valid CIDR block static route. Oracle uses the IPSec connection’s static routes when routing a tunnel’s traffic only if that tunnel’s routing attribute = STATIC. Otherwise the static routes are ignored.
>
> For more information about the workflow for setting up an IPSec connection, see [Site-to-Site VPN Overview](https://docs.cloud.oracle.com/iaas/Content/Network/Tasks/overviewIPsec.htm).
>
> To use any of the API operations, you must be authorized in an IAM policy. If you’re not authorized, talk to an administrator. If you’re an  administrator who needs to write policies to give users access, see [Getting Started with Policies](https://docs.cloud.oracle.com/iaas/Content/Identity/Concepts/policygetstarted.htm).

## Get All IPSEC Connections

```bash
oci network ip-sec-connection list --region us-phoenix-1
```

Sample output is:

```json
{
  "data": [
    {
      "compartment-id": "ocid1.compartment.oc1..aaaaaaaaoyhfolhnzyn332kkj7bmnqg6e7ojm3kal3eq23ldswsxnvjuiina",
      "cpe-id": "ocid1.cpe.oc1.phx.aaaaaaaawgn7joxgm4fsia46uzfyhf4y6prooe6ynfhpum6pceg2jz753ppq",
      "cpe-local-identifier": "129.213.129.79",
      "cpe-local-identifier-type": "IP_ADDRESS",
      "defined-tags": {},
      "display-name": "PHX-NP-LAB06-VPN-01",
      "drg-id": "ocid1.drg.oc1.phx.aaaaaaaa6kh66ef2qsy6bl2e53f6wzvoowqhkl2hznbxkvgjradbg5wql6ia",
      "freeform-tags": {},
      "id": "ocid1.ipsecconnection.oc1.phx.aaaaaaaagicyphtlb4cjalqtcv6shqqc5n3fok7n2a6fd2x7jktuvcynllaa",
      "lifecycle-state": "AVAILABLE",
      "static-routes": [
        "192.168.20.0/24"
      ],
      "time-created": "2024-12-25T19:32:04.850000+00:00",
      "transport-type": "INTERNET"
    }
  ]
}
```

## List All Tunnels

```bash
ipsc_id=$(oci network ip-sec-connection list --region us-phoenix-1 --query 'data[0].id' --raw-output)
oci network ip-sec-tunnel list --region us-phoenix-1 --ipsc-id ${ipsc_id} --all
```

Sample output is:

```json
{
  "data": [
    {
      "associated-virtual-circuits": [],
      "bgp-session-info": {
        "bgp-ipv6-state": "DOWN",
        "bgp-state": "DOWN",
        "customer-bgp-asn": "31899",
        "customer-interface-ip": "192.168.20.122/30",
        "customer-interface-ipv6": null,
        "oracle-bgp-asn": "31898",
        "oracle-interface-ip": "192.168.20.121/30",
        "oracle-interface-ipv6": null
      },
      "compartment-id": "ocid1.compartment.oc1..aaaaaaaaoyhfolhnzyn332kkj7bmnqg6e7ojm3kal3eq23ldswsxnvjuiina",
      "cpe-ip": "129.213.129.79",
      "display-name": "PHX-NP-LAB06-Tunnel-01",
      "dpd-mode": "INITIATE_AND_RESPOND",
      "dpd-timeout-in-sec": 20,
      "encryption-domain-config": null,
      "id": "ocid1.ipsectunnel.oc1.phx.aaaaaaaa3fiuty4xa5jkqiwvjupr2mnyk7icledogh2shazdaq4wkygmbbgq",
      "ike-version": "V1",
      "lifecycle-state": "AVAILABLE",
      "nat-translation-enabled": "AUTO",
      "oracle-can-initiate": "INITIATOR_OR_RESPONDER",
      "phase-one-details": {
        "custom-authentication-algorithm": null,
        "custom-dh-group": null,
        "custom-encryption-algorithm": null,
        "is-custom-phase-one-config": null,
        "is-ike-established": true,
        "lifetime": 28800,
        "negotiated-authentication-algorithm": "HMAC_SHA2_384",
        "negotiated-dh-group": "GROUP5",
        "negotiated-encryption-algorithm": "AES_CBC_256",
        "remaining-lifetime": 806,
        "remaining-lifetime-last-retrieved": "2024-12-26T14:35:03.249000+00:00"
      },
      "phase-two-details": {
        "custom-authentication-algorithm": null,
        "custom-encryption-algorithm": null,
        "dh-group": "GROUP5",
        "is-custom-phase-two-config": null,
        "is-esp-established": true,
        "is-pfs-enabled": true,
        "lifetime": 3600,
        "negotiated-authentication-algorithm": "NONE",
        "negotiated-dh-group": "GROUP5",
        "negotiated-encryption-algorithm": "AES_GCM_16_256",
        "remaining-lifetime": null,
        "remaining-lifetime-last-retrieved": "2024-12-26T14:35:03.249000+00:00"
      },
      "routing": "BGP",
      "status": "UP",
      "time-created": "2024-12-25T19:32:05.197000+00:00",
      "time-status-updated": "2024-12-26T14:35:03.245000+00:00",
      "vpn-ip": "129.146.222.41"
    },
    {
      "associated-virtual-circuits": [],
      "bgp-session-info": {
        "bgp-ipv6-state": "DOWN",
        "bgp-state": "DOWN",
        "customer-bgp-asn": "31899",
        "customer-interface-ip": "192.168.20.122/30",
        "customer-interface-ipv6": null,
        "oracle-bgp-asn": "31898",
        "oracle-interface-ip": "192.168.20.121/30",
        "oracle-interface-ipv6": null
      },
      "compartment-id": "ocid1.compartment.oc1..aaaaaaaaoyhfolhnzyn332kkj7bmnqg6e7ojm3kal3eq23ldswsxnvjuiina",
      "cpe-ip": "129.213.129.79",
      "display-name": "PHX-NP-LAB06-Tunnel-02",
      "dpd-mode": "INITIATE_AND_RESPOND",
      "dpd-timeout-in-sec": 20,
      "encryption-domain-config": null,
      "id": "ocid1.ipsectunnel.oc1.phx.aaaaaaaalyrfvmfom3ppgy4s7twxcx65kzvyhsihsiyi24etygdo4baxywhq",
      "ike-version": "V1",
      "lifecycle-state": "AVAILABLE",
      "nat-translation-enabled": "AUTO",
      "oracle-can-initiate": "INITIATOR_OR_RESPONDER",
      "phase-one-details": {
        "custom-authentication-algorithm": null,
        "custom-dh-group": null,
        "custom-encryption-algorithm": null,
        "is-custom-phase-one-config": null,
        "is-ike-established": true,
        "lifetime": 28800,
        "negotiated-authentication-algorithm": "HMAC_SHA2_384",
        "negotiated-dh-group": "GROUP5",
        "negotiated-encryption-algorithm": "AES_CBC_256",
        "remaining-lifetime": 799,
        "remaining-lifetime-last-retrieved": "2024-12-26T14:35:03.201000+00:00"
      },
      "phase-two-details": {
        "custom-authentication-algorithm": null,
        "custom-encryption-algorithm": null,
        "dh-group": "GROUP5",
        "is-custom-phase-two-config": null,
        "is-esp-established": true,
        "is-pfs-enabled": true,
        "lifetime": 3600,
        "negotiated-authentication-algorithm": "NONE",
        "negotiated-dh-group": "GROUP5",
        "negotiated-encryption-algorithm": "AES_GCM_16_256",
        "remaining-lifetime": null,
        "remaining-lifetime-last-retrieved": "2024-12-26T14:35:03.201000+00:00"
      },
      "routing": "BGP",
      "status": "UP",
      "time-created": "2024-12-25T19:32:05.170000+00:00",
      "time-status-updated": "2024-12-26T14:35:03.196000+00:00",
      "vpn-ip": "129.146.219.10"
    }
  ]
}
```

## Get IPSEC Tunnel Details

```bash
ipsc_id=$(oci network ip-sec-connection list --region us-phoenix-1 --query 'data[0].id' --raw-output)
tunnel_0_id=$(oci network ip-sec-tunnel list --region us-phoenix-1 --ipsc-id ${ipsc_id} --all --query 'data[0].id' --raw-output)
tunnel_1_id=$(oci network ip-sec-tunnel list --region us-phoenix-1 --ipsc-id ${ipsc_id} --all --query 'data[1].id' --raw-output)
oci network ip-sec-tunnel get --ipsc-id ${ipsc_id} --tunnel-id ${tunnel_0_id} --region us-phoenix-1
```

Sample output is:

```json
{
  "data": {
    "associated-virtual-circuits": [],
    "bgp-session-info": null,
    "compartment-id": "ocid1.compartment.oc1..aaaaaaaaoyhfolhnzyn332kkj7bmnqg6e7ojm3kal3eq23ldswsxnvjuiina",
    "cpe-ip": "132.145.136.64",
    "display-name": "PHX-NP-LAB06-Tunnel-02",
    "dpd-mode": "INITIATE_AND_RESPOND",
    "dpd-timeout-in-sec": 20,
    "encryption-domain-config": null,
    "id": "ocid1.ipsectunnel.oc1.phx.aaaaaaaagafa5op4mau5roayobrumj4iiunbjiihhdivp235zr24bmpimflq",
    "ike-version": "V1",
    "lifecycle-state": "AVAILABLE",
    "nat-translation-enabled": "AUTO",
    "oracle-can-initiate": "INITIATOR_OR_RESPONDER",
    "phase-one-details": {
      "custom-authentication-algorithm": null,
      "custom-dh-group": null,
      "custom-encryption-algorithm": null,
      "is-custom-phase-one-config": false,
      "is-ike-established": true,
      "lifetime": 28800,
      "negotiated-authentication-algorithm": null,
      "negotiated-dh-group": null,
      "negotiated-encryption-algorithm": null,
      "remaining-lifetime": null,
      "remaining-lifetime-last-retrieved": "2024-12-26T18:57:42.773000+00:00"
    },
    "phase-two-details": {
      "custom-authentication-algorithm": null,
      "custom-encryption-algorithm": null,
      "dh-group": "GROUP5",
      "is-custom-phase-two-config": false,
      "is-esp-established": false,
      "is-pfs-enabled": true,
      "lifetime": 3600,
      "negotiated-authentication-algorithm": null,
      "negotiated-dh-group": null,
      "negotiated-encryption-algorithm": null,
      "remaining-lifetime": null,
      "remaining-lifetime-last-retrieved": "2024-12-26T18:57:42.773000+00:00"
    },
    "routing": "STATIC",
    "status": "DOWN",
    "time-created": "2024-12-26T18:41:11.412000+00:00",
    "time-status-updated": "2024-12-26T18:57:42.769000+00:00",
    "vpn-ip": "158.101.38.140"
  },
  "etag": "d9ad72df2941410bc25d5b6aa186872a--gzip"
}
```

## IP-SEC Connection

> Renders a set of CPE configuration content for the specified IPSec connection (for all the tunnels in the connection). The content helps a network engineer configure the actual CPE device (for example, a hardware router) that the specified IPSec connection terminates on.
>
> The rendered content is specific to the type of CPE device (for example, Cisco ASA). Therefore the [Cpe](https://docs.cloud.oracle.com/api/#/en/iaas/latest/Cpe/) used by the specified [IPSecConnection](https://docs.cloud.oracle.com/api/#/en/iaas/latest/IPSecConnection/) must have the CPE’s device type specified by the cpeDeviceShapeId attribute. The content optionally includes answers that the customer provides (see [UpdateTunnelCpeDeviceConfig](https://docs.cloud.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/cmdref/network/tunnel-cpe-device-config/update.html)), merged with a template of other information specific to the CPE device type.
>
> The operation returns configuration information for all tunnels in the single specified [IPSecConnection](https://docs.cloud.oracle.com/api/#/en/iaas/latest/IPSecConnection/) object. Here are other similar operations:
>
> - [GetTunnelCpeDeviceConfigContent](https://docs.cloud.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/cmdref/network/tunnel-cpe-device-config/get-tunnel-cpe-device-config-content.html) returns CPE configuration content for a specific tunnel within an IPSec connection.
> - [GetCpeDeviceConfigContent](https://docs.cloud.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/cmdref/network/cpe/get-cpe-device-config-content.html) returns CPE configuration content for all IPSec connections that use a specific CPE.

```bash
ipsc_id=$(oci network ip-sec-connection list --region us-phoenix-1 --query 'data[0].id' --raw-output)
oci network ip-sec-connection get-ipsec-cpe-device-config-content --region us-phoenix-1 --file /tmp/cpe.json --ipsc-id ${ipsc-id}
```

This failed with:

```text
ServiceError:
{
    "client_version": "Oracle-PythonSDK/2.133.0, Oracle-PythonCLI/3.47.0",
    "code": null,
    "logging_tips": "Please run the OCI CLI command using --debug flag to find more debug information.",
    "message": "The service returned error code 400",
    "opc-request-id": "D4900A6F93234C3689023034D50BEEBC/18672C55BA0979C3403905F91AC7C576/634C1B9F584597846B58BBE74F70272F",
    "operation_name": "get_ipsec_cpe_device_config_content",
    "request_endpoint": "GET https://iaas.us-phoenix-1.oraclecloud.com/20160918/ipsecConnections/ocid1.ipsecconnection.oc1.phx.aaaaaaaaxjkxmvtikhsmd54223dzporgdbwm55rrwmzr7chmizbl4tvhigla/cpeConfigContent",
    "status": 400,
    "target_service": "virtual_network",
    "timestamp": "2024-12-26T19:13:42.744302+00:00",
    "troubleshooting_tips": "See [https://docs.oracle.com/iaas/Content/API/References/apierrors.htm] for more information about resolving this error. If you are unable to resolve this issue, run this CLI command with --debug option and contact Oracle support and provide them the full error message."
}
```
