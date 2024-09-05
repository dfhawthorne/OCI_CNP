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

sandbox_comp_id=$(                                  \
                    oci iam compartment list        \
                    --name          Sandbox         \
                    --query         'data[0].id'    \
                    --raw-output                    \
                )
if [[ -z "${sandbox_comp_id}" ]]
then
    printf 'Unable to find the Sandbox compartment. Exiting...\n' >&2
    exit 1
fi

# ------------------------------------------------------------------------------
# Get Sandbox VCN OCID. Create one (1) VCN in compartment, if not found
# ------------------------------------------------------------------------------

sandbox_vcn_id=$(                               \
    oci network vcn list                        \
        --compartment-id    ${sandbox_comp_id}  \
        --query             'data[0].id'        \
        --raw-output                            \
    )
if [[ -z "${sandbox_vcn_id}" ]]
then
    sandbox_vcn_id=$(                               \
        oci network vcn create                      \
            --compartment-id    ${sandbox_comp_id}  \
            --cidr-blocks       '[10.0.0.0/16]'     \
            --display-name      'sandbox-vcn'       \
            --dns-label         'sandbox'           \
            --wait-for-state    AVAILABLE           \
            --query             'data.id'           \
            --raw-output                            \
        )
    if [[ $? -ne 0 ]]
    then
        printf 'Unable to create VCN in Sandbox compartment. Exiting...\n' >&2
        exit 1
    fi
fi

# ------------------------------------------------------------------------------
# Find private subnet in the Sandbox compartment. Create it if not found
# ------------------------------------------------------------------------------

private_subnet_name="private subnet-sandbox-vcn"
private_subnet_id=$(                                \
    oci network subnet list                         \
        --compartment-id ${sandbox_comp_id}         \
        --display-name "${private_subnet_name}"     \
        --query 'data[0].id'                        \
        --raw-output                                \
    )
if [[ -z "${private_subnet_id}" ]]
then
    private_subnet_id=$(                                    \
        oci network subnet create                           \
            --compartment-id    ${sandbox_comp_id}          \
            --display-name      "${private_subnet_name}"    \
            --vcn-id            ${sandbox_vcn_id}           \
            --cidr-block        '10.0.1.0/24'               \
            --dns-label         'private'                   \
            --wait-for-state    AVAILABLE                   \
            --query             'data.id'                   \
            --raw-output                                    \
        )
    if [[ $? -ne 0 ]]
    then
        printf 'Unable to create private subnet in Sandbox compartment.' >&2
        printf ' Exiting...\n' >&2
        exit 1
    fi
fi

# ------------------------------------------------------------------------------
# Find public subnet in the Sandbox compartment. Create it if not found
# ------------------------------------------------------------------------------

public_subnet_name="public subnet-sandbox-vcn"
public_subnet_id=$(                                 \
    oci network subnet list                         \
        --compartment-id ${sandbox_comp_id}         \
        --display-name "${public_subnet_name}"      \
        --query 'data[0].id'                        \
        --raw-output                                \
    )
if [[ -z "${public_subnet_id}" ]]
then
    public_subnet_id=$(                                     \
        oci network subnet create                           \
            --compartment-id    ${sandbox_comp_id}          \
            --display-name      "${public_subnet_name}"     \
            --vcn-id            ${sandbox_vcn_id}           \
            --cidr-block        '10.0.2.0/24'               \
            --dns-label         'public'                    \
            --wait-for-state    AVAILABLE                   \
            --query            'data.id'                    \
            --raw-output                                    \
        )
    if [[ $? -ne 0 ]]
    then
        printf 'Unable to create public subnet in Sandbox compartment.' >&2
        printf ' Exiting...\n' >&2
        exit 1
    fi
fi

# ------------------------------------------------------------------------------
# Find free in first availability domain
# ------------------------------------------------------------------------------

ad_ocid=$(oci iam availability-domain list --query 'data[0].id' --raw-output)

# ------------------------------------------------------------------------------
#
# ------------------------------------------------------------------------------

