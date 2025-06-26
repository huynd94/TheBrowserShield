const puppeteer = require('puppeteer-firefox');
const puppeteerExtra = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');

// Add stealth plugin for Firefox
puppeteerExtra.use(StealthPlugin());

/**
 * Get Firefox executable path
 * @returns {string} Path to Firefox executable
 */
function getFirefoxExecutablePath() {
    // Common Firefox paths on Linux
    const paths = [
        '/usr/bin/firefox',
        '/usr/bin/firefox-esr',
        '/opt/firefox/firefox',
        process.env.FIREFOX_EXECUTABLE_PATH
    ].filter(Boolean);
    
    const fs = require('fs');
    for (const path of paths) {
        if (fs.existsSync(path)) {
            return path;
        }
    }
    
    return 'firefox'; // Let system find it
}

/**
 * Create Firefox browser instance with profile settings
 * @param {Object} profile - Profile configuration
 * @returns {Promise<Object>} Browser instance and page
 */
async function createFirefoxBrowserWithProfile(profile) {
    const firefoxPath = getFirefoxExecutablePath();
    
    const launchOptions = {
        product: 'firefox',
        executablePath: firefoxPath,
        headless: true,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-gpu',
            '--no-first-run',
            '--disable-extensions',
            '--disable-plugins',
            '--disable-images',
            '--disable-javascript', // Will be enabled per profile
        ]
    };

    // Add proxy configuration if provided
    if (profile.proxy && profile.proxy.host && profile.proxy.port) {
        if (profile.proxy.username && profile.proxy.password) {
            launchOptions.args.push(`--proxy-server=${profile.proxy.host}:${profile.proxy.port}`);
        } else {
            launchOptions.args.push(`--proxy-server=${profile.proxy.host}:${profile.proxy.port}`);
        }
    }

    const browser = await puppeteer.launch(launchOptions);
    const page = await browser.newPage();

    // Apply profile settings
    await applyFirefoxProfileSettings(page, profile);

    return { browser, page };
}

/**
 * Apply profile settings to Firefox page
 * @param {Object} page - Puppeteer page instance
 * @param {Object} profile - Profile configuration
 */
async function applyFirefoxProfileSettings(page, profile) {
    // Set viewport
    if (profile.viewport) {
        await page.setViewport({
            width: profile.viewport.width || 1920,
            height: profile.viewport.height || 1080
        });
    }

    // Set user agent
    if (profile.userAgent) {
        await page.setUserAgent(profile.userAgent);
    }

    // Set timezone
    if (profile.timezone) {
        await page.emulateTimezone(profile.timezone);
    }

    // Set geolocation
    if (profile.geolocation) {
        await page.setGeolocation({
            latitude: profile.geolocation.latitude,
            longitude: profile.geolocation.longitude,
            accuracy: profile.geolocation.accuracy || 100
        });
    }

    // Apply additional Firefox-specific spoofing
    await applyFirefoxSpoofingTechniques(page);
}

/**
 * Apply Firefox-specific spoofing techniques
 * @param {Object} page - Puppeteer page instance
 */
async function applyFirefoxSpoofingTechniques(page) {
    // Override webdriver detection
    await page.evaluateOnNewDocument(() => {
        // Remove webdriver property
        delete Object.getPrototypeOf(navigator).webdriver;
        
        // Mock browser-specific properties for Firefox
        Object.defineProperty(navigator, 'vendor', {
            get: () => ''
        });
        
        Object.defineProperty(navigator, 'vendorSub', {
            get: () => ''
        });

        // Firefox-specific navigator properties
        Object.defineProperty(navigator, 'buildID', {
            get: () => '20231101000000'
        });

        Object.defineProperty(navigator, 'oscpu', {
            get: () => 'Linux x86_64'
        });

        // Mock permissions
        const originalQuery = window.navigator.permissions.query;
        window.navigator.permissions.query = (parameters) => (
            parameters.name === 'notifications' ?
            Promise.resolve({ state: Notification.permission }) :
            originalQuery(parameters)
        );
    });

    // Set additional headers
    await page.setExtraHTTPHeaders({
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Accept-Encoding': 'gzip, deflate, br',
        'DNT': '1',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0'
    });
}

module.exports = {
    getFirefoxExecutablePath,
    createFirefoxBrowserWithProfile,
    applyFirefoxProfileSettings,
    applyFirefoxSpoofingTechniques
};