#!/usr/bin/env bash

# This DIR variable resolves any problem of referencing this script from another location on the disk
dir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

# Configuration values
image_name="ghcr.io/antimatter-studios/docker-dns"
alias_ip_address=10.254.254.254
os=$(uname | awk '{ print tolower($0) }')

source ${dir}/.${os}_functions

# Some nice text colours
red=$'\e[1;31m'; grn=$'\e[1;32m'; yel=$'\e[1;33m'; blu=$'\e[1;34m'; mag=$'\e[1;35m'; cyn=$'\e[1;36m'; end=$'\e[0m'

echo "${blu}Running the Local DNSMasq for ${yel}Docker / Kubernetes${end}"
compose=${dir}/docker-compose.yml

echo "Rebooting the docker-compose: ${yel}${compose}${end}"
docker-compose -f ${compose} stop
docker-compose -f ${compose} up -d --remove-orphans docker-dns

get_container_id ()
{
    docker ps | grep ${image_name} | awk '{ print $1 }'
}

install_domain ()
{
    if [[ -z $1 ]]; then echo "${red}Must pass the container id name as the first parameter${end}"; exit 2; fi
    if [[ -z $2 ]]; then echo "${red}Must pass the dns ip address as the second parameter${end}"; exit 1; fi
    if [[ -z $3 ]]; then echo "${red}Must pass the domain name as the third parameter${end}"; exit 2; fi

    echo "Installing domain ${yel}'$3'${end} with ip address ${yel}'$2'${end} into dnsmasq configuration in container id ${yel}'$1'${end}"

    docker exec -it $1 /bin/sh -c "echo 'address=/$3/$2' > /etc/dnsmasq.d/$3.conf"
    docker exec -it $1 kill -s SIGHUP 1

    sleep 2
}

while getopts "a:d:" param; do
    case ${param} in
        a)
            alias_ip_address=${OPTARG}

            echo "${yel}Setup the ${blu}${container_os_name} ${yel}environment${end}"

            container_ip_alias ${alias_ip_address}
            # NOTE: I found that using the alias ip address does not work on mac, so lets use the localhost ip address instead
            container_add_dns 127.0.0.1
            ;;
        d)
            domain_name=${OPTARG}

            container_id=$(get_container_id)

            install_domain ${container_id} ${alias_ip_address} ${domain_name}

            # we need to sleep for a second or two in order that the dns is updated
            echo "Testing DNS Resolution with a test domain ${yel}'${domain_name}'${end}"
            echo ${cyn}
            ping -c1 -W 1 ${domain_name}
            echo ${end}
            ;;
    esac
done
