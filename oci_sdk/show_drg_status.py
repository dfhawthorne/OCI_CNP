#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Show the DRG status across multiple regions
# ------------------------------------------------------------------------------

import argparse
import logging
import oci
import os.path

# Interpret passed arguments

parser = argparse.ArgumentParser(
                    prog='show_drg_status',
                    description='Shows the status of all DRGs in the selected regions')
parser.add_argument('region', nargs='*')
parser.add_argument('-v', '--verbose',
                    action='store_true')  # on/off flag
args = parser.parse_args()
verbose_mode = args.verbose
if verbose_mode:
    print(args.region, args.verbose)

if verbose_mode:
    logging.getLogger('oci').setLevel(logging.DEBUG)

# -------------------------------------------------------------------------------
# Get the OCI configuration for the MyLearn environment
# -------------------------------------------------------------------------------
 
with open(os.path.expanduser("~/.oci/oci_cli_rc"),"r") as f:
    for line in f:
        if line.startswith("compartment-id"):
            compartment_id = line.split('=')[1].strip('"')[:-1]
            if verbose_mode:
                print(f'Compartment id={compartment_id}')
            break

mylearn_config              = oci.config.from_file()
if verbose_mode:
    mylearn_config['log_requests']  = True

# -----------------------------------------------------------------------------
# Display DRG Route Table Distribution
# -----------------------------------------------------------------------------

def display_drg_rt_dist(client, drg_rd_id):
    response = client.get_drg_route_distribution(drg_rd_id)
    if response.status != 200: return
    if verbose_mode:
        print(response.data)
    distribution_type = response.data.distribution_type
    display_name = response.data.display_name
    lifecycle_state = response.data.lifecycle_state
    print(f"\t\t{distribution_type} Route Distribution: {display_name} ({lifecycle_state})")
    
    response = client.list_drg_route_distribution_statements(drg_rd_id)
    if response.status != 200: return
    if verbose_mode:
        print(response.data)
    for rule in response.data:
        action = rule.action
        id = rule.id
        match_criteria = rule.match_criteria
        priority = rule.priority
        print(f"\t\t\t{action} ({id}): Priority={priority}")
        for criterion in match_criteria:
            attachment_type = criterion.attachment_type
            match_type = criterion.match_type
            print(f"\t\t\t\t{match_type} {attachment_type}")

# -----------------------------------------------------------------------------
# Display DRG Route Table
# -----------------------------------------------------------------------------

def display_drg_rt(client, title, rt_id):
    response = client.get_drg_route_table(rt_id)
    if response.status == 200:
        if verbose_mode:
            print(response.data)
        display_name = response.data.display_name
        drg_rd_id = response.data.import_drg_route_distribution_id
        print(f"\tDRG Route for {title}: {display_name}")
        display_drg_rt_dist(client, drg_rd_id)

# -----------------------------------------------------------------------------
# Display DRG details
# -----------------------------------------------------------------------------

def display_drg_details(client, drg_list):
    for drg in drg_list:
        print(f"{drg.display_name}: {drg.lifecycle_state}")
        display_drg_rt(
            client,
            "IPSEC Tunnel",
            drg.default_drg_route_tables.ipsec_tunnel
            )
        display_drg_rt(
            client,
            "Remote Peering Connection",
            drg.default_drg_route_tables.remote_peering_connection
            )
        display_drg_rt(
            client,
            "VCN",
            drg.default_drg_route_tables.vcn
            )
        display_drg_rt(
            client,
            "Virtual Circuit",
            drg.default_drg_route_tables.virtual_circuit
            )

# -----------------------------------------------------------------------------
# Discover all DRGs in all three (3) regions
# -----------------------------------------------------------------------------

for region in args.region:
    print(f"Region: {region}\n")
    mylearn_config['region']    = region
    oci.config.validate_config(mylearn_config)
    nw_client = oci.core.VirtualNetworkClient(mylearn_config)

    try:
        response = nw_client.list_drgs(compartment_id)
    except oci.exceptions.ServiceError as ex:
        print(ex)
        exit()
    if response.status == 200:
        display_drg_details(nw_client,response.data)
