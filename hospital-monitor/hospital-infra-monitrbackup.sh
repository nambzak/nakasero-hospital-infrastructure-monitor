#!/bin/bash

# Hospital Infrastructure Monitoring Script
# Author: IT Department - Nakasero Hospital
# Description: Monitors critical infrastructure and sends alerts

# Configuration
HOSTS=(
    "EMC Storage:192.168.10.150"
    "ESXi Host 1:192.168.10.54"
    "ESXi Host 2:192.168.10.80"
    "vSphere:192.168.10.88"
)

# Email Configuration
SMTP_SERVER="smtppro.zoho.com"
SMTP_PORT="465"
EMAIL_FROM="isaac.nambafu@nakaserohospital.com"
EMAIL_USER="isaac.nambafu@nakaserohospital.com"
EMAIL_PASS="MAzdaxxxx5555"  # UPDATE WITH ACTUAL PASSWORD

# Recipients (comma-separated for mutt)
RECIPIENTS="isaacnbfu@gmail.com,gerald.balitwawula@nhl.co.ug,nhlitinternal@nakaserohospital.com,sydney.nahamya@nakaserohospital.com"

# Working directory
WORK_DIR="/opt/hospital-monitor"
LOG_FILE="$WORK_DIR/monitor.log"
STATE_FILE="$WORK_DIR/last_state.txt"
INITIAL_SENT_FILE="$WORK_DIR/initial_sent.flag"
CONFIG_FILE="$WORK_DIR/monitor.conf"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create working directory
mkdir -p "$WORK_DIR"
touch "$LOG_FILE"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to install required packages
install_dependencies() {
    log_message "Checking dependencies..."
    
    # Check for mutt (email client)
    if ! command -v mutt &> /dev/null; then
        echo "Installing mutt for email notifications..."
        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y mutt
        elif command -v yum &> /dev/null; then
            yum install -y mutt
        elif command -v dnf &> /dev/null; then
            dnf install -y mutt
        else
            echo "ERROR: Cannot install mutt. Please install manually."
            exit 1
        fi
    fi
    
    # Check for ping
    if ! command -v ping &> /dev/null; then
        echo "ERROR: ping command not found!"
        exit 1
    fi
    
    log_message "Dependencies check completed"
}

# Function to create email configuration
setup_email_config() {
    # Create mutt configuration
    cat > ~/.muttrc << EOF
set from = "$EMAIL_FROM"
set realname = "Hospital Infrastructure Monitor"
set smtp_url = "smtps://$EMAIL_USER:$EMAIL_PASS@$SMTP_SERVER:$SMTP_PORT"
set smtp_pass = "$EMAIL_PASS"
set content_type = "text/html"
EOF
    
    chmod 600 ~/.muttrc
    log_message "Email configuration created"
}

