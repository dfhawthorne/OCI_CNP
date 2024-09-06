# ------------------------------------------------------------------------------
# Output variables from create_vcn module
# ------------------------------------------------------------------------------

output "vcn_id" {
    value           = oci_core_vcn.vcn.id
    description     = "OCID of VCN"
}

output "natgw_id" {
    value           = oci_core_nat_gateway.NAT-gateway.id
    description     = "OCID of NAT Gateway"
}

output "igw_id" {
    value           = oci_core_internet_gateway.Internet-gateway.id
    description     = "OCID of Internet Gateway"
}

output "sgw_id" {
    value           = oci_core_service_gateway.Service-gateway.id
    description     = "OCID of Service Gateway"
}

output "dhcp_id" {
    value           = oci_core_dhcp_options.DHCP-Options.id
    description     = "OCID of DHCP Options"
}

output "pub_snet_id" {
    value           = oci_core_subnet.public-subnet.id
    description     = "OCID of public subnet"
}

output "priv_snet_id" {
    value           = oci_core_subnet.private-subnet.id
    description     = "OCID of private subnet"
}

output "priv_rt_id" {
    value           = oci_core_route_table.route-table-for-private-subnet.id
    description     = "OCID of route table for private subnet"
}

output "dflt_rt_id" {
    value           = oci_core_route_table.default-route-table.id
    description     = "OCID of default route table"
}

output "priv_sl_id" {
    value           = oci_core_security_list.security-list-for-private-subnet.id
    description     = "OCID of security list for private subnet"
}

output "dflt_sl_id" {
    value           = oci_core_default_security_list.Default-Security-List.id
    description     = "OCID of default security list"
}

