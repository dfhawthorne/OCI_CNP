# Lab 06: Site-to-Site Virtual Private Network: Connect OCI resources to on-premises via site-to-site VPN, using LibreSwan as the customer premises equipment

## Overview

> In this lab, you will connect OCI resources to an on-premises network. OCI will be leveraging the Phoenix region. __The on-premises network will be simulated by a VCN in the Ashburn region.__ In this region you will launch a VCN and an OCI VM compute instance that will be used as the customer premises equipment (CPE). The LibreSwan specialised software will be downloaded, installed, and configured in the compute instance. ICMP will be used for testing the success of the lab.
>
> Site-to-site VPN provides a site-to-site IPSec connection between your on-premises network and your virtual cloud network (VCN). The IPSec protocol suite encrypts IP traffic before the packets are transferred from the source to the destination, and then it decrypts the traffic when it arrives. Site-to-site VPN was previously referred to as VPN Connect and IPSec VPN.
>
> The following routing types are available, and you choose the routing type separately for each IPSec tunnel in site-to-site VPN:
>
> - BGP (Border Gateway Protocol) dynamic routing: The available routes are learned dynamically through BGP. The DRG dynamically learns the routes from your on-premises network. On the Oracle side, the DRG advertises the VCN's subnets.
> - Static routing: When you set up ther IPSec connection to the DRG, you specify the particular routes to your on-premises network that you want the VCN to know about. You also must configure your CPE device with static routes to the VCN's subnets. These routes are not learned dynamically. This lab will use static routing.
> - Policy-based routing: When you set up the IPSec connection to the DRG, you specify the particular routes to your on-premises network that you want the VCN to know about. You also must configure your CPE device with static routes to the VCN's subnets. These route are not learned dynamically.
>
> In this lab, you'll:
>
> 1. Launch an on-premises network and CPE VM in the Ashburn region.
> 1. Create site-to-site VPN resources in the Phoenix region.
> 1. Prepare IPSec configuration files.
> 1. Configure LibreSwan on the on-premises VM.
> 1. Test the connection

## Implementation

Run the following commands to set up the lab environment:

```bash
terraform init
terraform apply -auto-approve
./prepare_ipsec_files.sh
./configure_libreswan.sh
```

## Validation of Lab Environment

Run the following command to validate the lab environment:

```bash
./validate_setup.sh 
```

Sample output is:

```text
Pseudo-terminal will not be allocated because stdin is not a terminal.
Warning: Permanently added '141.148.166.83' (ED25519) to the list of known hosts.
Activate the web console with: systemctl enable --now cockpit.socket

PING 192.168.20.190 (192.168.20.190) 56(84) bytes of data.
64 bytes from 192.168.20.190: icmp_seq=1 ttl=61 time=57.5 ms
64 bytes from 192.168.20.190: icmp_seq=2 ttl=61 time=57.4 ms
64 bytes from 192.168.20.190: icmp_seq=3 ttl=61 time=57.4 ms
64 bytes from 192.168.20.190: icmp_seq=4 ttl=61 time=57.3 ms
64 bytes from 192.168.20.190: icmp_seq=5 ttl=61 time=57.3 ms
64 bytes from 192.168.20.190: icmp_seq=6 ttl=61 time=57.5 ms
64 bytes from 192.168.20.190: icmp_seq=7 ttl=61 time=57.3 ms
64 bytes from 192.168.20.190: icmp_seq=8 ttl=61 time=57.3 ms
64 bytes from 192.168.20.190: icmp_seq=9 ttl=61 time=57.3 ms
64 bytes from 192.168.20.190: icmp_seq=10 ttl=61 time=57.4 ms

--- 192.168.20.190 ping statistics ---
10 packets transmitted, 10 received, 0% packet loss, time 9013ms
rtt min/avg/max/mdev = 57.255/57.374/57.524/0.314 ms
```
