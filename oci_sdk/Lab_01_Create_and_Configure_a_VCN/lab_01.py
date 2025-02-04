#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Lab 01:
# Networking - Virtual Cloud Network: Create and Configure a Virtual Cloud
# Network.
# ------------------------------------------------------------------------------

import sys
sys.path.append('../common')

import mylearn

vcn_01_name = 'IAD-NP-LAB01-VCN-01'
iad_np_lab01_vcn_01 = mylearn.vcn(
    display_name=vcn_01_name,
    region='us-ashburn-1'
    )
iad_np_lab01_vcn_01.add_ig()
iad_np_lab01_vcn_01.add_route_rule(
    iad_np_lab01_vcn_01.ig.id
)
iad_np_lab01_vcn_01.add_sg()
iad_np_lab01_vcn_01.add_natg()
iad_np_lab01_vcn_01.add_subnet(
    "public subnet-" + vcn_01_name,
    public_access=True,
    dns_label='public'
    )
iad_np_lab01_vcn_01.add_subnet(
    "private subnet-" + vcn_01_name,
    public_access=False,
    dns_label='private'
    )
if iad_np_lab01_vcn_01.subnets[1].route_table_id == iad_np_lab01_vcn_01.vcn.default_route_table_id:
    route_rules=[]
    route_rules.append(
        mylearn.new_route_rule(
            iad_np_lab01_vcn_01.natg.id,
            cidr_block="0.0.0.0/0"
            )
        )
    route_rules.append(iad_np_lab01_vcn_01.new_service_route_rule())
    iad_np_lab01_vcn_01.new_route_table(
        1,
        display_name=f"route table for private subnet-{vcn_01_name}",
        route_rules=route_rules
        )

print(iad_np_lab01_vcn_01)
