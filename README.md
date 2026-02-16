# 🏥 Nakasero Hospital Infrastructure Monitoring System

![Version](https://img.shields.io/badge/version-2.0-blue)
![Status](https://img.shields.io/badge/status-production-green)
![License](https://img.shields.io/badge/license-MIT-orange)
![Python](https://img.shields.io/badge/python-3.8%2B-blue)
![Bash](https://img.shields.io/badge/bash-5.0%2B-lightgrey)
![Monitoring](https://img.shields.io/badge/monitoring-52%20hosts-success)

A comprehensive, real-time monitoring system for Nakasero Hospital's critical IT infrastructure. The system provides continuous ping-based monitoring, rich email alerts, and a web dashboard for visual status and host management.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Monitored Systems](#monitored-systems)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage Guide](#usage-guide)
- [Screenshots](#screenshots)
- [Directory Structure](#directory-structure)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Authors](#authors)
- [Support](#support)

---

## 🔍 Overview

The Nakasero Hospital Infrastructure Monitoring System was built to ensure 24/7 availability of all hospital IT systems. It currently monitors **52 critical hosts** including storage arrays, virtualization hosts, domain controllers, backup servers, medical systems (PACS/RIS), queue management systems, and more.

When a system goes down, the IT team receives **rich HTML emails** with troubleshooting steps. When it recovers, a recovery notification is sent. A web dashboard provides real-time status visualization and allows easy host management.

### Quick Stats
| Metric | Value |
|--------|-------|
| **Total Systems Monitored** | 52 hosts |
| **Monitoring Interval** | Every 60 seconds |
| **Alert Method** | Email via Zoho SMTP |
| **Dashboard Port** | 5000 |
| **Configuration** | Single JSON file |
| **Critical Systems** | 22 (individual alerts) |

---

## ✨ Key Features

### 1. Real-Time Monitoring
- Continuous ping checks every 60 seconds
- Status displayed live on web dashboard
- Color-coded indicators (green = up, red = down, yellow = unknown)
- Auto-refresh every 30 seconds

### 2. Rich Email Alerts

Critical Host Down Alert:

🚨 CRITICAL ALERT: MYQ Print Server (10.4.0.22) - OFFLINE
- Red header with "HOST OFFLINE DETECTED"
- Host details (name, IP, category)
- Detection time and monitoring server
- **5 troubleshooting steps** (physical connectivity, switch port, console, recent changes, virtualization alerts)
- **Required actions checklist**

**Recovery Alert:**
✅ RECOVERY: MYQ Print Server (10.4.0.22) - BACK ONLINE
- Green header with "HOST RECOVERY DETECTED"
- Recovery time
- **Post-recovery verification checklist** (5 steps)

**Batch Alerts:** Multiple non-critical hosts grouped into one email

### 3. Web Dashboard
- Live status of all 52 systems
- Search by name, IP, or purpose
- Filter by category (Storage, Virtualization, Medical, etc.)
- Filter by status (Online, Offline, Unknown)
- Sort by criticality
- Responsive design for mobile access

### 4. Host Management
- **Add new hosts** via web form
- **Edit existing hosts** (update name, category, purpose, critical flag)
- **Delete hosts** no longer needed
- **Enable/disable monitoring** per host
- All changes take effect immediately

### 5. Single Source of Truth
All hosts defined in one JSON file:
```json
{
  "hosts": [
    {
      "ip": "192.168.10.150",
      "name": "EMC Storage",
      "category": "Storage",
      "purpose": "Main storage array for all virtual infrastructure",
      "critical": true,
      "enabled": true,
      "type": "Physical Server",
      "os": "ME5.1.2.0.1",
      "location": "Server Room",
      "department": "IT Infrastructure",
      "notes": "21.5TB total, 420GB free (RED ALERT)"
    }
  ]
}
```
6. Systemd Integration
 .Services auto-start on boot
 .Auto-restart on failure
. Logging to journald and log files

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
         │
         │ writes
         ▼
┌─────────────────┐
│                 │
│  last_state.txt │
│  (current status│
│   for dashboard)│
│                 │
└─────────────────┘

Components:
Component	Location	Description
Bash Monitor	/opt/hospital-monitor/	Pings hosts, sends alerts
Flask Dashboard	/opt/hospital-dashboard/	Web interface, host management
JSON Config	/opt/hospital-dashboard/config/hosts.json	Single source of truth
Systemd Services	/etc/systemd/system/	hospital-monitor.service, hospital-dashboard.service

🖥️ Monitored Systems
The system currently monitors 52 hosts across these categories:

Category	Count	Examples
Storage	1	EMC Storage Array (192.168.10.150)
Virtualization	6	ESXi Hosts, vSphere, Hyper-V Hosts
Infrastructure	7	Domain Controllers, DNS, File Servers
Backup	4	NHL-STAGE, VEEAM servers
Medical Systems	15	PACS, RIS, Radiology VMs, Cardiac Systems
Applications	13	Dynamics 365, Kranium, QLIK, Booking System
Queue Systems	3	Q-SYS servers (Main Reception, Insurance, PEAD)
Print Services	1	MYQ Print Server
Monitoring	2	ZABBIX servers

🚀 Quick Start
# Ubuntu 20.04/22.04 LTS
sudo apt update
sudo apt install -y python3 python3-pip jq mutt git
sudo pip3 install flask psutil requests

Clone the Repository
git clone git@github.com:nambzak/nakasero-hospital-infrastructure-monitor.git
cd nakasero-hospital-infrastructure-monitor

Quick Install (if install.sh exists)
sudo ./install.sh

Manual Setup (if no install script)
# Copy files to /opt/
sudo cp -r hospital-monitor /opt/
sudo cp -r hospital-dashboard /opt/

# Set up systemd services
sudo cp *.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable hospital-dashboard hospital-monitor
sudo systemctl start hospital-dashboard hospital-monitor

Access the Dashboard
http://[YOUR-SERVER-IP]:5000

📥 Installation
Step 1: Install Dependencies
sudo apt update
sudo apt install -y python3 python3-pip python3-venv jq mutt nginx
sudo pip3 install flask psutil requests

Step 2: Create Directory Structure
sudo mkdir -p /opt/hospital-monitor
sudo mkdir -p /opt/hospital-dashboard/{templates,static/images,config,logs,data}
sudo chmod 755 /opt/hospital-{monitor,dashboard}

Step 3: Copy Files from Repository
# Monitoring scripts
sudo cp monitor/* /opt/hospital-monitor/
sudo chmod +x /opt/hospital-monitor/*.sh

# Dashboard files
sudo cp -r dashboard/* /opt/hospital-dashboard/

Step 4: Configure Email
Edit the monitoring script:
sudo nano /opt/hospital-monitor/hospital-infra-monitor.sh

Update these lines:
EMAIL_FROM="your-email@nakaserohospital.com"
EMAIL_USER="your-email@nakaserohospital.com"
EMAIL_PASS="your-actual-password"

Step 5: Set Up Systemd Services
# Copy service files
sudo cp systemd/*.service /etc/systemd/system/

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable hospital-dashboard.service
sudo systemctl enable hospital-monitor.service
sudo systemctl start hospital-dashboard.service
sudo systemctl start hospital-monitor.service

Step 6: Configure Firewall
sudo ufw allow 5000/tcp
sudo ufw reload

Step 7: Verify Installation
sudo systemctl status hospital-dashboard
sudo systemctl status hospital-monitor
curl http://localhost:5000/api/health

⚙️ Configuration
Email Settings (/opt/hospital-monitor/hospital-infra-monitor.sh)
SMTP_SERVER="smtppro.zoho.com"
SMTP_PORT="465"
EMAIL_FROM="your-email@nakaserohospital.com"
EMAIL_USER="your-email@nakaserohospital.com"
EMAIL_PASS="your-password"
RECIPIENTS=(
    "admin1@hospital.com"
    "admin2@hospital.com"
)

Hosts Configuration (/opt/hospital-dashboard/config/hosts.json)
Each host has these fields:

Field	Type	Required	Description
ip	string	✅	Unique IP address
name	string	✅	Descriptive host name
category	string	✅	Storage, Virtualization, Infrastructure, Backup, Application, Medical, Monitoring, Print, QueueSystem
purpose	string	❌	Brief description of host function
critical	boolean	❌	true = individual alerts, false = batch alerts
enabled	boolean	❌	true = monitoring active, false = ignored
type	string	❌	Physical Server, Virtual Machine, Desktop, Laptop
os	string	❌	Operating system
location	string	❌	Physical location
department	string	❌	Owning department
notes	string	❌	Any additional information

Example Host Entry
{
  "ip": "192.168.10.61",
  "name": "NHL_HMIS_APP",
  "category": "Medical",
  "purpose": "Kranium Database",
  "critical": true,
  "enabled": true,
  "type": "Virtual Machine",
  "os": "RHEL 7",
  "location": "ESXi Host 1",
  "department": "HMIS",
  "notes": "Main HMIS database server"
}

Monitoring Parameters (in script)

Parameter	Value	Description
Check interval	60 seconds	Time between ping cycles
Ping retries	2	Number of attempts per host
Ping timeout	2 seconds	Timeout per ping
Reminder interval	1 hour	Resend alert if still down

📖 Usage Guide
Accessing the Dashboard
Open a browser and navigate to:
http://[YOUR-SERVER-IP]:5000

Dashboard Features

Section	Description
Header	Hospital logo, title, last updated, auto-refresh countdown
Summary Cards	Total systems, online, offline, uptime percentage
Manage Hosts	Button to access host management
Search Bar	Search by name, IP, or purpose
Category Filter	Filter by system category
Status Filter	Filter by online/offline/unknown
Hosts Table	List of all systems with status, name, IP, category, purpose, critical flag, last check

Managing Hosts
Add a New Host:

Click Manage Hosts → Add New Host

Fill in required fields (IP and name)

Select category and purpose

Check Critical System if needed

Ensure Enable Monitoring is checked

Click Save Host

Edit a Host:

In Manage Hosts, click Edit next to the host

Modify any fields

Click Update Host

Delete a Host:

In Manage Hosts, click Delete next to the host

Confirm deletion

Understanding Alerts
Critical Host Down:

Individual email with red header

Includes 5 troubleshooting steps

Includes required actions checklist

Critical Host Recovery:

Individual email with green header

Includes post-recovery verification checklist

Non-Critical Batch:

One email for multiple hosts

Lists all affected systems

No individual troubleshooting (to avoid spam)

📁 Directory Structure
/opt/
├── hospital-monitor/
│   ├── hospital-infra-monitor.sh      # Main monitoring script
│   ├── monitor_wrapper.sh              # Wrapper for systemd
│   ├── last_state.txt                  # Current ping status
│   ├── monitor.log                      # Alert log
│   ├── history.log                      # Status change history
│   ├── recent_changes.tmp                # Recent changes for dashboard
│   ├── debug.log                          # Debug information
│   └── wrapper.log                        # Wrapper debug log
└── hospital-dashboard/
    ├── app.py                           # Flask application
    ├── config/
    │   └── hosts.json                    # Master host list
    ├── templates/
    │   ├── index.html                     # Main dashboard
    │   ├── manage_hosts.html               # Host management page
    │   ├── add_host.html                    # Add host form
    │   └── edit_host.html                   # Edit host form
    ├── static/
    │   ├── css/                             # Custom CSS
    │   ├── js/                              # Custom JavaScript
    │   └── images/
    │       └── nakasero-logo.png            # Hospital logo
    ├── logs/
    │   └── dashboard.log                    # Flask app log
    └── data/                                 # Persistent data

🔧 Troubleshooting
Common Issues and Solutions

Issue	Symptoms	Solution
Dashboard not loading	Browser cannot connect	sudo systemctl status hospital-dashboard
sudo ufw allow 5000/tcp
sudo ss -tlnp | grep 5000
Hosts showing unknown	Question mark icon	Wait 60 seconds for first ping
ping <IP> to test connectivity
grep <IP> /opt/hospital-dashboard/config/hosts.json
No email alerts	Systems down but no email	echo "test" | mutt -s "test" email@address.com
Check SMTP settings in script
tail -f /opt/hospital-monitor/monitor.log
Cannot add hosts	Form submission fails	ls -l /opt/hospital-dashboard/config/hosts.json (should be 644)
sudo chmod 644 /opt/hospital-dashboard/config/hosts.json
Monitor shows wrong host count	Garbled names in logs	Check JSON syntax: jq '.' /opt/hospital-dashboard/config/hosts.json
Restart monitor: sudo systemctl restart hospital-monitor
Service won't start	Systemd errors	sudo journalctl -u hospital-monitor -xe
Check script permissions: ls -l /opt/hospital-monitor/*.sh

Logs to Check
# Dashboard logs
sudo journalctl -u hospital-dashboard -f
tail -f /opt/hospital-dashboard/logs/dashboard.log

# Monitor logs
sudo journalctl -u hospital-monitor -f
tail -f /opt/hospital-monitor/monitor.log
tail -f /opt/hospital-monitor/debug.log
tail -f /opt/hospital-monitor/wrapper.log

Service Management
# Dashboard
sudo systemctl restart hospital-dashboard
sudo systemctl status hospital-dashboard

# Monitor
sudo systemctl restart hospital-monitor
sudo systemctl status hospital-monitor

👥 Contributing
We welcome contributions from the Nakasero Hospital IT team and the broader community.

How to Contribute
Fork the repository

Create a feature branch (git checkout -b feature/AmazingFeature)

Commit your changes (git commit -m 'Add some AmazingFeature')

Push to the branch (git push origin feature/AmazingFeature)

Open a Pull Request

Development Setup
# Clone your fork
git clone git@github.com:your-username/nakasero-hospital-infrastructure-monitor.git
cd nakasero-hospital-infrastructure-monitor

# Set up development environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

Coding Standards
Bash scripts: Use shellcheck for linting

Python: Follow PEP 8

HTML/CSS: Keep it clean and responsive

JSON: Validate with jq

📄 License
This project is licensed under the MIT License - see the LICENSE file for details.
MIT License

Copyright (c) 2026 Nakasero Hospital IT Department

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files...

👨‍💻 Authors
Isaac Nambafu - Lead Developer - @nambzak
Nakasero Hospital IT Team - Contributors and Testers

Acknowledgments
Nakasero Hospital administration for supporting this initiative

The IT team for rigorous testing and feedback

All hospital staff who depend on these systems daily

📞 Support
For issues, questions, or contributions:

Method	Contact
Email	isaac.nambafu@nakaserohospital.com
Internal	Contact Isaac or any IT team member
Phone	+256-706873857

Office Hours
Monday - Friday: 8:00 AM - 5:00 PM

On-call: 24/7 for critical issues

🗺️ Roadmap
Phase 2 (Current) ✅
JSON configuration

Web-based host management

Rich email alerts

52 hosts monitored

Phase 3 (Planned)
Uptime history graphs

User authentication

Audit logging

API auto-discovery

Mobile app

🙏 Final Notes
This system was built with one goal: ensure the hospital's critical systems are always available. Every alert, every dashboard update, every line of code is dedicated to patient care and operational excellence.

"Technology should work so doctors can focus on healing."

Maintained with ❤️ by Nakasero Hospital IT Department

Last updated: February 16, 2026





### 2. Rich Email Alerts

**Critical Host Down Alert:**
