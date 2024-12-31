#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Show the DRG status across multiple regions
# ------------------------------------------------------------------------------

import logging
import oci
import os.path

# Enable debug logging

logging.getLogger('oci').setLevel(logging.DEBUG)

# -------------------------------------------------------------------------------
# Get the OCI configuration for the MyLearn environment
# -------------------------------------------------------------------------------
 
with open(os.path.expanduser("~/.oci/oci_cli_rc"),"r") as f:
    for line in f:
        if line.startswith("compartment-id"):
            compartment_id = line.split('=')[1]
            break

mylearn_config              = oci.config.from_file()
mylearn_config['log_requests']  = True
ashburn_config              = dict(mylearn_config)
ashburn_config['region']    = 'us-ashburn-1'
london_config               = dict(mylearn_config)
london_config['region']     = 'uk-london-1'
phoenix_config              = dict(mylearn_config)
phoenix_config['region']    = 'us-phoenix-1'

# ------------------------------------------------------------------------------
# Open OCI Network Clients for all three (3) regions
# ------------------------------------------------------------------------------

ashburn_nw_client   = oci.core.VirtualNetworkClient(ashburn_config)
london_nw_client    = oci.core.VirtualNetworkClient(london_config)
phoenix_nw_client   = oci.core.VirtualNetworkClient(phoenix_config)

# -----------------------------------------------------------------------------
# Display DRG details
# -----------------------------------------------------------------------------

def display_drg_details(drg_list):
    print(drg_list)

# -----------------------------------------------------------------------------
# Discover all DRGs in all three (3) regions
# -----------------------------------------------------------------------------

try:
    display_drg_details(ashburn_nw_client.list_drgs(compartment_id))
except oci.exceptions.ServiceError as ex:
    print(ex)
try:
    display_drg_details(london_nw_client.list_drgs(compartment_id))
except oci.exceptions.ServiceError as ex:
    print(ex)
try:
    display_drg_details(phoenix_nw_client.list_drgs(compartment_id))
except oci.exceptions.ServiceError as ex:
    print(ex)
