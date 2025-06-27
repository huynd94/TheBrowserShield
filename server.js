const express = require('express');
const cors = require('cors');
const path = require('path');
const profileRoutes = require('./routes/profiles');
const proxyRoutes = require('./routes/proxy');
const modeRoutes = require('./routes/mode');
const errorHandler = require('./middleware/errorHandler');
const logger = require('./utils/logger');
const { authenticateToken, rateLimiter } = require('./middleware/auth');
const ModeSwitcher = require('./config/mode-switcher');

const app = express();
const PORT = process.env.PORT || 5000;

// Initialize mode switcher
const modeSwitcher = new ModeSwitcher();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Rate limiting (optional)
if (process.env.ENABLE_RATE_LIMIT === 'true') {
    app.use('/api', rateLimiter());
}

// API Authentication (optional)
if (process.env.API_TOKEN) {
    app.use('/api', authenticateToken);
}

// Logging middleware
app.use((req, res, next) => {
    logger.info(`${req.method} ${req.path} - ${req.ip}`);
    next();
});

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