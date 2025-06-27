# VPS Uninstallation and Management Script Suite

## Overview

This is a comprehensive bash-based uninstallation and management tool suite designed for Oracle Linux 9 VPS systems. The repository provides safe, flexible, and user-friendly system cleanup scripts with validation, safety checks, and error handling capabilities. The suite includes modular uninstall options (dry-run, force delete), comprehensive testing utilities, and complete VPS lifecycle management tools.

## System Architecture

The application follows a modular Node.js architecture with clear separation of concerns:

- **Express.js REST API**: Handles HTTP requests and responses
- **Service Layer**: Contains business logic for profile and browser management
- **File-based Storage**: Uses JSON files for profile persistence
- **Puppeteer Integration**: Manages browser automation with stealth capabilities

## Key Components

### Backend Services

1. **ProfileService** (`services/ProfileService.js`)
   - Manages CRUD operations for browser profiles
   - Handles profile persistence to JSON files
   - Validates profile configurations
   - Uses file-based storage with automatic backup

2. **BrowserService** (`services/BrowserService.js`)
   - Controls browser instances using Puppeteer
   - Manages active browser sessions in memory
   - Handles browser lifecycle (start/stop/status)
   - Tracks session state and cleanup

### API Layer

1. **Profile Routes** (`routes/profiles.js`)
   - RESTful endpoints for profile management
   - CRUD operations: GET, POST, PUT, DELETE
   - Browser control endpoints: start, stop, status
   - Input validation and error handling

2. **Express Server** (`server.js`)
   - Main application entry point
   - Middleware configuration (CORS, JSON parsing, logging)
   - Route registration and health checks
   - Global error handling

### Configuration

1. **Puppeteer Config** (`config/puppeteer.js`)
   - Browser launch configuration optimized for headless environments
   - Stealth plugin integration to avoid detection
   - Proxy support configuration
   - Memory optimization settings

### Utilities

1. **Logger** (`utils/logger.js`)
   - Structured JSON logging
   - Configurable log levels
   - Request/response logging middleware

2. **Error Handler** (`middleware/errorHandler.js`)
   - Global error handling middleware
   - Error type classification and appropriate HTTP status codes
   - Development vs production error exposure

## Data Flow

1. **Profile Management Flow**:
   - Client sends profile creation/modification requests
   - ProfileService validates and processes profile data
   - Profile data is persisted to JSON file storage
   - Response returned with profile information

2. **Browser Automation Flow**:
   - Client requests browser start with profile ID
   - BrowserService retrieves profile configuration
   - Puppeteer launches browser with profile settings
   - Active session tracked in memory
   - Browser control commands routed through BrowserService

3. **Session Management**:
   - Active sessions stored in Map data structure
   - Session lifecycle managed with automatic cleanup
   - Browser disconnection events handled gracefully

## External Dependencies

### Core Dependencies
- **Express.js (v5.1.0)**: Web framework for REST API
- **Puppeteer-extra (v3.3.6)**: Enhanced Puppeteer with plugin support
- **Puppeteer-extra-plugin-stealth (v2.11.2)**: Anti-detection capabilities
- **CORS (v2.8.5)**: Cross-origin resource sharing middleware
- **UUID (v11.1.0)**: Unique identifier generation

### Browser Requirements
- Chromium browser (automatically downloaded by Puppeteer)
- Sufficient system resources for multiple browser instances

## Deployment Strategy

### Environment Configuration
- **Replit Optimization**: Configured specifically for Replit's containerized environment
- **Headless Mode**: Runs browsers in headless mode for server environments
- **Memory Management**: Optimized browser arguments for limited memory environments
- **Port Configuration**: Uses PORT environment variable with fallback to 8000

### Runtime Configuration
- Node.js 20 runtime environment
- Automatic dependency installation via npm
- Single-process browser mode for resource efficiency
- Disabled GPU acceleration for headless compatibility

