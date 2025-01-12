#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Generates a file of Terraform IMPORT commands for selected resources in the
# default compartment.
# ------------------------------------------------------------------------------

import argparse
import logging
import oci
import os.path
import sys

# Interpret passed arguments

parser = argparse.ArgumentParser(
                    prog='generate_terraform_import_for_lab05',
                    description='Generate Terraform IMPORT statements for OCI CNP 2024 Lab 5')
parser.add_argument('-v', '--verbose',
                    action='store_true')  # on/off flag
args = parser.parse_args()

logging.basicConfig(stream=sys.stderr)
if args.verbose:
    logging.getLogger('oci').setLevel(logging.DEBUG)
    print(f"Passed Args: Verbose={args.verbose}", file=sys.stderr)

# -------------------------------------------------------------------------------
# Get the OCI configuration for the MyLearn environment
# -------------------------------------------------------------------------------
 
with open(os.path.expanduser("~/.oci/oci_cli_rc"),"r") as f:
    for line in f:
        if line.startswith("compartment-id"):
            compartment_id = line.split('=')[1].strip('"')[:-1]
            if args.verbose: print(f'Compartment id={compartment_id}', file=sys.stderr)
            break

mylearn_config              = oci.config.from_file()
if args.verbose:
    mylearn_config['log_requests']  = True

oci.config.validate_config(mylearn_config)

# -------------------------------------------------------------------------------
# Process all Network Resources
# -------------------------------------------------------------------------------

nw_client = oci.core.VirtualNetworkClient(mylearn_config)

vcn_response = nw_client.list_vcns(compartment_id)
if args.verbose: print(vcn_response.data, file=sys.stderr)

for vcn in vcn_response.data:
    vcn_id   = vcn.id
    vcn_name = vcn.display_name
    if len(vcn_name.split()) == 1:
        print(f'terraform import oci_core_vcn.{vcn_name} {vcn_id}')
    subnet_response = nw_client.list_subnets(compartment_id, vcn_id=vcn_id)
    if args.verbose: print(subnet_response.data, file=sys.stderr)
    for subnet in subnet_response.data:
        subnet_id   = subnet.id
        subnet_name = subnet.display_name
        if len(subnet_name.split()) == 1:
            print(f'terraform import oci_core_subnet.{subnet_name} {subnet_id}')
    lpg_response = nw_client.list_local_peering_gateways(compartment_id, vcn_id=vcn_id)
    if args.verbose: print(lpg_response.data, file=sys.stderr)
    for lpg in lpg_response.data:
        lpg_id   = lpg.id
        lpg_name = lpg.display_name
        if len(lpg_name.split()) == 1:
            print(f'terraform import oci_core_local_peering_gateway.{lpg_name} {lpg_id}')
    dhcp_response = nw_client.get_dhcp_options(vcn.default_dhcp_options_id)
    if args.verbose: print(dhcp_response.data, file=sys.stderr)
    dhcp_id   = dhcp_response.data.id
    dhcp_name = dhcp_response.data.display_name
    if len(dhcp_name.split()) == 1:
        print(f'terraform import oci_core_default_dhcp_options.{dhcp_name} {dhcp_id}')
    rt_response = nw_client.get_route_table(vcn.default_route_table_id)
    if args.verbose: print(rt_response.data, file=sys.stderr)
    rt_id   = rt_response.data.id
    rt_name = rt_response.data.display_name
    if len(rt_name.split()) == 1:
        print(f'terraform import oci_core_default_route_table.{rt_name} {rt_id}')
    sl_response = nw_client.get_security_list(vcn.default_security_list_id)
    if args.verbose: print(sl_response.data, file=sys.stderr)
    sl_id   = sl_response.data.id
    sl_name = sl_response.data.display_name
    if len(sl_name.split()) == 1:
        print(f'terraform import oci_core_default_security_list.{sl_name} {sl_id}')

ig_response = nw_client.list_internet_gateways(compartment_id)
if args.verbose: print(ig_response.data, file=sys.stderr)

for ig in ig_response.data:
    ig_id   = ig.id
    ig_name = ig.display_name
    if len(ig_name.split()) == 1:
        print(f'terraform import oci_core_internet_gateway.{ig_name} {ig_id}')

nsg_response = nw_client.list_network_security_groups(compartment_id=compartment_id)
if args.verbose: print(nsg_response.data, file=sys.stderr)

for nsg in nsg_response.data:
    nsg_id   = nsg.id
    nsg_name = nsg.display_name
    if len(nsg_name.split()) == 1:
        print(f'terraform import oci_core_network_security_group.{nsg_name} {nsg_id}')
        
# -------------------------------------------------------------------------------
# Process all Compute Resources
# -------------------------------------------------------------------------------

compute_client = oci.core.ComputeClient(mylearn_config)

compute_response = compute_client.list_instances(compartment_id,lifecycle_state="RUNNING")
if args.verbose: print(compute_response.data, file=sys.stderr)

for compute in compute_response.data:
    compute_id   = compute.id
    compute_name = compute.display_name
    print(f'terraform import oci_core_instance.{compute_name} {compute_id}')

# ------------------------------------------------------------------------------
# Process all DNS Resources
# ------------------------------------------------------------------------------

dns_client = oci.dns.DnsClient(mylearn_config)

dns_response = dns_client.list_resolvers(compartment_id)
if args.verbose: print(dns_response.data, file=sys.stderr)

for resolver in dns_response.data:
    resolver_id   = resolver.id
    resolver_name = resolver.display_name
    print(f'terrform import oci_dns_resolver.{resolver_name} {resolver_id}')

    dns_ep_response = dns_client.list_resolver_endpoints(resolver_id)
    if args.verbose: print(dns_ep_response.data, file=sys.stderr)

    for dns_ep in dns_ep_response.data:
        id_list      = ['resolverId']
        id_list.extend(dns_ep._self.split('/')[-3:])
        dns_ep_id    = '/'.join(id_list)
        dns_ep_name  = dns_ep.name
        print(f'terraform import oci_dns_resolver_endpoint.{dns_ep_name} {dns_ep_id}')
