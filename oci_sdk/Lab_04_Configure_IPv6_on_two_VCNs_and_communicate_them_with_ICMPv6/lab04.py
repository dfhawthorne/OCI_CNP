#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Lab 04:
# Networking - Virtual Cloud Network:
#   Configure IPv6 on two VCNs and communicate them with ICMPv6
# ------------------------------------------------------------------------------

import os
import paramiko
import sys

sys.path.append('../common')
import mylearn

# Create the first virtual cloud network

iad_np_lab04_vcn_01 = mylearn.vcn(
    "IAD-NP-LAB04-VCN-01",
    cidr_blocks=["10.1.0.0/16"],
    assign_ipv6_address=True
    )
iad_np_lab04_vcn_01.add_subnet(
    "IAD-NP-LAB04-01-SNT-01",
    ipv6_address="7e",
    public_access=True
    )
iad_np_lab04_vcn_01.add_ig(
    display_name="IAD-NP-LAB04-VCN-01-IG-01"
    )
iad_np_lab04_vcn_01.add_route_rule(
    iad_np_lab04_vcn_01.ig.id
    )

# Create the second virtual cloud network

iad_np_lab04_vcn_02 = mylearn.vcn(
    "IAD-NP-LAB04-VCN-02",
    cidr_blocks=["10.2.0.0/16"],
    assign_ipv6_address=True
    )
iad_np_lab04_vcn_02.add_subnet(
    "IAD-NP-LAB04-02-SNT-01",
    ipv6_address="7e",
    public_access=True
    )
iad_np_lab04_vcn_02.add_ig(
    display_name="IAD-NP-LAB04-VCN-02-IG-01"
    )
iad_np_lab04_vcn_02.add_route_rule(
    iad_np_lab04_vcn_02.ig.id
    )

# Create your first compute instance

public_ips = list()
iad_np_lab04_vm_01 = mylearn.compute(
    "IAD-NP-LAB04-VM-01",
    avail_domain="AD1",
    os="Oracle Linux",
    os_ver="8",
    shape="VM.Standard.A1.Flex",
    ocpus="1",
    memory_in_gb="6",
    subnet_id=iad_np_lab04_vcn_01.subnets[0].id,
    assign_ipv6_addr=True,
    ssh_keys="~/.ssh/id_rsa.pub"
)
public_ips.append(iad_np_lab04_vm_01.instance.public_ip)

# Create your second compute instance

iad_np_lab04_vm_02 = mylearn.compute(
    "IAD-NP-LAB04-VM-02",
    avail_domain="AD1",
    os="Oracle Linux",
    os_ver="8",
    shape="VM.Standard.A1.Flex",
    ocpus="1",
    memory_in_gb="6",
    subnet_id=iad_np_lab04_vcn_02.subnets[0].id,
    assign_ipv6_addr=True,
    ssh_keys="~/.ssh/id_rsa.pub"
)
public_ips.append(iad_np_lab04_vm_02.instance.public_ip)

# Enable IPv6 on the IAD-NP-LAB04-VM-01 compute instance, and on the route tables
# of both VMs

# Set up the SSH client
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

# Connect using the private key
private_key = paramiko.RSAKey.from_private_key_file(
    os.path.expanduser("~/.ssh/id_rsa")
    )
for public_ip in public_ips:
    ssh.connect(
        hostname=public_ip,
        username="opc",
        pkey=private_key
        )
    shell = ssh.invoke_shell()
    shell.send("sudo dhclient -6 enp0s6")
    output = ""
    while not shell.recv_ready():
        pass
    while shell.recv_ready():
        output += shell.recv(1024).decode()

    print(output)
    ssh.close()
