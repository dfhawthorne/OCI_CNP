# Lab 03: Networking - Virtual Cloud Network: Configure Remote VCN Peering

## Overview

In this lab, you will use Dynamic Routing Gateways (DRGs) to inter-connect two Virtual Cloud Networks (VCNs) in different OCI regions.

For this lab, the tenancy needs to be subscribed to the US East (Ashburn) and UK South (London) regions.

### Remote VCN Peering

Remote VCN is the process of connecting two VCNs, typically but not required to be in different regions. Peering allows VCNs' resources to communicate using private IP addresses.

### Dynamic Routing Gateway

A Dynamic Routing Gateway is a powerful virtual router that enables VCN connectivity to on-premises resources and to remote and local VCNs in the current tenancy and in other tenancies.

### Summary of Networking Components for Remote Peering:

The Networking service components required for a remote peering include:

- DRG attachment to each VCN in the peering relationship.
- A remote peering connection (RPC) on each DRG in the peering relationship.
- A connection between those two RPCs.
- Supporting route rules to enable traffic to flow over the connection.
- Supporting security rules to control the types of traffic allowed to and from the instances in the subnets that need to communciate with the other VCN.

In this lab, you will:

1. Create Virtual Cloud Network 01.
1. Create Virtual Cloud Network 02.
1. Create a Dynamic Routing Gateway in each OCI region.
1. Create Remote Peering Connection attachments and establish the connection between the two DRGs.
1. Add Route Rules.
1. Add Security Rules.
