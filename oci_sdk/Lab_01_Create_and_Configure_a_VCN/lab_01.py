#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Lab 01:
# Networking - Virtual Cloud Network: Create and Configure a Virtual Cloud
# Network.
# ------------------------------------------------------------------------------

import sys
sys.path.append('../common')

import mylearn

iad_np_lab01_vcn_01 = mylearn.vcn(
    display_name='IAD-NP-LAB01-VCN-01',
    region='us-ashburn-1'
    )
iad_np_lab01_vcn_01.add_ig()
iad_np_lab01_vcn_01.add_route_rule(
    iad_np_lab01_vcn_01.ig.id
)
iad_np_lab01_vcn_01.add_sg()
iad_np_lab01_vcn_01.add_natg()

print(iad_np_lab01_vcn_01)
