# Anti-Detect Browser Profile Manager

## Overview

This is a Node.js backend application that provides anti-detect browser profile management capabilities similar to GoLogin/Multilogin services. The system allows users to create, manage, and control browser profiles with custom fingerprints and proxy configurations for web automation and privacy purposes.

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

## Changelog

Changelog:
- June 25, 2025. Initial setup