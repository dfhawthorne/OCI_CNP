#!/usr/bin/env python3
"""
Wrapper module for executing MyLearn labs.
"""

import netaddr.ip
import oci
import os.path
import paramiko
import time

# ------------------------------------------------------------------------------
# Global variables
# ------------------------------------------------------------------------------

# OCI compartment OCID
compartment_id = None
# OCI configuration dictionary as loaded from OCI configuration file
oci_config = None
# Sleep interval between checking lifecycle state
sleep_time = 10

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
    
def new_route_rule(nw_entity_id, **kwargs):
    """Creates a route rule for the network entity.

    The required parameter is:
        nw_entity_id:
            The OCID for the network entity.

    The other optional parameters are:
        description:
            A textual description of the route rule. The default value is
            'Default routing is to the Internet'.
        destination:
            The route target for the rule. The default value is '0.0.0.0/0'.
        destination_type:
            The type of the route target for the rule. The default value is
            'CIDR_BLOCK'.
        route_type:
            The type of route rule. The default route type is 'STATIC'."""

    return oci.core.models.RouteRule(
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

# -------------------------------------------------------------------------------
# Availability Domains
# -------------------------------------------------------------------------------

class availability_domain:
    """Availabity domain"""

    def __init__(self, **kwargs):
        """Retrieves availability domains.
        
        The optional parameters are:
          region:
            The OCI region name. The default value is obtained from the OCI
            configuration file.
          compartment_id:
            The OCID of the OCI compartment where to create the RPC. The
            default value is obtained from the OCI CLI configuration file, if
            present."""

        global compartment_id
        global oci_config

        if oci_config is None:
            load_oci_config()
        config = dict(oci_config)
        if 'region' in kwargs.keys():
            config['region'] = kwargs['region']
            oci.config.validate_config(config)
        self.identity_client = oci.identity.IdentityClient(config)
        response = self.identity_client.list_availability_domains(
            config['tenancy']
            )
        self.availability_domains = response.data

# -------------------------------------------------------------------------------
# Dynamic Routing Gateway
# -------------------------------------------------------------------------------

class drg:
    """Creates and manage a dynamic routing gateway (DRG)"""

    def __init__(self, display_name, **kwargs):
        """Creates a DRG with the required display name.
        
        The only required parameter is <display_name>. This name is used to
        detect if the DRG has been created already. If so, the DRG details are
        used to populate the instance.
        
        The optional parameters are:
          region:
            The OCI region name. The default value is obtained from the OCI
            configuration file.
          compartment_id:
            The OCID of the OCI compartment where to create the RPC. The
            default value is obtained from the OCI CLI configuration file, if
            present."""

        global compartment_id
        global oci_config

        if oci_config is None:
            load_oci_config()
        config = dict(oci_config)
        if 'region' in kwargs.keys():
            config['region'] = kwargs['region']
            oci.config.validate_config(config)
        self.nw_client = oci.core.VirtualNetworkClient(config)
        response = self.nw_client.list_drgs(
            compartment_id=kwargs.get('compartment_id',compartment_id)
            )
        drg_found = False
        for drg in response.data:
            if drg.display_name == display_name:
                drg_found = True
                break
        if drg_found:
            self.drg = drg
        else:
            self.drg = self.nw_client.create_drg(
                oci.core.models.CreateDrgDetails(
                    compartment_id=kwargs.get(
                        'compartment_id',
                        compartment_id
                        ),
                    display_name=display_name
                    )
                ).data

        self.rpcs = list()
        self.attachments = list()
    
    def attach(self, vcn, **kwargs):
        """Attachs the VCN to the DRG. If the VCN is already attached to the DRG,
        the procedure returns. Otherwise, the procedure waits until both the DRG
        and DRG have been provisioned. The procedure waits 30 seconds before
        checking the life-cycle state.
        
        The only required parameter is:
          vcn:
            The response details from the creation of the VCN.
        
        Optional parameters are:
          compartment_id:
            The OCID of the compartment where to create the DRG. The default
            value is obtained from the value gathered at the instantiation of
            the DRG object.
          display_name:
            The name to be displayed for the DRG. There is NO default value."""

        global sleep_time

        for attachment in self.attachments:
            if attachment.network_details.type == oci.core.models.DrgAttachmentNetworkDetails.TYPE_VCN and \
                attachment.network_details.id == vcn.id:
                return

        while True:
            response = self.nw_client.get_drg(self.drg.id)
            if response.data.lifecycle_state == "AVAILABLE":
                break
            if response.data.lifecycle_state != 'PROVISIONING':
                raise Exception("DRG lifecycle state is neither PROVISIONING nor AVAILABLE")
            time.sleep(sleep_time)

        while True:
            response = self.nw_client.get_vcn(vcn.id)
            if response.data.lifecycle_state == "AVAILABLE":
                break
            if response.data.lifecycle_state != 'PROVISIONING':
                raise Exception("VCN lifecycle state is neither PROVISIONING nor AVAILABLE")
            time.sleep(sleep_time)
        
        response = self.nw_client.list_drg_attachments(
            kwargs.get('compartment_id',compartment_id),
            drg_id=self.drg.id,
            network_id=vcn.id,
            attachment_type="VCN",
            display_name=kwargs.get('display_name')
            )
        if len(response.data) == 0:
            response = self.nw_client.create_drg_attachment(
                oci.core.models.CreateDrgAttachmentDetails(
                    display_name=kwargs.get('display_name'),
                    drg_id=self.drg.id,
                    network_details=oci.core.models.DrgAttachmentNetworkCreateDetails(
                        id=vcn.id,
                        type=oci.core.models.DrgAttachmentNetworkCreateDetails.TYPE_VCN
                        )
                    )
                )
            self.attachments.append(response.data)
        else:
            self.attachments.append(response.data[0])

    def add_rpc(self, display_name, **kwargs):
        """Creates a remote peering connection (RPC) with the required
        display name.
        
        The only required parameter is <display_name>. This name is used to
        detect if the RPC has been created already. If so, the RPC details are
        used to populate the instance.
        
        The optional parameter is:
          compartment_id:
            The OCID of the OCI compartment where to create the RPC. The
            default value is obtained from the OCI CLI configuration file, if
            present."""

        global compartment_id

        response = self.nw_client.list_remote_peering_connections(
            compartment_id=kwargs.get('compartment_id',compartment_id)
            )
        rpc_found = False
        for rpc in response.data:
            if rpc.display_name == display_name:
                rpc_found = True
                break
        if rpc_found:
            self.rpcs.append(rpc)
        else:
            response = self.nw_client.create_remote_peering_connection(
                oci.core.models.CreateRemotePeeringConnectionDetails(
                    compartment_id=kwargs.get(
                        'compartment_id',
                        compartment_id
                        ),
                    display_name=display_name,
                    drg_id=self.drg.id
                    )
                )
            self.rpcs.append(response.data)
    
    def connect(self, display_name, remote_rpc_id, remote_peer_region):
        """Connects the RPC with the remote one."""

        global sleep_time

        rpc_found = False
        for rpc in self.rpcs:
            if rpc.display_name == display_name:
                rpc_found = True
        
        if not rpc_found:
            raise Exception(f"RPC '{display_name}' not found")
        
        while True:
            response = self.nw_client.get_remote_peering_connection(rpc.id)
            if response.data.lifecycle_state == "AVAILABLE":
                break
            if response.data.lifecycle_state != "PROVISIONING":
                raise Exception(f"RPC {rpc.id} lifecyle state is neither AVAILABLE nor PROVISIONING")
            time.sleep(sleep_time)
        
        if response.data.peering_status != 'PEERED':
            self.nw_client.connect_remote_peering_connections(
                rpc.id,
                oci.core.models.ConnectRemotePeeringConnectionsDetails(
                    peer_id=remote_rpc_id,
                    peer_region_name=remote_peer_region
                    )
                )
    
    def get_rpc_id(self, display_name):
        """Get the Remote Peering Connection (RPC) OCID that has the display
        name of <display_name>.
        
        There is only one (1) required parameter:
          display_name:
            Display name of the RPC."""

        rpc_found = False
        for rpc in self.rpcs:
            if rpc.display_name == display_name:
                rpc_found = True
        
        if not rpc_found:
            raise Exception(f"RPC '{display_name}' not found")

        return rpc.id

    def get_all_route_rules(self,**kwargs):
        """TODO"""

        global sleep_time

        while True:
            response = self.nw_client.get_drg(self.drg.id)
            if response.data.lifecycle_state == "AVAILABLE":
                break
            if response.data.lifecycle_state != 'PROVISIONING':
                raise Exception("DRG lifecycle state is neither PROVISIONING nor AVAILABLE")
            time.sleep(sleep_time)
        
        response = self.nw_client.create_drg_route_distribution(
            oci.core.models.CreateDrgRouteDistributionDetails(
                display_name=kwargs.get('display_name'),
                distribution_type=kwargs.get(
                    'distribution_type',
                    oci.core.models.CreateDrgRouteDistributionDetails.DISTRIBUTION_TYPE_IMPORT),
                drg_id=self.drg.id
                )
            )
        drg_route_distribution_id = response.data.id
        statements = list()
        statements.append(
            oci.core.models.AddDrgRouteDistributionStatementDetails(
                action=oci.core.models.AddDrgRouteDistributionStatementDetails.ACTION_ACCEPT,
                match_criteria=[
                    oci.core.models.DrgRouteDistributionMatchCriteria(
                        match_type=oci.core.models.DrgRouteDistributionMatchCriteria.MATCH_TYPE_MATCH_ALL
                        )
                    ],
                priority=1
                )
            )
        add_drg_route_distribution_statements_details = oci.core.models.AddDrgRouteDistributionStatementsDetails(
            statements=statements
            )
        response = self.nw_client.add_drg_route_distribution_statements(
            drg_route_distribution_id,
            add_drg_route_distribution_statements_details
            )

# -------------------------------------------------------------------------------
# DNS
# -------------------------------------------------------------------------------

class dns_zone:
    """Domain Name System (DNS)"""

    def __init__(self, vcn, zone_name, **kwargs):
        """Create a Domain Name System (DNS) object with the <zone_name>.
        
        The required parameter are:
          vcn:
            The VCN object to attach the DNS zone to.
          zone_name:
            This name is used to detect if the DNS zone has been created already.
            If so, the DNS zone details are used to populate the instance.
        
        The optional parameters are:
          compartment_id:
            The OCID of the OCI compartment where to create the VCN. The
            default value is obtained from the OCI CLI configuration file, if
            present.
          region:
            The OCI region name. The default value is obtained from the OCI
            configuration file.
          scope:
            Whether the DNS zone is 'PUBLIC' or 'PRIVATE'. Default value is
            'PRIVATE'."""

        global oci_config
        global compartment_id

        assert type(vcn).__name__ == 'Vcn', \
            'VCN object expected'
        assert type(zone_name) == str and len(zone_name) > 0, \
            'Zone name must be a string'

        if oci_config is None:
            load_oci_config()
        config = dict(oci_config)
        if 'region' in kwargs.keys():
            config['region'] = kwargs['region']
            oci.config.validate_config(config)
        self.dns_client = oci.dns.DnsClient(config)

        response = self.dns_client.list_views(
            kwargs.get('compartment_id',compartment_id),
            display_name=vcn.display_name,
            scope=kwargs.get('scope','PRIVATE'),
            sort_order='DESC',
            sort_by='timeCreated'
            )
        if len(response.data) == 0:
            raise Exception(f"No default DNS view found for VCN '{vcn.display_name}'")
        self.view = response.data[0]
        response = self.dns_client.list_zones(
            compartment_id=kwargs.get('compartment_id',compartment_id),
            name=zone_name,
            zone_type=kwargs.get('zone_type','PRIMARY'),
            scope=kwargs.get('scope','PRIVATE'),
            view_id=self.view.id
            )
        if len(response.data) > 0:
            self.zone = response.data[0]
        else:
            response = self.dns_client.create_zone(
                oci.dns.models.CreateZoneDetails(
                    name=zone_name,
                    zone_type=kwargs.get('zone_type','PRIMARY'),
                    compartment_id=kwargs.get('compartment_id',compartment_id),
                    migration_source=oci.dns.models.CreateZoneBaseDetails.MIGRATION_SOURCE_NONE,
                    scope=kwargs.get('scope','PRIVATE'),
                    view_id=self.view.id
                    ),
                scope=kwargs.get('scope','PRIVATE')
                )
            self.zone = response.data

    def add_dns_record(self, **kwargs):
        """Adds a DNS record.
        
        Optional parameters:
          address:
            IP address to resolve name to.
          name:
            Name of DNS entry.
          ttl:
            Time to live for DNS entry.
          type:
            Type of DNS entry."""
        
        response = self.dns_client.get_zone_records(
            self.zone.id,
            rtype=kwargs.get('type','A'),
            compartment_id=kwargs.get('compartment_id',compartment_id),
            scope=kwargs.get('scope','PRIVATE'),
            view_id=self.view.id,
            domain=kwargs.get('name')
            )
        if response.data.items is not None and len(response.data.items) > 0:
            self.domain = response.data
            items = response.data.items
        else:
            items = list()
        new_item = oci.dns.models.RecordDetails(
            domain=kwargs.get('name'),
            rdata=kwargs.get('address'),
            rtype=kwargs.get('type','A'),
            ttl=kwargs.get('ttl')
            )
        if new_item not in items:
            items.append(new_item)
            update_zone_records_details = oci.dns.models.UpdateZoneRecordsDetails(
                items=items
                )
            response = self.dns_client.update_zone_records(
                self.zone.id,
                update_zone_records_details, 
                scope=kwargs.get('scope','PRIVATE'),
                view_id=self.view.id
                )
# -------------------------------------------------------------------------------
# Virtual Cloud Network (VCN)
# -------------------------------------------------------------------------------

class vcn:
    """Creates and manage a virtual cloud network (VCN)"""

    def __init__(self, display_name, **kwargs):
        """Create a VCN with the required display name.
        
        The only required parameter is <display_name>. This name is used to
        detect if the VCN has been created already. If so, the VCN details are
        used to populate the instance.
        
        The optional parameters are:
          assign_ipv6_address:
            Whether to use IPv6 addresses in VCN. The default value is False.
          compartment_id:
            The OCID of the OCI compartment where to create the VCN. The
            default value is obtained from the OCI CLI configuration file, if
            present.
          cidr_blocks:
            A list of CIDR blocks to be used by the VCN. The default CIDR block
            list is [10.0.0.0/16].
          dns_label:
            DNS label for VCN. The default value is derived from the display
            name by converting to lowercase and removing dashes and
            underscores.
          region:
            The OCI region name. The default value is obtained from the OCI
            configuration file."""

        global compartment_id
        global oci_config

        if oci_config is None:
            load_oci_config()
        config = dict(oci_config)
        if kwargs.get('region') is not None:
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
                    display_name.lower().replace('-','').replace('_','')[:15]
                    ),
                cidr_blocks=cidr_blocks,
                is_ipv6_enabled=kwargs.get('assign_ipv6_address',False)
            )
            self.vcn     = self.nw_client.create_vcn(vcn_details).data
        self.ig      = None
        self.sg      = None
        self.natg    = None
        self.lpg     = None
        self.subnets = []

    def add_ig(self, **kwargs):
        """Create an Internet Gateway that is enabled.
        
        The optional parameters are:
          compartment_id:
            The OCID of the OCI compartment where to create the VCN. The default
            value is obtained from the OCI CLI configuration file, if present.
          display_name:
            The name assigned to the Internet Gateway. The default value is 
            'Internet Gateway-<name of VCN>'."""

        global compartment_id

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
            response = self.nw_client.create_internet_gateway(
                oci.core.models.CreateInternetGatewayDetails(
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
                )
            self.ig = response.data
    
    def new_service_route_rule(self):
        """Creates a routing rule for a service gateway."""

        response = self.nw_client.get_service(self.sg.services[0].service_id)
        return new_route_rule(
            self.sg.id,
            destination=response.data.cidr_block,
            destination_type=oci.core.models.RouteRule.DESTINATION_TYPE_SERVICE_CIDR_BLOCK,
            description="Access to local services",
            route_type=oci.core.models.RouteRule.ROUTE_TYPE_STATIC
            )

    def new_route_table(self, subnet_idx, **kwargs):
        """Creates a new route table for subnet"""

        global compartment_id
        global sleep_time

        rt_response = self.nw_client.create_route_table(
            oci.core.models.CreateRouteTableDetails(
                compartment_id=kwargs.get('compartment_id',compartment_id),
                display_name=kwargs.get('display_name'),
                route_rules=kwargs.get('route_rules'),
                vcn_id=self.vcn.id
                )
            )

        while True:
            response = self.nw_client.get_subnet(self.subnets[subnet_idx].id)
            if response.data.lifecycle_state == "AVAILABLE":
                break
            if response.data.lifecycle_state != 'PROVISIONING':
                raise Exception("Subnet lifecycle state is neither PROVISIONING nor AVAILABLE")
            time.sleep(sleep_time)

        self.nw_client.update_subnet(
            self.subnets[subnet_idx].id,
            oci.core.models.UpdateSubnetDetails(
                route_table_id=rt_response.data.id
                )
            )
        self.subnets[subnet_idx].route_table_id = rt_response.data.id

    def add_route_rule(self, nw_entity_id, rt_id=None, **kwargs):
        """Add a route rule to the specified route table.

        If no route table is specified, the default route table for the VCN
        is used.

        If the nw_entity_id is found in the current route table rules, the
        addition is skipped.

        The other optional parameters are:
          description:
            A textual description of the route rule. The default value is
            'Default routing is to the Internet'.
          destination:
            The route target for the rule. The default value is '0.0.0.0/0'.
          destination_type:
            The type of the route target for the rule. The default value is
            'CIDR_BLOCK'.
          route_type:
            The type of route rule. The default route type is 'STATIC'.
        """

        if rt_id == None:
            rt_id = self.vcn.default_route_table_id
        response = self.nw_client.get_route_table(rt_id)
        route_found = False
        new_rule = new_route_rule(nw_entity_id, **kwargs)
        for rule in response.data.route_rules:
            if rule == new_rule:
                route_found = True
                break
        if not route_found:
            new_route_table = list(response.data.route_rules)
            new_route_table.append(new_rule)
            self.nw_client.update_route_table(
                self.vcn.default_route_table_id,
                oci.core.models.UpdateRouteTableDetails(
                    route_rules=new_route_table
                )
            )

    def add_sg(self, service_type='ALL', **kwargs):
        """Adds a Service Gateway to the VCN.
        
        If a Service Gateway already exists in the VCN, those details are used
        instead of creating a new one.
        
        Optional parameters:
          compartment_id:
            The OCID of the OCI compartment where to create the VCN. The default
            value is obtained from the OCI CLI configuration file, if present.
          display_name:
            The display name of the Service Gateway. Default value is
            'Service gateway-<display name for VCN>'.
          service_type:update_oci_config
            The type of services to attach. Default value is 'ALL'. Other valid
            values are 'OBJECT'."""

        global compartment_id

        response = self.nw_client.list_service_gateways(
            kwargs.get(
                'compartment_id',
                compartment_id
                ),
            vcn_id=self.vcn.id
        )
        if len(response.data) > 0:
            self.sg = response.data[0]
        else:
            response = self.nw_client.list_services()
            service_ocid = None
            for service in response.data:
                if service_type in service.description.upper():
                    service_ocid = service.id
                    break
            self.sg = self.nw_client.create_service_gateway(
                oci.core.models.CreateServiceGatewayDetails(
                    display_name=kwargs.get(
                        'display_name',
                        f'Service gateway-{self.vcn.display_name}'
                        ),
                    compartment_id=kwargs.get(
                        'compartment_id',
                        compartment_id
                        ),
                    services=[
                        oci.core.models.ServiceIdRequestDetails(
                            service_id=service_ocid
                        )
                    ],
                    vcn_id=self.vcn.id
                )
            ).data

    def add_natg(self, **kwargs):
        """Adds a NAT Gateway to the VCN.
        
        If a NAT Gateway already exists in the VCN, those details are used
        instead of creating a new one.
        
        Optional parameters:
          compartment_id:
            The OCID of the OCI compartment where to create the VCN. The default
            value is obtained from the OCI CLI configuration file, if present.
          display_name:
            The display name of the NAT Gateway. Default value is
            'NAT gateway-<display name for VCN>'."""
        
        global compartment_id

        response = self.nw_client.list_nat_gateways(
            kwargs.get(
                'compartment_id',
                compartment_id
                ),
            vcn_id=self.vcn.id
        )
        if len(response.data) > 0:
            self.natg = response.data[0]
        else:
            self.natg = self.nw_client.create_nat_gateway(
                oci.core.models.CreateNatGatewayDetails(
                    display_name=kwargs.get(
                        'display_name',
                        f'NAT gateway-{self.vcn.display_name}'
                        ),
                    compartment_id=kwargs.get(
                        'compartment_id',
                        compartment_id
                        ),
                    vcn_id=self.vcn.id
                )
            ).data

    def add_lpg(self, **kwargs):
        """Adds a Local Peering Gateway to the VCN.
        
        If a Local Peering Gateway already exists in the VCN, those details
        are used instead of creating a new one.
        
        Optional parameters:
          compartment_id:
            The OCID of the OCI compartment where to create the VCN. The
            default value is obtained from the OCI CLI configuration file,
            if present.
          display_name:
            The display name of the Local Peering Gateway. Default value is
            'Local peering gateway-<display name for VCN>'."""
        
        global compartment_id

        response = self.nw_client.list_local_peering_gateways(
            kwargs.get(
                'compartment_id',
                compartment_id
                ),
            vcn_id=self.vcn.id
        )
        if len(response.data) > 0:
            self.lpg = response.data[0]
        else:
            self.lpg = self.nw_client.create_local_peering_gateway(
                oci.core.models.CreateLocalPeeringGatewayDetails(
                    display_name=kwargs.get(
                        'display_name',
                        f'Local peering gateway-{self.vcn.display_name}'
                        ),
                    compartment_id=kwargs.get(
                        'compartment_id',
                        compartment_id
                        ),
                    vcn_id=self.vcn.id
                )
            ).data

    def connect_lpgs(self, lpg_id):
        """Connect Local Peering Gateways.
        """
        assert self.lpg is not None, "VCN does not have a LPG"

        response = self.nw_client.get_local_peering_gateway(self.lpg.id)
        self.lpg = response.data
        if self.lpg.peer_id is None:
            response = self.nw_client.connect_local_peering_gateways(
                self.lpg.id,
                oci.core.models.ConnectLocalPeeringGatewaysDetails(
                    peer_id=lpg_id
                    )
                )
            response = self.nw_client.get_local_peering_gateway(self.lpg.id)
            self.lpg = response.data
        
    def add_subnet(self, display_name, public_access=False, **kwargs):
        """Adds a Subnet to the VCN.
        
        If a Subnet already exists in the VCN, those details are used
        instead of creating a new one.

        Required parameters:
          display_name:
            The display name of the Subnet.
        
        Optional parameters:
          cidr_block:
            The CIDR block for the subnet. The default value is calculated in
            one (1) of two (2) ways:
              (1) A subnet equivalent to the first 24-bit CIDR block based on the
                  first VCN CIDR block.
              (2) The next 24-bit CIDR block following the last subnet created.
          compartment_id:
            The OCID of the OCI compartment where to create the VCN. The default
            value is obtained from the OCI CLI configuration file, if present.
          ipv6_address:
            The IPv6 subnet address for this subnet.
          public_access:
            Whether or not the subnet has publicly visible IP addresses. The
            default value is False (only private IP addresses are available in
            the subnet.)"""

        global compartment_id

        response = self.nw_client.list_subnets(
            kwargs.get(
                'compartment_id',
                compartment_id
                ),
            display_name=kwargs.get(
                'display_name',
                display_name
            ),
            vcn_id=self.vcn.id
        )
        if len(response.data) > 0:
            self.subnets.append(response.data[0])
        else:
            cidr_block = kwargs.get('cidr_block')
            if cidr_block is None:
                if len(self.subnets) == 0:
                    vcn_block = netaddr.ip.IPNetwork(
                        self.vcn.cidr_blocks[0]
                        )
                    cidr_block = str(
                        list(
                            vcn_block.subnet(24,count=1)
                        )[0]
                    )
                else:
                    cidr_block = str(
                        netaddr.ip.IPNetwork(
                            self.subnets[-1].cidr_block
                            ).next()
                        )
            prohibit_public_ip_on_vnic = not public_access
            if 'ipv6_address' in kwargs.keys():
                ipv6_subnet_num = int(kwargs['ipv6_address'],base=16) + 1
                assert self.vcn.ipv6_cidr_blocks is not None, \
                    "IPv6 Address missing"
                ipv6_subnet_cidr = str(
                    list(
                        netaddr.ip.IPNetwork(
                            self.vcn.ipv6_cidr_blocks[0],
                            version=6
                            ).subnet(
                                64,
                                count=ipv6_subnet_num
                            )
                        )[-1]
                    )
                ipv6_cidr_blocks = [ipv6_subnet_cidr]
            else:
                ipv6_cidr_blocks = None

            self.subnets.append(
                self.nw_client.create_subnet(
                    oci.core.models.CreateSubnetDetails(
                        cidr_block=cidr_block,
                        compartment_id=kwargs.get(
                            'compartment_id',
                            compartment_id
                        ),
                        display_name=display_name,
                        prohibit_public_ip_on_vnic=prohibit_public_ip_on_vnic,
                        dns_label=kwargs.get(
                            'dns_label',
                            display_name.lower().replace('-','').replace('_','').replace(' ','')[:15]
                        ),
                        ipv6_cidr_blocks=ipv6_cidr_blocks,
                        vcn_id=self.vcn.id
                    )
                ).data
            )

    def add_ingress_rule(self, **kwargs):
        """Add an Ingress Rule to a security rule
        
        Optional parameters:
          code:
            The numeric code for ICMP or ICMPv6 rule.
          description:
            A textual description of the rule. There is NO default value.
          dest_ports:
            A tuple of ports (min,max).
          dest_type:
            The type of destination for the rule. The default value is 'CIDR_BLOCK'.
          is_stateless:
            A Boolean value indicating whether the rule is stateless or not.
            The default value is False.
          protocol:
            Textual representation of protocol to be used. Valid values are:
              - 'ICMP' (default value)
              - 'TCP'
              - 'UDP'
              - 'ICMPv6'
          sl_id:
            OCID for security list. Default value is default-security-list-id
            for the VCN.
          source_type:
            The type of source for the rule. The default value is 'CIDR_BLOCK'.
          src_ports:
            A tuple of ports (min,max).
          type:
            The numeric type for ICMP or ICMPv6 rule."""

        sl_id = kwargs.get('sl_id',self.vcn.default_security_list_id)
        response = self.nw_client.get_security_list(sl_id)
        ingress_rules = response.data.ingress_security_rules
        protocol = kwargs.get('protocol','ICMP')
        if   protocol == "ICMP":
            if kwargs.get('code') is not None:
                icmp_options = oci.core.models.IcmpOptions(
                    code=kwargs.get('code'),
                    type=kwargs.get('type')
                    )
            else:
                icmp_options = oci.core.models.IcmpOptions(
                    type=kwargs.get('type')
                    )
            req_rule = oci.core.models.IngressSecurityRule(
                source_type=kwargs.get(
                    'source_type',
                    oci.core.models.IngressSecurityRule.SOURCE_TYPE_CIDR_BLOCK
                    ),
                protocol="1",
                is_stateless=kwargs.get('is_stateless',False),
                source=kwargs.get('source'),
                icmp_options=icmp_options,
                description=kwargs.get('description')
                )
        elif protocol == "TCP":
            dest_ports = kwargs.get('dest_ports')
            src_ports  = kwargs.get('src_ports')
            if dest_ports is not None:
                destination_port_range=oci.core.models.PortRange(
                    min=dest_ports[0],
                    max=dest_ports[1]
                    )
            else:
                destination_port_range=None
            if src_ports is not None:
                source_port_range=oci.core.models.PortRange(
                    min=src_ports[0],
                    max=src_ports[1]
                    )
            else:
                source_port_range=None
            req_rule = oci.core.models.IngressSecurityRule(
                source_type=kwargs.get(
                    'source_type',
                    oci.core.models.IngressSecurityRule.SOURCE_TYPE_CIDR_BLOCK
                    ),
                protocol="6",
                is_stateless=kwargs.get('is_stateless',False),
                source=kwargs.get('source'),
                tcp_options=oci.core.models.TcpOptions(
                    destination_port_range=destination_port_range,
                    source_port_range=source_port_range
                    ),
                description=kwargs.get('description')
                )
        elif protocol == "UDP":
            dest_ports = kwargs.get('dest_ports')
            src_ports  = kwargs.get('src_ports')
            if dest_ports is not None:
                destination_port_range=oci.core.models.PortRange(
                    min=dest_ports[0],
                    max=dest_ports[1]
                    )
            else:
                destination_port_range=None
            if src_ports is not None:
                source_port_range=oci.core.models.PortRange(
                    min=src_ports[0],
                    max=src_ports[1]
                    )
            else:
                destination_port_range=None
            req_rule = oci.core.models.IngressSecurityRule(
                source_type=kwargs.get(
                    'source_type',
                    oci.core.models.IngressSecurityRule.SOURCE_TYPE_CIDR_BLOCK
                    ),
                protocol="17",
                is_stateless=kwargs.get('is_stateless',False),
                source=kwargs.get('source'),
                udp_options=oci.core.models.UdpOptions(
                    destination_port_range=destination_port_range,
                    source_port_range=source_port_range
                    ),
                description=kwargs.get('description')
                )
        elif protocol == "ICMPv6":
            if kwargs.get('type') is not None:
                icmp_options = oci.core.models.IcmpOptions(
                    code=kwargs.get('code'),
                    type=kwargs.get('type')
                    )
            else:
                icmp_options = None
            req_rule = oci.core.models.IngressSecurityRule(
                source_type=kwargs.get(
                    'source_type',
                    oci.core.models.IngressSecurityRule.SOURCE_TYPE_CIDR_BLOCK
                    ),
                protocol="58",
                is_stateless=kwargs.get('is_stateless',False),
                source=kwargs.get('source'),
                icmp_options=icmp_options,
                description=kwargs.get('description')
                )
        rule_found = False
        for rule in ingress_rules:
            if rule == req_rule:
                rule_found = True
                break
        if not rule_found:
            ingress_rules.append(req_rule)
            response = self.nw_client.update_security_list(
                sl_id,
                oci.core.models.UpdateSecurityListDetails(
                    ingress_security_rules=ingress_rules
                    )
                )

    def print_security_list(self, sl_ocid, indent=0):
        """Print security list"""

        def print_port_range(sp, dp):
            result  = ''
            if sp is None:
                result += "PORTS=ALL"
            else:
                if sp.min == sp.max:
                    result += f"PORT={sp.min}"
                else:
                    result += f"PORTS={sp.min}-{sp.max}"
            result += " -> "
            if dp is None:
                result += "PORTS=ALL "
            else:
                if dp.min == dp.max:
                    result += f"PORT={dp.min} "
                else:
                    result += f"PORTS={dp.min}-{dp.max} "
            return result

        offset  = ''.ljust(indent)
        response = self.nw_client.get_security_list(sl_ocid)
        sl = response.data
        result = f"{offset}{sl.display_name}:\n"
        result += f"{offset}  Egress Security Rules:\n"
        for rule in sl.egress_security_rules:
            if rule.destination_type == "CIDR_BLOCK":
                result += f"{offset}    {rule.destination.ljust(18)} "
            else:
                result += f"{offset}    {rule.destination.ljust(18)} {rule.destination_type} "
            result += "STATELESS " if rule.is_stateless else "STATEFUL "
            if rule.protocol == "1":
                result += f"ICMP (type={rule.icmp_options.type}"
                if rule.icmp_options.code is not None:
                    result += f", code={rule.icmp_options.code}"
                result += ") "
            elif rule.protocol == "6":
                result += "TCP "
                result += print_port_range(
                    rule.tcp_options.source_port_range,
                    rule.tcp_options.destination_port_range
                )
            elif rule.protocol == "17":
                result += "UDP "
                result += print_port_range(
                    rule.udp_options.source_port_range,
                    rule.udp_options.destination_port_range
                )
            elif rule.protocol == "58":
                result += f"ICMPv6 (type={rule.icmp_options.type}"
                if rule.icmp_options.code is not None:
                    result += f", code={rule.icmp_options.code}"
                result += ") "
            else:
                result += str(rule.protocol) + ' '
            result += '\n'
        result += f"{offset}  Ingress Security Rules:\n"
        for rule in sl.ingress_security_rules:
            if rule.source_type == "CIDR_BLOCK":
                result += f"{offset}    {rule.source.ljust(18)} "
            else:
                result += f"{offset}    {rule.source.ljust(18)} {rule.source_type} "
            result += "STATELESS " if rule.is_stateless else "STATEFUL "
            if rule.protocol == "1":
                result += f"ICMP (type={rule.icmp_options.type}"
                if rule.icmp_options.code is not None:
                    result += f", code={rule.icmp_options.code}"
                result += ") "
            elif rule.protocol == "6":
                result += "TCP "
                result += print_port_range(
                    rule.tcp_options.source_port_range,
                    rule.tcp_options.destination_port_range
                )
            elif rule.protocol == "17":
                result += "UDP "
                result += print_port_range(
                    rule.udp_options.source_port_range,
                    rule.udp_options.destination_port_range
                )
            elif rule.protocol == "58":
                result += "ICMPv6 "
                if rule.icmp_options is not None:
                    result += f"(type={rule.icmp_options.type}"
                    if rule.icmp_options.code is not None:
                        result += f", code={rule.icmp_options.code}"
                    result += ") "
            else:
                result += str(rule.protocol) + ' '
            result += '\n'
        return result

    def print_subnet(self, subnet_idx, indent=0):
        """Print subnet details"""

        offset  = ''.ljust(indent)
        subnet  = self.subnets[subnet_idx]
        result  = f"{offset}Subnet '{subnet.display_name}': "
        result += 'PRIVATE' if subnet.prohibit_public_ip_on_vnic else 'PUBLIC'
        result += f"\n{offset}  {subnet.cidr_block.ljust(18)}"
        result += f"\n{offset}  Route Table:"
        if subnet.route_table_id == self.vcn.default_route_table_id:
            result += " VCN Default\n"
        else:
            result += '\n'
            result += self.print_route_table(subnet.route_table_id,indent=indent+4)
        result += f"{offset}  Security Lists:\n"
        for sl_id in subnet.security_list_ids:
            if sl_id == self.vcn.default_security_list_id:
                result += f"{offset}    VCN Default\n"
            else:
                result += self.print_security_list(sl_id,indent=indent+4)
        return result

    def print_route_table(self, rt_id, indent=0):
        """Prints an OCI route table with a leading indent."""

        response = self.nw_client.get_route_table(rt_id).data
        offset  = ''.ljust(indent)
        result  = f"{offset}'{response.display_name}': {response.lifecycle_state}\n"
        for rule in response.route_rules:
            result += offset + '  '
            result += rule.destination.ljust(18) + ' '
            if self.ig is not None and rule.network_entity_id == self.ig.id:
                result += f"Internet Gateway ('{self.ig.display_name}') "
            elif self.natg is not None and rule.network_entity_id == self.natg.id:
                result += f"NAT Gateway ('{self.natg.display_name}') "
            elif self.sg is not None and rule.network_entity_id == self.sg.id:
                result += f"Service Gateway ('{self.sg.display_name}') "
            result += rule.route_type + ' '
            if rule.description is not None:
                result += rule.description
            result += '\n'
        return result

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
        result += "  Subnets:\n"
        for subnet_idx in range(len(self.subnets)):
            result += self.print_subnet(subnet_idx,indent=4)
        result += "  Route Tables:\n    Default:\n"
        result += self.print_route_table(self.vcn.default_route_table_id,indent=6)
        result += "  Security Lists:\n    Default:\n"
        result += self.print_security_list(self.vcn.default_security_list_id,indent=6)
        return result

# ------------------------------------------------------------------------------
# A sub-class that emulates the OCI Console Wizard to create a VCN
# ------------------------------------------------------------------------------

class vcn_wizard(vcn):

    def __init__(
        self,
        display_name=None,
        region=None,
        cidr_blocks=["10.0.0.0/16"]
        ):
        super().__init__(
            display_name,
            region=region,
            cidr_blocks=cidr_blocks
            )
        self.add_ig()
        self.add_route_rule(self.ig.id)
        self.add_sg()
        self.add_natg()
        self.add_subnet(
            "public subnet-" + display_name,
            public_access=True,
            dns_label='public'
            )
        self.add_subnet(
            "private subnet-" + display_name,
            public_access=False,
            dns_label='private'
            )
        if self.subnets[1].route_table_id == self.vcn.default_route_table_id:
            route_rules=[]
            route_rules.append(
                new_route_rule(
                    self.natg.id,
                    cidr_block="0.0.0.0/0"
                    )
                )
            route_rules.append(self.new_service_route_rule())
            self.new_route_table(
                1,
                display_name=f"route table for private subnet-{display_name}",
                route_rules=route_rules
                )

# ------------------------------------------------------------------------------
# Network Security Group (NSG) Class
# ------------------------------------------------------------------------------

class nsg:
    """Creates and manages NSG class"""

    def __init__(self, display_name, **kwargs):
        """Create a NSG with the required display name.
        
        The only required parameter is <display_name>. This name is used to
        detect if the NSG has been created already. If so, the NSG details are
        used to populate the instance.
        
        The optional parameters are:
          compartment_id:
            The OCID of the OCI compartment where to create the VCN. The
            default value is obtained from the OCI CLI configuration file, if
            present.
          region:
            The OCI region name. The default value is obtained from the OCI
            configuration file.
          vcn_id:
            OCID for VCN."""

        global compartment_id
        global oci_config

        if oci_config is None:
            load_oci_config()
        config = dict(oci_config)
        if kwargs.get('region') is not None:
            config['region'] = kwargs['region']
            oci.config.validate_config(config)
        self.nw_client = oci.core.VirtualNetworkClient(config)
        response = self.nw_client.list_network_security_groups(
            compartment_id=kwargs.get('compartment_id',compartment_id),
            display_name=display_name,
            vcn_id=kwargs.get('vcn_id')
            )
        if len(response.data) > 0:
            self.nsg = response.data[0]
        else:
            response = self.nw_client.create_network_security_group(
                oci.core.models.CreateNetworkSecurityGroupDetails(
                    compartment_id=kwargs.get('compartment_id',compartment_id),
                    display_name=display_name,
                    vcn_id=kwargs.get('vcn_id')
                    )
                )
            self.nsg = response.data
    
    def add_nsg_rule_action(self,**kwargs):
        """"""

# ------------------------------------------------------------------------------
# Class for launching COMPUTE instances
# ------------------------------------------------------------------------------

class compute:
    """Launches and manages COMPUTE instances."""

    def __init__(self, display_name, **kwargs):
        """Creates a COMPUTE instance with the required display name.
        
        The only required parameter is <display_name>. This name is used to
        detect if the COMPUTE instance has been created already. If so, the
        COMPUTE instance details are used to populate the instance.
        
        The optional parameters are:
          assign_ipv6_addr:
            Whether to assign an IPv6 address to the primary VNIC. Default value is
            False.
          avail_domain:
            Availability domain into which launch the COMPUTE instance.
          compartment_id:
            The OCID of the OCI compartment where to create the RPC. The
            default value is obtained from the OCI CLI configuration file, if
            present.
          memory_in_gb:
            The amount of memory (in GB) to allocate to the COMPUTE instance on
            launch. Default value is six (6).
          ocpus:
            The number of Oracle CPUs to allocate to the COMPUTE instance on
            launch. Default value is one (1).
          os:
            The type of operating system to use. There is no default value.

            Along with <os_ver>, <os> is used to select the COMPUTE image to
            launch that is compatible with <shape>.
          os_ver:
            Version of operating system to use. There is no default value.
          region:
            The OCI region name. The default value is obtained from the OCI
            configuration file.
          shape:
            Shape of the COMPUTE instance to be launched.
          ssh_keys:
            File location of SSH public key to be stored on the COMPUTE instance.
          subnet:
            Subnet details for attaching the primary VNIC to.
          """

        global compartment_id
        global oci_config
        global sleep_time

        if oci_config is None:
            load_oci_config()
        config = dict(oci_config)
        if 'region' in kwargs.keys():
            config['region'] = kwargs['region']
            oci.config.validate_config(config)
        self.compute_client = oci.core.ComputeClient(config)
        self.network_client = oci.core.VirtualNetworkClient(config)
        response = self.compute_client.list_instances(
            kwargs.get('compartment_id',compartment_id),
            display_name=display_name,
            lifecycle_state="RUNNING"
            )
        if len(response.data) > 0:
            self.instance = response.data[0]
        else:
            response = self.compute_client.list_images(
                kwargs.get('compartment_id',compartment_id),
                operating_system=kwargs.get('os'),
                operating_system_version=kwargs.get('os_ver'),
                shape=kwargs.get('shape'),
                sort_by="TIMECREATED",
                sort_order="DESC",
                lifecycle_state="AVAILABLE"
            )
            if len(response.data) == 0:
                raise Exception(f"No compute images found.")
            compute_image = response.data[0]
            shape_config = oci.core.models.LaunchInstanceShapeConfigDetails(
                memory_in_gbs=float(kwargs.get('memory_in_gb',6)),
                ocpus=float(kwargs.get('ocpus','1'))
            )
            if 'ssh_keys' in kwargs.keys():
                with open(os.path.expanduser(kwargs['ssh_keys']),"r") as f:
                    public_ssh_key_content = f.read()
                metadata = {
                        'ssh_authorized_keys': public_ssh_key_content
                    }
            else:
                metadata = None
            if 'subnet' in kwargs.keys():
                subnet = kwargs['subnet']
                if subnet.ipv6_cidr_blocks is not None:
                    assign_ipv6_ip = (len(subnet.ipv6_cidr_blocks) > 0)
                else:
                    assign_ipv6_ip = False
                create_vnic_details = oci.core.models.CreateVnicDetails(
                    assign_ipv6_ip=assign_ipv6_ip,
                    assign_public_ip=(not subnet.prohibit_public_ip_on_vnic),
                    subnet_id=subnet.id
                    )
            else:
                create_vnic_details = None
            response = self.compute_client.launch_instance(
                oci.core.models.LaunchInstanceDetails(
                    availability_domain=kwargs.get('avail_domain'),
                    compartment_id=kwargs.get('compartment_id',compartment_id),
                    create_vnic_details=create_vnic_details,
                    display_name=display_name,
                    image_id=compute_image.id,
                    shape=kwargs.get('shape'),
                    shape_config=shape_config,
                    metadata=metadata
                )
            )
            self.instance = response.data

            while True:
                response = self.compute_client.get_instance(self.instance.id)
                if response.data.lifecycle_state == "RUNNING":
                    break
                if response.data.lifecycle_state not in ['PROVISIONING','TERMINATING', 'TERMINATED']:
                    raise Exception("COMPUTE instance lifecycle state is neither PROVISIONING, TERMINATING, TERMINATED, nor AVAILABLE")
                time.sleep(sleep_time)

        response = self.compute_client.list_vnic_attachments(
            kwargs.get('compartment_id',compartment_id),
            instance_id=self.instance.id
            )
        self.vnics = list()
        for vnic in response.data:
            if vnic.lifecycle_state != 'ATTACHED': continue
            self.vnics.append(
                self.network_client.get_vnic(vnic.vnic_id).data
            )
    
    def run_ssh_commands(self,**kwargs):
        """Runs one or more commands over SSH link to the COMPUTE instance.
        
        Optional parameters:
          cmds:
            A list of commands to run. The default to run 'uptime'.
          ssh_private_key:
            Location of SSH private key file. The default is to use the
            previous value used.
        """

        ssh_client = paramiko.SSHClient()
        ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        # Connect using the private key
        if self.private_key is None:
            self.private_key = paramiko.RSAKey.from_private_key_file(
                os.path.expanduser(
                    kwargs.get('ssh_private_key')
                    )
                )

        ssh_client.connect(
            hostname=self.vnics[0].public_ip,
            username="opc",
            pkey=self.private_key
            )

        cmds = kwargs.get('cmds',['uptime'])
        for command in cmds:
            stdin, stdout, stderr = ssh_client.exec_command(command)
                
            # Wait for the command to complete
            while not stdout.channel.exit_status_ready():
                time.sleep(0.1)
            
            # Read the output
            stdout_output = stdout.read().decode('utf-8')
            stderr_output = stderr.read().decode('utf-8')
            
            # Print the results
            print("\nStandard Output:")
            print(stdout_output)
            
            print("\nStandard Error:")
            print(stderr_output)
            
            # Get the exit status
            exit_status = stdout.channel.recv_exit_status()

        ssh_client.close()
