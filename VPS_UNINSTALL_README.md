# VPS Uninstallation Script Suite

Comprehensive bash-based uninstallation and management tools for Oracle Linux 9 VPS systems.

## 📋 Overview

This repository provides a complete suite of bash scripts designed for safe, flexible, and user-friendly system cleanup and management operations on VPS environments.

### Key Features

- **Safety First**: Dry-run mode for all destructive operations
- **Flexible Options**: Force mode, interactive prompts, verbose logging
- **Comprehensive Coverage**: Services, packages, files, logs cleanup
- **Validation Tools**: Built-in testing and validation capabilities
- **Cross-Platform**: Works on Oracle Linux, RHEL, CentOS, Ubuntu

## 🛠️ Available Scripts

### 1. VPS Uninstall Suite (`vps-uninstall-suite.sh`)
**Primary uninstallation tool with modular cleanup options**

```bash
# Complete system uninstallation
./scripts/vps-uninstall-suite.sh uninstall

# Preview changes safely
./scripts/vps-uninstall-suite.sh --dry-run uninstall

# Force removal without prompts
./scripts/vps-uninstall-suite.sh --force uninstall

# Individual cleanup operations
./scripts/vps-uninstall-suite.sh clean-services
./scripts/vps-uninstall-suite.sh clean-packages
./scripts/vps-uninstall-suite.sh clean-files
./scripts/vps-uninstall-suite.sh clean-logs

# System validation and backup
./scripts/vps-uninstall-suite.sh validate
./scripts/vps-uninstall-suite.sh backup
```

### 2. BrowserShield Uninstaller (`uninstall-browsershield-vps.sh`)
**Specialized uninstaller for BrowserShield application**

```bash
# Safe preview
./scripts/uninstall-browsershield-vps.sh --dry-run

# Interactive uninstall
./scripts/uninstall-browsershield-vps.sh

# Force uninstall
./scripts/uninstall-browsershield-vps.sh --force
```

### 3. VPS Manager (`vps-manager-fixed.sh`)
**Complete VPS lifecycle management tool**

```bash
# Deploy application
./scripts/vps-manager-fixed.sh deploy

# System status and monitoring
./scripts/vps-manager-fixed.sh status
./scripts/vps-manager-fixed.sh health
./scripts/vps-manager-fixed.sh logs

# Maintenance operations
./scripts/vps-manager-fixed.sh update
./scripts/vps-manager-fixed.sh backup
./scripts/vps-manager-fixed.sh restart

# Safe uninstallation with options
./scripts/vps-manager-fixed.sh uninstall
```

### 4. Validation Suite (`validation-suite.sh`)
**Comprehensive testing and validation framework**

```bash
# Run all validation tests
./scripts/validation-suite.sh

# Test script syntax and functionality
./scripts/test-runner.sh
```

## 🚀 Quick Start

### Installation

```bash
# Download scripts
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/vps-uninstall-suite.sh -o vps-uninstall-suite.sh
curl -fsSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/vps-manager-fixed.sh -o vps-manager.sh

# Make executable
chmod +x vps-uninstall-suite.sh vps-manager.sh
```

### Safe Testing

```bash
# Always test with dry-run first
./vps-uninstall-suite.sh --dry-run uninstall

# Review what would be removed
./vps-uninstall-suite.sh --dry-run clean-files
```

### Production Use

```bash
# Complete uninstallation
./vps-uninstall-suite.sh uninstall

# Or use VPS Manager for guided process
./vps-manager.sh uninstall
```

## 📖 Detailed Usage

### Command Options

| Option | Description | Example |
|--------|-------------|---------|
| `--dry-run` | Preview actions without executing | `--dry-run uninstall` |
| `--force` | Skip confirmation prompts | `--force clean-packages` |
| `--verbose` | Enable detailed logging | `--verbose validate` |
| `--non-interactive` | Disable user prompts | `--non-interactive uninstall` |
| `--help` | Show help information | `--help` |

### Available Commands

| Command | Description | Components Affected |
|---------|-------------|-------------------|
| `uninstall` | Complete system removal | All components |
| `clean-services` | Remove systemd services | Services, daemon configs |
| `clean-packages` | Remove installed packages | Node.js, Chrome, etc. |
| `clean-files` | Remove application files | App dirs, user data |
| `clean-logs` | Remove log files | System logs, app logs |
| `validate` | System validation check | Environment verification |
| `backup` | Create system backup | Data and config backup |

