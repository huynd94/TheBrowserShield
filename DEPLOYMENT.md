# Production Deployment Guide

## Current Status
This Replit version uses a **Mock Browser Service** for demonstration purposes because Puppeteer requires specific system-level dependencies that may not be available in all containerized environments.

## Mock vs Production Differences

### Mock Implementation (Current - Replit Demo)
- ✅ All API endpoints work perfectly
- ✅ Profile management (CRUD operations)
- ✅ Session management and tracking
- ✅ Demonstrates anti-detection features
- ⚠️ Browser operations are simulated (no real browser launches)

### Production Implementation (Real Deployment)
- ✅ Real Puppeteer browser automation
- ✅ Actual fingerprint spoofing and anti-detection
- ✅ Real proxy support and IP rotation
- ✅ Actual webpage interaction and scraping

## How to Deploy for Production

### 1. VPS/Dedicated Server Deployment
For real browser automation, deploy on:
- **Ubuntu/Debian VPS** (DigitalOcean, AWS EC2, Linode)
- **Docker container** with full Chrome/Chromium support
- **Dedicated server** with sufficient RAM (4GB+ recommended)

### 2. Required System Dependencies
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y \
    chromium-browser \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libdrm2 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libxss1 \
    libxtst6 \
    xdg-utils
```

### 3. Production Configuration Changes

Replace the mock service import in `routes/profiles.js`:
```javascript
// Change this line:
const BrowserService = require('../services/MockBrowserService');

// To this:
const BrowserService = require('../services/BrowserService');
```

### 4. Environment Variables for Production
```bash
NODE_ENV=production
PORT=8000
LOG_LEVEL=info
CHROME_PATH=/usr/bin/chromium-browser  # or your Chrome path
MAX_BROWSER_INSTANCES=5
BROWSER_TIMEOUT=60000
```

### 5. Docker Production Setup
```dockerfile
FROM node:18-slim

# Install Chrome dependencies
RUN apt-get update && apt-get install -y \
    chromium \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libdrm2 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libxss1 \
    libxtst6 \
    xdg-utils \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .
RUN npm install

EXPOSE 8000
CMD ["node", "server.js"]
```

### 6. Performance Optimizations for Production

#### Memory Management
- Set `--max-old-space-size=4096` for Node.js
- Limit concurrent browser instances
- Implement browser session recycling

#### Security Considerations
- Use rate limiting middleware
- Implement API authentication
- Sanitize user inputs for script execution
- Use HTTPS in production

### 7. Anti-Detection Enhancements for Production

The current implementation includes basic anti-detection features. For production, consider adding:

#### Advanced Fingerprint Spoofing
- Canvas fingerprint randomization
- WebGL fingerprint modification
- Audio context fingerprinting
- Screen resolution spoofing
- Hardware concurrency randomization

#### Behavioral Patterns
- Random mouse movements
- Human-like typing patterns
- Variable page load delays
- Realistic scroll behaviors

### 8. Monitoring and Logging
- Set up proper logging with Winston or similar
- Monitor browser memory usage
- Track session success rates
- Alert on browser crash patterns

## Testing the Current Mock Implementation

Even though this is a mock version, you can test all API functionality:

```bash
# Create a new profile
curl -X POST http://localhost:5000/api/profiles \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Profile",
    "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "timezone": "America/New_York",
    "viewport": {"width": 1920, "height": 1080},
    "spoofFingerprint": true
  }'

# Start mock browser
curl -X POST http://localhost:5000/api/profiles/[PROFILE_ID]/start

# Check session status
curl -X GET http://localhost:5000/api/profiles/[PROFILE_ID]/status

# Navigate to URL (mock)
curl -X POST http://localhost:5000/api/profiles/[PROFILE_ID]/navigate \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'

# Execute script (mock)
curl -X POST http://localhost:5000/api/profiles/[PROFILE_ID]/execute \
  -H "Content-Type: application/json" \
  -d '{"script": "navigator.userAgent"}'

# Stop browser
curl -X POST http://localhost:5000/api/profiles/[PROFILE_ID]/stop
```

## Migration Path

1. **Test the API** with the current mock implementation
2. **Deploy to production server** with real system dependencies
3. **Switch to real BrowserService** by changing the import
4. **Add monitoring and security** features
5. **Scale horizontally** as needed

The architecture is designed to make this transition seamless - only the browser service implementation changes, all other components remain the same.