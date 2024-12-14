# Lab 07: Remote Peering: InterConnect OCI resources between regions and extend to on-premises

## Overview

> A Dynamic Routing Gateway (DRG) is an OCI virtual router. It provides a path for traffic between on-premises networks and Virtaul Cloud Networks via Site-to-site VPN, or via FastConnect. DRGs are also used for routing traffic between VCNs that are located within the same region, remote regions, and/or in other OCI accounts (tenancies). Using different types of attachmennts, custom network topologies can be constructed using components in different regions and tenancies. Each DRG attachment has an associated route table which is used to route packets entering the DRG to their next hop.
>
> A DRG can have multiple network atatchments of each of the following types:
>
> - __VCN attachments__: you can attach mutiple VCNs to a single DRG. Each VCN can be in the same or different tenancies as the DRG.
> - __RPC attachments__: you can peer a DRG to other DRGs (including DRGs in other regions) using remote peering connections.
> - __IPSEC_TUNNEL attachments__: you can use Site-to-site VPN to attach two or more IPSec tunnels to your DRG to connect to on-premises networks. This is also allowed across tenancies.
> - __VIRTUAL_CIRCUIT attachments__: you can attach one or more FastConnect virtual circuits to your DRG to connect to on-premises networks.
>
> In the following practices, you will configure the dynamic routing gateway created in Lab One in the Phoenix region to connect to resources in a third region, UK South (london), via OCI's remote peering connection. Once this is successfully configured, the DRG in Phoenix will be configured to route traffic from on-premises to London, extending the existing on-premises to OCI site-to-site VPN reach.
>
> ![Network layout for Lab 07. Ashburn, Phoenix, and London regions are used.](Lab_07.png)
>
> In this lab, you'll:
>
> 1. Create the required remote peering resources in the UK South region.
> 1. Configure a dynamic routing gateway for remote peering.
> 1. Route from on-premises to the remote region.

## Implementation Notes

This lab extends [Lab 06: Site-to-Site Virtual Private Network: Connect OCI resources to on-premises via site-to-site VPN, using LibreSwan as the customer premises equipment](https://github.com/dfhawthorne/OCI_CNP/tree/main/terraform/Lab_06_Site_to_Site_Virtual_Private_Network). I have created soft links to the Terraform scripts in that lab.

The exception is `phoenix_vcn.tf` is updated with Remote Peering Connection to London, along with an expanded security list and route table.

## Implementation

Run the following commands to set up the lab:

```bash
terraform init
terraform apply -auto-approve
./setup_ssh.sh
./prepare_ipsec_files.sh
./configure_libreswan.sh
```

## Validation

To validate the lab set-up, run the following command:

```bash
./validate_setup.sh     
```

Sample output is:

```text
Pseudo-terminal will not be allocated because stdin is not a terminal.
Activate the web console with: systemctl enable --now cockpit.socket

PING 192.168.20.193 (192.168.20.193) 56(84) bytes of data.
64 bytes from 192.168.20.193: icmp_seq=1 ttl=61 time=57.4 ms
64 bytes from 192.168.20.193: icmp_seq=2 ttl=61 time=57.2 ms
64 bytes from 192.168.20.193: icmp_seq=3 ttl=61 time=57.3 ms
64 bytes from 192.168.20.193: icmp_seq=4 ttl=61 time=57.2 ms
64 bytes from 192.168.20.193: icmp_seq=5 ttl=61 time=57.2 ms
64 bytes from 192.168.20.193: icmp_seq=6 ttl=61 time=57.3 ms
64 bytes from 192.168.20.193: icmp_seq=7 ttl=61 time=57.4 ms
64 bytes from 192.168.20.193: icmp_seq=8 ttl=61 time=57.2 ms
64 bytes from 192.168.20.193: icmp_seq=9 ttl=61 time=57.3 ms
64 bytes from 192.168.20.193: icmp_seq=10 ttl=61 time=57.4 ms

--- 192.168.20.193 ping statistics ---
10 packets transmitted, 10 received, 0% packet loss, time 9012ms
rtt min/avg/max/mdev = 57.150/57.274/57.380/0.077 ms
PING 172.17.0.96 (172.17.0.96) 56(84) bytes of data.
64 bytes from 172.17.0.96: icmp_seq=1 ttl=62 time=127 ms
64 bytes from 172.17.0.96: icmp_seq=2 ttl=62 time=127 ms
64 bytes from 172.17.0.96: icmp_seq=3 ttl=62 time=127 ms
64 bytes from 172.17.0.96: icmp_seq=4 ttl=62 time=127 ms
64 bytes from 172.17.0.96: icmp_seq=5 ttl=62 time=127 ms
64 bytes from 172.17.0.96: icmp_seq=6 ttl=62 time=127 ms
64 bytes from 172.17.0.96: icmp_seq=7 ttl=62 time=127 ms
64 bytes from 172.17.0.96: icmp_seq=8 ttl=62 time=127 ms
64 bytes from 172.17.0.96: icmp_seq=9 ttl=62 time=127 ms
64 bytes from 172.17.0.96: icmp_seq=10 ttl=62 time=127 ms

--- 172.17.0.96 ping statistics ---
10 packets transmitted, 10 received, 0% packet loss, time 9012ms
rtt min/avg/max/mdev = 127.187/127.282/127.398/0.425 ms
Pseudo-terminal will not be allocated because stdin is not a terminal.
Activate the web console with: systemctl enable --now cockpit.socket

PING 172.31.0.108 (172.31.0.108) 56(84) bytes of data.
64 bytes from 172.31.0.108: icmp_seq=1 ttl=62 time=126 ms
64 bytes from 172.31.0.108: icmp_seq=2 ttl=62 time=126 ms
64 bytes from 172.31.0.108: icmp_seq=3 ttl=62 time=126 ms
64 bytes from 172.31.0.108: icmp_seq=4 ttl=62 time=126 ms
64 bytes from 172.31.0.108: icmp_seq=5 ttl=62 time=126 ms
64 bytes from 172.31.0.108: icmp_seq=6 ttl=62 time=126 ms
64 bytes from 172.31.0.108: icmp_seq=7 ttl=62 time=126 ms
64 bytes from 172.31.0.108: icmp_seq=8 ttl=62 time=126 ms
64 bytes from 172.31.0.108: icmp_seq=9 ttl=62 time=126 ms
64 bytes from 172.31.0.108: icmp_seq=10 ttl=62 time=126 ms

--- 172.31.0.108 ping statistics ---
10 packets transmitted, 10 received, 0% packet loss, time 9011ms
rtt min/avg/max/mdev = 125.961/126.032/126.139/0.229 ms
```