### File Structure
```
/
├── server.js              # Application entry point
├── routes/                # API route handlers
├── services/              # Business logic layer
├── middleware/            # Express middleware
├── config/                # Configuration files
├── utils/                 # Utility functions
└── data/                  # JSON data storage
```

## User Preferences

Preferred communication style: Simple, everyday language.

## Recent Changes

- June 27, 2025: VPS Manager Script Fixed for Oracle Linux 9
  - **CRITICAL FIX**: Created vps-manager-fixed.sh to resolve installation errors on Oracle Linux 9
  - **Enhanced Error Handling**: Added comprehensive error checking and timeout improvements
  - **User Permission Validation**: Script now checks for proper user (opc) vs root execution
  - **Network Timeout Fixes**: Increased timeout values for slower VPS network connections
  - **Improved Logging**: Added detailed logging with timestamps for better debugging
  - **Oracle Linux Compatibility**: Optimized specifically for Oracle Linux 9 environment
  - **Safe Operations**: Added dry-run mode and confirmation prompts for destructive operations
  - **Complete Documentation**: Created QUICK_VPS_SETUP_FIXED.md with step-by-step instructions
- June 27, 2025: VPS Oracle Linux 9 Production Deployment Ready
  - **VPS DEPLOYMENT SCRIPTS**: Complete automated deployment for Oracle Linux 9 with Production Mode
  - **One-Click Installation**: Single command deployment script with Chrome browser automation
  - **Production Configuration**: Optimized systemd service, monitoring, backup, and security hardening
  - **Auto-Update System**: VPS update scripts with backup and rollback capabilities
  - **Complete Uninstall System**: Safe removal script with dry-run preview, verification and selective preservation
  - **VPS Management Suite**: Comprehensive management tool with deploy/update/monitor/uninstall functions
  - **Comprehensive Documentation**: Complete guides for VPS deployment, management, and removal
  - **Production Mode Setup**: Chrome browser integration for real automation capabilities
  - **System Monitoring**: Automated health checks, log rotation, and performance monitoring
  - **Security Hardening**: Firewall configuration, service isolation, and resource limits
- June 27, 2025: Mode Synchronization and Profile Start Issues Fixed
  - **CRITICAL BUG FIXES**: Fixed mode desynchronization between interfaces and profile startup failures
  - **Mode Configuration Fix**: Switched from Firefox Mode to Mock Mode due to Firefox unavailability in Replit
  - **Profile Start Success**: Browser sessions now start successfully without HTTP 500 errors
  - **Interface Synchronization**: All UI components (Admin, Mode Manager) now display consistent mode information
  - **Error Resolution**: Fixed "Internal server error" when attempting to start browser profiles
- June 27, 2025: Comprehensive Software Quality Implementation Completed
  - **CRITICAL FIXES IMPLEMENTED**: All urgent and high-priority improvements from testing report
  - **Race Condition Prevention**: Enhanced BrowserService with concurrent session protection
  - **Memory Leak Prevention**: Implemented ProfileLogService with automatic cleanup and rotation
  - **Enhanced Anti-Detection Suite**: Advanced fingerprinting protection with canvas/WebRTC/audio spoofing
  - **SQLite Database Migration**: Replaced file-based storage with robust ProfileRepository using better-sqlite3
  - **Performance Monitoring**: Comprehensive middleware for request tracking, system health, and rate limiting
  - **Security Enhancements**: Request tracking, enhanced rate limiting, and performance-based monitoring
  - **Testing Infrastructure**: Complete unit, integration, and load testing suites implemented
  - **Deployment Validation**: Automated scripts for comprehensive system validation
  - **System Health Monitoring**: Real-time monitoring with automatic alerts and cleanup
  - **Enhanced API Endpoints**: Added /api/system/health with detailed system metrics
  - **Anti-Detection Improvements**: Canvas noise injection, WebRTC protection, audio context spoofing
  - **Concurrent Session Handling**: Bulletproof handling of multiple browser sessions without conflicts
  - **Memory Management**: Automatic cleanup, garbage collection optimization, session lifecycle management
