const fs = require('fs').promises;
const path = require('path');
const logger = require('../utils/logger');

const PROXY_POOL_FILE = path.join(__dirname, '../data/proxy-pool.json');

class ProxyPoolService {
    constructor() {
        this.proxyPool = [];
        this.proxyUsage = new Map(); // Track usage stats
        this.initialized = false;
    }

    /**
     * Initialize proxy pool service
     */
    async initialize() {
        if (this.initialized) return;
        
        try {
            await this.loadProxyPool();
            this.initialized = true;
            logger.info('ProxyPoolService initialized successfully');
        } catch (error) {
            logger.error('Failed to initialize ProxyPoolService:', error);
            this.proxyPool = [];
            this.initialized = true;
        }
    }

    /**
     * Load proxy pool from file
     */
    async loadProxyPool() {
        try {
            const data = await fs.readFile(PROXY_POOL_FILE, 'utf8');
            this.proxyPool = JSON.parse(data);
            logger.info(`Loaded ${this.proxyPool.length} proxies from pool`);
        } catch (error) {
            if (error.code === 'ENOENT') {
                logger.info('Proxy pool file not found, starting with empty pool');
                await this.saveProxyPool();
            } else {
                throw error;
            }
        }
    }

    /**
     * Save proxy pool to file
     */
    async saveProxyPool() {
        try {
            const dataDir = path.dirname(PROXY_POOL_FILE);
            await fs.mkdir(dataDir, { recursive: true });
            
            await fs.writeFile(PROXY_POOL_FILE, JSON.stringify(this.proxyPool, null, 2));
            logger.info(`Saved ${this.proxyPool.length} proxies to pool`);
        } catch (error) {
            logger.error('Failed to save proxy pool:', error);
            throw error;
        }
    }

