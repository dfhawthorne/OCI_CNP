#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Validate Lab setup by testing DNS entries
# ------------------------------------------------------------------------------

printf "\nTesting from VM01\n\n"

ssh -F .ssh/config VM01 <<DONE
host server01.zone-a.local
host -t NS zone-a.local
host -t SOA zone-a.local
host server01.zone-b.local
DONE

exit 0
