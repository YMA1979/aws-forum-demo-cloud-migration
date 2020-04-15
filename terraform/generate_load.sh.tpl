#!/bin/bash

BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

# Duration in seconds
DURATION=600
CONCURRENT=20

function print-help {
    echo -e "\n${BLUE}Usage: generate_load.sh <port> ${NC}"
    echo -e "${BLUE}    <port> the TCP port to which to generate traffic ${NC}"
    exit 0
}

if [[ -z "${1}" ]]; then
    print-help
else

echo -e "${GREEN}Going to generate traffic load on ${bigip_address}:${1} ${NC} \n\n"

echo "siege -c${CONCURRENT} ${bigip_address}:${1} -b -t${DURATION}s \n"

siege -c${CONCURRENT} ${bigip_address}:${1} -b -t${DURATION}s
