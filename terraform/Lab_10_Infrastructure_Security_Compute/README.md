# Lab 10: Infrastructure Security - Compute: Set Up a Bastion Host

## Overview

> Oracle Cloud Infrastructure (OCI) Bastion restricts and limits access to target resources that do not have public endpoints. Bastions enable authorised users to connect to target resources via Secure Shell (SSH) sessions from certain IP addresses. Targets can include resources auch as compute instances, DB systems, and Autonomous Database for Transaction Processing and Mixed Workloads databases. Bastions provide an extra layer of security through the configuration of CIDR block allowlists specify what IP addresses or IP address ranges can connect to a session hosted by the bastion.
>
> In this lab, you'll:
>
> 1. Create and configure a Virtual Cloud Network
> 1. Enable Bastion plug-in on a compute instance
> 1. Create a Bastion
> 1. Create a Bastion session
> 1. Connect to a compute instance using a managed SSH session
>
> ![Lab layout](Lab_10.png)

## Implementation

Run the following commands to connect to the VM via the Bastion:

```bash
terraform init
terraform apply -auto-approve
bastion_id=$(terraform output -raw bastion_id)
private_ip=$(terraform output -raw private_ip)
vm_id=$(terraform output -raw vm_id)
session_id=$(                                       \
    oci bastion session create-managed-ssh          \
        --bastion-id ${bastion_id}                  \
        --key-type PUB                              \
        --ssh-public-key-file ~/.ssh/id_rsa.pub     \
        --target-os-username opc                    \
        --target-private-ip ${private_ip}           \
        --target-resource-id ${vm_id}               \
        --wait-for-state SUCCEEDED                  \
        --wait-for-state FAILED                     \
        --raw-output                                \
        --query 'data.resources[0].identifier'      \
    )
eval $(                                             \
    oci bastion session get                         \
    --session-id ${session_id}                      \
    --query 'data."ssh-metadata".command'           \
    --raw-output |                                  \
    sed -e 's!<privateKey>!~/.ssh/id_rsa!g'         \
    )
```

Sample output is:

```text
The authenticity of host 'host.bastion.us-ashburn-1.oci.oraclecloud.com (147.154.11.76)' can't be established.
ED25519 key fingerprint is SHA256:xpIfHc+0Ry+rBHhqm34bz9PWzN5uIOoWT2V2Rm4g5o4.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'host.bastion.us-ashburn-1.oci.oraclecloud.com' (ED25519) to the list of known hosts.
The authenticity of host '10.0.1.110 (<no hostip for proxy command>)' can't be established.
ED25519 key fingerprint is SHA256:FsqE9EgICWnX30Mv9Bze2tyiU4SsIHqL3a+mbtdcVg8.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.0.1.110' (ED25519) to the list of known hosts.
Activate the web console with: systemctl enable --now cockpit.socket

[opc@instance20241129121320 ~]$
```

## Testing

Run the following command to confirm the correct IP address:

```bash
ifconfig
```

The expected output is:

```text
enp0s6: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
        inet 10.0.1.110  netmask 255.255.255.0  broadcast 10.0.1.255
        inet6 fe80::17ff:fe11:1a84  prefixlen 64  scopeid 0x20<link>
        ether 02:00:17:11:1a:84  txqueuelen 1000  (Ethernet)
        RX packets 38187  bytes 845414922 (806.2 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 23440  bytes 5614008 (5.3 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 72  bytes 5840 (5.7 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 72  bytes 5840 (5.7 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```