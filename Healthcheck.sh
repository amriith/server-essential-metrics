#!/bin/bash



RED='\E[031M'
GREEN='\E[032M'
YELLOW='\E[033M'
BLUE='\E[034M'
ORANGE='\E[035M'
NC='\E[0m' 
BOLD=$(tput bold)

separator="-----------------------------------------------------------------"

echo -e "${BOLD}${GREEN} Healthcheck started at $(date +%Y-%m-%d\ %H:%M:%S) ${NC}"

header(){
    echo -e "${BOLD}${ORANGE}${NC}"
    echo "${separator}"
}

header "Memory Usage"


total_memory=$(free -m | awk '/^Mem:/{print $1 "MB"}')
used_memory=$(free -m | awk '/^Mem:/{print $2 "MB"}')
free_memory=$(free -m | awk '/^Mem:/{print $3}')  

if [ $(echo "$free_memory < 3000" | bc -l) -eq 1 ]; then
    echo -e "${BOLD}${RED}Free Memory: ${free_memory}MB ${NC}"
else
    echo -e "${BOLD}${GREEN}Free Memory: ${free_memory}MB ${NC}"
fi

header "Disk Usage"

disk_usage=$(df -h | awk '$NF=="/"{printf "%s\t%s\t%s\t%s\n", $1, $2, $3, $5}')