# Function to send email
send_email() {
    local subject="$1"
    local body="$2"
    local is_initial="$3"
    
    # For initial email, we'll use a simpler method to ensure it sends
    if [ "$is_initial" = "true" ]; then
        # Create a temporary file for email
        local temp_email="/tmp/initial_email_$(date +%s).html"
        cat > "$temp_email" << EOF
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; }
        .header { background-color: #2c3e50; color: white; padding: 20px; }
        .content { padding: 20px; }
        .systems { background-color: #f8f9fa; padding: 15px; border-left: 4px solid #3498db; }
        .footer { margin-top: 30px; padding-top: 15px; border-top: 1px solid #eee; font-size: 12px; color: #7f8c8d; }
    </style>
</head>
<body>
    <div class="header">
        <h2>🏥 Hospital Infrastructure Monitoring System</h2>
    </div>
    
    <div class="content">
        <p><strong>Dear IT Team,</strong></p>
        
        <p>This is an automated notification to inform you that infrastructure monitoring has been activated for the following critical systems:</p>
        
        <div class="systems">
            <h3>🔧 Systems Being Monitored:</h3>
            <ul>
                <li><strong>EMC Storage:</strong> 192.168.10.150</li>
                <li><strong>ESXi Host 1:</strong> 192.168.10.54</li>
                <li><strong>ESXi Host 2:</strong> 192.168.10.80</li>
                <li><strong>vSphere Management:</strong> 192.168.10.88</li>
            </ul>
        </div>
        
        <p><strong>Network Information:</strong></p>
        <ul>
            <li>DNS Server: 192.168.10.16</li>
            <li>Default Gateway: 10.4.0.1</li>
        </ul>
        
        <p><strong>⚠️ Important:</strong> You will only receive further automated emails if any of these critical systems become unreachable.</p>
        
        <p>Monitoring initiated at: $(date '+%Y-%m-%d %H:%M:%S')<br>
        Monitoring host: $(hostname)</p>
    </div>
    
    <div class="footer">
        <p><em>This is an automated message from the Hospital Infrastructure Monitoring System.<br>
        Please do not reply to this email. For issues with monitoring, contact IT support.</em></p>
    </div>
</body>
</html>
EOF
        
        # Try multiple methods to send email
        local email_sent=false
        
        # Method 1: Using mutt (preferred)
        if command -v mutt &> /dev/null; then
            if echo "$body" | mutt -e "set content_type=text/html" -s "$subject" "$RECIPIENTS" < "$temp_email"; then
                email_sent=true
                log_message "Initial notification sent via mutt"
            fi
        fi
        
        # Method 2: Using mail command (fallback)
        if [ "$email_sent" = false ] && command -v mail &> /dev/null; then
            echo -e "Subject: $subject\nContent-Type: text/html\n\n$(cat $temp_email)" | \
            mail -s "$subject" -a "Content-Type: text/html" "$RECIPIENTS"
            if [ $? -eq 0 ]; then
                email_sent=true
                log_message "Initial notification sent via mail"
            fi
        fi
        
        # Method 3: Using sendmail (fallback)
        if [ "$email_sent" = false ] && command -v sendmail &> /dev/null; then
            (
                echo "To: $RECIPIENTS"
                echo "Subject: $subject"
                echo "Content-Type: text/html"
                echo ""
                cat "$temp_email"
            ) | sendmail -t
            if [ $? -eq 0 ]; then
                email_sent=true
                log_message "Initial notification sent via sendmail"
            fi
        fi
        
        rm -f "$temp_email"
        
        if [ "$email_sent" = true ]; then
            touch "$INITIAL_SENT_FILE"
            return 0
        else
            return 1
        fi
        
    else
        # For alert emails
        if command -v mutt &> /dev/null; then
            echo "$body" | mutt -e "set content_type=text/html" -s "$subject" "$RECIPIENTS"
            if [ $? -eq 0 ]; then
                log_message "Alert email sent"
                return 0
            else
                log_message "Failed to send alert email"
                return 1
            fi
        else
            log_message "ERROR: mutt not available for sending alerts"
            return 1
        fi
    fi
}

# Function to check host connectivity
check_host() {
    local ip="$1"
    
    # Use ping with 2 packets, 2 second timeout
    if ping -c 2 -W 2 "$ip" > /dev/null 2>&1; then
        echo "up"
    else
        echo "down"
    fi
}

# Function to display current status
show_status() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}    HOSPITAL INFRASTRUCTURE MONITOR${NC}"
    echo -e "${BLUE}    $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${BLUE}=================================================${NC}"
    echo ""
    
    local all_up=true
    
    for host_info in "${HOSTS[@]}"; do
        local name="${host_info%:*}"
        local ip="${host_info#*:}"
        local status=$(check_host "$ip")
        
        if [ "$status" = "up" ]; then
            echo -e "  ${GREEN}✓ $name${NC}"
            echo -e "     ${GREEN}$ip - ONLINE${NC}"
        else
            echo -e "  ${RED}✗ $name${NC}"
            echo -e "     ${RED}$ip - OFFLINE${NC}"
            all_up=false
        fi
        echo ""
    done
    
    echo -e "${BLUE}Network Infrastructure:${NC}"
    echo -e "  DNS Server: 192.168.10.16"
    echo -e "  Gateway: 10.4.0.1"
    echo ""
    echo -e "${YELLOW}Monitoring host: $(hostname)${NC}"
    echo -e "${YELLOW}Next check in 60 seconds${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    if [ "$all_up" = false ]; then
        echo -e "\n${RED}⚠️  CRITICAL: Some systems are offline!${NC}"
    fi
}

