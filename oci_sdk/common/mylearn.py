#!/usr/bin/env python3
"""
Wrapper module for executing MyLearn labs.
"""

import oci
import os.path

# ------------------------------------------------------------------------------
# Global variables
# ------------------------------------------------------------------------------

# OCI compartment OCID
compartment_id = None
# OCI configuration dictionary as loaded from OCI configuration file
oci_config = None

# -------------------------------------------------------------------------------
# Helper functions for MyLearn module
# -------------------------------------------------------------------------------

def load_oci_config():
    """Load OCI configuration from default location ('~/.oci/config') and
    compartment OCID from the default OCI CLI configuration file
    ('~/.oci/oci_cli_rc').
    """

    global compartment_id
    global oci_config

    with open(os.path.expanduser("~/.oci/oci_cli_rc"),"r") as f:
        for line in f:
            if line.startswith("compartment-id"):
                compartment_id = line.split('=')[1].strip('"')[:-1]
                break

    oci_config = oci.config.from_file()

# -------------------------------------------------------------------------------
# Virtual Cloud Network (VCN)
# -------------------------------------------------------------------------------

class vcn:
    """Creates and manage a virtual cloud network (VCN)"""

    def __init__(self, display_name, **kwargs):
        """Create a VCN with the required display name. The default CIDR
        block is 10.0.0.0/16."""

        global compartment_id
        global oci_config

        if oci_config == None:
            load_oci_config()
        config = dict(oci_config)
        if 'region' in kwargs.keys():
            config['region'] = kwargs['region']
            oci.config.validate_config(config)
        self.nw_client = oci.core.VirtualNetworkClient(config)
        response = self.nw_client.list_vcns(
            compartment_id=kwargs.get('compartment_id',compartment_id),
            display_name=display_name
        )
        if len(response.data) > 0:
            self.vcn = response.data[0]
        else:
            if kwargs.get('cidr_blocks') == None:
                if kwargs.get('cidr_block') == None:
                    cidr_blocks = ['10.0.0.0/16']
                else:
                    cidr_blocks = list(kwargs.get('cidr_block'))
            else:
                cidr_blocks = kwargs.get('cidr_blocks')
            vcn_details = oci.core.models.CreateVcnDetails(
                display_name=display_name,
                compartment_id=kwargs.get('compartment_id',compartment_id),
                dns_label=kwargs.get(
                    'dns_label',
                    display_name.lower().replace('-','').replace('_','')[:16]
                    ),
                cidr_blocks=cidr_blocks
            )
            self.vcn     = self.nw_client.create_vcn(vcn_details)
        self.ig      = None
        self.sg      = None
        self.natg    = None
        self.subnets = []

    def add_ig(self, **kwargs):
        """Create an Internet Gateway. The default display name is
        'Internet Gateway-<name of VCN>'."""
        response = self.nw_client.list_internet_gateways(
            kwargs.get(
                'compartment_id',
                compartment_id
                ),
            vcn_id=self.vcn.id
        )
        if len(response.data) > 0:
            self.ig = response.data[0]
        else:
            ig_details = oci.core.models.CreateInternetGatewayDetails(
                display_name=kwargs.get(
                    'display_name',
                    f'Internet gateway-{self.vcn.display_name}'
                    ),
                compartment_id=kwargs.get(
                    'compartment_id',
                    compartment_id
                    ),
                is_enabled=True,
                vcn_id=self.vcn.id
            )
            self.ig = self.nw_client.create_internet_gateway(ig_details)
    
    def add_route_rule(self, nw_entity_id, rt_id=None, **kwargs):
        if rt_id == None:
            rt_id = self.vcn.default_route_table_id
        response = self.nw_client.get_route_table(rt_id)
        print(response.data)
        route_found = False
        for rule in response.data.route_rules:
            if rule.network_entity_id == nw_entity_id:
                route_found = True
                break
        if not route_found:
            new_route_table = list(response.data.route_rules)
            new_route_table.append(
                oci.core.models.RouteRule(
                    description=kwargs.get(
                        'description',
                        'Default routing is to the Internet'
                    ),
                    destination=kwargs.get(
                        'destination',
                        '0.0.0.0/0'
                    ),
                    destination_type=kwargs.get(
                        'destination_type',
                        oci.core.models.RouteRule.DESTINATION_TYPE_CIDR_BLOCK
                    ),
                    network_entity_id=nw_entity_id,
                    route_type=kwargs.get(
                        'route_type',
                        oci.core.models.RouteRule.ROUTE_TYPE_STATIC
                    )
                )
            )
            self.nw_client.update_route_table(
                self.vcn.default_route_table_id,
                oci.core.models.UpdateRouteTableDetails(
                    route_rules=new_route_table
                )
            )

    def add_sg(self, **kwargs):
        pass

    def add_natg(self, **kwargs):
        pass

    def add_subnet(self, **kwargs):
        pass

    def __str__(self):
        result      = f"VCN:\n  display-name='{self.vcn.display_name}'\n"
        result     +=  "  CIDR blocks:\n"
        for cidr in self.vcn.cidr_blocks:
            result += f"    {cidr}\n"
        result     +=  "  Internet Gateway:\n"
        if self.ig == None:
            result +=  "    Not connected\n"
        else:
            result += f"    display-name: {self.ig.display_name}\n"
        result += "  NAT Gateway:\n"
        if self.natg == None:
            result +=  "    Not connected\n"
        else:
            result += f"    display-name: {self.natg.display_name}\n"
        result     +=  "  Service Gateway:\n"
        if self.sg == None:
            result +=  "    Not connected\n"
        else:
            result += f"    display-name: {self.sg.display_name}\n"
        return result
