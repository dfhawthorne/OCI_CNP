#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Lab 02:
# Networking - Virtual Cloud Network:
#   Configure Local VCN Peering
# ------------------------------------------------------------------------------

import sys

sys.path.append('../common')
import mylearn

iad_np_lab02_vcn_01 = mylearn.vcn_wizard(
    display_name="IAD-NP-LAB02-VCN-01",
    cidr_blocks=["172.16.0.0/16"],
    region="us-ashburn-1"
    )
iad_np_lab02_vcn_01.add_lpg(display_name="IAD-NP-LAB02-LPG-01")
iad_np_lab02_vcn_02 = mylearn.vcn_wizard(
    display_name="IAD-NP-LAB02-VCN-02",
    cidr_blocks=["192.168.0.0/16"],
    region="us-ashburn-1"
    )
iad_np_lab02_vcn_02.add_lpg(display_name="IAD-NP-LAB02-LPG-02")
iad_np_lab02_vcn_02.connect_lpgs(iad_np_lab02_vcn_01.lpg.id)
iad_np_lab02_vcn_01.add_route_rule(
    iad_np_lab02_vcn_01.lpg.id,
    destination="192.168.0.0/24"
    )
iad_np_lab02_vcn_02.add_route_rule(
    iad_np_lab02_vcn_02.lpg.id,
    destination="172.16.0.0/24"
    )
iad_np_lab02_vcn_01.add_ingress_rule(
    protocol="ICMP",
    source="192.168.0.0/24",
    type=8
    )
iad_np_lab02_vcn_02.add_ingress_rule(
    protocol="ICMP",
    source="172.16.0.0/24",
    type=8
    )

