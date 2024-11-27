#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Lab 09:
# Instrastructure Security - Network: Create a Self-Signed Certificate and Perform
# SSL Termination on OCI Load Balancer
#
# Install and configure Apache web server
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Get Terraform Output Variables
# ------------------------------------------------------------------------------

pgm_name=$(basename $0)

vm_01_public_ip=$(terraform output -raw vm_01_public_ip)
case "${vm_01_public_ip}" in
    *Warning*)
        printf '%s: Unable to retrieve output variable, %s\n' \
            "${pgm_name}" "vm_01_public_ip" >&2
        exit 1
        ;;
    *)  ;;
esac

vm_02_public_ip=$(terraform output -raw vm_02_public_ip)
case "${vm_02_public_ip}" in
    *Warning*)
        printf '%s: Unable to retrieve output variable, %s\n' \
            "${pgm_name}" "vm_02_public_ip" >&2
        exit 1
        ;;
    *)  ;;
esac

# ------------------------------------------------------------------------------
# Save private SSH key
# ------------------------------------------------------------------------------

private_key_pem=$(terraform output -raw private_key_pem)
case "${vm_01_public_ip}" in
    *Warning*)
        printf '%s: Unable to retrieve output variable, %s\n' \
            "${pgm_name}" "private_key_pem" >&2
        exit 1
        ;;
    *)  ;;
esac

private_key_file='.ssh/private_key'
ssh_key_dir=$(dirname "${private_key_file}")
if [[ ! -d "${ssh_key_dir}" ]]
then
    mkdir -p "${ssh_key_dir}"
    chmod 700 "${ssh_key_dir}"
fi
if [[ ! -f "${private_key_file}" ]]
then
    sed -nre '/^---/,/^---/p' <(terraform output -raw private_key_pem) \
        >"${private_key_file}"
    chmod 600 "${private_key_file}"
fi

# ------------------------------------------------------------------------------
# Connect to Compute Instances and perform installation
# ------------------------------------------------------------------------------

server_id=0
for ip_addr in "${vm_01_public_ip}" "${vm_02_public_ip}"
do
    (( server_id++ ))
    ssh \
        -i "${private_key_file}" \
        -o StrictHostKeyChecking=accept-new \
        opc@${ip_addr} <<DONE
            # Install the Apache server
            sudo yum -y install httpd
            # Enable Apache and start the Apache server
            sudo systemctl enable httpd
            sudo systemctl restart httpd
            # Create a firewall rule to enable HTTP connection through port 80
            # and reload the firewall:
            sudo firewall-cmd --permanent --ad-port=80/tcp
            sudo firewall-cmd --reload
            # Create an index file for your web server
            printf 'You are visiting Web Server %d\n" ${server_id} | \
                sudo tee /var/www/html/index.html >/dev/null
DONE
done
