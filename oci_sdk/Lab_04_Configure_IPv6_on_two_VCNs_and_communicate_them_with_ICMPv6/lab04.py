#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Lab 04:
# Networking - Virtual Cloud Network:
#   Configure IPv6 on two VCNs and communicate them with ICMPv6
# ------------------------------------------------------------------------------

import os
import paramiko
import sys
import time

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

ashburn_ad = mylearn.availability_domain()

iad_np_lab04_vm_01 = mylearn.compute(
    "IAD-NP-LAB04-VM-01",
    avail_domain=ashburn_ad.availability_domains[0].name,
    os="Oracle Linux",
    os_ver="8",
    shape="VM.Standard.A1.Flex",
    ocpus="1",
    memory_in_gb="6",
    subnet=iad_np_lab04_vcn_01.subnets[0],
    ssh_keys="~/.ssh/id_rsa.pub"
)
vm01_public_ipv4  = iad_np_lab04_vm_01.vnics[0].public_ip
vm01_private_ipv4 = iad_np_lab04_vm_01.vnics[0].private_ip
vm01_public_ipv6  = iad_np_lab04_vm_01.vnics[0].ipv6_addresses[0]

# Create your second compute instance

iad_np_lab04_vm_02 = mylearn.compute(
    "IAD-NP-LAB04-VM-02",
    avail_domain=ashburn_ad.availability_domains[0].name,
    os="Oracle Linux",
    os_ver="8",
    shape="VM.Standard.A1.Flex",
    ocpus="1",
    memory_in_gb="6",
    subnet=iad_np_lab04_vcn_02.subnets[0],
    ssh_keys="~/.ssh/id_rsa.pub"
)
vm02_public_ipv4  = iad_np_lab04_vm_02.vnics[0].public_ip
vm02_private_ipv4 = iad_np_lab04_vm_02.vnics[0].private_ip
vm02_public_ipv6  = iad_np_lab04_vm_02.vnics[0].ipv6_addresses[0]

# Enable IPv6 on the IAD-NP-LAB04-VM-01 compute instance, and on the route
# tables of both VMs

def enable_ipv6(local_ipv4):

    ssh_client = paramiko.SSHClient()
    ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    # Connect using the private key
    private_key = paramiko.RSAKey.from_private_key_file(
        os.path.expanduser("~/.ssh/id_rsa")
        )

    ssh_client.connect(
        hostname=local_ipv4,
        username="opc",
        pkey=private_key
        )

    command = "sudo dhclient -6 enp0s6"
    stdin, stdout, stderr = ssh_client.exec_command(command)
        
    # Wait for the command to complete
    while not stdout.channel.exit_status_ready():
        time.sleep(0.1)
    
    # Read the output
    stdout_output = stdout.read().decode('utf-8')
    stderr_output = stderr.read().decode('utf-8')
    
    # Print the results
    print("\nStandard Output:")
    print(stdout_output)
    
    print("\nStandard Error:")
    print(stderr_output)
    
    # Get the exit status
    exit_status = stdout.channel.recv_exit_status()

    ssh_client.close()

enable_ipv6(vm01_public_ipv4)
enable_ipv6(vm02_public_ipv4)

# Create a dynamic routing gateway and attach the VCNs

iad_np_lab04_drg_01 = mylearn.drg("IAD-NP-LAB04-DRG-01")
iad_np_lab04_vcn_01.add_route_rule(
    iad_np_lab04_drg_01.drg.id,
    destination=iad_np_lab04_vcn_02.vcn.cidr_blocks[0]
    )
iad_np_lab04_vcn_01.add_route_rule(
    iad_np_lab04_drg_01.drg.id,
    destination=iad_np_lab04_vcn_02.vcn.ipv6_cidr_blocks[0]
    )
iad_np_lab04_vcn_01.add_ingress_rule(
    protocol="ICMP",
    type=8,
    source=iad_np_lab04_vcn_02.vcn.cidr_blocks[0]
    )
iad_np_lab04_vcn_01.add_ingress_rule(
    protocol="ICMPv6",
    source=iad_np_lab04_vcn_02.vcn.ipv6_cidr_blocks[0]
    )
iad_np_lab04_vcn_02.add_route_rule(
    iad_np_lab04_drg_01.drg.id,
    destination=iad_np_lab04_vcn_01.vcn.cidr_blocks[0]
    )
iad_np_lab04_vcn_02.add_route_rule(
    iad_np_lab04_drg_01.drg.id,
    destination=iad_np_lab04_vcn_01.vcn.ipv6_cidr_blocks[0]
    )
iad_np_lab04_vcn_02.add_ingress_rule(
    protocol="ICMP",
    type=8,
    source=iad_np_lab04_vcn_01.vcn.cidr_blocks[0]
    )
iad_np_lab04_vcn_02.add_ingress_rule(
    protocol="ICMPv6",
    source=iad_np_lab04_vcn_01.vcn.ipv6_cidr_blocks[0]
    )
iad_np_lab04_drg_01.attach(
    iad_np_lab04_vcn_01.vcn,
    display_name="IAD-NP-LAB04-VCN-01-ATCH"
    )
iad_np_lab04_drg_01.attach(
    iad_np_lab04_vcn_02.vcn,
    display_name="IAD-NP-LAB04-VCN-02-ATCH"
    )
iad_np_lab04_drg_01.get_all_route_rules()

print(iad_np_lab04_vcn_01)
print(iad_np_lab04_vcn_02)

def test_ping(local_ipv4, remote_ipv4, remote_ipv6):

    ssh_client = paramiko.SSHClient()
    ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    # Connect using the private key
    private_key = paramiko.RSAKey.from_private_key_file(
        os.path.expanduser("~/.ssh/id_rsa")
        )

    ssh_client.connect(
        hostname=local_ipv4,
        username="opc",
        pkey=private_key
        )

    cmds = list()
    cmds.append(f"ping -4 -c 10 {remote_ipv4}")
    cmds.append(f"ping -6 -c 10 {remote_ipv6}")
    for command in cmds:
        stdin, stdout, stderr = ssh_client.exec_command(command)
            
        # Wait for the command to complete
        while not stdout.channel.exit_status_ready():
            time.sleep(0.1)
        
        # Read the output
        stdout_output = stdout.read().decode('utf-8')
        stderr_output = stderr.read().decode('utf-8')
        
        # Print the results
        print("\nStandard Output:")
        print(stdout_output)
        
        print("\nStandard Error:")
        print(stderr_output)
        
        # Get the exit status
        exit_status = stdout.channel.recv_exit_status()

    ssh_client.close()

test_ping(vm01_public_ipv4, vm02_private_ipv4, vm02_public_ipv6)
test_ping(vm02_public_ipv4, vm01_private_ipv4, vm01_public_ipv6)
