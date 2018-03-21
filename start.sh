#!/usr/bin/env bash

# Configuration values
alias_ip_address=10.254.254.254

# Some nice text colours
red=$'\e[1;31m'; grn=$'\e[1;32m'; yel=$'\e[1;33m'; blu=$'\e[1;34m'; mag=$'\e[1;35m'; cyn=$'\e[1;36m'; end=$'\e[0m'

echo "${yel}Running the Local DNSMasq for ${blu}Docker / Kubernetes${end}"

# This DIR variable resolves any problem of referencing this script from another location on the disk
directory=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
compose=${directory}/docker-compose.yml

echo "Rebooting the docker-compose: ${yel}$compose${end}"
docker-compose -f $compose stop

if [[ "$(uname)" = "Darwin" ]]; then
    docker-compose -f ${compose} up -d --remove-orphans local-dns-osx
elif [[ "$(uname)" = "Linux" ]]; then
    docker-compose -f ${compose} up -d --remove-orphans local-dns-linux
else
    echo "Could not support this operating system"
    exit 1
fi

get_container_id ()
{
    docker ps | grep "christhomas/supervisord-dnsmasq" | awk '{ print $1 }'
}

linux_ip_alias ()
{
    if [[ -z $1 ]]; then echo "${red}Must pass the alias ip address as the first parameter${end}"; exit 1; fi

    echo "Adding Loopback Alias IP Address '$1'"
    sudo ifconfig lo:40 $1 netmask 255.255.255.0 up
}

linux_add_dns ()
{
    if [[ -z $1 ]]; then echo "${red}Must pass the dns ip address as the first parameter${end}"; exit 1; fi
    if [[ -z $2 ]]; then echo "${red}Must pass the container id name as the second parameter${end}"; exit 2; fi

    # Now lets configure the DNS server inside the docker container to resolve our project domains
    resolve_conf=/etc/resolvconf/resolv.conf.d/head

    echo "Updating DNS Resolver to use container id ${yel}'$2'${end} with ip address ${yel}'$1'${end}"
    echo "${blu}Note: If you are asked for your password, it means your sudo password${end}"

    linux_remove_dns $2

    echo "nameserver $1 # CONTAINER:dnsmasq ip address" | sudo tee -a $resolve_conf
    sudo resolvconf -u
}

linux_remove_dns ()
{
    # Now lets configure the DNS server inside the docker container to resolve our project domains
    resolve_conf=/etc/resolvconf/resolv.conf.d/head

    # I wanted to use a variable here, but the special characters defeated me :(
    sudo sed -i "/\# CONTAINER\:dnsmasq ip address/d" $resolve_conf

    sudo resolvconf -u
}

linux_remove_package_mdns ()
{
    package="libnss-mdns"
    found=$(dpkg-query -W --showformat='${Status}\n' $package | grep "install ok installed")

    if [ "$found" != "" ]; then
        echo "The package ${yel}'libnss-mdns'${end} was installed"
        echo "On GNU/Linux systems this must be uninstalled for ${yel}*.local${end} domains to function correctly and as expected"
        sudo apt-get remove -y libnss-mdns
    fi
}

darwin_ip_alias ()
{
    if [[ -z $1 ]]; then echo "${red}Must pass the alias ip address as the first parameter${end}"; exit 1; fi

    echo "Adding Loopback Alias IP Address: ${yel}'$1'${end}"
    sudo ifconfig lo0 alias $1
}

darwin_add_dns ()
{
    if [[ -z $1 ]]; then echo "${red}Must pass the dns ip address as the first parameter${end}"; exit 1; fi

    echo "DNS Servers: ${yel}'$1'${end}"
    sudo networksetup -setdnsservers 'Wi-Fi' $1
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

if [[ "$(uname)" = "Linux" ]]; then
    linux_remove_package_mdns
fi

while getopts "a:d:" param; do
    case ${param} in
        a)
            alias_ip_address=${OPTARG}

            if [[ "$(uname)" = "Darwin" ]]; then
                echo "${yel}Setup the ${blu}Apple Mac OS ${yel}environment${end}"

                darwin_ip_alias ${alias_ip_address}
                darwin_add_dns ${alias_ip_address}
            elif [[ "$(uname)" = "Linux" ]]; then
                echo "${yel}Setup the ${blu}GNU/Linux ${yel}environment${end}"

                container_id=$(get_container_id)

                dns_ip_address=$(docker inspect -f '{{ range .NetworkSettings.Networks }}{{ .IPAddress }}{{ end }}' ${container_id})

                linux_ip_alias ${alias_ip_address}
                linux_add_dns ${dns_ip_address} ${container_id}
            fi
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
