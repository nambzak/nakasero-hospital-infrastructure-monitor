#!/bin/bash

# ==============================================
# Hospital Infrastructure Monitoring Script
# Version: 3.0 – Rich email alerts, per-host details
# ==============================================

# ----------------------------------------------------------------------
# CONFIGURATION – EDIT YOUR EMAIL PASSWORD HERE
# ----------------------------------------------------------------------
SMTP_SERVER="smtppro.zoho.com"
SMTP_PORT="465"
EMAIL_FROM="isaac.nambafu@nakaserohospital.com"
EMAIL_USER="isaac.nambafu@nakaserohospital.com"
EMAIL_PASS=""   # <--- UPDATE WITH YOUR ACTUAL SMTP SETTINGS

RECIPIENTS=(
    "isaacnbfu@gmail.com"
    "gerald.balitwawula@nhl.co.ug"
    "nhlitinternal@nakaserohospital.com"
    "sydney.nahamya@nakaserohospital.com"
)

# ----------------------------------------------------------------------
# PATHS
# ----------------------------------------------------------------------
MONITOR_DIR="/opt/hospital-monitor"
LOG_FILE="$MONITOR_DIR/monitor.log"
STATE_FILE="$MONITOR_DIR/last_state.txt"
HISTORY_FILE="$MONITOR_DIR/history.log"
RECENT_CHANGES="$MONITOR_DIR/recent_changes.tmp"
DEBUG_LOG="$MONITOR_DIR/debug.log"
CONFIG_FILE="/opt/hospital-dashboard/config/hosts.json"

# ----------------------------------------------------------------------
# COLORS (for console output)
# ----------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ----------------------------------------------------------------------
# CHECK DEPENDENCIES
# ----------------------------------------------------------------------
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is not installed. Please run: sudo apt install jq"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file $CONFIG_FILE not found!"
    exit 1
fi

# ----------------------------------------------------------------------
# LOAD HOSTS FROM JSON – STORE DETAILS IN ASSOCIATIVE ARRAYS
# ----------------------------------------------------------------------
declare -A HOST_NAME     # ip -> name
declare -A HOST_CATEGORY  # ip -> category
declare -A HOST_CRITICAL  # ip -> true/false
ALL_HOSTS=()              # list of "name:ip" for iteration

load_hosts_from_json() {
    while IFS= read -r line; do
        ip=$(echo "$line" | jq -r '.ip')
        name=$(echo "$line" | jq -r '.name')
        category=$(echo "$line" | jq -r '.category')
        critical=$(echo "$line" | jq -r '.critical // false')
        enabled=$(echo "$line" | jq -r '.enabled // true')
        if [ "$enabled" = "true" ]; then
            HOST_NAME["$ip"]="$name"
            HOST_CATEGORY["$ip"]="$category"
            HOST_CRITICAL["$ip"]="$critical"
            ALL_HOSTS+=("$name:$ip")
        fi
    done < <(jq -c '.hosts[]' "$CONFIG_FILE")
}

load_hosts_from_json

