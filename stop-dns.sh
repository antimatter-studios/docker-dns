#!/usr/bin/env bash

# Some nice text colours
red=$'\e[1;31m'; grn=$'\e[1;32m'; yel=$'\e[1;33m'; blu=$'\e[1;34m'; mag=$'\e[1;35m'; cyn=$'\e[1;36m'; end=$'\e[0m'

echo "${yel}Stopping the Local DNSMasq for ${blu}Docker / Kubernetes${end}"

# This DIR variable resolves any problem of referencing this script from another location on the disk
directory=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
compose=${directory}/docker-compose.yml

echo "Stopping the docker-compose: ${yel}$compose${end}"
docker-compose -f $compose stop

get_container_id ()
{
    docker ps | grep "christhomas/supervisord-dnsmasq" | awk '{ print $1 }'
}

linux_remove_dns ()
{
    # Now lets configure the DNS server inside the docker container to resolve our project domains
    resolve_conf=/etc/resolvconf/resolv.conf.d/head

    # I wanted to use a variable here, but the special characters defeated me :(
    sudo sed -i "/\# CONTAINER\:$1 ip address/d" $resolve_conf
}

darwin_add_dns ()
{
    if [[ -z $1 ]]; then echo "${red}Must pass the dns ip address as the first parameter${end}"; exit 1; fi

    echo "DNS Servers: ${yel}'$1'${end}"
    sudo networksetup -setdnsservers 'Wi-Fi' $1
}

darwin_remove_dns ()
{
    dns_ip_address="8.8.8.8 8.8.4.4"
    echo "DNS Servers: ${yel}'${dns_ip_address}'${end}"
    sudo networksetup -setdnsservers 'Wi-Fi' ${dns_ip_address}
}

if [[ "$(uname)" = "Linux" ]]; then
    linux_remove_dns $(get_container_id)
elif [[ "$(uname)" = "Darwin" ]]; then
    darwin_remove_dns
fi