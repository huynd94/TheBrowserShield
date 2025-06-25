# 🛡️ BrowserShield - Anti-Detect Browser Profile Manager

A professional Node.js application for managing anti-detect browser profiles with advanced fingerprint spoofing, proxy rotation, and session management. Similar to GoLogin/Multilogin but open-source and self-hosted.

## ✨ Features

### 🎭 Anti-Detection & Stealth
- **Fingerprint Spoofing**: Canvas, WebGL, Audio fingerprint randomization
- **Navigator Spoofing**: User agent, platform, languages, plugins
- **Stealth Mode**: Puppeteer-extra with stealth plugin integration
- **WebDriver Protection**: Hide automation detection properties

### 🌐 Proxy Management
- **Multi-Protocol Support**: HTTP, HTTPS, SOCKS4, SOCKS5
- **Proxy Pool System**: Centralized proxy management with usage tracking
- **Smart Rotation**: Random, least-used, and manual proxy selection
- **Authentication**: Username/password proxy authentication

### 👤 Profile Management
- **Complete CRUD**: Create, read, update, delete profiles
- **Custom Configurations**: Timezone, viewport, user agent per profile
- **Isolated Sessions**: Separate user data directories
- **Auto-Navigation**: Start browser with specific URL

### 🖥️ Web Interface
- **Modern UI**: Bootstrap-based management interface
- **Real-time Monitoring**: Active session tracking with uptime
- **Activity Logs**: Comprehensive logging for all operations
- **Statistics Dashboard**: System and usage statistics

### 🔒 Security & Performance
- **API Authentication**: Optional token-based authentication
- **Rate Limiting**: Configurable request rate limiting
- **Session Isolation**: Each profile runs in separate browser instance
- **Resource Management**: Memory optimization and cleanup

## 🚀 Quick Installation

### Oracle Linux 9 / RHEL (Recommended)

**One-line installer:**
```bash
curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-browsershield.sh | bash
```

**Manual installation:**
```bash
wget https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/install-browsershield.sh
chmod +x install-browsershield.sh
./install-browsershield.sh
```

### Development Setup

```bash
# Clone repository
git clone https://github.com/huynd94/TheBrowserShield.git
cd TheBrowserShield

# Install dependencies
npm install

# Start development server
npm start
```

## 🌐 Access

After installation:
- **Web Interface**: `http://YOUR_VPS_IP:5000`
- **API Endpoint**: `http://YOUR_VPS_IP:5000/api`
- **Health Check**: `http://YOUR_VPS_IP:5000/health`

## 📖 API Documentation

### Profile Management
```bash
# List all profiles
GET /api/profiles

# Create new profile
POST /api/profiles
{
  "name": "My Profile",
  "userAgent": "Chrome Windows",
  "timezone": "America/New_York",
  "viewport": {"width": 1366, "height": 768},
  "spoofFingerprint": true,
  "proxy": {
    "host": "proxy.example.com",
    "port": 8080,
    "type": "http"
  }
}

# Start browser with auto-navigation
POST /api/profiles/:id/start
{
  "autoNavigateUrl": "https://bot.sannysoft.com"
}

# Stop browser session
POST /api/profiles/:id/stop
```

### Proxy Pool Management
```bash
# Add proxy to pool
POST /api/proxy
{
  "host": "proxy.example.com",
  "port": 8080,
  "type": "http",
  "country": "US",
  "provider": "ProxyProvider"
}

# Get random proxy
GET /api/proxy/random

# Get proxy statistics
GET /api/proxy/stats
```

### Activity Logs & Statistics
```bash
# Get profile activity logs
GET /api/profiles/:id/logs

# Get system statistics
GET /api/profiles/system/stats

# Get system activity logs
GET /api/profiles/system/logs
```

## 🔧 Configuration

### Environment Variables
```bash
PORT=5000
NODE_ENV=production
API_TOKEN=your-secure-token
ENABLE_RATE_LIMIT=true
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable
```

