# Lab 02: Networking - Virtual Cloud Network: Configure Local VCN Peering

## Overview

In this practice, you will configure Local Peering Gateways (LPGs) to interconnect two Virtual Cloud Networks (VCNs).

### Local VCN Peering

Local VCN peering is the process of connecting two VCNs in the same region so that their resources can communicate using private IP addresses.

### Local Peering Gateway

A Local Peering Gateway is a component of a VCN for routing traffic to a locally peered VCN.

### Summary of Networking Components for Peering using an LPG:

The Networking service components required for a local peering include:

- Two VCNs with _non-overlapping_ CIDRs, in the same region.
- A local peering gateway (LPG) on each VCN in the peering relationship.
- A connection between those two LPGs.
- Supporting route rules to enable traffic to flow over the connection.
- Supporting security rules to control the types of traffic allowed to and from the instances in the subnets that need to communicate with the other VCN.

In this lab, you will:

1. Create Virtual Cloud Network 01.
1. Create Virtual Cloud Network 02.
1. Add a Local Peering Gateway (LPG) to each VCN.
1. Connect the VCNs.
1. Add Route Rules.
1. Add Security Rules.

