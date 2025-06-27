#!/bin/bash

# BrowserShield Firefox Mode Update Script
# Updates Firefox Mode with compatibility fixes for VPS deployment
# Version: 1.1

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[INFO] BrowserShield Firefox Mode Update${NC}"
echo -e "${BLUE}[INFO] Version: 1.1${NC}"
echo -e "${BLUE}[INFO] Updating Firefox Mode compatibility...${NC}"

# Check if we're in the right directory
if [ ! -f "server.js" ]; then
    echo -e "${RED}[ERROR] server.js not found. Please run from BrowserShield directory.${NC}"
    exit 1
fi

# Backup current config
if [ -f "config/firefox-puppeteer.js" ]; then
    cp config/firefox-puppeteer.js config/firefox-puppeteer.js.backup
    echo -e "${GREEN}[SUCCESS] Backed up firefox-puppeteer.js${NC}"
fi

# Create updated Firefox configuration
cat > config/firefox-puppeteer-simple.js << 'EOF'
const puppeteerExtra = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');

// Add stealth plugin
puppeteerExtra.use(StealthPlugin());

/**
 * Create Firefox-style browser instance with Chrome engine
 * Compatible with VPS environment
 */
async function createFirefoxBrowserWithProfile(profile) {
    try {
        const launchOptions = {
            headless: true,
            args: [
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-dev-shm-usage',
                '--disable-gpu',
                '--no-first-run',
                '--single-process'
            ]
        };

        // Add proxy if configured
        if (profile.proxy && profile.proxy.host && profile.proxy.port) {
            launchOptions.args.push(`--proxy-server=${profile.proxy.host}:${profile.proxy.port}`);
        }

        const browser = await puppeteerExtra.launch(launchOptions);
        const page = await browser.newPage();

        // Apply Firefox-like settings
        await applyFirefoxProfileSettings(page, profile);
        await applyFirefoxSpoofingTechniques(page);

        return { browser, page };
    } catch (error) {
        console.error('Error creating Firefox browser:', error);
        throw new Error('Failed to create Firefox browser: ' + error.message);
    }
}

/**
 * Apply Firefox-style profile settings
 */
async function applyFirefoxProfileSettings(page, profile) {
    // Set Firefox user agent
    const firefoxUA = profile.userAgent || 
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/119.0';
    
    await page.setUserAgent(firefoxUA);

    // Set viewport
    if (profile.viewport) {
        await page.setViewport({
            width: profile.viewport.width || 1920,
            height: profile.viewport.height || 1080
        });
    }

    // Set timezone if specified
    if (profile.timezone) {
        await page.emulateTimezone(profile.timezone);
    }
}

/**
 * Apply Firefox-specific spoofing techniques
 */
async function applyFirefoxSpoofingTechniques(page) {
    // Override navigator properties to simulate Firefox
    await page.evaluateOnNewDocument(() => {
        // Firefox-specific navigator properties
        Object.defineProperty(navigator, 'userAgent', {
            get: () => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/119.0'
        });
        
        Object.defineProperty(navigator, 'appName', {
            get: () => 'Netscape'
        });
        
        Object.defineProperty(navigator, 'appVersion', {
            get: () => '5.0 (Windows)'
        });
        
        Object.defineProperty(navigator, 'product', {
            get: () => 'Gecko'
        });
        
        Object.defineProperty(navigator, 'vendor', {
            get: () => ''
        });
        
        // Simulate Firefox WebGL renderer
        const getParameter = WebGLRenderingContext.prototype.getParameter;
        WebGLRenderingContext.prototype.getParameter = function(parameter) {
            if (parameter === 37445) {
                return 'Mozilla';
            }
            if (parameter === 37446) {
                return 'Mozilla Firefox';
            }
            return getParameter.apply(this, arguments);
        };
    });
}

module.exports = {
    createFirefoxBrowserWithProfile,
    applyFirefoxProfileSettings,
    applyFirefoxSpoofingTechniques
};
EOF

echo -e "${GREEN}[SUCCESS] Created firefox-puppeteer-simple.js${NC}"

# Update FirefoxBrowserService to use simple implementation
if [ -f "services/FirefoxBrowserService.js" ]; then
    sed -i "s/firefox-puppeteer'/firefox-puppeteer-simple'/g" services/FirefoxBrowserService.js
    echo -e "${GREEN}[SUCCESS] Updated FirefoxBrowserService.js${NC}"
fi

# Install required dependencies if needed
if [ -f "package.json" ]; then
    echo -e "${BLUE}[INFO] Installing/updating dependencies...${NC}"
    npm install puppeteer-extra puppeteer-extra-plugin-stealth
    echo -e "${GREEN}[SUCCESS] Dependencies updated${NC}"
fi

echo -e "${GREEN}[SUCCESS] Firefox Mode update completed!${NC}"
echo -e "${YELLOW}[INFO] Please restart the BrowserShield service to apply changes.${NC}"
echo -e "${BLUE}[INFO] Run: systemctl restart browsershield${NC}"