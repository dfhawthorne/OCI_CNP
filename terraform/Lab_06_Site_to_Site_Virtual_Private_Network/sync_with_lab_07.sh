#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Synchronises Lab 06 resources with those created in Lab 07
# ------------------------------------------------------------------------------

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
            -state=../Lab_07_Remote_Peering/terraform.tfstate \
            ${resource_name} | \
        sed -nre '/^\s+id\s+/s/.*=\s+"(.*)"/\1/p' |
        head -n 1 \
        )
    [[ -z "${resource_id}" ]] && continue
    printf '         address = %s\n' "${resource_id}"
    terraform state rm ${resource_name}
    terraform import ${resource_name} ${resource_id}
done < <(terraform state list)

