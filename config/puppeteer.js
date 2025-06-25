const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');

// Add stealth plugin to avoid detection
puppeteer.use(StealthPlugin());

const PUPPETEER_CONFIG = {
    // Optimized for headless environments like Replit
    headless: true,
    args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-accelerated-2d-canvas',
        '--no-first-run',
        '--no-zygote',
        '--single-process',
        '--disable-gpu',
        '--disable-background-timer-throttling',
        '--disable-backgrounding-occluded-windows',
        '--disable-features=TranslateUI',
        '--disable-renderer-backgrounding',
        '--disable-web-security',
        '--disable-features=VizDisplayCompositor',
        '--memory-pressure-off'
    ],
    // Reduce memory usage
    ignoreDefaultArgs: ['--disable-extensions'],
    defaultViewport: null
};

/**
 * Create browser instance with profile settings
 * @param {Object} profile - Profile configuration
 * @returns {Promise<Object>} Browser instance and page
 */
async function createBrowserWithProfile(profile) {
    const config = { ...PUPPETEER_CONFIG };
    
    // Add proxy configuration if provided
    if (profile.proxy && profile.proxy.host && profile.proxy.port) {
        const proxyUrl = `${profile.proxy.type || 'http'}://${profile.proxy.host}:${profile.proxy.port}`;
        config.args.push(`--proxy-server=${proxyUrl}`);
    }
    
    // Launch browser
    const browser = await puppeteer.launch(config);
    const page = await browser.newPage();
    
    // Apply profile settings
    await applyProfileSettings(page, profile);
    
    return { browser, page };
}

/**
 * Apply profile settings to page
 * @param {Object} page - Puppeteer page instance
 * @param {Object} profile - Profile configuration
 */
async function applyProfileSettings(page, profile) {
    // Set user agent
    if (profile.userAgent) {
        await page.setUserAgent(profile.userAgent);
    }
    
    // Set viewport
    const viewport = profile.viewport || { width: 1366, height: 768 };
    await page.setViewport(viewport);
    
    // Set timezone
    if (profile.timezone) {
        await page.emulateTimezone(profile.timezone);
    }
    
    // Set proxy authentication if provided
    if (profile.proxy && profile.proxy.username && profile.proxy.password) {
        await page.authenticate({
            username: profile.proxy.username,
            password: profile.proxy.password
        });
    }
    
    // Additional fingerprint spoofing if enabled
    if (profile.spoofFingerprint) {
        await applySpoofingTechniques(page);
    }
}

/**
 * Apply additional spoofing techniques
 * @param {Object} page - Puppeteer page instance
 */
async function applySpoofingTechniques(page) {
    // Override navigator properties
    await page.evaluateOnNewDocument(() => {
        // Spoof webdriver property
        Object.defineProperty(navigator, 'webdriver', {
            get: () => undefined,
        });
        
        // Spoof languages
        Object.defineProperty(navigator, 'languages', {
            get: () => ['en-US', 'en'],
        });
        
        // Spoof plugins
        Object.defineProperty(navigator, 'plugins', {
            get: () => [1, 2, 3, 4, 5],
        });
        
        // Spoof permissions
        const originalQuery = window.navigator.permissions.query;
        window.navigator.permissions.query = (parameters) => (
            parameters.name === 'notifications' ?
                Promise.resolve({ state: Notification.permission }) :
                originalQuery(parameters)
        );
        
        // Remove webdriver traces
        delete window.cdc_adoQpoasnfa76pfcZLmcfl_Array;
        delete window.cdc_adoQpoasnfa76pfcZLmcfl_Promise;
        delete window.cdc_adoQpoasnfa76pfcZLmcfl_Symbol;
    });
    
    // Set additional headers
    await page.setExtraHTTPHeaders({
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
        'Upgrade-Insecure-Requests': '1',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache'
    });
}

module.exports = {
    createBrowserWithProfile,
    applyProfileSettings,
    PUPPETEER_CONFIG
};
