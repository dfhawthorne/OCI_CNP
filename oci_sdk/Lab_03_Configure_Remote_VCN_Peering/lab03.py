#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Lab 03:
# Networking - Virtual Cloud Network:
#   Configure Remote VCN Peering
# ------------------------------------------------------------------------------

import sys

sys.path.append('../common')
import mylearn

# Create Virtual Cloud Network 01
iad_np_lab03_vcn_01 = mylearn.vcn_wizard(
    "IAD-NP-LAB03-VCN-01",
    cidr_blocks=["172.17.0.0/16"],
    region="us-ashburn-1"
    )
# Create Virtual Cloud Network 02
lhr_np_lab03_vcn_01 = mylearn.vcn_wizard(
    "IAD-NP-LAB03-VCN-01",
    cidr_blocks=["10.0.0.0/16"],
    region="uk-london-1"
    )
# Create a Dynamic Routing Gateway in Each OCI Region
iad_np_lab03_drg_01 = mylearn.drg(
    "IAD-NP-LAB03-DRG-01",
    region="us-ashburn-1"
    )
iad_np_lab03_drg_01.attach(iad_np_lab03_vcn_01.vcn)
lhr_np_lab03_drg_01 = mylearn.drg(
    "LHR-NP-LAB03-DRG-01",
    region="uk-london-1"
    )
lhr_np_lab03_drg_01.attach(lhr_np_lab03_vcn_01.vcn)
# Create Remote Peering Connection Attachments and Establish the Connection
# Between the Two DRGs
iad_np_lab03_drg_01.add_rpc("IAD-NP-LAB03-RPC-01")
lhr_np_lab03_drg_01.add_rpc("LHR-NP-LAB03-RPC-01")
iad_np_lab03_drg_01.connect(
    "IAD-NP-LAB03-RPC-01",
    lhr_np_lab03_drg_01.get_rpc_id("LHR-NP-LAB03-RPC-01"),
    "uk-london-1"
    )
# Add Route Rules
iad_np_lab03_vcn_01.add_route_rule(
    iad_np_lab03_drg_01.drg.id,
    destination="10.0.0.0/24"
    )
lhr_np_lab03_vcn_01.add_route_rule(
    lhr_np_lab03_drg_01.drg.id,
    destination="172.17.0.0/24"
    )
# Add Security Rules
lhr_np_lab03_vcn_01.add_ingress_rule(
    protocol="ICMP",
    type=8,
    source="172.17.0.0/24"
    )
iad_np_lab03_vcn_01.add_ingress_rule(
    protocol="ICMP",
    type=8,
    source="10.10.0.0/24"
    )
