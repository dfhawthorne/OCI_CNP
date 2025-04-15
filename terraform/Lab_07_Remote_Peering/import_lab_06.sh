#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Imports Lab 06 resources into Lab 07
# ------------------------------------------------------------------------------

lab_06_state=../Lab_06_Site_to_Site_Virtual_Private_Network/terraform.tfstate
while read resource_name
do
    case "${resource_name}" in
        data.*) continue ;;
        *) ;;
    esac
    printf 'Resource name = %s\n' "${resource_name}"
    resource_id=$( \
        terraform \
            state \
            show \
            -state="${lab_06_state}" \
            ${resource_name} | \
        sed -nre '/^\s+id\s+/s/.*=\s+"(.*)"/\1/p' |
        head -n 1 \
        )
    [[ -z "${resource_id}" ]] && continue
    printf '         address = %s\n' "${resource_id}"
    terraform state rm ${resource_name}
    terraform import ${resource_name} ${resource_id}
done < <(terraform state list -state="${lab_06_state}")

