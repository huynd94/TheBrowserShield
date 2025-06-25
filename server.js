const express = require('express');
const cors = require('cors');
const path = require('path');
const profileRoutes = require('./routes/profiles');
const errorHandler = require('./middleware/errorHandler');
const logger = require('./utils/logger');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Logging middleware
app.use((req, res, next) => {
    logger.info(`${req.method} ${req.path} - ${req.ip}`);
    next();
});

// Routes
app.use('/api/profiles', profileRoutes);

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
            'GET /api/profiles': 'List all profiles',
            'POST /api/profiles': 'Create new profile',
            'GET /api/profiles/:id': 'Get profile by ID',
            'PUT /api/profiles/:id': 'Update profile',
            'DELETE /api/profiles/:id': 'Delete profile',
            'POST /api/profiles/:id/start': 'Start browser with profile',
            'POST /api/profiles/:id/stop': 'Stop browser session',
            'GET /api/profiles/:id/status': 'Get browser session status'
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
            }
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