# Function to send alert email
send_alert_email() {
    local down_hosts_list="$1"
    
    local subject="🚨 CRITICAL ALERT: Hospital Infrastructure Systems DOWN"
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')
    local monitoring_host=$(hostname)
    
    local body="<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; }
        .critical { background-color: #ff4444; color: white; padding: 20px; }
        .content { padding: 20px; border: 2px solid #ff4444; margin: 20px 0; }
        .systems { background-color: #fff3cd; padding: 15px; border-left: 4px solid #856404; }
        .info { background-color: #e3f2fd; padding: 15px; }
        .footer { font-size: 12px; color: #666; margin-top: 30px; }
    </style>
</head>
<body>
    <div class='critical'>
        <h1>🚨 CRITICAL INFRASTRUCTURE ALERT</h1>
        <h2>Hospital Critical Systems Unreachable</h2>
    </div>
    
    <div class='content'>
        <p><strong>Time of Detection:</strong> $current_time</p>
        <p><strong>Monitoring Server:</strong> $monitoring_host</p>
        
        <div class='systems'>
            <h3>⚠️ Affected Systems:</h3>
            $down_hosts_list
        </div>
        
        <div class='info'>
            <h3>📡 Network Information:</h3>
            <ul>
                <li>DNS Server: 192.168.10.16</li>
                <li>Default Gateway: 10.4.0.1</li>
                <li>Network Segment: Hospital LAN</li>
            </ul>
            
            <h3>🛠️ Immediate Actions Required:</h3>
            <ol>
                <li>Check physical connections to affected systems</li>
                <li>Verify power supply to servers</li>
                <li>Check network switch connectivity</li>
                <li>Contact on-call infrastructure engineer</li>
            </ol>
        </div>
    </div>
    
    <div class='footer'>
        <p><em>This is an automated alert from the Hospital Infrastructure Monitoring System.<br>
        Sent to: IT Management Team - Nakasero Hospital</em></p>
    </div>
</body>
</html>"
    
    send_email "$subject" "$body" "false"
}

# Function to send recovery email
send_recovery_email() {
    local recovered_hosts="$1"
    
    local subject="✅ RECOVERY: Hospital Infrastructure Systems RESTORED"
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    local body="<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; }
        .recovery { background-color: #28a745; color: white; padding: 20px; }
        .content { padding: 20px; }
        .footer { font-size: 12px; color: #666; margin-top: 30px; }
    </style>
</head>
<body>
    <div class='recovery'>
        <h1>✅ INFRASTRUCTURE RECOVERY NOTIFICATION</h1>
        <h2>Hospital Systems Back Online</h2>
    </div>
    
    <div class='content'>
        <p><strong>Recovery Time:</strong> $current_time</p>
        
        <h3>🎉 Restored Systems:</h3>
        $recovered_hosts
        
        <p><strong>All critical hospital infrastructure systems are now operational.</strong></p>
        
        <p><em>No further action required. This is an automated recovery notification.</em></p>
    </div>
    
    <div class='footer'>
        <p><em>Hospital Infrastructure Monitoring System<br>
        Nakasero Hospital IT Department</em></p>
    </div>
</body>
</html>"
    
    send_email "$subject" "$body" "false"
}

# Function to send initial notification
send_initial_notification() {
    if [ -f "$INITIAL_SENT_FILE" ]; then
        log_message "Initial notification already sent"
        return 0
    fi
    
    log_message "Sending initial notification to all recipients..."
    
    local subject="🏥 INITIAL NOTIFICATION: Hospital Infrastructure Monitoring Activated"
    
    # Create HTML body for initial email
    local body="initial"  # Placeholder, actual HTML created in send_email function
    
    if send_email "$subject" "$body" "true"; then
        log_message "Initial notification sent successfully to all recipients"
        return 0
    else
        log_message "ERROR: Failed to send initial notification"
        return 1
    fi
}

# Function to load previous state
load_previous_state() {
    declare -gA PREV_STATE
    if [ -f "$STATE_FILE" ]; then
        while IFS=':' read -r ip state; do
            PREV_STATE["$ip"]="$state"
        done < "$STATE_FILE"
    fi
}

# Function to save current state
save_current_state() {
    > "$STATE_FILE"
    for host_info in "${HOSTS[@]}"; do
        local ip="${host_info#*:}"
        local current_state="${CURRENT_STATE[$ip]}"
        echo "$ip:$current_state" >> "$STATE_FILE"
    done
}

# Main monitoring function
monitor_loop() {
    log_message "Starting monitoring loop"
    
    declare -A CURRENT_STATE
    declare -A ALERT_SENT
    declare -A LAST_ALERT_TIME
    
    # Initialize alert tracking
    for host_info in "${HOSTS[@]}"; do
        local ip="${host_info#*:}"
        ALERT_SENT["$ip"]="false"
        LAST_ALERT_TIME["$ip"]=0
    done
    
    while true; do
        local down_hosts=()
        local recovered_hosts=()
        local current_time=$(date +%s)
        
        # Check each host
        for host_info in "${HOSTS[@]}"; do
            local name="${host_info%:*}"
            local ip="${host_info#*:}"
            local status=$(check_host "$ip")
            
            CURRENT_STATE["$ip"]="$status"
            
            # Check if status changed
            local prev_status="${PREV_STATE[$ip]}"
            
            if [ "$status" = "down" ] && [ "$prev_status" != "down" ]; then
                # Host just went down
                down_hosts+=("$name ($ip)")
                ALERT_SENT["$ip"]="true"
                LAST_ALERT_TIME["$ip"]=$current_time
                log_message "ALERT: $name ($ip) went DOWN"
                
            elif [ "$status" = "up" ] && [ "$prev_status" = "down" ]; then
                # Host recovered
                recovered_hosts+=("$name ($ip)")
                ALERT_SENT["$ip"]="false"
                log_message "RECOVERY: $name ($ip) is back UP"
                
            elif [ "$status" = "down" ] && [ "${ALERT_SENT[$ip]}" = "true" ]; then
                # Host still down, check if we need to resend alert (after 1 hour)
                local time_since_alert=$((current_time - LAST_ALERT_TIME[$ip]))
                if [ $time_since_alert -ge 3600 ]; then
                    down_hosts+=("$name ($ip) - STILL DOWN")
                    LAST_ALERT_TIME["$ip"]=$current_time
                    log_message "REMINDER: $name ($ip) still DOWN for over 1 hour"
                fi
            fi
        done
        
        # Display status
        show_status
        
        # Send alerts if needed
        if [ ${#down_hosts[@]} -gt 0 ]; then
            local down_list_html="<ul>"
            for host in "${down_hosts[@]}"; do
                down_list_html+="<li><strong>$host</strong></li>"
            done
            down_list_html+="</ul>"
            
            send_alert_email "$down_list_html"
        fi
        
        # Send recovery notifications if needed
        if [ ${#recovered_hosts[@]} -gt 0 ]; then
            local recovered_list_html="<ul>"
            for host in "${recovered_hosts[@]}"; do
                recovered_list_html+="<li><strong>$host</strong></li>"
            done
            recovered_list_html+="</ul>"
            
            send_recovery_email "$recovered_list_html"
        fi
        
        # Update previous state
        for ip in "${!CURRENT_STATE[@]}"; do
            PREV_STATE["$ip"]="${CURRENT_STATE[$ip]}"
        done
        
        save_current_state
        
        # Wait for next check (60 seconds)
        sleep 60
    done
}

# Main execution
main() {
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}    Hospital Infrastructure Monitor${NC}"
    echo -e "${BLUE}    Starting up...${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}Warning: Not running as root. Some features may not work.${NC}"
    fi
    
    # Install dependencies
    install_dependencies
    
    # Setup email configuration
    setup_email_config
    
    # Load previous state
    load_previous_state
    
    # Send initial notification
    echo -e "\n${YELLOW}Sending initial notification to recipients...${NC}"
    send_initial_notification
    
    # Start monitoring
    echo -e "\n${GREEN}Starting continuous monitoring...${NC}"
    echo -e "${GREEN}Initial notification sent to:${NC}"
    echo "$RECIPIENTS" | tr ',' '\n' | while read email; do
        echo "  - $email"
    done
    
    monitor_loop
}

# Trap Ctrl+C for clean exit
trap 'log_message "Monitoring stopped by user"; echo -e "\n${YELLOW}Monitoring stopped.${NC}"; exit 0' INT TERM

# Run main function
main
