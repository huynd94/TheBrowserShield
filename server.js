const express = require('express');
const cors = require('cors');
const path = require('path');
const profileRoutes = require('./routes/profiles');
const proxyRoutes = require('./routes/proxy');
const errorHandler = require('./middleware/errorHandler');
const logger = require('./utils/logger');
const { authenticateToken, rateLimiter } = require('./middleware/auth');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Serve static files (UI)
app.use(express.static(path.join(__dirname, 'public')));

// Rate limiting (optional)
if (process.env.ENABLE_RATE_LIMIT === 'true') {
    app.use('/api', rateLimiter());
}

// API Authentication (optional)
if (process.env.API_TOKEN) {
    app.use(authenticateToken);
}

// Logging middleware
app.use((req, res, next) => {
    logger.info(`${req.method} ${req.path} - ${req.ip}`);
    next();
});

// Routes
app.use('/api/profiles', profileRoutes);
app.use('/api/proxy', proxyRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        timestamp: new Date().toISOString(),
        service: 'Anti-Detect Browser Profile Manager'
    });
});

// Root endpoint with API documentation
app.get('/', (req, res) => {
    res.json({
        service: 'Anti-Detect Browser Profile Manager',
        version: '1.0.0',
        endpoints: {
            'GET /health': 'Health check',
            'GET /': 'Web UI for profile management',
            'GET /api/profiles': 'List all profiles',
            'POST /api/profiles': 'Create new profile',
            'GET /api/profiles/:id': 'Get profile by ID',
            'PUT /api/profiles/:id': 'Update profile',
            'DELETE /api/profiles/:id': 'Delete profile',
            'POST /api/profiles/:id/start': 'Start browser with profile (supports autoNavigateUrl)',
            'POST /api/profiles/:id/stop': 'Stop browser session',
            'GET /api/profiles/:id/status': 'Get browser session status',
            'GET /api/profiles/:id/logs': 'Get profile activity logs',
            'POST /api/profiles/:id/navigate': 'Navigate browser to URL',
            'POST /api/profiles/:id/execute': 'Execute JavaScript in browser',
            'GET /api/profiles/sessions/active': 'Get all active sessions',
            'GET /api/profiles/system/logs': 'Get system activity logs',
            'GET /api/profiles/system/stats': 'Get system statistics',
            'GET /api/proxy': 'List all proxies in pool',
            'POST /api/proxy': 'Add proxy to pool',
            'DELETE /api/proxy/:id': 'Remove proxy from pool',
            'GET /api/proxy/random': 'Get random proxy from pool',
            'GET /api/proxy/least-used': 'Get least used proxy',
            'POST /api/proxy/:id/test': 'Test proxy connectivity',
            'POST /api/proxy/:id/toggle': 'Toggle proxy active status',
            'GET /api/proxy/stats': 'Get proxy pool statistics'
        },
        documentation: {
            createProfile: {
                method: 'POST',
                endpoint: '/api/profiles',
                body: {
                    name: 'string (required)',
                    userAgent: 'string (optional)',
                    timezone: 'string (optional, e.g., "America/New_York")',
                    proxy: {
                        host: 'string',
                        port: 'number',
                        type: 'string (http/https/socks4/socks5)',
                        username: 'string (optional)',
                        password: 'string (optional)'
                    },
                    viewport: {
                        width: 'number (default: 1366)',
                        height: 'number (default: 768)'
                    },
                    spoofFingerprint: 'boolean (default: true)'
                }
            },
            startBrowserWithAutoNav: {
                method: 'POST',
                endpoint: '/api/profiles/:id/start',
                body: {
                    autoNavigateUrl: 'string (optional, URL to navigate to after starting browser)'
                }
            },
            addProxyToPool: {
                method: 'POST',
                endpoint: '/api/proxy',
                body: {
                    host: 'string (required)',
                    port: 'number (required)',
                    type: 'string (http/https/socks4/socks5)',
                    username: 'string (optional)',
                    password: 'string (optional)',
                    country: 'string (optional)',
                    city: 'string (optional)',
                    provider: 'string (optional)'
                }
            }
        },
        features: {
            webUI: 'Access web management interface at /',
            proxyPool: 'Manage shared proxy pool for profiles',
            activityLogs: 'Track all profile and browser activities',
            separateUserData: 'Each profile uses isolated browser data directory',
            autoNavigation: 'Start browser and navigate to URL in one request',
            apiAuthentication: 'Optional API token authentication (set API_TOKEN env var)',
            rateLimiting: 'Optional rate limiting (set ENABLE_RATE_LIMIT=true)',
            mockMode: 'Currently running in demo mode - switch to BrowserService for production'
        }
    });
});

// Error handling middleware
app.use(errorHandler);

// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('SIGTERM received, shutting down gracefully');
    const BrowserService = require('./services/BrowserService');
    await BrowserService.stopAllBrowsers();
    process.exit(0);
});

process.on('SIGINT', async () => {
    logger.info('SIGINT received, shutting down gracefully');
    const BrowserService = require('./services/BrowserService');
    await BrowserService.stopAllBrowsers();
    process.exit(0);
});

app.listen(PORT, '0.0.0.0', () => {
    logger.info(`Anti-Detect Browser Profile Manager running on port ${PORT}`);
    logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
