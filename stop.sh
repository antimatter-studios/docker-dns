#!/usr/bin/env bash

# This DIR variable resolves any problem of referencing this script from another location on the disk
dir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

# Configuration values
os=$(uname | awk '{ print tolower($0) }')

source ${dir}/.${os}_functions

# Some nice text colours
red=$'\e[1;31m'; grn=$'\e[1;32m'; yel=$'\e[1;33m'; blu=$'\e[1;34m'; mag=$'\e[1;35m'; cyn=$'\e[1;36m'; end=$'\e[0m'

echo "${yel}Stopping the Local DNSMasq for ${blu}Docker / Kubernetes${end}"

compose=${dir}/docker-compose.yml

echo "Stopping the docker-compose: ${yel}$compose${end}"
docker-compose -f $compose stop

container_remove_dns
