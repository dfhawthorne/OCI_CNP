# Lab 05: Design and Implement a Real-Network Architecture: Configuring private DNS Zones, views, resolvers, listeners and forwarders

## Overview

Customers want to specify their own private DNS domain names to manage their private assets in OCI, as well as support DNS resolution between VCNs and between VCNs and on-premises networks. With private DNS, customers can:

- Create private DNS zones with their desired names and create records for their private resources.
- Create a private DNS resolver for DNS resolution to and from other private networks.
- Resolve queries for custom private zones and system-generated zones, such as oraclevcn.com.
- See DNS views and implement conditional forwarding for split-horizon environments.

![Layout of two VCNs connected via local peering](Lab_05_Layout.png)

In this lab, you'll:

1. Create custom private zones.
1. Configure a VCN resolver
1. Configure the VCN resolver to add the other private view

