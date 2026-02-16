#!/bin/bash
# Wrapper for hospital-infra-monitor.sh
# Reads hosts from dashboard config and exports as HOSTS array

CONFIG_FILE="/opt/hospital-dashboard/config/hosts.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Dashboard config not found at $CONFIG_FILE"
    exit 1
fi

# Parse JSON and build HOSTS array
HOSTS=()
while IFS= read -r line; do
    name=$(echo "$line" | jq -r '.name')
    ip=$(echo "$line" | jq -r '.ip')
    enabled=$(echo "$line" | jq -r '.enabled // true')
    if [ "$enabled" = "true" ]; then
        HOSTS+=("$name:$ip")
    fi
done < <(jq -c '.hosts[]' "$CONFIG_FILE")

export HOSTS

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Monitor wrapper: loaded ${#HOSTS[@]} hosts from dashboard config" >> /opt/hospital-monitor/wrapper.log

# Now run the original script
exec /opt/hospital-monitor/hospital-infra-monitor.sh
