#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Examine VCN/Subnets Characteristics
# ===================================
#
# Finds all VCNs and Subnets in the tenancy
# ------------------------------------------------------------------------------

oci session validate --local || exit 1

# ------------------------------------------------------------------------------
# Find all compartments in tenancy
# - Store OCID in an array, compartment, indexed by its name
# ------------------------------------------------------------------------------

declare -A compartment

while read key value
do
    case "${key}" in
        '---')
            continue
            ;;
        '-')
            unset comp_id comp_name
            key="${value%%:*}"
            value="${value#*:}"
            ;;
        *)  key="${key%%:*}"
            ;;
    esac
    case "${key}" in
        'id')
            comp_id="${value}"
            ;;
        'name')
            comp_name="${value}"
            ;;
        *)  continue
            ;;
    esac
    [[ -n "${comp_id}" && -n "${comp_name}" ]] && \
        compartment["${comp_name}"]="${comp_id}"
done < <(                                              \
        oci iam compartment list                       \
            --query 'data[*].{id: "id", name: "name"}' \
            --include-root |                           \
        json_xs -f json -t yaml                        \
        )

# ------------------------------------------------------------------------------
# Find all VCNs in tenancy by querying all compartments
# ------------------------------------------------------------------------------

declare -A vcn_cidr_block vcn_id vcn_dns_label vcn_domain vcn_comp_name

for comp_name in ${!compartment[*]}
do
    unset temp_cidr_block temp_vcn_name temp_dns_label temp_domain_name temp_vcn_id
    while read key value
    do
        case "${key}" in
            '---')
                continue
                ;;
            '-')
                [[ "${value}" == "cidr-blocks:" ]] && continue
                [[ -z "$temp_cidr_block[@]" ]] \
                    && temp_cidr_block[1]="${value}" \
                    || temp_cidr_block+=("${value}")
                ;;
            'display-name:')
                temp_vcn_name="${value}"
                ;;
            'dns-label:')
                [[ "${value}" != '~' ]] && temp_dns_label="${value}"
                ;;
            'id:')
                temp_vcn_id="${value}"
                ;;
            'vcn-domain-name:')
                [[ "${value}" != '~' ]] && temp_domain_name="${value}"
                ;;
            *)  ;;
        esac
    done < <(                                      \
        oci network vcn list                       \
            --compartment-id ${compartment[$comp_name]} \
            --query 'data[*].{"cidr-blocks": "cidr-blocks", "display-name": "display-name", "id": "id", "dns-label": "dns-label", "vcn-domain-name": "vcn-domain-name"}' | \
        json_xs -f json -t yaml 2>/dev/null        \
    )
    if [[ -n "${temp_vcn_name}" ]]
    then
        [[ -n "${temp_cidr_block[@]}" ]] && \
            vcn_cidr_block["${temp_vcn_name}"]="${temp_cidr_block}"
        [[ -n "${temp_vcn_id}" ]] && \
            vcn_id["${temp_vcn_name}"]="${temp_vcn_id}"
        [[ -n "${temp_dns_label}" ]] && \
            vcn_dns_label["${temp_vcn_name}"]="${temp_dns_label}"
        [[ -n "${temp_domain_name}" ]] && \
            vcn_domain["${temp_vcn_name}"]="${temp_domain_name}"
        vcn_comp_name["${temp_vcn_name}"]="${comp_name}"
    fi
done

# ------------------------------------------------------------------------------
# Find all Subnets in tenancy by querying all VCNs in compartments that have a
#   VCN
# ------------------------------------------------------------------------------

declare -A subnet_name subnet_cidr subnet_vcn_name subnet_comp_name

for vcn_name in ${!vcn_comp_name[*]}
do
    unset temp_cidr_block temp_subnet_name temp_subnet_id
    comp_name="${vcn_comp_name[${vcn_name}]}"
    while read key value
    do
        case "${key}" in
            '---')
                continue
                ;;
            '-')
                if [[ -n "${temp_subnet_id}" ]]
                then
                    subnet_vcn_name["${temp_subnet_id}"]="${vcn_name}"
                    subnet_comp_name["${temp_subnet_id}"]="${vcn_comp_name[${vcn_name}]}"
                    [[ -n "${temp_subnet_name}" ]] && \
                        subnet_name["${temp_subnet_id}"]="${temp_subnet_name}"
                    [[ -n "${temp_cidr_block}" ]] && \
                        subnet_cidr["${temp_subnet_id}"]="${temp_cidr_block}"
                fi
                unset temp_cidr_block temp_subnet_name temp_subnet_id
                key="${value%%:*}"
                value="${value#*:}"
                ;;
            *)  key="${key%%:*}"
                ;;
        esac
        case "${key}" in
            'cidr-block')
                temp_cidr_block="${value}"
                ;;
            'display-name')
                temp_subnet_name="${value}"
                ;;
            'id')
                temp_subnet_id="${value}"
                ;;
            *)  ;;
        esac
    done < <(                                           \
        oci network subnet list                         \
            --compartment-id ${compartment[$comp_name]} \
            --vcn-id ${vcn_id[$vcn_name]}               \
            --query 'data[*].{"cidr-block": "cidr-block", "display-name": "display-name", "id": "id"}' | \
        json_xs -f json -t yaml 2>/dev/null             \
    )
    if [[ -n "${temp_subnet_id}" ]]
    then
        subnet_vcn_name["${temp_subnet_id}"]="${vcn_name}"
        subnet_comp_name["${temp_subnet_id}"]="${vcn_comp_name[${vcn_name}]}"
        [[ -n "${temp_subnet_name}" ]] && \
            subnet_name["${temp_subnet_id}"]="${temp_subnet_name}"
        [[ -n "${temp_cidr_block}" ]] && \
            subnet_cidr["${temp_subnet_id}"]="${temp_cidr_block}"
    fi
done

# ------------------------------------------------------------------------------
# Print out VCN and Subnet Summary
# ------------------------------------------------------------------------------

for vcn_name in ${!vcn_comp_name[@]}
do
    printf "VCN, '%s', is defined in compartment, '%s', with:\n" \
        "${vcn_name}" "${vcn_comp_name[${vcn_name}]}"
    printf "    OCID=%s\n" "${vcn_id[$vcn_name]}"
    temp_cidr_block="${vcn_cidr_block[$vcn_name]}"
    for cidr in ${temp_cidr_block[@]}
    do
        printf '    CIDR Block %s\n' "${cidr}"
    done
    for subnet_id in ${!subnet_vcn_name[@]}
    do
        [[ "${subnet_vcn_name[${subnet_id}]}" != "${vcn_name}" ]] && \
            continue
        printf "    Subnet '%s' has CIDR=%s\n" \
            "${subnet_name[${subnet_id}]}" "${subnet_cidr[${subnet_id}]}"
    done
    [[ -n "${vcn_dns_label[$vcn_name]}" ]] && \
        printf "    DNS Label='%s'\n" "${vcn_dns_label[$vcn_name]}"
    [[ -n "${vcn_domain[$vcn_name]}" ]] && \
        printf "    DNS Domain='%s'\n" "${vcn_domain[$vcn_name]}"
done
