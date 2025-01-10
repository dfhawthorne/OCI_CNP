#!/usr/bin/env bash
# -----------------------------------------------------------------------------------------
# Saves the generated PEM key for SSH access
# -----------------------------------------------------------------------------------------

mkdir -p .ssh
chmod 700 .ssh
sed -nre '/^---/,/^---/p' <(terraform output private_key_pem) >.ssh/id_pem
chmod 600 .ssh/id_pem
