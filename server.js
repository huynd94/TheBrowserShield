const express = require('express');
const cors = require('cors');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Request logging
app.use((req, res, next) => {
    const timestamp = new Date().toISOString();
    console.log(`${timestamp} - ${req.method} ${req.path} - ${req.ip}`);
    next();
});

// In-memory storage for demo
let profiles = [
    {
        id: uuidv4(),
        name: "Default Profile",
        userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
        timezone: "America/New_York",
        viewport: { width: 1920, height: 1080 },
        status: "mock",
        createdAt: new Date().toISOString()
    },
    {
        id: uuidv4(),
        name: "Mobile Profile", 
        userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
        timezone: "Europe/London",
        viewport: { width: 375, height: 667 },
        status: "mock",
        createdAt: new Date().toISOString()
    },
    {
        id: uuidv4(),
        name: "MacOS Profile",
        userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
        timezone: "Asia/Tokyo",
        viewport: { width: 1440, height: 900 },
        status: "mock",
        createdAt: new Date().toISOString()
    }
];

let activeSessions = [];
let serverStartTime = Date.now();

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        service: 'BrowserShield Anti-Detect Browser Manager',
        mode: 'Mock Mode',
        timestamp: new Date().toISOString(),
        uptime: Math.floor((Date.now() - serverStartTime) / 1000),
        version: '1.0.0'
    });
});

// Serve documentation files
app.get('/INSTALL.md', (req, res) => {
    res.sendFile(path.join(__dirname, 'INSTALL.md'));
});

app.get('/HUONG_DAN_UPDATE.md', (req, res) => {
    res.sendFile(path.join(__dirname, 'HUONG_DAN_UPDATE.md'));
});

app.get('/UPDATE_GUIDE.md', (req, res) => {
    res.sendFile(path.join(__dirname, 'UPDATE_GUIDE.md'));
});

app.get('/DEPLOYMENT.md', (req, res) => {
    res.sendFile(path.join(__dirname, 'DEPLOYMENT.md'));
});

app.get('/README.md', (req, res) => {
    res.sendFile(path.join(__dirname, 'README.md'));
});

// Browser control interface
app.get('/browser-control', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'browser-control.html'));
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

// Serve mode manager page
app.get('/mode-manager', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'mode-manager.html'));
});

// Mode Management API
const ModeSwitcher = require('./config/mode-switcher');
const modeSwitcher = new ModeSwitcher();

// Mode endpoints
app.get('/api/mode', (req, res) => {
    try {
        const modeInfo = modeSwitcher.getCurrentModeInfo();
        res.json({
            success: true,
            data: modeInfo
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to get mode information'
        });
    }
});

app.post('/api/mode/switch', (req, res) => {
    try {
        const { mode } = req.body;
        
        if (!mode) {
            return res.status(400).json({
                success: false,
                error: 'Mode is required'
            });
        }

        const result = modeSwitcher.switchMode(mode);
        
        if (result.success) {
            res.json({
                success: true,
                data: result,
                message: 'Mode switched successfully. Server restart required.'
            });
        } else {
            res.status(400).json({
                success: false,
                error: result.error
            });
        }
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to switch mode'
        });
    }
});

app.get('/api/mode/check-requirements', (req, res) => {
    try {
        const modes = modeSwitcher.getAvailableModes();
        res.json({
            success: true,
            data: modes
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to check requirements'
        });
    }
});

// API Routes
app.get('/api/profiles', (req, res) => {
    res.json({
        success: true,
        count: profiles.length,
        profiles: profiles
    });
});

app.post('/api/profiles', (req, res) => {
    const { name, userAgent, timezone, viewport, proxy, autoNavigateUrl } = req.body;
    
    if (!name) {
        return res.status(400).json({
            success: false,
            error: 'Profile name is required'
        });
    }

    const profile = {
        id: uuidv4(),
        name,
        userAgent: userAgent || "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
        timezone: timezone || "America/New_York",
        viewport: viewport || { width: 1920, height: 1080 },
        proxy: proxy || null,
        autoNavigateUrl: autoNavigateUrl || null,
        status: "mock",
        createdAt: new Date().toISOString()
    };

    profiles.push(profile);
    
    res.json({
        success: true,
        profile: profile
    });
});

