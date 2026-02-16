#!/usr/bin/env python3
"""
Nakasero Hospital Dashboard - Phase 2
- Reads hosts from JSON config file
- Provides API for CRUD operations
"""

import os
import json
import datetime
import subprocess
from flask import Flask, jsonify, render_template, request, redirect, url_for

app = Flask(__name__)

# ==============================================
# PATHS
# ==============================================
MONITOR_DIR = "/opt/hospital-monitor"
STATE_FILE = os.path.join(MONITOR_DIR, "last_state.txt")
LOG_FILE = os.path.join(MONITOR_DIR, "monitor.log")
CONFIG_FILE = "/opt/hospital-dashboard/config/hosts.json"

# ==============================================
# HELPER FUNCTIONS
# ==============================================

def load_hosts():
    """Load hosts from JSON config file."""
    if not os.path.exists(CONFIG_FILE):
        return []
    with open(CONFIG_FILE, 'r') as f:
        data = json.load(f)
    return data.get('hosts', [])

def save_hosts(hosts):
    """Save hosts list to JSON config file."""
    # Ensure directory exists
    os.makedirs(os.path.dirname(CONFIG_FILE), exist_ok=True)
    with open(CONFIG_FILE, 'w') as f:
        json.dump({'hosts': hosts}, f, indent=2)

def get_host_by_ip(ip):
    """Return host dict for given IP, or None."""
    hosts = load_hosts()
    for host in hosts:
        if host['ip'] == ip:
            return host
    return None

def update_host(updated_host):
    """Replace existing host with updated one."""
    hosts = load_hosts()
    for i, host in enumerate(hosts):
        if host['ip'] == updated_host['ip']:
            hosts[i] = updated_host
            save_hosts(hosts)
            return True
    return False

def delete_host(ip):
    """Remove host by IP."""
    hosts = load_hosts()
    new_hosts = [h for h in hosts if h['ip'] != ip]
    if len(new_hosts) != len(hosts):
        save_hosts(new_hosts)
        return True
    return False

def get_server_ip():
    """Get this server's IP."""
    try:
        return subprocess.check_output(['hostname', '-I']).decode().split()[0].strip()
    except:
        return "Unknown"

def read_state_file():
    """Read status from last_state.txt."""
    status_map = {}
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE, 'r') as f:
            for line in f:
                line = line.strip()
                if ':' in line:
                    ip, status = line.split(':', 1)
                    status_map[ip.strip()] = status.strip()
    return status_map

# ==============================================
# ROUTES
# ==============================================

@app.route('/')
def index():
    """Main dashboard page."""
    return render_template('index.html')

# ------------------ API: Status ------------------
@app.route('/api/status')
def api_status():
    """Return full dashboard status."""
    hosts = load_hosts()
    status_map = read_state_file()
    
    enriched_hosts = []
    total = up = down = 0
    
    for host in hosts:
        if not host.get('enabled', True):
            continue
        ip = host['ip']
        status = status_map.get(ip, 'unknown')
        total += 1
        if status == 'up':
            up += 1
        elif status == 'down':
            down += 1
        
        enriched_hosts.append({
            'ip': ip,
            'name': host.get('name', ip),
            'category': host.get('category', 'Uncategorized'),
            'purpose': host.get('purpose', ''),
            'critical': host.get('critical', False),
            'status': status,
            'last_check': datetime.datetime.now().isoformat()
        })
    
    return jsonify({
        'last_updated': datetime.datetime.now().isoformat(),
        'summary': {
            'total': total,
            'up': up,
            'down': down,
            'unknown': total - up - down,
            'uptime_percentage': (up / total * 100) if total > 0 else 0
        },
        'hosts': enriched_hosts,
        'server': {
            'hostname': subprocess.check_output(['hostname']).decode().strip(),
            'ip': get_server_ip()
        }
    })

@app.route('/api/health')
def api_health():
    """Health check."""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.datetime.now().isoformat(),
        'phase': '2',
        'config_file': os.path.exists(CONFIG_FILE),
        'hosts_count': len(load_hosts())
    })

