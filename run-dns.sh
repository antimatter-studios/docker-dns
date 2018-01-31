#!/bin/sh

echo "Running the Local DNSMasq for Docker / Kubernetes"

# This DIR variable resolves any problem of referencing this script from another location on the disk
directory=$(dirname "$(readlink -f "$0")")
compose=$directory/docker-compose.yml

echo "Rebooting the docker-compose: $compose"
docker-compose -f $compose stop
docker-compose -f $compose up -d

# Only run this command on linux since on mac this is not a problem
if [ $(uname -o) = "GNU/Linux" ]; then
    package="libnss-mdns"
    found=$(dpkg-query -W --showformat='${Status}\n' $package | grep "install ok installed")

    if [ "$found" != "" ]; then
        echo "The package 'libnss-mdns' was installed"
        echo "On GNU/Linux systems this must be uninstalled for *.local domains to function correctly and as expected"
        sudo apt-get remove libnss-mdns
    fi
fi

# Now lets configure the DNS server inside the docker container to resolve our project domains
local_domain=docker.local
resolve_conf=/etc/resolvconf/resolv.conf.d/head
container_name="cthomas/supervisord-dnsmasq:latest"
container_id=$(docker ps | grep $container_name | awk '{ print $1 }')
ipaddress=$(docker inspect -f '{{ range .NetworkSettings.Networks }}{{ .IPAddress }}{{ end }}' $container_id)

echo "Updating DNS Resolver to use container id '$container_id' with ip address '$ipaddress'"
echo "Note: If you are asked for your password, it means your sudo password"

# I wanted to use a variable here, but the special characters defeated me :(
sudo sed -i "/\# CONTAINER\:cthomas\/supervisord-dnsmasq\:latest/d" $resolve_conf

echo "nameserver $ipaddress # CONTAINER:$container_name ip address" | sudo tee -a $resolve_conf
sudo resolvconf -u

echo "Adding your custom domain from the command line"
while getopts "d:" domain; do
    case $domain in
        d)
            echo "Installing domain '${OPTARG}' into dnsmasq configuration"
            config="address=/${OPTARG}/127.0.0.1"
            file="/etc/dnsmasq.d/${OPTARG}.conf"
            docker exec -it $container_id /bin/sh -c "echo '$config' > $file"
            ;;
    esac
done
docker exec -it $container_id kill -s SIGHUP 1

# we need to sleep for a second or two in order that the dns is updated
sleep 2
echo "Testing DNS Resolution with a test domain 'test-dns.$local_domain'"
ping -c1 -W 1 test-dns.$local_domain