#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Get IPV6 addresses
# ------------------------------------------------------------------------------

oci_session.sh

vm_01_id=$(oci compute instance list --query 'data[0].id' --raw-output --lifecycle-state RUNNING)
vm_02_id=$(oci compute instance list --query 'data[1].id' --raw-output --lifecycle-state RUNNING)
vm_01_vnic_id=$(oci compute instance list-vnics --instance-id ${vm_01_id} --all --query 'data[0].id' --raw-output)
vm_02_vnic_id=$(oci compute instance list-vnics --instance-id ${vm_02_id} --all --query 'data[0].id' --raw-output)
vm_01_ipv6=$(oci network ipv6 list --vnic-id ${vm_01_vnic_id} --query 'data[0]."ip-address"' --raw-output)
vm_02_ipv6=$(oci network ipv6 list --vnic-id ${vm_02_vnic_id} --query 'data[0]."ip-address"' --raw-output)

printf 'ip v6 address for VM_01=%s\n' ${vm_01_ipv6}
printf 'ip v6 address for VM_02=%s\n' ${vm_02_ipv6}

