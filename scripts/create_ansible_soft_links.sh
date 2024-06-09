#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Create soft links to central Ansible resources
# ------------------------------------------------------------------------------

if [[ $# -lt 1 ]]
then
    printf "Expected a target directory. Exiting...\n" >&2
    exit 1
fi

script_dir=$(dirname $(realpath "$0"))
parent_dir=$(dirname "$script_dir")

if [[ ! -d "${parent_dir}/ansible" ]]
then
    printf "Unable to locate ansible directory. Exiting...\n" >&2
    exit 1
fi

for ansible_resource in ansible.cfg inventory logs passwords
do
    full_path="${parent_dir}/ansible/${ansible_resource}"
    if [[ ! -f "${full_path}" ]]
    then
        printf "Unable to locate Ansible resource, '%s'. Exiting...\n" \
            "${full_path}" >&2
        exit 1
    fi
    find $1 -type d -print0 | \
        xargs -0 -I@ ln -vs "${full_path}" '@'/"${ansible_resource}"
done

exit 0
       