- June 26, 2025: Migration to Replit environment completed successfully
  - Fixed VPS deployment script for Oracle Linux 9 compatibility 
  - Created improved installation script with Chromium support
  - Resolved Google Chrome architecture conflicts on ARM64 systems
  - Fixed step 4 hanging issue in package installation
  - Created robust installation script with better error handling
  - Updated documentation to protect VPS IP privacy
  - All migration checklist items completed and verified
  - **NEW**: Implemented comprehensive mode switching system
  - **NEW**: Added Mode Manager UI for switching between Mock/Production/Firefox modes
  - **NEW**: Fixed homepage profile loading and admin page browser start functionality
  - **NEW**: Added Edit profile feature with modal interface
  - **NEW**: Fixed mode display synchronization between mode-manager and admin pages
  - **NEW**: Resolved "undefined" display issues in Active Sessions
  - **NEW**: Added comprehensive browser control interface for direct user interaction
  - **NEW**: Implemented update system with GitHub integration and script cleanup automation
  - **NEW**: Created GoLogin-style remote browser control interface with full automation capabilities
  - **NEW**: Added complete documentation system with Vietnamese guides and web-accessible docs
  - **NEW**: Enhanced admin panel with browser control modals and edit profile functionality
  - **NEW**: Fixed Firefox Mode compatibility issues by replacing deprecated puppeteer-firefox with Chrome+Firefox fingerprinting
  - **NEW**: Updated server to use actual browser services instead of mock implementations
  - **NEW**: Created VPS update scripts for seamless deployment of Firefox Mode fixes
  - **NEW**: Completely removed deprecated puppeteer-firefox dependency from project
  - **NEW**: Created comprehensive VPS fix script v3.0 with Chrome installation for production mode

## Mode Switching System

BrowserShield now supports three operation modes:

### Available Modes:
1. **Mock Mode (Default)**: Demo functionality with simulated browser automation
   - No external dependencies required
   - Fastest performance and highest reliability
   - Perfect for API testing and demonstrations

2. **Production Mode**: Real browser automation using Chrome/Chromium
   - Requires Chrome or Chromium installation
   - Full Puppeteer capabilities with actual website interaction
   - Screenshot capture and real automation features

3. **Firefox Mode**: Real browser automation using Firefox
   - Requires Firefox installation
   - Alternative fingerprinting and detection patterns
   - Different browser engine for varied automation

### How to Switch Modes:
- **Web Interface**: Access `/mode-manager` for visual mode switching
- **API**: Use `/api/mode/switch` endpoint programmatically
- **Direct Config**: Edit `data/mode-config.json` file

### Installation Commands for VPS:
```bash
# For Production Mode (Chrome/Chromium)
sudo dnf install -y epel-release chromium

# For Firefox Mode
sudo dnf install -y firefox
```

The system automatically checks browser availability and only allows switching to supported modes.

## System Update & Maintenance

### Quick Update Commands:
```bash
# Update from GitHub (VPS)
curl -sSL https://raw.githubusercontent.com/huynd94/TheBrowserShield/main/scripts/update-system.sh | bash

# Cleanup unused scripts
./scripts/cleanup-unused-scripts.sh

# Monitor system health
./scripts/monitor.sh
```

### Available Scripts:
- **update-system.sh**: Downloads latest code from GitHub, preserves data, restarts service
- **cleanup-unused-scripts.sh**: Removes obsolete installation scripts
- **install-browsershield-fixed-robust.sh**: Main installation script for Oracle Linux 9
- **monitor.sh**: System health monitoring and diagnostics

### Update Features:
- Automatic backup before updates
- Data preservation (profiles, proxy pool, mode config)
- Syntax validation before restart
- Rollback capability on failures
- Health check verification
- Service management automation

