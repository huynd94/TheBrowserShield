const express = require('express');
const cors = require('cors');
const path = require('path');
const profileRoutes = require('./routes/profiles');
const proxyRoutes = require('./routes/proxy');
const modeRoutes = require('./routes/mode');
const errorHandler = require('./middleware/errorHandler');
const logger = require('./utils/logger');
const { authenticateToken, rateLimiter } = require('./middleware/auth');
const { 
    performanceMonitor, 
    systemHealthMonitor, 
    createRateLimiter,
    requestTracker 
} = require('./middleware/performance');
const ModeSwitcher = require('./config/mode-switcher');

const app = express();
const PORT = process.env.PORT || 5000;

// Initialize mode switcher
const modeSwitcher = new ModeSwitcher();

// Initialize system health monitoring
const healthMonitor = systemHealthMonitor();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Request tracking for debugging
app.use(requestTracker);

// Performance monitoring
app.use(performanceMonitor);

// Enhanced rate limiting with performance tracking
app.use('/api', createRateLimiter({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: process.env.ENABLE_RATE_LIMIT === 'true' ? 100 : 10000, // Higher limit for development
    message: 'Too many requests, please try again later.'
}));

// API Authentication (optional)
if (process.env.API_TOKEN) {
    app.use('/api', authenticateToken);
}

// Routes
app.use('/api/profiles', profileRoutes);
app.use('/api/proxy', proxyRoutes);
app.use('/api/mode', modeRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
    const currentMode = modeSwitcher.getCurrentModeInfo();
    res.json({
        status: 'ok',
        service: 'BrowserShield Anti-Detect Browser Manager',
        mode: currentMode.name,
        timestamp: new Date().toISOString(),
        version: '2.0.0'
    });
});

// Enhanced system health endpoint
app.get('/api/system/health', (req, res) => {
    try {
        const memory = process.memoryUsage();
        const uptime = process.uptime();
        const currentMode = modeSwitcher.getCurrentModeInfo();
        
        const systemHealth = {
            timestamp: new Date().toISOString(),
            uptime: Math.floor(uptime),
            memory: {
                rss: Math.round(memory.rss / 1024 / 1024), // MB
                heapUsed: Math.round(memory.heapUsed / 1024 / 1024), // MB
                heapTotal: Math.round(memory.heapTotal / 1024 / 1024), // MB
                external: Math.round(memory.external / 1024 / 1024), // MB
                heapUsagePercent: Math.round((memory.heapUsed / memory.heapTotal) * 100)
            },
            nodeVersion: process.version,
            platform: process.platform,
            arch: process.arch
        };
        
        res.json({
            success: true,
            data: {
                ...systemHealth,
                mode: currentMode,
                service: 'BrowserShield Anti-Detect Browser Manager',
                version: '2.0.0',
                status: 'healthy'
            }
        });
    } catch (error) {
        logger.error('Health check failed:', error);
        res.status(500).json({
            success: false,
            error: 'Health check failed',
            details: error.message
        });
    }
});

// Serve documentation files
app.get('/docs/:file', (req, res) => {
    const file = req.params.file;
    const allowedFiles = ['INSTALL.md', 'HUONG_DAN_UPDATE.md', 'UPDATE_GUIDE.md', 'DEPLOYMENT.md', 'README.md'];
    
    if (allowedFiles.includes(file)) {
        res.sendFile(path.join(__dirname, file));
    } else {
        res.status(404).json({ error: 'Documentation file not found' });
    }
});

// Mode manager interface
app.get('/mode-manager', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'mode-manager.html'));
});

// Admin interface
app.get('/admin', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

// Browser control interface
app.get('/browser-control', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'browser-control.html'));
});

// Root endpoint - redirect to main app
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Global error handler
app.use(errorHandler);

// Start server
app.listen(PORT, '0.0.0.0', () => {
    const currentMode = modeSwitcher.getCurrentModeInfo();
    console.log('🛡️ BrowserShield Anti-Detect Browser Manager running on port', PORT);
    console.log('📱 Environment:', process.env.NODE_ENV || 'development');
    console.log('🌐 Access: http://localhost:' + PORT);
    console.log('🎭 Mode:', currentMode.name);
    
    logger.info('BrowserShield server started', {
        port: PORT,
        mode: currentMode.name,
        version: '2.0.0'
    });
});

// Graceful shutdown
process.on('SIGINT', async () => {
    console.log('\n🔄 Shutting down BrowserShield server...');
    
    try {
        // Get the appropriate browser service and stop all browsers
        const BrowserServiceClass = modeSwitcher.getBrowserServiceClass();
        if (BrowserServiceClass) {
            const browserService = new BrowserServiceClass();
            await browserService.stopAllBrowsers();
            console.log('✅ All browser sessions closed');
        }
    } catch (error) {
        console.error('❌ Error during shutdown:', error.message);
    }
    
    console.log('👋 BrowserShield server stopped');
    process.exit(0);
});

module.exports = app;