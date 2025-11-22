#!/bin/bash

# Color codes
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
ORANGE='\033[35m'
NC='\033[0m'
GOLD='\033[38;5;220m'
BOLD=$(tput bold)

separator="  

==================================================================================
"

echo -e "${BOLD}${GREEN}Healthcheck started at $(date +%Y-%m-%d\ %H:%M:%S)${NC}"

header(){
    echo -e "${BOLD}${ORANGE}$1${NC}"
    echo "${separator}"
}

# Memory Usage
header " 💻 Memory Usage"

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

echo "${separator}"

# Docker Stats
header " 🐳 Docker Stats"

docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${BOLD}${GOLD}Docker is not running or no containers found.${NC}"
fi

echo "${separator}"

# Disk Usage
header " 💾 Disk Usage"

disk_usage=$(df -h | awk '$NF=="/"{printf "%s\t%s\t%s\t%s\n", $1, $2, $3, $5}')
echo " $disk_usage"

# Check disk usage percentage and warn if low
disk_percent=$(df -h | awk '$NF=="/"{print $5}' | sed 's/%//')
if [ "$disk_percent" -gt 80 ]; then
    echo -e "${BOLD}${RED}WARNING: Disk usage is ${disk_percent}% - Consider freeing up disk space or run docker prune commands.${NC}"
elif [ "$disk_percent" -gt 60 ]; then
    echo -e "${BOLD}${YELLOW}Notice: Disk usage is ${disk_percent}% - Monitor disk space.${NC}"
else
    echo -e "${BOLD}${GREEN}Disk usage is ${disk_percent}% - Good.${NC}"
fi

echo "${separator}"

# Peak Load Times and Average
header " ⏱ Peak Load Times and Average"
uptime_info=$(uptime)
echo "$uptime_info"

load_15mins=$(uptime | awk -F 'load average:' '{print $2}' | awk -F ',' '{print $3}' | sed 's/^[ \t]*//')
cpu_cores=$(nproc)

if (( $(echo "$load_15mins > $cpu_cores" | bc -l) )); then 
    echo -e "${BOLD}${RED}High Load Average: $load_15mins on $cpu_cores CPU cores${NC}"
else 
    echo -e "${BOLD}${GREEN}Healthy Load Average: $load_15mins on $cpu_cores CPU cores${NC}"
fi

echo "${separator}"

# Failed Log In Attempts
header " 🥷 Failed Log In Attempts"

if [ -f /var/log/auth.log ]; then
    echo -e "${BOLD}Top IPs causing failed logins:${NC}"
    grep "Failed password" /var/log/auth.log | awk '{for(i=1;i<=NF;i++){if($i=="from"){print $(i+1)}}}' | sort | uniq -c | sort -nr | head -10
    echo ""
    echo -e "${BOLD}Recent Failed Login Attempts:${NC}"
    grep -E "Failed|Failure" /var/log/auth.log | tail -20
elif [ -f /var/log/secure ]; then
    echo -e "${BOLD}Top IPs causing failed logins:${NC}"
    grep "Failed password" /var/log/secure | awk '{for(i=1;i<=NF;i++){if($i=="from"){print $(i+1)}}}' | sort | uniq -c | sort -nr | head -10
    echo ""
    echo -e "${BOLD}Recent Failed Login Attempts:${NC}"
    grep -E "Failed|Failure" /var/log/secure | tail -20
else
    echo -e "${BOLD}${YELLOW}No recognised authentication log file found${NC}"
fi

echo "${separator}"

# Server Logins / Suspicious Activity
header " 🥷 Server Logins / Suspicious Activity"
echo "Last 5 login attempts:"
last -n 5

echo ""
echo "Failed login counts (if any):"
faillog -a 2>/dev/null | awk '$4 > 1' || echo "No failed login data available"

echo "${separator}"

# Details of Open ports
header " 🖧 Open Ports and Services"
if command -v ss >/dev/null 2>&1; then
    ss -tuln
elif command -v netstat >/dev/null 2>&1; then
    netstat -tuln
else
    echo -e "${BOLD}${YELLOW}Neither ss nor netstat is available on this system.${NC}"
fi

echo "${separator}"

# Outdated Security Packages
header "🛡️ Outdated Security Packages"
if command -v yum >/dev/null 2>&1; then
    sudo yum check-update --security 2>/dev/null || echo "Unable to check for security updates"
elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get --just-print upgrade 2>/dev/null | grep "^Inst" | grep -i security || echo "No security updates pending or unable to check"
else
    echo -e "${BOLD}${YELLOW}Neither yum nor apt-get is available on this system.${NC}"
fi

echo "${separator}"

# Environment Variables Check
header " 🧩 Environment Variables Check"
sensitive_vars=$(env | grep -E 'PASSWORD|SECRET|KEY|TOKEN' | sed 's/=.*/=***HIDDEN***/')
if [ -n "$sensitive_vars" ]; then
    echo -e "${BOLD}${RED}WARNING: Sensitive environment variables detected:${NC}"
    echo "$sensitive_vars"
else
    echo -e "${BOLD}${GREEN}No sensitive environment variables detected in current environment.${NC}"
fi

echo "${separator}"

# Docker Container Health Check
header " 🩺 Docker Container Health Check"

if command -v docker >/dev/null 2>&1; then
    exited_containers=$(docker ps -a --filter "status=exited" --format "{{.ID}}: {{.Names}}" 2>/dev/null)
    if [ -n "$exited_containers" ]; then
        echo -e "${BOLD}${RED}Exited Containers Found:${NC}"
        echo "$exited_containers"
        for container_id in $(echo "$exited_containers" | awk -F: '{print $1}'); do
            echo -e "${BOLD}Last 3 lines of logs for container ID $container_id:${NC}"
            docker logs --tail 3 "$container_id" 2>/dev/null
            echo "-----------------------------------"
        done
    else
        echo -e "${BOLD}${GREEN}No exited containers found.${NC}"
    fi
else
    echo -e "${BOLD}${GOLD}Docker is not installed or not accessible.${NC}"
fi

echo "${separator}"

# Input/Output Bottleneck Identification
header " 📥 I/O Bottleneck Identification"

if command -v iostat >/dev/null 2>&1; then
    iostat -x 1 3
else
    echo -e "${BOLD}${GOLD}iostat command not found. Please install sysstat package.${NC}"
fi

echo "${separator}"

# Log File Rotation and Cleanup Recommendations
header " 📜 Log File Rotation and Cleanup Recommendations"

log_dirs=("/var/log" "/var/log/nginx" "/var/log/mysql")
large_logs_found=0

for dir in "${log_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${BOLD}Checking log directory: $dir${NC}"
        large_logs=$(find "$dir" -type f -name "*.log" -size +100M -exec ls -lh {} \; 2>/dev/null)
        if [ -n "$large_logs" ]; then
            echo "$large_logs"
            large_logs_found=1
        else
            echo "No large log files (>100MB) found in $dir"
        fi
    else
        echo -e "${BOLD}${YELLOW}Directory $dir does not exist.${NC}"
    fi
done

if [ $large_logs_found -eq 1 ]; then
    echo -e "${BOLD}${YELLOW}Consider setting up log rotation using logrotate if not already configured.${NC}"
else
    echo -e "${BOLD}${GREEN}Log file sizes appear healthy.${NC}"
fi

echo "${separator}"

echo -e "${BOLD}${GREEN}Healthcheck completed at $(date +%Y-%m-%d\ %H:%M:%S)${NC}"