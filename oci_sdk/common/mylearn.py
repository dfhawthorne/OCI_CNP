#!/usr/bin/env python3
"""
Wrapper module for executing MyLearn labs.
"""

import netaddr.ip
import oci
import os.path
import time

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
    
def new_route_rule(nw_entity_id, **kwargs):
    """Creates a route rule:
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

        if oci_config == None:
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
        """Attachs the VCN to the DRG."""

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
            time.sleep(30)

        while True:
            response = self.nw_client.get_vcn(vcn.id)
            if response.data.lifecycle_state == "AVAILABLE":
                break
            if response.data.lifecycle_state != 'PROVISIONING':
                raise Exception("VCN lifecycle state is neither PROVISIONING nor AVAILABLE")
            time.sleep(30)
        
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
        display name and .
        
        The only required parameter is <display_name>. This name is used to
        detect if the RPC has been created already. If so, the RPC details are
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
            time.sleep(30)
        
        if response.data.peering_status != 'PEERED':
            self.nw_client.connect_remote_peering_connections(
                rpc.id,
                oci.core.models.ConnectRemotePeeringConnectionsDetails(
                    peer_id=remote_rpc_id,
                    peer_region_name=remote_peer_region
                    )
                )
    
    def get_rpc_id(self, display_name):
        """Get the Remote Peering Connection (RPC) OCID"""

        rpc_found = False
        for rpc in self.rpcs:
            if rpc.display_name == display_name:
                rpc_found = True
        
        if not rpc_found:
            raise Exception(f"RPC '{display_name}' not found")

        return rpc.id

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
          region:
            The OCI region name. The default value is obtained from the OCI
            configuration file.
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
            underscores."""

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
            time.sleep(30)

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
        for rule in response.data.route_rules:
            if rule.network_entity_id == nw_entity_id:
                route_found = True
                break
        if not route_found:
            new_route_table = list(response.data.route_rules)
            new_route_table.append(new_route_rule(nw_entity_id,**kwargs))
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
            print(response)
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
                            display_name.lower().replace('-','').replace('_','').replace(' ','')
                        ),
                        vcn_id=self.vcn.id
                    )
                ).data
            )

    def add_ingress_rule(self, **kwargs):
        """Add an Ingress Rule to a security rule
        
        Optional parameters:
          sl_id:
            OCID for security list. Default value """

        sl_id = kwargs.get('sl_id',self.vcn.default_security_list_id)
        response = self.nw_client.get_security_list(sl_id)
        ingress_rules = response.data.ingress_security_rules
        protocol = kwargs.get('protocol','ICMP')
        if   protocol == "ICMP":
            req_rule = oci.core.models.IngressSecurityRule(
                source_type=kwargs.get(
                    'source_type',
                    oci.core.models.IngressSecurityRule.SOURCE_TYPE_CIDR_BLOCK
                    ),
                protocol="1",
                is_stateless=kwargs.get('is_stateless',False),
                source=kwargs.get('source'),
                icmp_options=oci.core.models.IcmpOptions(
                    code=kwargs.get('code'),
                    type=kwargs.get('type')
                    ),
                description=kwargs.get('description')
                )
        elif protocol == "TCP":
            dest_ports = kwargs.get('dest_ports')
            src_ports  = kwargs.get('src_ports')
            if dest_ports:
                destination_port_range=oci.core.models.PortRange(
                    min=dest_ports[0],
                    max=dest_ports[1]
                    )
            else:
                destination_port_range=None
            if src_ports:
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
            if dest_ports:
                destination_port_range=oci.core.models.PortRange(
                    min=dest_ports[0],
                    max=dest_ports[1]
                    )
            else:
                destination_port_range=None
            if src_ports:
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
            req_rule = oci.core.models.IngressSecurityRule(
                source_type=kwargs.get(
                    'source_type',
                    oci.core.models.IngressSecurityRule.SOURCE_TYPE_CIDR_BLOCK
                    ),
                protocol="58",
                is_stateless=kwargs.get('is_stateless',False),
                source=kwargs.get('source'),
                icmp_options=oci.core.models.IcmpOptions(
                    code=kwargs.get('code'),
                    mode=kwargs.get('mode')
                    ),
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
                result += f"ICMPv6 (type={rule.icmp_options.type}"
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
            if rule.network_entity_id == self.ig.id:
                result += f"Internet Gateway ('{self.ig.display_name}') "
            elif rule.network_entity_id == self.natg.id:
                result += f"NAT Gateway ('{self.natg.display_name}') "
            elif rule.network_entity_id == self.sg.id:
                result += f"Service Gateway ('{self.sg.display_name}') "
            result += rule.route_type + ' '
            if rule.description:
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
