#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# 
# ------------------------------------------------------------------------------

# Save Private Keys

mkdir -p .ssh
chmod 700 .ssh

# Create SSH configuration file

vm_01_ipv4_addr=$(terraform output -raw vm_01_public_ipv4_addr) || exit 1
vm_02_ipv4_addr=$(terraform output -raw vm_02_public_ipv4_addr) || exit 1

cat >.ssh/config <<DONE
Host *
    IdentityFile ${HOME}/.ssh/id_rsa
    StrictHostKeyChecking=accept-new
    User opc
    UserKnownHostsFile ${PWD}/.ssh/known_hosts
Host VM01
    Hostname ${vm_01_ipv4_addr}
Host VM02
    Hostname ${vm_02_ipv4_addr}
DONE
