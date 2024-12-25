#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Show the status of DRGs in all regions (Ashburn, London, and Phoenix)
#
# Note: compartment_id is obtained by default from the OCI CLI configuration
#       file (~/.oci/oci_cli_rc)
# ------------------------------------------------------------------------------

oci session validate --local || \
    exit 1

# DEBUG=DEBUG
region_list="us-ashburn-1 uk-london-1 us-phoenix-1"

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

function display_route_table {
	if [[ -z "$1" || -z "$2" || -z "$3" ]]
	then
		printf '%s expects three parameters\n' "${FUNCNAME}" >&2
		return 1
	fi

	eval rt_type=$1
	eval rt_id=$2
	eval region=$3

	[[ -n "${DEBUG}" ]] && \
		printf '%s: route-table-id="%s"\n' "${FUNCNAME}" "${rt_id}"
	case "${rt_id}" in
		ocid1.drgroutetable.oc1.phx.*)
			;;
		ocid1.drgroutetable.oc1.uk-london-1.*)
			;;
		*)
			printf '%s: Invalid route-table-id="%s"\n' 							\
				"${FUNCNAME}" 													\
				"${rt_id}" >&2
			return 1
			;;
	esac

	rt_data=$(																	\
		oci network drg-route-table get 										\
			--drg-route-table-id ${rt_id} 										\
			--region ${region}													\
	)

	display_name=$(jq -r '.data."display-name"' <(echo "${rt_data}"))
	drg_rd_id=$(jq -r '.data."import-drg-route-distribution-id"' <(echo "${rt_data}"))

	printf '        DRG Route Table for %s: %s\n' "${rt_type}" "${display_name}"
	printf '            Import Route Distribution:\n'

	oci network drg-route-distribution-statement list 							\
		--route-distribution-id=${drg_rd_id} 									\
		--region=${region} 														\
		--query 'data[*]' 														\
		--output table
	
	printf '            Route Rules\n'

	oci network drg-route-rule list 											\
		--drg-route-table-id ${rt_id} 											\
		--region ${region} 														\
		--query 'data[*]' 														\
		--output table

	return 0
}

function display_route_dist {
	if [[ -z "$1" || -z "$2" ]]
	then
		printf '%s expects two parameters\n' "${FUNCNAME}" >&2
		return 1
	fi

	eval rt_dist_id=$1
	eval region=$2

	[[ -n "${DEBUG}" ]] && \
		printf '%s: route-distribution-id="%s"\n' "${FUNCNAME}" "${rt_dist_id}"
	case "${rt_dist_id}" in
		ocid1.drgroutedistribution.oc1.phx.*)
			;;
		ocid1.drgroutedistribution.oc1.uk-london-1.*)
			;;
		*)
			printf '%s: Invalid route-distribution-id="%s"\n' \
				"${FUNCNAME}" \
				"${rt_dist_id}" >&2
			return 1
			;;
	esac
	drg_rt_data=$(														\
		oci network drg-route-distribution get 							\
			--region ${region} 											\
			--route-distribution-id ${rt_dist_id} 						\
		)
	display_name=$(														\
		echo "${drg_rt_data}" | jq -r '.data."display-name"'			\
	)
	printf '   Default %s DRG Route: %s\n'								\
		$(echo "${drg_rt_data}" | jq -r '.data."distribution-type"')	\
		"${display_name}"
	oci network drg-route-distribution-statement list 					\
		--region ${region} 												\
		--route-distribution-id ${rt_dist_id} 							\
		--output table
	return 0
}

function display_drg {
	if [[ -z "$1" ]]
	then
		printf '%s expects a parameter\n' "${FUNCNAME}" >&2
		return 1
	fi

	eval drg_id=$1

	case "${drg_id}" in
		ocid1.drg.oc1.phx.*)
			region=us-phoenix-1
			;;
		ocid1.drg.oc1.uk-london-1.*)
			region=uk-london-1
			;;
		*)
			printf '%s: DRG-ID ("%s") is invalid\n' \
				"${FUNCNAME}" \
				"${drg_id}" >&2
			return 1
			;;
	esac

	[[ -n "${DEBUG}" ]] && \
		printf '%s: DRG-ID="%s"\n' ${FUNCNAME} ${drg_id}
	drg_data=$( \
		oci network drg get    \
			--region ${region} \
			--drg-id ${drg_id} \
		)
	[[ -n "${DEBUG}" ]] && 														\
		printf '%s: drg_data="""\n%s\n"""\n' "${FUNCNAME}" "${drg_data}"

	drg_name=$(jq -r '.data."display-name"' <(echo "${drg_data}"))
	printf '%s: %s\n' "${region}" "${drg_name}"

	declare -A default_drg_route_tables
	export_default_drg_route_dist=$(											\
		jq -r '.data."default-export-drg-route-distribution-id"' <(echo "${drg_data}") \
		)
	display_route_dist "${export_default_drg_route_dist}" "${region}"
	for key in "ipsec-tunnel" "remote-peering-connection" "vcn" "virtual-circuit"
	do
		printf -v query '.data."default-drg-route-tables"."%s"' ${key}
		default_drg_route_tables[${key}]=$(										\
			echo "${drg_data}" | 												\
			jq -r "${query}" 	            									\
			)
	done
	[[ -n "${DEBUG}" ]] && echo "${!default_drg_route_tables[@]}"
	for key in "${!default_drg_route_tables[@]}"
	do
		display_route_table ${key} "${default_drg_route_tables[$key]}" "${region}"
	done
}

for region in ${region_list}
do
    for drg_id in $(                              								\
		oci network drg list                      								\
			--query 'data[*].id'                  								\
			--region ${region}                    								\
			)
    do
		case "${drg_id}" in
			[|]) continue ;;
			*) ;;
		esac
		display_drg ${drg_id}
	done
done

