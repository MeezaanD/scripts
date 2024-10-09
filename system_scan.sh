#!/bin/bash

# Set your email address here
EMAIL="meezaandavids365@gmail.com"
LOGFILE="/tmp/system_check_report.txt"

# Function to check CPU usage
check_cpu_usage() {
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    echo "Current CPU Usage: $CPU_USAGE%" | tee -a "$LOGFILE"

    if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
        echo "Warning: CPU usage is above 80%!" | tee -a "$LOGFILE"
    fi
}

# Function to check disk space
check_disk_space() {
    DISK_USAGE=$(df / | grep / | awk '{ print $5 }' | sed 's/%//g')
    echo "Disk Space Usage: $DISK_USAGE%" | tee -a "$LOGFILE"

    if [ "$DISK_USAGE" -gt 80 ]; then
        echo "Warning: Disk space usage is above 80%!" | tee -a "$LOGFILE"
    fi
}

# Function to check for outdated applications
check_outdated_apps() {
    OUTDATED_APPS=$(apt list --upgradable 2>/dev/null | grep -E 'upgradable from' || true)
    
    if [ -n "$OUTDATED_APPS" ]; then
        echo "The following applications are outdated and can be updated:" | tee -a "$LOGFILE"
        echo "$OUTDATED_APPS" | tee -a "$LOGFILE"
    else
        echo "All applications are up to date." | tee -a "$LOGFILE"
    fi
}

# Function to clean unnecessary files
clean_unnecessary_files() {
    echo "Cleaning unnecessary files..." | tee -a "$LOGFILE"

    # Clear old log files
    sudo find /var/log -name "*.log" -type f -mtime +30 -exec rm -f {} \;
    echo "Removed log files older than 30 days." | tee -a "$LOGFILE"

    # Clear temporary files
    sudo rm -rf /tmp/*
    echo "Cleared temporary files." | tee -a "$LOGFILE"

    # Clear apt cache
    sudo apt-get clean
    echo "Cleared apt cache." | tee -a "$LOGFILE"
}

# Function to send the email with the log file
send_email() {
    echo "Sending system check report to $EMAIL..."
    
    # Check if mail command works
    if command -v mail &> /dev/null; then
        mail -s "System Check Report" "$EMAIL" < "$LOGFILE"
        echo "Email sent."
    else
        echo "Mail command not found. Please install mailutils or configure another mail tool." | tee -a "$LOGFILE"
    fi
}

# Main script execution
echo "Starting basic system check..." | tee -a "$LOGFILE"

check_cpu_usage
check_disk_space
check_outdated_apps
clean_unnecessary_files

echo "System check and cleanup completed." | tee -a "$LOGFILE"

# Send the report via email
send_email
