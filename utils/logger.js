/**
 * Simple logger utility
 */
class Logger {
    constructor() {
        this.logLevel = process.env.LOG_LEVEL || 'info';
    }

    /**
     * Get timestamp string
     */
    getTimestamp() {
        return new Date().toISOString();
    }

    /**
     * Format log message
     */
    formatMessage(level, message, meta = {}) {
        const timestamp = this.getTimestamp();
        const logObj = {
            timestamp,
            level: level.toUpperCase(),
            message,
            ...meta
        };
        
        return JSON.stringify(logObj);
    }

    /**
     * Log info message
     */
    info(message, meta = {}) {
        if (this.shouldLog('info')) {
            console.log(this.formatMessage('info', message, meta));
        }
    }

    /**
     * Log error message
     */
    error(message, meta = {}) {
        if (this.shouldLog('error')) {
            console.error(this.formatMessage('error', message, meta));
        }
    }

    /**
     * Log warning message
     */
    warn(message, meta = {}) {
        if (this.shouldLog('warn')) {
            console.warn(this.formatMessage('warn', message, meta));
        }
    }

    /**
     * Log debug message
     */
    debug(message, meta = {}) {
        if (this.shouldLog('debug')) {
            console.log(this.formatMessage('debug', message, meta));
        }
    }

    /**
     * Check if we should log at this level
     */
    shouldLog(level) {
        const levels = ['error', 'warn', 'info', 'debug'];
        const currentLevelIndex = levels.indexOf(this.logLevel);
        const messageLevelIndex = levels.indexOf(level);
        
        return currentLevelIndex >= messageLevelIndex;
    }
}

module.exports = new Logger();
