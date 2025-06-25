const logger = require('../utils/logger');

/**
 * Global error handling middleware
 */
function errorHandler(error, req, res, next) {
    logger.error('Unhandled error:', {
        message: error.message,
        stack: error.stack,
        url: req.url,
        method: req.method,
        ip: req.ip,
        userAgent: req.get('User-Agent')
    });

    // Don't expose internal errors in production
    const isDevelopment = process.env.NODE_ENV !== 'production';
    
    // Default error response
    let statusCode = 500;
    let message = 'Internal server error';
    let details = null;

    // Handle specific error types
    if (error.name === 'ValidationError') {
        statusCode = 400;
        message = 'Validation error';
        details = error.message;
    } else if (error.message && error.message.includes('not found')) {
        statusCode = 404;
        message = error.message;
    } else if (error.message && error.message.includes('already running')) {
        statusCode = 409;
        message = error.message;
    } else if (error.message && error.message.includes('required')) {
        statusCode = 400;
        message = error.message;
    } else if (error.code === 'ECONNREFUSED') {
        statusCode = 503;
        message = 'Service temporarily unavailable';
        details = isDevelopment ? 'Connection refused' : null;
    } else if (error.code === 'ENOTFOUND') {
        statusCode = 502;
        message = 'Bad gateway';
        details = isDevelopment ? 'DNS resolution failed' : null;
    } else if (error.code === 'ETIMEDOUT') {
        statusCode = 504;
        message = 'Gateway timeout';
        details = isDevelopment ? 'Operation timed out' : null;
    }

    const errorResponse = {
        success: false,
        message,
        timestamp: new Date().toISOString(),
        path: req.path,
        method: req.method
    };

    // Add details in development mode or for client errors
    if (isDevelopment || statusCode < 500) {
        if (details) {
            errorResponse.details = details;
        }
        if (isDevelopment && error.stack) {
            errorResponse.stack = error.stack;
        }
    }

    res.status(statusCode).json(errorResponse);
}

module.exports = errorHandler;