    /**
     * Add proxy to pool
     * @param {Object} proxyConfig - Proxy configuration
     * @returns {Object} Added proxy with ID
     */
    async addProxy(proxyConfig) {
        await this.initialize();
        
        const proxy = {
            id: `proxy-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
            host: proxyConfig.host,
            port: proxyConfig.port,
            type: proxyConfig.type || 'http',
            username: proxyConfig.username || null,
            password: proxyConfig.password || null,
            country: proxyConfig.country || null,
            city: proxyConfig.city || null,
            provider: proxyConfig.provider || null,
            active: true,
            addedAt: new Date().toISOString(),
            lastUsed: null,
            usageCount: 0
        };

        this.proxyPool.push(proxy);
        await this.saveProxyPool();
        
        logger.info(`Added proxy to pool: ${proxy.host}:${proxy.port}`);
        return proxy;
    }

    /**
     * Remove proxy from pool
     * @param {string} proxyId - Proxy ID
     * @returns {boolean} True if removed
     */
    async removeProxy(proxyId) {
        await this.initialize();
        
        const index = this.proxyPool.findIndex(p => p.id === proxyId);
        if (index === -1) return false;
        
        const proxy = this.proxyPool[index];
        this.proxyPool.splice(index, 1);
        await this.saveProxyPool();
        
        logger.info(`Removed proxy from pool: ${proxy.host}:${proxy.port}`);
        return true;
    }

    /**
     * Get all proxies in pool
     * @returns {Array} Array of proxies
     */
    async getAllProxies() {
        await this.initialize();
        return this.proxyPool;
    }

    /**
     * Get random proxy from pool
     * @param {Object} filters - Optional filters
     * @returns {Object|null} Random proxy or null if none available
     */
    async getRandomProxy(filters = {}) {
        await this.initialize();
        
        let availableProxies = this.proxyPool.filter(proxy => proxy.active);
        
        // Apply filters
        if (filters.country) {
            availableProxies = availableProxies.filter(p => p.country === filters.country);
        }
        if (filters.type) {
            availableProxies = availableProxies.filter(p => p.type === filters.type);
        }
        if (filters.provider) {
            availableProxies = availableProxies.filter(p => p.provider === filters.provider);
        }
        
        if (availableProxies.length === 0) return null;
        
        // Select random proxy
        const randomIndex = Math.floor(Math.random() * availableProxies.length);
        const selectedProxy = availableProxies[randomIndex];
        
        // Update usage stats
        selectedProxy.lastUsed = new Date().toISOString();
        selectedProxy.usageCount++;
        await this.saveProxyPool();
        
        return selectedProxy;
    }

    /**
     * Get least used proxy from pool
     * @param {Object} filters - Optional filters
     * @returns {Object|null} Least used proxy or null if none available
     */
    async getLeastUsedProxy(filters = {}) {
        await this.initialize();
        
        let availableProxies = this.proxyPool.filter(proxy => proxy.active);
        
        // Apply filters
        if (filters.country) {
            availableProxies = availableProxies.filter(p => p.country === filters.country);
        }
        if (filters.type) {
            availableProxies = availableProxies.filter(p => p.type === filters.type);
        }
        
        if (availableProxies.length === 0) return null;
        
        // Sort by usage count (ascending)
        availableProxies.sort((a, b) => a.usageCount - b.usageCount);
        const selectedProxy = availableProxies[0];
        
        // Update usage stats
        selectedProxy.lastUsed = new Date().toISOString();
        selectedProxy.usageCount++;
        await this.saveProxyPool();
        
        return selectedProxy;
    }

    /**
     * Test proxy connectivity
     * @param {Object} proxy - Proxy configuration
     * @returns {Object} Test result
     */
    async testProxy(proxy) {
        // This is a mock implementation for demo
        // In production, you would make an actual HTTP request through the proxy
        
        const testResult = {
            proxyId: proxy.id,
            host: proxy.host,
            port: proxy.port,
            tested: true,
            success: Math.random() > 0.2, // 80% success rate for demo
            responseTime: Math.floor(Math.random() * 1000) + 100, // 100-1100ms
            testedAt: new Date().toISOString(),
            mock: true
        };
        
        logger.info(`Proxy test ${testResult.success ? 'passed' : 'failed'}: ${proxy.host}:${proxy.port}`);
        return testResult;
    }

    /**
     * Get proxy pool statistics
     * @returns {Object} Statistics
     */
    async getPoolStats() {
        await this.initialize();
        
        const stats = {
            total: this.proxyPool.length,
            active: this.proxyPool.filter(p => p.active).length,
            inactive: this.proxyPool.filter(p => !p.active).length,
            byType: {},
            byCountry: {},
            totalUsage: this.proxyPool.reduce((sum, p) => sum + p.usageCount, 0),
            mostUsed: null,
            leastUsed: null
        };
        
        // Count by type
        this.proxyPool.forEach(proxy => {
            stats.byType[proxy.type] = (stats.byType[proxy.type] || 0) + 1;
            if (proxy.country) {
                stats.byCountry[proxy.country] = (stats.byCountry[proxy.country] || 0) + 1;
            }
        });
        
        // Find most and least used
        if (this.proxyPool.length > 0) {
            const sortedByUsage = [...this.proxyPool].sort((a, b) => b.usageCount - a.usageCount);
            stats.mostUsed = sortedByUsage[0];
            stats.leastUsed = sortedByUsage[sortedByUsage.length - 1];
        }
        
        return stats;
    }

    /**
     * Toggle proxy active status
     * @param {string} proxyId - Proxy ID
     * @returns {boolean} New active status
     */
    async toggleProxyStatus(proxyId) {
        await this.initialize();
        
        const proxy = this.proxyPool.find(p => p.id === proxyId);
        if (!proxy) return null;
        
        proxy.active = !proxy.active;
        await this.saveProxyPool();
        
        logger.info(`Proxy ${proxy.host}:${proxy.port} ${proxy.active ? 'activated' : 'deactivated'}`);
        return proxy.active;
    }
}

module.exports = new ProxyPoolService();