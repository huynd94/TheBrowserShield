# BrowserShield System Update Guide

## Quick Update Commands

### For VPS (Oracle Linux 9)
```bash
# Update system from GitHub (recommended)
curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/update-system.sh | bash

# OR if you have the files locally:
cd /home/opc/browsershield/scripts
./update-system.sh
```

### Cleanup Unused Scripts
```bash
# Remove obsolete installation scripts
cd /home/opc/browsershield/scripts
./cleanup-unused-scripts.sh
```

## What the Update Script Does

### 1. **Backup Current Installation**
- Creates timestamped backup: `/home/opc/browsershield-backup-YYYYMMDD-HHMMSS`
- Preserves profiles data, proxy pool, mode configuration
- Backs up environment settings

### 2. **Download Latest Code**
- Pulls from GitHub repository
- Falls back to ZIP download if Git fails
- Verifies download integrity

### 3. **Smart Update Process**
- Stops BrowserShield service safely
- Updates application files
- Preserves user data and configurations
- Updates dependencies
- Validates syntax before restart

### 4. **Service Management**
- Updates systemd service configuration
- Restarts service automatically
- Performs health checks
- Provides rollback on failure

### 5. **Cleanup & Verification**
- Removes temporary files
- Keeps only last 3 backups
- Tests web interface
- Reports update status

## Manual Update Process (Alternative)

If automated script fails, follow these steps:

### 1. Manual Backup
```bash
cd /home/opc
cp -r browsershield browsershield-backup-manual-$(date +%Y%m%d)
```

### 2. Stop Service
```bash
sudo systemctl stop browsershield.service
```

### 3. Download Latest Code
```bash
cd /tmp
git clone https://github.com/huynd94/TheBrowserShield.git browsershield-new
```

### 4. Preserve Data
```bash
cp /home/opc/browsershield/data/* /tmp/browsershield-new/data/
cp /home/opc/browsershield/.env /tmp/browsershield-new/
```

### 5. Replace Installation
```bash
rm -rf /home/opc/browsershield
mv /tmp/browsershield-new /home/opc/browsershield
cd /home/opc/browsershield
```

### 6. Update Dependencies
```bash
npm install --production
```

### 7. Start Service
```bash
sudo systemctl start browsershield.service
```

## Rollback Procedure

If update fails or causes issues:

### 1. Stop Current Service
```bash
sudo systemctl stop browsershield.service
```

### 2. Restore from Backup
```bash
cd /home/opc
rm -rf browsershield
cp -r browsershield-backup-YYYYMMDD-HHMMSS browsershield
```

### 3. Restart Service
```bash
sudo systemctl start browsershield.service
```

## Update Verification

After update, verify system functionality:

### 1. Check Service Status
```bash
sudo systemctl status browsershield.service
```

### 2. Test Web Interface
```bash
curl http://localhost:5000/health
```

### 3. Verify Features
- Access: http://your-server:5000
- Admin: http://your-server:5000/admin
- Mode Manager: http://your-server:5000/mode-manager

### 4. Check Logs
```bash
sudo journalctl -u browsershield.service -n 20
```

## Scheduled Updates

### Setup Automatic Updates (Optional)
```bash
# Create cron job for weekly updates
(crontab -l 2>/dev/null; echo "0 2 * * 1 /home/opc/browsershield/scripts/update-system.sh >> /home/opc/update.log 2>&1") | crontab -
```

### Manual Update Check
```bash
# Check for updates without installing
cd /home/opc/browsershield
git fetch origin
git log HEAD..origin/main --oneline
```

## Troubleshooting Updates

### Common Issues

#### 1. Git Clone Fails
**Solution**: Check internet connection and GitHub access
```bash
ping github.com
curl -I https://github.com/huynd94/TheBrowserShield
```

#### 2. Permission Denied
**Solution**: Ensure running as opc user, not root
```bash
whoami  # Should return 'opc'
```

#### 3. Port Already in Use
**Solution**: Kill existing processes
```bash
sudo pkill -f "node server.js"
sudo systemctl restart browsershield.service
```

#### 4. NPM Install Fails
**Solution**: Clear cache and reinstall
```bash
npm cache clean --force
rm -rf node_modules package-lock.json
npm install --production
```

#### 5. Service Won't Start
**Solution**: Check syntax and logs
```bash
cd /home/opc/browsershield
node -c server.js
sudo journalctl -u browsershield.service -n 50
```

### Recovery Commands
```bash
# Reset to working state
sudo systemctl stop browsershield.service
cd /home/opc
rm -rf browsershield
curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-browsershield-fixed-robust.sh | bash
```

## Update Notifications

### Check Current Version
```bash
cd /home/opc/browsershield
grep '"version"' package.json
```

### Monitor for Updates
- Watch GitHub repository: https://github.com/huynd94/TheBrowserShield
- Check release notes and commits
- Subscribe to notifications

## Security Considerations

### Before Updating
- Backup important data
- Note current configuration
- Plan for downtime
- Test in staging environment if available

### After Updating
- Verify all features work
- Check logs for errors
- Monitor system performance
- Update firewall rules if needed

## Maintenance Schedule

### Weekly Tasks
- Run update script
- Check system health
- Review logs
- Clean old backups

### Monthly Tasks
- Full system backup
- Performance review
- Security audit
- Documentation update

## Support

### Getting Help
1. Check logs: `sudo journalctl -u browsershield.service -f`
2. Monitor system: `cd /home/opc/browsershield/scripts && ./monitor.sh`
3. Review this guide
4. Contact system administrator

### Reporting Issues
When reporting update issues, include:
- Current version
- Error messages
- System logs
- Steps to reproduce
- System information