if [ ${#ALL_HOSTS[@]} -eq 0 ]; then
    echo "ERROR: No hosts to monitor. Check $CONFIG_FILE" | tee -a "$DEBUG_LOG"
    exit 1
fi

echo "[$(date)] Loaded ${#ALL_HOSTS[@]} hosts from JSON config" >> "$DEBUG_LOG"

# ----------------------------------------------------------------------
# LOGGING FUNCTIONS
# ----------------------------------------------------------------------
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_history() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$HISTORY_FILE"
}

# ----------------------------------------------------------------------
# EMAIL FUNCTION (using mutt)
# ----------------------------------------------------------------------
send_email() {
    local subject="$1"
    local body="$2"
    local to_emails=$(printf ",%s" "${RECIPIENTS[@]}")
    to_emails=${to_emails:1}

    if command -v mutt &> /dev/null; then
        echo "$body" | mutt -e "set content_type=text/html" -s "$subject" "$to_emails"
        if [ $? -eq 0 ]; then
            log_message "Email sent: $subject"
        else
            log_message "FAILED to send email: $subject"
        fi
    else
        log_message "ERROR: mutt not installed – cannot send email"
    fi
}

# ----------------------------------------------------------------------
# HOST CHECK FUNCTION (ping with retry)
# ----------------------------------------------------------------------
check_host() {
    local ip="$1"
    local retries=2
    local timeout=2

    for ((i=1; i<=retries; i++)); do
        if ping -c 1 -W $timeout "$ip" > /dev/null 2>&1; then
            echo "up"
            return 0
        fi
        sleep 1
    done
    echo "down"
}

# ----------------------------------------------------------------------
# LOAD / SAVE STATE
# ----------------------------------------------------------------------
declare -A PREV_STATE
load_previous_state() {
    if [ -f "$STATE_FILE" ]; then
        while IFS=':' read -r ip state; do
            PREV_STATE["$ip"]="$state"
        done < "$STATE_FILE"
    fi
}

save_current_state() {
    > "$STATE_FILE"
    for ip in "${!PREV_STATE[@]}"; do
        echo "$ip:${PREV_STATE[$ip]}" >> "$STATE_FILE"
    done
}

# ----------------------------------------------------------------------
# DISPLAY STATUS (console)
# ----------------------------------------------------------------------
show_status() {
    clear
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}   HOSPITAL INFRASTRUCTURE MONITOR${NC}"
    echo -e "${CYAN}   $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""

    local all_up=true
    for host_entry in "${ALL_HOSTS[@]}"; do
        local name="${host_entry%:*}"
        local ip="${host_entry#*:}"
        local status="${PREV_STATE[$ip]:-unknown}"

        if [ "$status" = "up" ]; then
            echo -e "  ${GREEN}✓ $name${NC}"
            echo -e "     ${GREEN}$ip - ONLINE${NC}"
        elif [ "$status" = "down" ]; then
            echo -e "  ${RED}✗ $name${NC}"
            echo -e "     ${RED}$ip - OFFLINE${NC}"
            all_up=false
        else
            echo -e "  ${YELLOW}? $name${NC}"
            echo -e "     ${YELLOW}$ip - UNKNOWN${NC}"
        fi
        echo ""
    done

    if [ "$all_up" = false ]; then
        echo -e "\n${RED}⚠️  Some systems are offline!${NC}"
    fi
    echo -e "${CYAN}===============================================${NC}"
}

