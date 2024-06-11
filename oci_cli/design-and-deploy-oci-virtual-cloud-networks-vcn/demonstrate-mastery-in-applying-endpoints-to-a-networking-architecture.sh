#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Create all network resources in the Sandbox Compartment:
# - VCN
# - Subnets
#   - private
#   - public
# - DRG
# - Internet Gateway
# - NAT Gateway
# - Service Gateway
# - compute instances
#   - private
#   - public
# -------------------------------------------------------------------------------

# Ensure that we have a valid OCI CLI session. Exit if invalid
oci session validate --local || exit 1

# ------------------------------------------------------------------------------
# Get the OCID of the Sandbox compartment. Exit if not found
# ------------------------------------------------------------------------------

sandbox_comp_id=$(                           \
                    oci iam compartment list \
                    --name Sandbox           \
                    --query 'data[0].id'     \
                    --raw-output             \
                )
if [[ -z "${sandbox_comp_id}" ]]
then
    printf 'Unable to find the Sandbox compartment. Exiting...\n' >&2
    exit 1
fi

# ------------------------------------------------------------------------------
# Get Sandbox VCN OCID. Create one (1) VCN in compartment, if not found
# ------------------------------------------------------------------------------

sandbox_vcn_id=$(                                       \
                oci network vcn list                    \
                    --query 'data[0].id'                \
                    --compartment-id ${sandbox_comp_id} \
                    --raw-output                        \
                )
if [[ -z "${sandbox_vcn_id}" ]]
then
    oci network vcn create                   \
        --compartment-id  ${sandbox_comp_id} \
        --cidr-blocks     '[10.0.0.0/16]'    \
        --display-name    'sandbox-vcn'      \
        --dns-label       'sandbox'          \
        --wait-for-state  AVAILABLE
    if [[ $? -ne 0 ]]
    then
        printf 'Unable to create VCN in Sandbox compartment. Exiting...\n' >&2
        exit 1
    fi
    sandbox_vcn_id=$(                                       \
                    oci network vcn list                    \
                        --query 'data[0].id'                \
                        --compartment-id ${sandbox_comp_id} \
                        --raw-output                        \
                    )
fi

# ------------------------------------------------------------------------------
# Find private subnet in the Sandbox compartment. Create it if not found
# ------------------------------------------------------------------------------

private_subnet_id=$(                                                \
                    oci network subnet list                         \
                        --compartment-id ${sandbox_comp_id}         \
                        --display-name "private subnet-sandbox-vcn" \
                        --query 'data[0].id'                        \
                        --raw-output                                \
                    )
if [[ -z "${private_subnet_id}" ]]
then
    oci network subnet create                               \
        --compartment-id    ${sandbox_comp_id}              \
        --display-name      "private subnet-sandbox-vcn"    \
        --vcn-id            ${sandbox_vcn_id}               \
        --cidr-block        '10.0.2.0/24'                   \
        --dns-label         'private'                       \
        --wait-for-state    AVAILABLE
    if [[ $? -ne 0 ]]
    then
        printf 'Unable to create private subnet in Sandbox compartment.' >&2
        printf ' Exiting...\n' >&2
        exit 1
    fi
    private_subnet_id=$(                                                \
                        oci network subnet list                         \
                            --compartment-id ${sandbox_comp_id}         \
                            --display-name "private subnet-sandbox-vcn" \
                            --query 'data[0].id'                        \
                            --raw-output                                \
                        )
fi

# ------------------------------------------------------------------------------
# Find public subnet in the Sandbox compartment. Create it if not found
# ------------------------------------------------------------------------------

private_subnet_id=$(                                                \
                    oci network subnet list                         \
                        --compartment-id ${sandbox_comp_id}         \
                        --display-name "public subnet-sandbox-vcn" \
                        --query 'data[0].id'                        \
                        --raw-output                                \
                    )
if [[ -z "${private_subnet_id}" ]]
then
    oci network subnet create                               \
        --compartment-id    ${sandbox_comp_id}              \
        --display-name      "public subnet-sandbox-vcn"    \
        --vcn-id            ${sandbox_vcn_id}               \
        --cidr-block        '10.0.2.0/24'                   \
        --dns-label         'public'                       \
        --wait-for-state    AVAILABLE
    if [[ $? -ne 0 ]]
    then
        printf 'Unable to create public subnet in Sandbox compartment.' >&2
        printf ' Exiting...\n' >&2
        exit 1
    fi
    private_subnet_id=$(                                                \
                        oci network subnet list                         \
                            --compartment-id ${sandbox_comp_id}         \
                            --display-name "public subnet-sandbox-vcn" \
                            --query 'data[0].id'                        \
                            --raw-output                                \
                        )
fi

# ------------------------------------------------------------------------------
#
# ------------------------------------------------------------------------------