app.get('/api/profiles/:id', (req, res) => {
    const profile = profiles.find(p => p.id === req.params.id);
    if (!profile) {
        return res.status(404).json({
            success: false,
            error: 'Profile not found'
        });
    }
    
    res.json({
        success: true,
        profile: profile
    });
});

app.delete('/api/profiles/:id', (req, res) => {
    const profileIndex = profiles.findIndex(p => p.id === req.params.id);
    if (profileIndex === -1) {
        return res.status(404).json({
            success: false,
            error: 'Profile not found'
        });
    }

    // Stop session if active
    const sessionIndex = activeSessions.findIndex(s => s.profileId === req.params.id);
    if (sessionIndex !== -1) {
        activeSessions.splice(sessionIndex, 1);
    }

    // Remove profile
    const deletedProfile = profiles.splice(profileIndex, 1)[0];
    
    res.json({
        success: true,
        message: 'Profile deleted successfully',
        profile: deletedProfile
    });
});

app.post('/api/profiles/:id/start', (req, res) => {
    const profile = profiles.find(p => p.id === req.params.id);
    if (!profile) {
        return res.status(404).json({
            success: false,
            error: 'Profile not found'
        });
    }

    // Check if session already exists
    const existingSession = activeSessions.find(s => s.profileId === req.params.id);
    if (existingSession) {
        return res.json({
            success: true,
            message: 'Session already active',
            session: existingSession
        });
    }

    // Mock browser session
    const session = {
        profileId: req.params.id,
        sessionId: uuidv4(),
        status: 'mock_active',
        startTime: Date.now(),
        browserType: 'mock',
        currentUrl: req.body.autoNavigateUrl || profile.autoNavigateUrl || 'about:blank'
    };

    activeSessions.push(session);

    res.json({
        success: true,
        message: 'Mock browser session started',
        session: {
            ...session,
            uptime: 0
        }
    });
});

app.post('/api/profiles/:id/stop', (req, res) => {
    const sessionIndex = activeSessions.findIndex(s => s.profileId === req.params.id);
    if (sessionIndex === -1) {
        return res.status(404).json({
            success: false,
            error: 'No active session found'
        });
    }

    const stoppedSession = activeSessions.splice(sessionIndex, 1)[0];

    res.json({
        success: true,
        message: 'Mock browser session stopped',
        session: stoppedSession
    });
});

app.get('/api/profiles/sessions/active', (req, res) => {
    const sessionsWithUptime = activeSessions.map(session => ({
        ...session,
        uptime: Math.floor((Date.now() - session.startTime) / 1000)
    }));

    res.json({
        success: true,
        count: sessionsWithUptime.length,
        sessions: sessionsWithUptime
    });
});

// Mock navigation endpoint
app.post('/api/profiles/:id/navigate', (req, res) => {
    const { url } = req.body;
    const session = activeSessions.find(s => s.profileId === req.params.id);
    
    if (!session) {
        return res.status(404).json({
            success: false,
            error: 'No active session found'
        });
    }

    session.currentUrl = url;
    
    res.json({
        success: true,
        message: `Mock navigation to ${url}`,
        currentUrl: url
    });
});

// Mock script execution endpoint
app.post('/api/profiles/:id/execute', (req, res) => {
    const { script } = req.body;
    const session = activeSessions.find(s => s.profileId === req.params.id);
    
    if (!session) {
        return res.status(404).json({
            success: false,
            error: 'No active session found'
        });
    }
    
    res.json({
        success: true,
        message: 'Mock script execution completed',
        result: `Mock result for: ${script.substring(0, 50)}...`
    });
});

// Error handling
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(500).json({
        success: false,
        error: 'Internal server error'
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found'
    });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🛡️ BrowserShield Anti-Detect Browser Manager running on port ${PORT}`);
    console.log(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🌐 Access: http://localhost:${PORT}`);
    
    // Display current mode
    try {
        const currentMode = modeSwitcher.getCurrentModeInfo();
        console.log(`🎭 Mode: ${currentMode.info.name}`);
    } catch (error) {
        console.log(`🎭 Mode: Mock (Demo)`);
    }
});

module.exports = app;