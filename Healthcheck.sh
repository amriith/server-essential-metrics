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

# Extract load averages from uptime output
load_1min=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | sed 's/^[ \t]*//')
load_5min=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $2}' | sed 's/^[ \t]*//')
load_15min=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $3}' | sed 's/^[ \t]*//')

# Get number of CPU cores
cpu_cores=$(nproc)

echo ""
echo "Load Averages:"
echo "  1 minute:  $load_1min"
echo "  5 minutes: $load_5min"
echo "  15 minutes: $load_15min"
echo "  CPU Cores: $cpu_cores"

# Analyze system performance based on load averages
echo ""
echo "System Performance Analysis:"

# Check 1-minute load average
if [ $(echo "$load_1min > $cpu_cores" | bc -l) -eq 1 ]; then
    echo -e "${BOLD}${RED}CRITICAL: 1-minute load average ($load_1min) exceeds CPU cores ($cpu_cores)${NC}"
elif [ $(echo "$load_1min > $cpu_cores * 0.8" | bc -l) -eq 1 ]; then
    echo -e "${BOLD}${YELLOW}WARNING: 1-minute load average ($load_1min) is high${NC}"
else
    echo -e "${BOLD}${GREEN}GOOD: 1-minute load average ($load_1min) is normal${NC}"
fi

# Check 5-minute load average
if [ $(echo "$load_5min > $cpu_cores" | bc -l) -eq 1 ]; then
    echo -e "${BOLD}${RED}CRITICAL: 5-minute load average ($load_5min) exceeds CPU cores ($cpu_cores)${NC}"
elif [ $(echo "$load_5min > $cpu_cores * 0.8" | bc -l) -eq 1 ]; then
    echo -e "${BOLD}${YELLOW}WARNING: 5-minute load average ($load_5min) is high${NC}"
else
    echo -e "${BOLD}${GREEN}GOOD: 5-minute load average ($load_5min) is normal${NC}"
fi

# Check 15-minute load average
if [ $(echo "$load_15min > $cpu_cores" | bc -l) -eq 1 ]; then
    echo -e "${BOLD}${RED}CRITICAL: 15-minute load average ($load_15min) exceeds CPU cores ($cpu_cores)${NC}"
elif [ $(echo "$load_15min > $cpu_cores * 0.8" | bc -l) -eq 1 ]; then
    echo -e "${BOLD}${YELLOW}WARNING: 15-minute load average ($load_15min) is high${NC}"
else
    echo -e "${BOLD}${GREEN}GOOD: 15-minute load average ($load_15min) is normal${NC}"
fi
