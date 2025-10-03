#!/bin/bash

# Color codes - fixed the escape sequences
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
ORANGE='\033[35m'
NC='\033[0m'
GOLD='\033[38;5;220m'
BOLD=$(tput bold)

separator="-----------------------------------------------------------------"

echo -e "${BOLD}${GREEN}Healthcheck started at $(date +%Y-%m-%d\ %H:%M:%S)${NC}"

header(){
    echo -e "${BOLD}${ORANGE}$1${NC}"
    echo "${separator}"
}

#Memory Usage
header "Memory Usage"

total_memory=$(free -m | awk '/^Mem:/{print $2 "MB"}')
used_memory=$(free -m | awk '/^Mem:/{print $3 "MB"}')
free_memory=$(free -m | awk '/^Mem:/{print $4}')  


if [ $(awk 'BEGIN {print ('$free_memory' < 1000)}') -eq 1 ]; then
    echo -e "${BOLD}${RED}Free Memory: ${free_memory}MB${NC} ${BOLD}${RED}WARNING: Low memory${NC}!"
else
    echo -e "${BOLD}${GREEN}Free Memory: ${free_memory}MB${NC}"
fi

echo "Total Memory: ${total_memory}"
echo "Used Memory: ${used_memory}"

#Docker Stats
header "Docker Stats"

docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
if [ $? -ne 0 ]; then
    echo -e "${BOLD}${GOLD}Docker is not running or no containers found.${NC}"
fi

#Disk Usage
header "Disk Usage"

disk_usage=$(df -h | awk '$NF=="/"{printf "%s\t%s\t%s\t%s\n", $1, $2, $3, $5}')
echo "$disk_usage"

# Check disk usage percentage and warn if low
disk_percent=$(df -h | awk '$NF=="/"{print $5}' | sed 's/%//')
if [ "$disk_percent" -gt 80 ]; then
    echo -e "${BOLD}${RED}WARNING: Disk usage is ${disk_percent}% - Consider freeing up disk space or run docker prune commands.${NC}"
elif [ "$disk_percent" -gt 60 ]; then
    echo -e "${BOLD}${YELLOW}Notice: Disk usage is ${disk_percent}% - Monitor disk space.${NC}"
else
    echo -e "${BOLD}${GREEN}Disk usage is ${disk_percent}% - Good.${NC}"
fi

#Peak Load Times and Average
header "Peak Load Times and Average"
uptime_info=$(uptime)
echo "$uptime_info"


load_15mins=$(uptime | awk -F 'load average:' 'print $2' | awk -F ',' '{print $3}' | sed 's/^[ \t]*//')

cpu_cores=$(nproc)

if [ $(echo "$load_15mins gt $cpu_cores)]
then 
    echo -e " ${BOLD}${RED} High Load Average: $load_15mins on $cpu_cores CPU cores ${NC}"
else 
    echo -e " ${BOLD}${GREEN} Healthy Load Average: $load_15mins on $cpu_cores CPU cores ${NC}"
fi

#