### API Authentication
```bash
# Set API token for authentication
export API_TOKEN="your-secure-token"

# Use token in requests
curl -H "Authorization: Bearer your-secure-token" \
  http://localhost:5000/api/profiles
```

## 🏗️ Architecture

```
├── server.js              # Main application entry point
├── routes/                # API route handlers
│   ├── profiles.js        # Profile management routes
│   └── proxy.js          # Proxy pool routes
├── services/              # Business logic layer
│   ├── BrowserService.js  # Real browser automation
│   ├── MockBrowserService.js # Demo/testing service
│   ├── ProfileService.js  # Profile CRUD operations
│   ├── ProxyPoolService.js # Proxy management
│   └── ProfileLogService.js # Activity logging
├── middleware/            # Express middleware
│   ├── auth.js           # Authentication & rate limiting
│   └── errorHandler.js   # Global error handling
├── config/               # Configuration files
│   └── puppeteer.js     # Browser launch configuration
├── public/               # Web interface
│   ├── index.html       # Main UI
│   └── app.js          # Frontend JavaScript
└── data/                # Application data
    ├── profiles.json    # Profile storage
    ├── proxy-pool.json  # Proxy pool storage
    └── logs/           # Activity logs
```

## 🛠️ Management Commands

### Service Control
```bash
# Check status
sudo systemctl status browsershield.service

# Start/Stop/Restart
sudo systemctl start browsershield.service
sudo systemctl restart browsershield.service

# View logs
sudo journalctl -u browsershield.service -f
```

### Monitoring & Maintenance
```bash
# System monitor
/home/browserapp/browsershield/monitor.sh

# Update application
/home/browserapp/browsershield/update.sh

# Backup data
tar -czf backup-$(date +%Y%m%d).tar.gz /home/browserapp/browsershield/data/
```

## 🔍 Features in Detail

### Anti-Detection Capabilities
- **WebDriver Property Hiding**: Removes `navigator.webdriver`
- **Plugin Spoofing**: Randomizes navigator.plugins
- **Canvas Fingerprinting**: Adds subtle noise to canvas rendering
- **WebGL Fingerprinting**: Modifies WebGL parameters
- **Audio Context**: Spoofs audio fingerprinting
- **Screen Resolution**: Customizable viewport per profile

### Proxy Features
- **Pool Management**: Centralized proxy inventory
- **Usage Statistics**: Track proxy usage and performance
- **Health Monitoring**: Test proxy connectivity
- **Smart Selection**: Least-used, random, or manual selection
- **Country/Provider Filtering**: Organize proxies by location

### Security Features
- **Isolated User Data**: Each profile uses separate Chrome user directory
- **Process Isolation**: Browser sessions run in separate processes
- **Memory Management**: Automatic cleanup of inactive sessions
- **Secure Token Storage**: Environment-based API token management

## 📊 Performance & Scaling

### System Requirements
- **Minimum**: 2GB RAM, 2 CPU cores, 10GB storage
- **Recommended**: 4GB+ RAM, 4+ CPU cores, 20GB+ storage
- **Concurrent Sessions**: ~10-50 profiles per 4GB RAM

### Optimization Tips
- Use SSD storage for better performance
- Monitor memory usage with included tools
- Implement proxy rotation for large-scale operations
- Regular cleanup of old browser data and logs

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature-name`
3. Commit changes: `git commit -am 'Add feature'`
4. Push to branch: `git push origin feature-name`
5. Submit pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check [DEPLOYMENT.md](DEPLOYMENT.md) for detailed setup
- **Installation Guide**: See [INSTALL.md](INSTALL.md) for quick start
- **Issues**: Report bugs via GitHub Issues
- **Project URL**: https://github.com/huynd94/TheBrowserShield
- **Original Demo**: https://replit.com/@ngocdm2006/BrowserShield

## 🏷️ Version

**Current Version**: 1.0.0
- ✅ Complete anti-detect browser management
- ✅ Web UI with real-time monitoring
- ✅ Proxy pool management
- ✅ Activity logging system
- ✅ Production-ready deployment scripts
- ✅ Oracle Linux 9 optimization