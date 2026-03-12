# Server Performance Health Check Scripts

A collection of bash scripts to monitor and analyze server performance, security, and health.



## Prerequisites

Before using these scripts, ensure you have:

- Linux/Unix-based system (Ubuntu, CentOS, etc.)
- Bash shell installed
- Root or sudo access for some commands
- Required packages installed:

```bash
# Install required packages
sudo apt-get update
sudo apt-get install -y bc net-tools docker.io curl
```

## Installation

### Step 1: Clone or Download Scripts
```bash
ls -la  # List all scripts
```

### Step 2: Make Scripts Executable
```bash
chmod +x Healthcheck.sh
chmod +x *.sh  # Make all scripts executable
```

### Step 3: Verify Installation
```bash
./Healthcheck.sh --help  # If help is available
```

## Quick Start

### Running the Main Health Check
```bash
# Basic usage
./Healthcheck.sh

# With output to file
./Healthcheck.sh > healthcheck_report.txt

# Schedule to run daily at 2 AM
crontab -e
# Add this line:
0 2 * * * /path/to/Healthcheck.sh >> /var/log/healthcheck.log 2>&1
```


## Best Practices

1. **Run regularly**: Schedule via cron for continuous monitoring
2. **Review logs**: Check `/var/log/healthcheck.log` periodically
3. **Set alerts**: Configure email notifications for critical warnings
4. **Backup reports**: Archive historical health check reports
5. **Update packages**: Keep system packages current for security



## Support & Documentation

For more information:
- Check script comments: `head -50 Healthcheck.sh`
- Review individual function definitions
- Test in non-production environment first

## Version History

- v1.0 - Initial release with core health checks