#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Find Terraform resources not discovered through the
# generate_terraform_import.py script
#
# Parameter:
# 1. Terraform directory
# ---------------------------------------------------------------------------

if [[ $# -eq 0 ]]
then
    printf '%s: Missing directory\n' $(basename $0) >&2
    exit 1
fi

diff <(                                  \
    terraform                            \
        -chdir=$1                        \
        state                            \
        list |                           \
        sed -nre '/^oci_/p' |            \
        sort                             \
    )                                    \
    <(                                   \
        ./generate_terraform_import.py | \
        cut -d\  -f 3 |                  \
        sort                             \
    )

