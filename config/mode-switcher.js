/**
 * BrowserShield Mode Switcher
 * Manages different operation modes: Mock, Production (Chrome), Firefox
 */

const fs = require('fs');
const path = require('path');

class ModeSwitcher {
    constructor() {
        this.configFile = path.join(__dirname, '../data/mode-config.json');
        this.currentMode = this.loadCurrentMode();
    }

    /**
     * Load current mode from config file
     */
    loadCurrentMode() {
        try {
            if (fs.existsSync(this.configFile)) {
                const config = JSON.parse(fs.readFileSync(this.configFile, 'utf8'));
                return config.mode || 'mock';
            }
        } catch (error) {
            console.warn('Failed to load mode config, using default:', error.message);
        }
        return 'mock';
    }

    /**
     * Save current mode to config file
     */
    saveCurrentMode(mode) {
        try {
            const config = {
                mode: mode,
                lastChanged: new Date().toISOString(),
                capabilities: this.getModeCapabilities(mode)
            };
            
            // Ensure data directory exists
            const dataDir = path.dirname(this.configFile);
            if (!fs.existsSync(dataDir)) {
                fs.mkdirSync(dataDir, { recursive: true });
            }
            
            fs.writeFileSync(this.configFile, JSON.stringify(config, null, 2));
            this.currentMode = mode;
            return true;
        } catch (error) {
            console.error('Failed to save mode config:', error.message);
            return false;
        }
    }

    /**
     * Get available modes with their status
     */
    getAvailableModes() {
        return {
            mock: {
                name: 'Mock Mode',
                description: 'Demo mode with simulated browser automation',
                available: true,
                requirements: 'None',
                features: ['Profile management', 'Session simulation', 'API testing'],
                performance: 'Fastest',
                reliability: 'Highest'
            },
            production: {
                name: 'Production Mode (Chrome)',
                description: 'Real browser automation with Chrome/Chromium',
                available: this.checkChromeAvailability(),
                requirements: 'Chrome/Chromium installed',
                features: ['Real browser automation', 'Website interaction', 'Screenshot capture'],
                performance: 'Medium',
                reliability: 'High'
            },
            firefox: {
                name: 'Firefox Mode',
                description: 'Real browser automation with Firefox',
                available: this.checkFirefoxAvailability(),
                requirements: 'Firefox installed',
                features: ['Firefox automation', 'Alternative fingerprinting', 'Website interaction'],
                performance: 'Medium',
                reliability: 'High'
            }
        };
    }

    /**
     * Check if Chrome/Chromium is available
     */
    checkChromeAvailability() {
        const { execSync } = require('child_process');
        try {
            // Check for various Chrome/Chromium paths
            const chromePaths = [
                'google-chrome',
                'google-chrome-stable',
                'chromium',
                'chromium-browser',
                '/usr/bin/google-chrome-stable',
                '/usr/bin/chromium',
                '/usr/bin/chromium-browser'
            ];

            for (const chromePath of chromePaths) {
                try {
                    execSync(`which ${chromePath}`, { stdio: 'ignore' });
                    return true;
                } catch (e) {
                    // Continue checking other paths
                }
            }
            return false;
        } catch (error) {
            return false;
        }
    }

    /**
     * Check if Firefox is available
     */
    checkFirefoxAvailability() {
        const { execSync } = require('child_process');
        try {
            execSync('which firefox', { stdio: 'ignore' });
            return true;
        } catch (error) {
            return false;
        }
    }

    /**
     * Get capabilities for a specific mode
     */
    getModeCapabilities(mode) {
        const modes = this.getAvailableModes();
        return modes[mode] ? modes[mode].features : [];
    }

    /**
     * Switch to a different mode
     */
    switchMode(newMode) {
        const availableModes = this.getAvailableModes();
        
        if (!availableModes[newMode]) {
            return {
                success: false,
                error: `Invalid mode: ${newMode}. Available modes: ${Object.keys(availableModes).join(', ')}`
            };
        }

        if (!availableModes[newMode].available) {
            return {
                success: false,
                error: `Mode ${newMode} is not available. Requirements: ${availableModes[newMode].requirements}`
            };
        }

        const previousMode = this.currentMode;
        
        if (this.saveCurrentMode(newMode)) {
            return {
                success: true,
                previousMode: previousMode,
                currentMode: newMode,
                message: `Successfully switched from ${previousMode} to ${newMode}`,
                requiresRestart: true
            };
        } else {
            return {
                success: false,
                error: 'Failed to save mode configuration'
            };
        }
    }

    /**
     * Get current mode info
     */
    getCurrentModeInfo() {
        const modes = this.getAvailableModes();
        return {
            currentMode: this.currentMode,
            info: modes[this.currentMode],
            allModes: modes
        };
    }

    /**
     * Get the appropriate browser service class for current mode
     */
    getBrowserServiceClass() {
        switch (this.currentMode) {
            case 'production':
                return require('../services/BrowserService');
            case 'firefox':
                return require('../services/FirefoxBrowserService');
            case 'mock':
            default:
                return require('../services/MockBrowserService');
        }
    }

    /**
     * Get mode-specific configuration
     */
    getModeConfig() {
        switch (this.currentMode) {
            case 'production':
                return {
                    puppeteerOptions: {
                        headless: true,
                        args: [
                            '--no-sandbox',
                            '--disable-setuid-sandbox',
                            '--disable-dev-shm-usage',
                            '--disable-accelerated-2d-canvas',
                            '--no-first-run',
                            '--no-zygote',
                            '--single-process',
                            '--disable-gpu'
                        ]
                    }
                };
            case 'firefox':
                return {
                    puppeteerOptions: {
                        product: 'firefox',
                        headless: true
                    }
                };
            case 'mock':
            default:
                return {
                    mockFeatures: {
                        simulateDelay: true,
                        generateScreenshots: false,
                        mockNavigation: true
                    }
                };
        }
    }
}

module.exports = ModeSwitcher;