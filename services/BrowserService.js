const { createBrowserWithProfile } = require('../config/puppeteer');
const ProfileService = require('./ProfileService');
const logger = require('../utils/logger');

class BrowserService {
    constructor() {
        this.activeSessions = new Map(); // profileId -> { browser, page, startTime }
    }

    /**
     * Start browser with profile
     * @param {string} profileId - Profile ID
     * @returns {Object} Session info
     */
    async startBrowser(profileId) {
        // Check if browser is already running for this profile
        if (this.activeSessions.has(profileId)) {
            throw new Error(`Browser is already running for profile ${profileId}`);
        }

        // Get profile
        const profile = await ProfileService.getProfile(profileId);
        if (!profile) {
            throw new Error(`Profile not found: ${profileId}`);
        }

        try {
            logger.info(`Starting browser for profile: ${profile.name} (${profileId})`);
            
            // Create browser instance with profile settings
            const { browser, page } = await createBrowserWithProfile(profile);
            
            // Store session
            const session = {
                browser,
                page,
                profile,
                startTime: new Date().toISOString(),
                status: 'running'
            };
            
            this.activeSessions.set(profileId, session);
            
            // Set up browser event handlers
            browser.on('disconnected', () => {
                logger.info(`Browser disconnected for profile: ${profileId}`);
                this.activeSessions.delete(profileId);
            });

            // Navigate to a test page to verify everything works
            await page.goto('https://httpbin.org/headers', { 
                waitUntil: 'networkidle2',
                timeout: 30000 
            });
            
            logger.info(`Browser started successfully for profile: ${profile.name} (${profileId})`);
            
            return {
                profileId,
                profileName: profile.name,
                status: 'running',
                startTime: session.startTime,
                browserInfo: {
                    userAgent: profile.userAgent,
                    viewport: profile.viewport,
                    timezone: profile.timezone,
                    proxy: profile.proxy ? {
                        host: profile.proxy.host,
                        port: profile.proxy.port,
                        type: profile.proxy.type
                    } : null
                }
            };
            
        } catch (error) {
            logger.error(`Failed to start browser for profile ${profileId}:`, error);
            
            // Clean up if browser creation failed
            if (this.activeSessions.has(profileId)) {
                const session = this.activeSessions.get(profileId);
                if (session.browser) {
                    try {
                        await session.browser.close();
                    } catch (closeError) {
                        logger.error('Error closing browser after failed start:', closeError);
                    }
                }
                this.activeSessions.delete(profileId);
            }
            
            throw error;
        }
    }

    /**
     * Stop browser session
     * @param {string} profileId - Profile ID
     * @returns {boolean} True if stopped, false if not running
     */
    async stopBrowser(profileId) {
        const session = this.activeSessions.get(profileId);
        if (!session) {
            return false;
        }

        try {
            logger.info(`Stopping browser for profile: ${profileId}`);
            
            await session.browser.close();
            this.activeSessions.delete(profileId);
            
            logger.info(`Browser stopped for profile: ${profileId}`);
            return true;
            
        } catch (error) {
            logger.error(`Error stopping browser for profile ${profileId}:`, error);
            // Remove from active sessions even if close failed
            this.activeSessions.delete(profileId);
            throw error;
        }
    }

    /**
     * Get browser session status
     * @param {string} profileId - Profile ID
     * @returns {Object|null} Session status or null if not running
     */
    getBrowserStatus(profileId) {
        const session = this.activeSessions.get(profileId);
        if (!session) {
            return null;
        }

        return {
            profileId,
            profileName: session.profile.name,
            status: session.status,
            startTime: session.startTime,
            uptime: Math.floor((Date.now() - new Date(session.startTime).getTime()) / 1000),
            browserInfo: {
                userAgent: session.profile.userAgent,
                viewport: session.profile.viewport,
                timezone: session.profile.timezone,
                proxy: session.profile.proxy ? {
                    host: session.profile.proxy.host,
                    port: session.profile.proxy.port,
                    type: session.profile.proxy.type
                } : null
            }
        };
    }

    /**
     * Get all active browser sessions
     * @returns {Array} Array of active sessions
     */
    getAllActiveSessions() {
        const sessions = [];
        for (const [profileId, session] of this.activeSessions) {
            sessions.push({
                profileId,
                profileName: session.profile.name,
                status: session.status,
                startTime: session.startTime,
                uptime: Math.floor((Date.now() - new Date(session.startTime).getTime()) / 1000)
            });
        }
        return sessions;
    }

    /**
     * Stop all browser sessions
     */
    async stopAllBrowsers() {
        const profileIds = Array.from(this.activeSessions.keys());
        const promises = profileIds.map(profileId => 
            this.stopBrowser(profileId).catch(error => 
                logger.error(`Error stopping browser for profile ${profileId}:`, error)
            )
        );
        
        await Promise.all(promises);
        logger.info(`Stopped ${profileIds.length} browser sessions`);
    }

    /**
     * Execute script in browser
     * @param {string} profileId - Profile ID
     * @param {string} script - JavaScript code to execute
     * @returns {any} Script result
     */
    async executeScript(profileId, script) {
        const session = this.activeSessions.get(profileId);
        if (!session) {
            throw new Error(`No active browser session for profile: ${profileId}`);
        }

        try {
            const result = await session.page.evaluate(script);
            return result;
        } catch (error) {
            logger.error(`Error executing script in profile ${profileId}:`, error);
            throw error;
        }
    }

    /**
     * Navigate to URL
     * @param {string} profileId - Profile ID
     * @param {string} url - URL to navigate to
     * @returns {Object} Navigation result
     */
    async navigateToUrl(profileId, url) {
        const session = this.activeSessions.get(profileId);
        if (!session) {
            throw new Error(`No active browser session for profile: ${profileId}`);
        }

        try {
            const response = await session.page.goto(url, { 
                waitUntil: 'networkidle2',
                timeout: 30000 
            });
            
            return {
                url: session.page.url(),
                title: await session.page.title(),
                status: response.status(),
                statusText: response.statusText()
            };
        } catch (error) {
            logger.error(`Error navigating to URL in profile ${profileId}:`, error);
            throw error;
        }
    }
}

module.exports = new BrowserService();
