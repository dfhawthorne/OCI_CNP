#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Update Terraform variables based on MyLearn OCI CLI configuration
# ------------------------------------------------------------------------------

pgm_name=$(basename $0)
pgm_dir=$(dirname $0)
pushd "${pgm_dir}" >/dev/null

config=~mylearn/oci_config.txt
sed_pgm=$(basename ${pgm_name} .sh).sed
tfvars=terraform.tfvars

if [[ ! -r "${config}" ]]
then
    printf '%s: Unable to read %s\n' "${pgm_name}" "${config}" >&2
    exit 1
fi

if [[ ! -x "${sed_pgm}" ]]
then
    printf '%s: Unable to execute %s\n' "${pgm_name}" "${sed_pgm}" >&2
    exit 1
fi

if [[ ! -w "${tfvars}" ]]
then
    printf '%s: Unable to update %s\n' "${pgm_name}" "${tfvars}" >&2
    exit 1
fi

sed \
    -i \
    -rf <("./${sed_pgm}" "${config}") \
    "${tfvars}"