# ----------------------------------------------------------------------
# INDIVIDUAL HOST ALERT (for critical hosts)
# ----------------------------------------------------------------------
send_individual_alert() {
    local host_name="$1"
    local ip="$2"
    local status="$3"  # "down" or "up"
    local category="${HOST_CATEGORY[$ip]:-Uncategorized}"
    local critical="${HOST_CRITICAL[$ip]:-false}"

    local subject
    local body

    if [ "$status" = "down" ]; then
        if [ "$critical" = "true" ]; then
            subject="🚨🚨 CRITICAL ALERT: $host_name ($ip) - OFFLINE"
        else
            subject="⚠️ ALERT: $host_name ($ip) - OFFLINE"
        fi

        body="<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        .alert-header { background-color: #dc3545; color: white; padding: 20px; border-radius: 5px 5px 0 0; }
        .info-box { padding: 20px; border: 2px solid #dc3545; margin: 0; border-radius: 0 0 5px 5px; }
        .details { background-color: #f8f9fa; padding: 15px; margin: 15px 0; border-left: 4px solid #6c757d; }
        .actions { background-color: #fff3cd; padding: 15px; border: 1px solid #ffc107; }
    </style>
</head>
<body>
    <div class='alert-header'>
        <h2>🔴 HOST OFFLINE DETECTED</h2>
        <h3>$host_name</h3>
    </div>
    
    <div class='info-box'>
        <h3>📋 Host Details:</h3>
        <table border='0' cellpadding='8'>
            <tr><td><strong>Host Name:</strong></td><td>$host_name</td></tr>
            <tr><td><strong>IP Address:</strong></td><td>$ip</td></tr>
            <tr><td><strong>Category:</strong></td><td>$category</td></tr>
            <tr><td><strong>Status:</strong></td><td><span style='color: #dc3545; font-weight: bold;'>OFFLINE</span></td></tr>
            <tr><td><strong>Detection Time:</strong></td><td>$(date '+%Y-%m-%d %H:%M:%S')</td></tr>
            <tr><td><strong>Monitoring Host:</strong></td><td>$(hostname)</td></tr>
        </table>
        
        <div class='details'>
            <h4>🔍 Immediate Troubleshooting:</h4>
            <ol>
                <li>Check physical connectivity and power to the host</li>
                <li>Verify network switch port status</li>
                <li>Check if host is responsive via console/ILO</li>
                <li>Review recent changes or maintenance</li>
                <li>Check for alerts in virtualization management</li>
            </ol>
        </div>
        
        <div class='actions'>
            <h4>🚀 Required Actions:</h4>
            <ul>
                <li>Document incident in IT service log</li>
                <li>Check dependent services and systems</li>
                <li>Initiate recovery procedures</li>
                <li>Notify relevant department if service affected</li>
            </ul>
        </div>
    </div>
    
    <p style='color: #6c757d; font-size: 11px; margin-top: 20px;'>
        <em>Automated alert from Nakasero Hospital Infrastructure Monitoring System</em>
    </p>
</body>
</html>"
    else
        # Recovery
        subject="✅ RECOVERY: $host_name ($ip) - BACK ONLINE"
        body="<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        .recovery-header { background-color: #28a745; color: white; padding: 20px; border-radius: 5px 5px 0 0; }
        .info-box { padding: 20px; border: 2px solid #28a745; margin: 0; border-radius: 0 0 5px 5px; }
        .verification { background-color: #d4edda; padding: 15px; margin: 15px 0; }
    </style>
</head>
<body>
    <div class='recovery-header'>
        <h2>✅ HOST RECOVERY DETECTED</h2>
        <h3>$host_name</h3>
    </div>
    
    <div class='info-box'>
        <h3>📋 Recovery Details:</h3>
        <table border='0' cellpadding='8'>
            <tr><td><strong>Host Name:</strong></td><td>$host_name</td></tr>
            <tr><td><strong>IP Address:</strong></td><td>$ip</td></tr>
            <tr><td><strong>Category:</strong></td><td>$category</td></tr>
            <tr><td><strong>Status:</strong></td><td><span style='color: #28a745; font-weight: bold;'>ONLINE</span></td></tr>
            <tr><td><strong>Recovery Time:</strong></td><td>$(date '+%Y-%m-%d %H:%M:%S')</td></tr>
            <tr><td><strong>Downtime Duration:</strong></td><td>Calculating...</td></tr>
        </table>
        
        <div class='verification'>
            <h4>🔍 Post-Recovery Verification:</h4>
            <ol>
                <li>Verify all services on the host are running</li>
                <li>Check system logs for error messages</li>
                <li>Monitor system stability for next 30 minutes</li>
                <li>Update incident documentation with recovery details</li>
                <li>Communicate recovery to affected departments</li>
            </ol>
        </div>
    </div>
    
    <p style='color: #6c757d; font-size: 11px; margin-top: 20px;'>
        <em>Automated recovery notification from Nakasero Hospital Infrastructure Monitoring System</em>
    </p>
</body>
</html>"
    fi

    send_email "$subject" "$body"
}

# ----------------------------------------------------------------------
# BATCH ALERT (for multiple non-critical hosts)
# ----------------------------------------------------------------------
send_batch_alert() {
    local down_hosts_list="$1"
    local recovered_hosts_list="$2"
    if [ -z "$down_hosts_list" ] && [ -z "$recovered_hosts_list" ]; then
        return 0
    fi

    local subject=""
    local body=""

    if [ -n "$down_hosts_list" ] && [ -n "$recovered_hosts_list" ]; then
        subject="🔄 MIXED STATUS UPDATE: Multiple Hosts Changed State"
    elif [ -n "$down_hosts_list" ]; then
        subject="⚠️ MULTIPLE HOSTS OFFLINE"
    else
        subject="✅ MULTIPLE HOSTS RECOVERED"
    fi

    body="<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        .header { padding: 20px; color: white; border-radius: 5px 5px 0 0; }
        .mixed { background-color: #ffc107; color: black; }
        .down { background-color: #dc3545; }
        .recovered { background-color: #28a745; }
        .content { padding: 20px; border: 1px solid #dee2e6; border-radius: 0 0 5px 5px; }
        .section { margin: 15px 0; padding: 15px; border-radius: 5px; }
        .down-section { background-color: #f8d7da; border: 1px solid #f5c6cb; }
        .recovered-section { background-color: #d4edda; border: 1px solid #c3e6cb; }
    </style>
</head>
<body>"

    if [ -n "$down_hosts_list" ] && [ -n "$recovered_hosts_list" ]; then
        body+="<div class='header mixed'><h2>🔄 MULTIPLE STATUS CHANGES DETECTED</h2></div>"
    elif [ -n "$down_hosts_list" ]; then
        body+="<div class='header down'><h2>⚠️ MULTIPLE HOSTS OFFLINE</h2></div>"
    else
        body+="<div class='header recovered'><h2>✅ MULTIPLE HOSTS RECOVERED</h2></div>"
    fi

    body+="<div class='content'>
            <p><strong>Detection Time:</strong> $(date '+%Y-%m-%d %H:%M:%S')</p>"

    if [ -n "$down_hosts_list" ]; then
        body+="<div class='section down-section'>
                <h3>🔴 Systems Currently OFFLINE:</h3>
                $down_hosts_list
              </div>"
    fi

    if [ -n "$recovered_hosts_list" ]; then
        body+="<div class='section recovered-section'>
                <h3>🟢 Systems That Recovered:</h3>
                $recovered_hosts_list
              </div>"
    fi

    body+="</div>
</body>
</html>"

    send_email "$subject" "$body"
}

# ----------------------------------------------------------------------
# LOAD PREVIOUS STATE
# ----------------------------------------------------------------------
load_previous_state

# ----------------------------------------------------------------------
# MAIN MONITORING LOOP
# ----------------------------------------------------------------------
monitor_loop() {
    declare -A CURRENT_STATE
    declare -A ALERT_SENT
    declare -A LAST_ALERT_TIME

    # Initialize alert tracking
    for host_entry in "${ALL_HOSTS[@]}"; do
        local ip="${host_entry#*:}"
        ALERT_SENT["$ip"]="false"
        LAST_ALERT_TIME["$ip"]=0
    done

    while true; do
        local down_hosts=()
        local recovered_hosts=()
        local down_html=""
        local recovered_html=""
        local current_time=$(date +%s)

        # Check each host
        for host_entry in "${ALL_HOSTS[@]}"; do
            local name="${host_entry%:*}"
            local ip="${host_entry#*:}"
            local status=$(check_host "$ip")

            CURRENT_STATE["$ip"]="$status"
            local prev_status="${PREV_STATE[$ip]:-unknown}"

            if [ "$status" != "$prev_status" ]; then
                if [ "$status" = "down" ]; then
                    # Host went down
                    log_message "ALERT: $name ($ip) went DOWN"
                    if [ "${HOST_CRITICAL[$ip]}" = "true" ]; then
                        # Send individual detailed alert for critical hosts
                        send_individual_alert "$name" "$ip" "down"
                    else
                        # Collect for batch alert
                        down_hosts+=("$name ($ip)")
                        down_html+="<li><strong>$name</strong> ($ip) - ${HOST_CATEGORY[$ip]}</li>"
                    fi
                    ALERT_SENT["$ip"]="true"
                    LAST_ALERT_TIME["$ip"]=$current_time
                elif [ "$status" = "up" ] && [ "$prev_status" = "down" ]; then
                    # Host recovered
                    log_message "RECOVERY: $name ($ip) is back UP"
                    if [ "${HOST_CRITICAL[$ip]}" = "true" ]; then
                        # Send individual detailed recovery for critical hosts
                        send_individual_alert "$name" "$ip" "up"
                    else
                        # Collect for batch alert
                        recovered_hosts+=("$name ($ip)")
                        recovered_html+="<li><strong>$name</strong> ($ip) - ${HOST_CATEGORY[$ip]}</li>"
                    fi
                    ALERT_SENT["$ip"]="false"
                fi
            elif [ "$status" = "down" ] && [ "${ALERT_SENT[$ip]}" = "true" ]; then
                # Still down, send reminder every hour
                local time_since=$((current_time - LAST_ALERT_TIME[$ip]))
                if [ $time_since -ge 3600 ]; then
                    log_message "REMINDER: $name ($ip) still DOWN"
                    if [ "${HOST_CRITICAL[$ip]}" = "true" ]; then
                        # Send reminder for critical hosts (maybe with different subject)
                        send_individual_alert "$name" "$ip" "down"  # reuse down alert
                    else
                        down_hosts+=("$name ($ip) - STILL DOWN")
                        down_html+="<li><strong>$name</strong> ($ip) – still down after 1 hour</li>"
                    fi
                    LAST_ALERT_TIME["$ip"]=$current_time
                fi
            fi

            # Update previous state
            PREV_STATE["$ip"]="$status"
        done

        # Display status on console
        show_status

        # Send batch alerts for non-critical hosts
        if [ ${#down_hosts[@]} -gt 0 ] || [ ${#recovered_hosts[@]} -gt 0 ]; then
            send_batch_alert "$down_html" "$recovered_html"
        fi

        # Save current state to file
        save_current_state

        # Wait 60 seconds
        sleep 60
    done
}

# ----------------------------------------------------------------------
# TRAP CLEAN EXIT
# ----------------------------------------------------------------------
trap 'log_message "Monitoring stopped by user"; echo -e "\n${YELLOW}Stopped.${NC}"; exit 0' INT TERM

# ----------------------------------------------------------------------
# START MONITORING
# ----------------------------------------------------------------------
log_message "=========================================="
log_message "Hospital Infrastructure Monitor starting"
log_message "Monitoring ${#ALL_HOSTS[@]} hosts from JSON config"
log_message "Config file: $CONFIG_FILE"
log_message "=========================================="

monitor_loop