# ------------------ API: Host Management ------------------
@app.route('/api/hosts', methods=['GET'])
def api_get_hosts():
    """Return all hosts (full details)."""
    return jsonify(load_hosts())

@app.route('/api/hosts/<ip>', methods=['GET'])
def api_get_host(ip):
    """Return single host."""
    host = get_host_by_ip(ip)
    if host:
        return jsonify(host)
    return jsonify({'error': 'Host not found'}), 404

@app.route('/api/hosts', methods=['POST'])
def api_add_host():
    """Add a new host."""
    data = request.get_json()
    if not data or 'ip' not in data:
        return jsonify({'error': 'IP address required'}), 400
    
    # Check duplicate IP
    if get_host_by_ip(data['ip']):
        return jsonify({'error': 'Host with this IP already exists'}), 409
    
    # Ensure required fields
    new_host = {
        'ip': data['ip'],
        'name': data.get('name', data['ip']),
        'category': data.get('category', 'Other'),
        'purpose': data.get('purpose', ''),
        'critical': data.get('critical', False),
        'enabled': data.get('enabled', True),
        'type': data.get('type', 'Unknown'),
        'os': data.get('os', 'Unknown'),
        'location': data.get('location', 'Nakasero Hospital'),
        'department': data.get('department', 'IT'),
        'notes': data.get('notes', '')
    }
    
    hosts = load_hosts()
    hosts.append(new_host)
    save_hosts(hosts)
    return jsonify(new_host), 201

@app.route('/api/hosts/<ip>', methods=['PUT'])
def api_update_host(ip):
    """Update an existing host."""
    data = request.get_json()
    if not data:
        return jsonify({'error': 'No data provided'}), 400
    
    existing = get_host_by_ip(ip)
    if not existing:
        return jsonify({'error': 'Host not found'}), 404
    
    # If IP is being changed, check for duplicate
    new_ip = data.get('ip', ip)
    if new_ip != ip and get_host_by_ip(new_ip):
        return jsonify({'error': 'New IP already in use'}), 409
    
    updated = {
        'ip': new_ip,
        'name': data.get('name', existing['name']),
        'category': data.get('category', existing['category']),
        'purpose': data.get('purpose', existing['purpose']),
        'critical': data.get('critical', existing['critical']),
        'enabled': data.get('enabled', existing['enabled']),
        'type': data.get('type', existing.get('type', 'Unknown')),
        'os': data.get('os', existing.get('os', 'Unknown')),
        'location': data.get('location', existing.get('location', 'Nakasero Hospital')),
        'department': data.get('department', existing.get('department', 'IT')),
        'notes': data.get('notes', existing.get('notes', ''))
    }
    
    # If IP changed, remove old entry and add new
    if new_ip != ip:
        delete_host(ip)
        hosts = load_hosts()
        hosts.append(updated)
        save_hosts(hosts)
    else:
        update_host(updated)
    
    return jsonify(updated)

@app.route('/api/hosts/<ip>', methods=['DELETE'])
def api_delete_host(ip):
    """Delete a host."""
    if delete_host(ip):
        return jsonify({'success': True})
    return jsonify({'error': 'Host not found'}), 404

# ------------------ Web Interface for Host Management ------------------
@app.route('/manage')
def manage_hosts():
    """Host management page."""
    return render_template('manage_hosts.html')

@app.route('/add')
def add_host():
    """Add host form."""
    return render_template('add_host.html')

@app.route('/edit/<ip>')
def edit_host(ip):
    """Edit host form."""
    host = get_host_by_ip(ip)
    if not host:
        return "Host not found", 404
    return render_template('edit_host.html', host=host)

# ==============================================
# MAIN
# ==============================================
if __name__ == '__main__':
    print("=" * 60)
    print("🏥 NAKASERO HOSPITAL DASHBOARD - PHASE 2")
    print("=" * 60)
    print(f"📁 Config file: {CONFIG_FILE}")
    print(f"📄 Hosts loaded: {len(load_hosts())}")
    print(f"🌐 Dashboard URL: http://0.0.0.0:5000")
    print("=" * 60)
    app.run(host='0.0.0.0', port=5000, debug=False)