## 🔒 Safety Features

### Dry-Run Mode
Preview all operations before execution:
```bash
./vps-uninstall-suite.sh --dry-run uninstall
```

### Interactive Prompts
User confirmation for destructive operations:
```bash
# Will prompt for confirmation
./vps-uninstall-suite.sh clean-packages
```

### Force Mode
Skip all prompts for automation:
```bash
./vps-uninstall-suite.sh --force --non-interactive uninstall
```

### Backup Creation
Automatic backup before major operations:
```bash
./vps-uninstall-suite.sh backup
```

## 📁 What Gets Removed

### System Services
- `browsershield.service`
- Systemd configurations
- Service logs and journal entries

### Installed Packages
- Node.js and npm
- Google Chrome / Chromium
- Application dependencies

### Application Files
```
/home/*/browsershield/
/opt/browsershield/
/var/lib/browsershield/
/etc/browsershield/
/tmp/browsershield*
```

### User Data
```
~/.config/browsershield/
~/.local/share/browsershield/
~/.cache/browsershield/
```

### Log Files
```
/var/log/browsershield*
/var/log/*browsershield*
/etc/logrotate.d/browsershield
```

## 🧪 Testing and Validation

### Run Validation Suite
```bash
# Complete validation
./scripts/validation-suite.sh

# Test runner
./scripts/test-runner.sh
```

### Manual Testing
```bash
# Test syntax
bash -n vps-uninstall-suite.sh

# Test help
./vps-uninstall-suite.sh --help

# Test dry-run
./vps-uninstall-suite.sh --dry-run validate
```

## 🔧 Troubleshooting

### Permission Issues
```bash
# Ensure proper user (not root)
whoami  # Should show 'opc' or regular user

# Fix permissions
chmod +x *.sh
```

### Missing Commands
Scripts automatically detect and handle missing system commands:
- `systemctl` (systemd management)
- `dnf/yum/apt` (package management)
- `journalctl` (log management)

### Environment Compatibility
- **Oracle Linux 9**: Full compatibility
- **RHEL/CentOS**: Full compatibility
- **Ubuntu/Debian**: Partial compatibility (package manager differences)
- **Replit/Containers**: Limited compatibility (missing systemd)

## 📊 Logging and Monitoring

### Log Files
All operations create detailed logs:
```
/tmp/vps-uninstall-YYYYMMDD_HHMMSS.log
```

### Monitoring Operations
```bash
# Real-time monitoring
tail -f /tmp/vps-uninstall-*.log

# Check last operation
ls -la /tmp/vps-uninstall-*.log | tail -1
```

## 🔄 Recovery and Rollback

### Backup Recovery
```bash
# List backups
ls -la /tmp/vps-backup-*.tar.gz

# Extract backup
tar -xzf /tmp/vps-backup-20250627_120000.tar.gz
```

### Partial Recovery
```bash
# Restore specific components
./vps-uninstall-suite.sh backup  # Create current state backup
# Then manually restore needed files
```

## 📚 Examples

### Complete Uninstallation Workflow
```bash
# 1. Create backup
./vps-uninstall-suite.sh backup

# 2. Preview uninstallation
./vps-uninstall-suite.sh --dry-run uninstall

# 3. Execute uninstallation
./vps-uninstall-suite.sh uninstall

# 4. Validate clean state
./vps-uninstall-suite.sh validate
```

### Selective Cleanup
```bash
# Remove only services
./vps-uninstall-suite.sh clean-services

# Remove only application files
./vps-uninstall-suite.sh clean-files

# Clean logs only
./vps-uninstall-suite.sh clean-logs
```

### Automated Cleanup
```bash
# Fully automated uninstall
./vps-uninstall-suite.sh --force --non-interactive uninstall
```

## 🎯 Best Practices

1. **Always test with `--dry-run` first**
2. **Create backups before major operations**
3. **Use verbose mode for troubleshooting**
4. **Review logs after operations**
5. **Test in non-production environment first**

## 📞 Support

For issues or questions:
1. Check logs in `/tmp/vps-uninstall-*.log`
2. Run validation: `./scripts/validation-suite.sh`
3. Test with dry-run mode first
4. Review this documentation

---

**Version**: 1.0.0  
**Compatibility**: Oracle Linux 9, RHEL 8+, CentOS 8+  
**License**: MIT