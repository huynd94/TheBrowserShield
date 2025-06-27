# BrowserShield Scripts Directory

This directory contains essential scripts for BrowserShield system management.

## Available Scripts

### Production Scripts
- `update-system.sh` - Updates BrowserShield from GitHub repository
- `install-browsershield-fixed-robust.sh` - Robust installation script for Oracle Linux 9
- `monitor.sh` - System monitoring and health checks
- `cleanup-unused-scripts.sh` - Removes obsolete scripts (this script)

## Usage

### Update System
```bash
./update-system.sh
```

### Monitor System
```bash
./monitor.sh
```

### Fresh Installation
```bash
curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-browsershield-fixed-robust.sh | bash
```

## Maintenance

- Scripts are automatically maintained via the update system
- Obsolete scripts are cleaned up periodically
- Backups are created before any cleanup operations

## Last Cleanup
Fri Jun 27 01:59:13 AM UTC 2025
