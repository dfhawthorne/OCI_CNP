#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Validate Lab setup by pinging 
# ------------------------------------------------------------------------------

printf "\nPinging from VM01\n\n"

ssh -F .ssh/config VM01 <<DONE
printf "\nPinging VM02\n\n"
ping -c 10 -4 172.16.0.208
DONE

printf "\nPinging from VM02\n\n"

ssh -F .ssh/config VM02 <<DONE
printf "\nPinging VM01\n\n"
ping -c 10 -4 10.0.0.161
DONE
