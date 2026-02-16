# nakasero-hospital-infrastructure-monitor
A simple web to help the Nakasero Hospital IT team to monitor the infrastructure and get alerted in time incase of any issues
# Nakasero Hospital Infrastructure Monitoring System

![Version](https://img.shields.io/badge/version-2.0-blue)
![Status](https://img.shields.io/badge/status-production-green)
![License](https://img.shields.io/badge/license-MIT-orange)

A comprehensive, real‑time monitoring system for Nakasero Hospital's critical IT infrastructure.  
The system provides continuous ping‑based monitoring, rich email alerts, and a web dashboard for visual status and host management.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [Screenshots](#screenshots)
- [License](#license)

---

## 🔍 Overview

The Nakasero Hospital Infrastructure Monitoring System was built to ensure 24/7 availability of all hospital IT systems. It currently monitors **52 critical hosts** including:

- Storage arrays (EMC)
- Virtualization hosts (ESXi, Hyper‑V)
- Domain controllers
- Backup servers
- Medical systems (PACS, RIS, Cardiac)
- Queue management systems
- And more...

When a system goes down, the IT team receives **rich HTML emails** with troubleshooting steps. When it recovers, a recovery notification is sent.

---

## ✨ Features

- ✅ **Real‑time monitoring** – continuous ping checks every 60 seconds
- ✅ **Rich email alerts** – detailed HTML with troubleshooting steps
- ✅ **Web dashboard** – live status with search, filters, and host management
- ✅ **Single source of truth** – all hosts defined in one JSON file
- ✅ **Add/Edit/Delete hosts** – via web interface, no script editing
- ✅ **Critical vs. non‑critical alerts** – individual alerts for critical systems
- ✅ **Hourly reminders** – for hosts that stay down
- ✅ **Recovery notifications** – when systems come back online

---

## 🏗️ Architecture
