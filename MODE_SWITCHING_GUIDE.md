# BrowserShield Mode Switching Guide

## Available Modes

BrowserShield supports three operation modes:

### 1. Mock Mode (Default) 🎭
- **Purpose**: Demo and testing environment
- **Features**: Simulates all browser automation functionality
- **Requirements**: None
- **Performance**: Fastest
- **Reliability**: Highest
- **Use Cases**: 
  - Testing API endpoints
  - Demo purposes
  - Development without browser overhead
  - Training and tutorials

### 2. Production Mode (Chrome/Chromium) 🚀
- **Purpose**: Real browser automation with Chrome
- **Features**: 
  - Full Puppeteer capabilities
  - Real website interaction
  - Screenshot capture
  - Anti-detection techniques
  - Proxy support
- **Requirements**: Chrome or Chromium installed
- **Performance**: Medium (depends on system resources)
- **Reliability**: High
- **Use Cases**:
  - Web scraping
  - Automated testing
  - Data collection
  - Social media automation

### 3. Firefox Mode 🦊
- **Purpose**: Real browser automation with Firefox
- **Features**:
  - Firefox-specific automation
  - Alternative fingerprinting
  - Different detection patterns
  - Proxy support
- **Requirements**: Firefox installed
- **Performance**: Medium
- **Reliability**: High
- **Use Cases**:
  - Alternative to Chrome
  - Different browser fingerprint
  - Firefox-specific testing

## Mode Switching Methods

### Method 1: Web Interface (Recommended)
1. Access the Mode Manager: `http://your-server:5000/mode-manager`
2. View current mode status and available options
3. Click "Switch to [Mode Name]" for desired mode
4. Confirm the switch in the modal dialog
5. Restart the server when prompted

### Method 2: API Endpoints

#### Check Current Mode
```bash
curl http://localhost:5000/api/mode
```

#### Check Available Modes
```bash
curl http://localhost:5000/api/mode/check-requirements
```

#### Switch Mode
```bash
curl -X POST http://localhost:5000/api/mode/switch \
  -H "Content-Type: application/json" \
  -d '{"mode": "production"}'
```

### Method 3: Configuration File
Edit `data/mode-config.json`:
```json
{
  "mode": "production",
  "lastChanged": "2025-06-26T14:15:00.000Z",
  "capabilities": ["Real browser automation", "Website interaction", "Screenshot capture"]
}
```

## Installation Requirements by Mode

### For Production Mode (Chrome)
On Oracle Linux 9:
```bash
# Install Chrome (x86_64 only)
sudo dnf install -y wget
wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
sudo dnf install -y ./google-chrome-stable_current_x86_64.rpm

# OR install Chromium (works on both x86_64 and ARM64)
sudo dnf install -y epel-release
sudo dnf install -y chromium
```

### For Firefox Mode
On Oracle Linux 9:
```bash
sudo dnf install -y firefox
```

### Verification Commands
```bash
# Check Chrome/Chromium
which google-chrome-stable || which chromium || which chromium-browser

# Check Firefox
which firefox

# Test installation
google-chrome-stable --version
firefox --version
```

## Mode-Specific Features

### Mock Mode Features
- Profile management (simulated)
- Session tracking (simulated)
- API endpoints (fully functional)
- Browser start/stop (simulated)
- Navigation commands (simulated)
- Script execution (simulated)
- Proxy configuration (simulated)

### Production Mode Features
- Real browser instances
- Actual website loading
- Screenshot capture
- Element interaction
- Form submission
- JavaScript execution
- Cookie management
- Local storage access
- Proxy routing

### Firefox Mode Features
- Firefox-specific fingerprinting
- Different user agent patterns
- Alternative rendering engine
- Firefox extension support
- Different security model

## Performance Considerations

### Mock Mode
- RAM Usage: ~50MB
- CPU Usage: Minimal
- Startup Time: Instant
- Concurrent Sessions: Unlimited (simulated)

### Production Mode
- RAM Usage: ~200-500MB per browser instance
- CPU Usage: Medium-High
- Startup Time: 2-5 seconds per instance
- Concurrent Sessions: Limited by system resources

### Firefox Mode
- RAM Usage: ~300-600MB per browser instance
- CPU Usage: Medium-High
- Startup Time: 3-7 seconds per instance
- Concurrent Sessions: Limited by system resources

## Troubleshooting

### Common Issues

#### Chrome/Chromium Not Found
```bash
# Check installation
rpm -qa | grep -i chrome
rpm -qa | grep -i chromium

# Install missing packages
sudo dnf install -y chromium-browser
```

#### Firefox Not Found
```bash
# Check installation
which firefox
rpm -qa | grep firefox

# Install Firefox
sudo dnf install -y firefox
```

#### Permission Issues
```bash
# Fix browser permissions
sudo chown -R $(whoami):$(whoami) ~/.config
sudo chmod -R 755 ~/.config
```

#### Display Issues (Headless)
```bash
# Install X11 dependencies
sudo dnf install -y xorg-x11-server-Xvfb
export DISPLAY=:99
```

### Mode Switch Failures

#### "Mode not available" Error
- Check browser installation
- Verify dependencies
- Run requirement check: `curl http://localhost:5000/api/mode/check-requirements`

#### Server Won't Restart
- Check for port conflicts: `netstat -tulpn | grep 5000`
- Kill existing processes: `pkill -f "node server.js"`
- Restart service: `sudo systemctl restart browsershield`

## Best Practices

### Development Environment
- Use Mock Mode for API development
- Switch to Production Mode for testing
- Use Firefox Mode for cross-browser compatibility

### Production Environment
- Start with Mock Mode for initial setup
- Switch to Production Mode after verification
- Monitor resource usage with multiple sessions

### Resource Management
- Limit concurrent browser sessions in production
- Implement session cleanup
- Monitor memory usage
- Use headless mode for better performance

## API Integration

### Mode-Aware Code Example
```javascript
// Check current mode before operations
const modeInfo = await fetch('/api/mode').then(r => r.json());

if (modeInfo.data.currentMode === 'mock') {
    console.log('Running in demo mode');
    // Handle mock responses
} else {
    console.log('Running with real browsers');
    // Handle real browser responses
}
```

### Conditional Features
```javascript
// Enable features based on mode capabilities
const capabilities = modeInfo.data.info.features;

if (capabilities.includes('Screenshot capture')) {
    // Enable screenshot functionality
}

if (capabilities.includes('Real browser automation')) {
    // Enable advanced automation features
}
```

## Security Considerations

### Mock Mode
- No external connections made
- No real data exposure
- Safe for public demos

### Production/Firefox Mode
- Real browser connections
- Potential data exposure
- Implement proper authentication
- Use secure proxy configurations
- Monitor for suspicious activity

## Monitoring and Logging

### Check Mode Status
- Access: `http://your-server:5000/mode-manager`
- API: `GET /api/mode`
- Logs: Check server console output

### Performance Monitoring
- System resources: `htop`, `free -h`
- Browser processes: `ps aux | grep chrome`
- Network usage: `netstat -i`

### Log Files
- Server logs: `journalctl -u browsershield -f`
- Browser logs: Check application logs
- Mode changes: Recorded in `data/mode-config.json`