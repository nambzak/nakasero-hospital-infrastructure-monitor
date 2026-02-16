# Nakasero Hospital Infrastructure Monitoring System

![Version](https://img.shields.io/badge/version-2.0-blue)
![Status](https://img.shields.io/badge/status-production-green)
![License](https://img.shields.io/badge/license-MIT-orange)
![Python](https://img.shields.io/badge/python-3.8%2B-blue)
![Bash](https://img.shields.io/badge/bash-5.0%2B-lightgrey)

A comprehensive, real-time monitoring system for Nakasero Hospital's critical IT infrastructure. The system provides continuous ping-based monitoring, rich email alerts, and a web dashboard for visual status and host management.

---

## 📋 Quick Overview

| Feature | Description |
|---------|-------------|
| **Total Systems Monitored** | 52 critical hosts |
| **Monitoring Interval** | Every 60 seconds |
| **Alert Method** | Rich HTML emails via Zoho SMTP |
| **Dashboard Access** | Web-based on port 5000 |
| **Host Management** | Add/edit/delete via web interface |
| **Configuration** | Single JSON file |

---

## 🔍 What We Monitor

The system currently monitors **52 hosts** including:

| Category | Examples |
|----------|----------|
| **Storage** | EMC Storage Array (192.168.10.150) |
| **Virtualization** | ESXi Hosts, vSphere, Hyper-V Hosts |
| **Infrastructure** | Domain Controllers, DNS, File Servers |
| **Backup** | NHL-STAGE, VEEAM servers |
| **Medical Systems** | PACS, RIS, Radiology VMs, Cardiac Systems |
| **Applications** | Dynamics 365, Kranium, QLIK, Booking System |
| **Queue Systems** | Q-SYS servers (Main Reception, Insurance, PEAD) |
| **Print Services** | MYQ Print Server |

---

## ✨ Key Features

### 1. Real-Time Monitoring
- Continuous ping checks every 60 seconds
- Status displayed live on web dashboard
- Color-coded indicators (green = up, red = down)

### 2. Rich Email Alerts
When a critical system goes down:
- Detailed HTML email with:
  - Host name, IP, category
  - Detection time
  - 5 troubleshooting steps
  - Required actions checklist

When a system recovers:
- Recovery time
- Post-recovery verification checklist

### 3. Web Dashboard
- Live status of all 52 systems
- Search by name, IP, or purpose
- Filter by category and status
- Sort by criticality

### 4. Host Management
- Add new hosts via web form
- Edit existing host details
- Delete hosts no longer needed
- Enable/disable monitoring per host

### 5. Single Source of Truth
All hosts defined in one JSON file:
```json
{
  "hosts": [
    {
      "ip": "192.168.10.150",
      "name": "EMC Storage",
      "category": "Storage",
      "purpose": "Main storage array",
      "critical": true,
      "enabled": true
    }
  ]
}
```

🏗️ Architecture
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│                 │      │                 │      │                 │
│  JSON Config    │──────▶  Flask Dashboard│──────▶  Web Browser    │
│  (hosts.json)   │      │  (port 5000)    │      │                 │
│                 │      │                 │      │                 │
└────────┬────────┘      └─────────────────┘      └─────────────────┘
         │
         │ reads
         ▼
┌─────────────────┐      ┌─────────────────┐
│                 │      │                 │
│ Bash Monitor    │──────▶  Email Alerts   │
│ (ping every 60s)│      │ (Zoho SMTP)     │
│                 │      │                 │
└─────────────────┘      └─────────────────┘

Components:
Bash Monitor: /opt/hospital-monitor/ – pings hosts, sends alerts

Flask Dashboard: /opt/hospital-dashboard/ – web interface, host management

JSON Config: /opt/hospital-dashboard/config/hosts.json – single source of truth

Systemd Services: Auto-start on boot, auto-restart on failure

🚀 Quick Start (for IT Team)
Prerequisites
# Ubuntu 20.04/22.04 LTS
sudo apt update
sudo apt install -y python3 python3-pip jq mutt
sudo pip3 install flask psutil requests

One-Line Install (after cloning)
git clone https://github.com/[YOUR_USERNAME]/nakasero-hospital-infrastructure-monitor.git
cd nakasero-hospital-infrastructure-monitor
# Installation instructions will be added

Access the Dashboard
http://[SERVER-IP]:5000

📁 Repository Structure
nakasero-hospital-infrastructure-monitor/
├── monitor/                          # Monitoring scripts
│   ├── hospital-infra-monitor.sh     # Main monitoring script
│   ├── monitor_wrapper.sh             # Systemd wrapper
│   └── README.md                      # Monitor-specific docs
├── dashboard/                         # Flask web application
│   ├── app.py                          # Main Flask app
│   ├── config/
│   │   ├── hosts.json.example          # Example host configuration
│   │   └── README.md
│   ├── templates/                       # HTML templates
│   │   ├── index.html                    # Main dashboard
│   │   ├── manage_hosts.html             # Host management
│   │   ├── add_host.html                  # Add host form
│   │   └── edit_host.html                 # Edit host form
│   ├── static/
│   │   └── images/
│   │       └── nakasero-logo.png          # Hospital logo
│   └── README.md
├── docs/                               # Documentation
│   ├── phase2_documentation.pdf        # Full technical manual
│   ├── installation.md                  # Detailed install guide
│   ├── configuration.md                  # Configuration reference
│   └── troubleshooting.md                # Common issues
├── screenshots/                         # For README
│   ├── dashboard.png
│   ├── manage-hosts.png
│   └── email-alert.png
├── scripts/                             # Utility scripts
│   ├── backup.sh                         # Backup script
│   └── restore.sh                         # Restore script
├── install.sh                            # Automated installer
├── LICENSE                               # MIT License
└── README.md                             # This file



### 2. Rich Email Alerts
When a critical system goes down:
