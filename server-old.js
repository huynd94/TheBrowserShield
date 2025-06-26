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
app.use(express.static(path.join(__dirname, 'public')));

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

// Root endpoint with web interface
app.get('/', (req, res) => {
    res.send(`
<!DOCTYPE html>
<html>
<head>
    <title>BrowserShield - Anti-Detect Browser Manager</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; margin-bottom: 30px; }
        .status { background: #e8f5e8; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .api-info { background: #f0f8ff; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .profiles { margin: 30px 0; }
        .profile { background: #fafafa; padding: 15px; margin: 10px 0; border-radius: 5px; border-left: 4px solid #007bff; }
        .endpoints { background: #fff8dc; padding: 15px; border-radius: 5px; margin: 20px 0; }
        ul { list-style-type: none; padding: 0; }
        li { padding: 8px 0; border-bottom: 1px solid #eee; }
        a { color: #007bff; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .footer { text-align: center; margin-top: 40px; color: #666; }
        .admin-link { background: linear-gradient(135deg, #2c3e50, #3498db); color: white; padding: 15px 30px; border-radius: 50px; text-decoration: none; display: inline-block; margin: 20px 0; font-weight: bold; text-align: center; transition: transform 0.2s; }
        .admin-link:hover { color: white; transform: translateY(-2px); }
    </style>
</head>
<body>
    <div class="container">
        <h1><i class="fas fa-shield-alt"></i> BrowserShield Anti-Detect Browser Manager</h1>
        
        <div class="status">
            <h3><i class="fas fa-check-circle"></i> Service Status</h3>
            <p><strong>Status:</strong> Running in Mock Mode</p>
            <p><strong>Port:</strong> 5000</p>
            <p><strong>API Token:</strong> 4qEar4YvWqO7Djho4CMfprldGshIoKaFfJAEjepvs2k=</p>
            <p><strong>Started:</strong> ${new Date().toISOString()}</p>
        </div>

        <div class="text-center">
            <a href="/admin" class="admin-link">
                <i class="fas fa-cog"></i> Open Admin Panel
            </a>
        </div>

        <div class="api-info">
            <h3><i class="fas fa-code"></i> API Information</h3>
            <p>All API endpoints are functional and return mock data for testing purposes.</p>
            <p>Use the API token above for authenticated requests (if enabled).</p>
        </div>

        <div class="endpoints">
            <h3><i class="fas fa-link"></i> Available Endpoints</h3>
            <ul>
                <li><a href="/health">GET /health</a> - Service health check</li>
                <li><a href="/admin">GET /admin</a> - Admin panel</li>
                <li><a href="/api/profiles">GET /api/profiles</a> - List all profiles</li>
                <li><a href="/api/profiles/sessions/active">GET /api/profiles/sessions/active</a> - Active sessions</li>
                <li>POST /api/profiles - Create new profile</li>
                <li>POST /api/profiles/:id/start - Start browser session</li>
                <li>POST /api/profiles/:id/stop - Stop browser session</li>
                <li>DELETE /api/profiles/:id - Delete profile</li>
            </ul>
        </div>

        <div class="footer">
            <p>BrowserShield v1.0.0 - Anti-Detect Browser Profile Manager</p>
            <p>Running on Node.js ${process.version}</p>
        </div>
    </div>
</body>
</html>
    `);
});

// Admin panel endpoint
app.get('/admin', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'admin.html'));
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
