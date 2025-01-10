#!/usr/bin/env bash
# -----------------------------------------------------------------------------------------
# Saves the generated PEM key for SSH access and creates the SSH configuration
# file. -----------------------------------------------------------------------------------------

mkdir -p .ssh
chmod 700 .ssh
sed -nre '/^---/,/^---/p' <(terraform output private_key_pem) >.ssh/id_pem
chmod 600 .ssh/id_pem
cat >.ssh/config <<DONE
Host *
    IdentityFile .ssh/id_pem
    StrictHostKeyChecking=accept-new
    User opc
    UserKnownHostsFile .ssh/known_hosts
Host VM01
    Hostname $(terraform output -raw public_ip)
DONE

