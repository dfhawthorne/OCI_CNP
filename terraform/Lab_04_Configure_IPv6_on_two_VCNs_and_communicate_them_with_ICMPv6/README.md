# Lab 04: Virtual Cloud Network (VCN): Configure IPv6 on two VCNs and communicate them with ICMPv6

## Overview

In this lab, you will interconnect two VCNs in the same region. The Dynamic Routing Gateway (DRG) will be used as an attachment to both VCNs.

The objective is to privately communicate two compute instances, one in each VCN, with each other via the DRG with IPv6. Ping6 will be used for testing the success of the lab.

For this, the VCNs, subnets, and compute instances' VNICs need to be enabled for IPv6 addressing. For the VMs the VM.Standard.A1.Flex shape will be used.

The compute instances' internal OS firewall needs to be configured for IPv6. After enabling IPv6 on all OCI components that require it, you will SSH to both VMs and run the following command:

![Layout for lab showing two VCNs with a single instance in each. The command to enable DHCP for IPv6 on the VNIC is shown as 'sudo dhclient -6 enp0s6'.](Lab_04_layout.png)

## Set up environment: Create VCNs and instances

You will first build two VCNs in the same region and in the same compartment, with a public subnet in each VCN, with access to the internet. It also requires two compute instances, one in each subnet:

- VCN1:
  - Names: __IAD-NP-LAB04-VCN-01__
  - CIDR Block: __10.1.0.0/16__
  - Public subnet
  - CIDR Block: __10.1.0.0/24__
- VCN2:
  - Names: __IAD-NP-LAB04-VCN-02__
  - CIDR Block: __10.2.0.0/16__
  - Public subnet
  - CIDR Block: __10.2.0.0/24__
- Two Compute Instances:
  - Name: __IAD-NP-LAB04-VM-01__, __IAD-NP-LAB04-VM-02__
  - Image: Oracle Linux 8
  - Shape: __VM.Standard.A1.Flex__ with 1 OCPU and 6 GB

You'll set these up, then proceed with the lab.
