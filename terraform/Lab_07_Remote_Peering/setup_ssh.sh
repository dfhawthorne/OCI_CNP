#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# 
# ------------------------------------------------------------------------------

# Save Private Keys

mkdir -p .ssh
chmod 700 .ssh
sed -nre '/^---/,/^---/p' \
    <(terraform output -raw private_key_pem) \
    >.ssh/id_pem || exit 1
chmod 600 .ssh/id_pem
sed -nre '/^---/,/^---/p' \
    <(terraform output -raw lhr_private_key_pem) \
    >.ssh/lhr_id_pem || exit 1
chmod 600 .ssh/lhr_id_pem

# Create SSH configuration file

cpe_public_ip=$(terraform output -raw cpe_public_ip) || exit 1
lhr_vm_public_ip=$(terraform output -raw lhr_vm_01_public_ip) || exit 1
phx_vm_public_ip=$(terraform output -raw phx_vm_01_public_ip) || exit 1

cat >.ssh/config <<DONE
Host CPE
    Hostname ${cpe_public_ip}
    IdentityFile ${PWD}/.ssh/id_pem
    StrictHostKeyChecking=accept-new
    User opc
    UserKnownHostsFile ${PWD}/.ssh/known_hosts
Host PHX
    Hostname ${phx_vm_public_ip}
    IdentityFile ${PWD}/.ssh/id_pem
    StrictHostKeyChecking=accept-new
    User opc
    UserKnownHostsFile ${PWD}/.ssh/known_hosts
Host LHR
    Hostname ${lhr_vm_public_ip}
    IdentityFile ${PWD}/.ssh/lhr_id_pem
    StrictHostKeyChecking=accept-new
    User opc
    UserKnownHostsFile ${PWD}/.ssh/known_hosts
DONE
