#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Lab 05:
#   Design and Implement Real-World Network Architecture:
#     Configuring private DNS Zones, views, resolvers, listeners and
#     forwarders.
# ------------------------------------------------------------------------------

import oci
import sys

sys.path.append("../common")

import mylearn

# Create Two VCNs and a Subnet

iad_np_lab05_vcn_01 = mylearn.vcn_wizard(
    "IAD-NP-LAB05-VCN-01",
    cidr_blocks=["10.0.0.0/16"]
    )
iad_np_lab05_vcn_02 = mylearn.vcn_wizard(
    "IAD-NP-LAB05-VCN-02",
    cidr_blocks=["172.16.0.0/16"]
    )

# Establish Local Peering for VCNs

iad_np_lab05_vcn_01.add_lpg(display_name="IAD-LAB05-LPG-to-VCN02")
iad_np_lab05_vcn_02.add_lpg(display_name="IAD-LAB05-LPG-to-VCN01")
iad_np_lab05_vcn_01.connect_lpgs(iad_np_lab05_vcn_02.lpg.id)
iad_np_lab05_vcn_01.add_route_rule(
    iad_np_lab05_vcn_01.lpg.id,
    destination=iad_np_lab05_vcn_02.vcn.cidr_blocks[0]
    )
iad_np_lab05_vcn_01.add_ingress_rule(
    type=8,
    protocol="ICMP",
    source=iad_np_lab05_vcn_02.vcn.cidr_blocks[0]
    )
iad_np_lab05_vcn_02.add_route_rule(
    iad_np_lab05_vcn_02.lpg.id,
    destination=iad_np_lab05_vcn_01.vcn.cidr_blocks[0]
    )
iad_np_lab05_vcn_02.add_ingress_rule(
    type=8,
    protocol="ICMP",
    source=iad_np_lab05_vcn_01.vcn.cidr_blocks[0]
    )

# Create a VM Instance

iad_ads = mylearn.availability_domain()
iad_np_lab05_vm_01 = mylearn.compute(
    "IAD-NP-LAB05-VM-01",
    avail_domain=iad_ads.availability_domains[0].name,
    shape="VM.Standard.A1.Flex",
    ocpus=1,
    memory_in_gb=6,
    os="Oracle Linux",
    os_ver="8",
    subnet=iad_np_lab05_vcn_01.subnets[0],
    ssh_keys="~/.ssh/id_rsa.pub"
    )

# Create zone-a.local Custom private Zone

zone_a_local = mylearn.dns_zone(
    iad_np_lab05_vcn_01.vcn,
    "zone-a.local"
    )
zone_a_local.add_dns_record(
    type="A",
    name="server01",
    ttl=30,
    address="10.0.0.2"
    )

# Create zone-b.local Custom private Zone

zone_b_local = mylearn.dns_zone(
    iad_np_lab05_vcn_02.vcn,
    "zone-b.local"
    )
zone_b_local.add_dns_record(
    type="A",
    name="server01",
    ttl=30,
    address="172.0.0.2"
    )

# Test Instance for Associated Zones (p.53)

cmds = list()
cmds.append("host server01.zone-a.local")
cmds.append("host -t NS zone-a.local")
cmds.append("host -t SOA zone-a.local")
cmds.append("host server01.zone-b.local")
iad_np_lab05_vm_01.run_ssh_commands(
    ssh_private_key="~/.ssh/id_rsa",
    cmds=cmds
    )
