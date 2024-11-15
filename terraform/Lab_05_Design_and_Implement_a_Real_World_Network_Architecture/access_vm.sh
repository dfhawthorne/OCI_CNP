#!/usr/bin/env bash
# -------------------------------------------------------------------------
# Opens a SSH connection to the created VM
# -------------------------------------------------------------------------

ssh -i .ssh/id_pem opc@$(terraform output -raw public_ip) <<DONE
host server01.zone-a.local
host -t NS zone-a.local
host -t SOA zone-a.local
host server01.zone-b.local
exit
DONE
