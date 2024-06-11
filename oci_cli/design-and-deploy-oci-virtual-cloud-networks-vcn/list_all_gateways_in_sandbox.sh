#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# List all gateways in the Sandbox compartment
# ------------------------------------------------------------------------------

oci session validate --local || exit 1

sandbox_comp_id=$(oci iam compartment list --name Sandbox --query 'data[0].id' --raw-output)

oci network drg list --compartment-id ${sandbox_comp_id}
oci network internet-gateway list --compartment-id ${sandbox_comp_id}
oci network local-peering-gateway list --compartment-id ${sandbox_comp_id}
oci network nat-gateway list --compartment-id ${sandbox_comp_id}
oci network service-gateway list --compartment-id ${sandbox_comp_id}