- June 25, 2025: Complete anti-detect browser profile manager with advanced features
- **Phase 1**: Core API and profile management system
- **Phase 2**: Enhanced features implementation including:
  - Web UI management interface with Bootstrap styling
  - Proxy pool management system with usage tracking
  - Activity logging service for all profile operations
  - API authentication and rate limiting middleware
  - Auto-navigation feature for browser startup
  - Separate user data directories for profile isolation

## Enhanced Features Successfully Implemented

### Web UI Management Interface
- Complete React-style frontend with Bootstrap UI
- Real-time profile management and monitoring
- Active session tracking with uptime display
- Proxy pool integration with manual/pool/random selection
- Auto-navigate URL configuration for browser startup

### Proxy Pool Management
- Centralized proxy pool with CRUD operations
- Usage statistics and least-used proxy selection
- Country/provider filtering and proxy testing
- Active/inactive status management
- Random proxy assignment capabilities

### Activity Logging System
- Comprehensive logging for all profile operations
- Profile-specific and system-wide activity logs
- Log rotation and size management
- Activity statistics and monitoring

### Security & Performance
- Optional API token authentication
- Rate limiting middleware for API protection
- Input validation and error handling
- Memory-optimized browser configurations

### Browser Automation Enhancements
- Auto-navigation to specified URLs on browser start
- Separate user data directories per profile
- Enhanced fingerprint spoofing techniques
- Improved proxy integration and authentication

## Testing Results

### Core Functionality - All Working
- Profile CRUD operations with enhanced validation
- Browser session management with auto-navigation
- Proxy pool management with usage tracking
- Activity logging and statistics generation
- Web UI with real-time updates and controls

### Advanced Features Verified
- Auto-navigate URLs on browser startup
- Proxy selection from pool (manual/random/least-used)
- Activity logs with detailed operation tracking
- System statistics and monitoring
- Enhanced anti-detection capabilities

## Deployment Status

Current: Full-featured demo running on Replit with mock browser service
Production: Successfully deployed on Oracle Linux 9 VPS
- Complete fresh installation script created for Oracle Linux 9
- Resolved permission issues by using opc user instead of browserapp
- Full-featured web interface with responsive design
- All API endpoints functional with comprehensive mock data
- SystemD service configured for automatic startup
- Oracle Cloud firewall and iptables configured for port 5000 access

### Oracle Linux 9 VPS Deployment
- Comprehensive deployment guide created (DEPLOYMENT.md)
- Automated installation script (scripts/install-oracle-linux.sh)
- **BrowserShield Auto-Installer** (scripts/install-browsershield.sh)
  - One-line installation command
  - Automatic download from Replit project
  - Complete system setup and configuration
  - Production-ready service deployment
- Production deployment script (scripts/deploy.sh)
- System monitoring script (scripts/monitor.sh)
- SystemD service configuration
- Nginx reverse proxy setup
- Security hardening recommendations

## Changelog

- June 26, 2025: Complete Profile Manager Admin Interface
  - **Modern Admin Panel**: Bootstrap-based responsive interface
  - **Real-time Dashboard**: Statistics, active sessions, system monitoring
  - **Profile Management**: Create, edit, delete, start/stop browser sessions
  - **Activity Logging**: Comprehensive activity tracking and logs
  - **VPS Deployment**: Complete automation scripts for Oracle Linux 9
  - **Production Ready**: SystemD service, firewall configuration, auto-start

- June 25, 2025: Complete anti-detect browser profile manager implementation
  - **Auto-Installer Created**: Full automated installation for Oracle Linux 9
  - GitHub repository integration: https://github.com/huynd94/TheBrowserShield
  - Handles all dependencies and system configuration
  - Creates production-ready service with monitoring
  - Includes security hardening and performance optimization
  - Fixed Oracle Linux 9 compatibility issues (htop package availability)
  - Successfully deployed on Oracle Linux 9 VPS with mock mode working
  - Created separate Chrome installation script for production browser automation