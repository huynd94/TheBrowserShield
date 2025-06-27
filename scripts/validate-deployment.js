#!/usr/bin/env node
/**
 * Comprehensive deployment validation script for BrowserShield
 * Validates all critical improvements and system functionality
 */

const http = require('http');
const { execSync } = require('child_process');

class DeploymentValidator {
    constructor(baseUrl = 'http://localhost:5000') {
        this.baseUrl = baseUrl;
        this.results = {
            api: [],
            security: [],
            performance: [],
            features: []
        };
    }

    async validateDeployment() {
        console.log('🔍 Starting BrowserShield Deployment Validation');
        console.log('=' * 60);

        try {
            await this.validateAPI();
            await this.validateSecurity();
            await this.validatePerformance();
            await this.validateFeatures();
            
            this.generateReport();
        } catch (error) {
            console.error('❌ Deployment validation failed:', error.message);
            process.exit(1);
        }
    }

    async validateAPI() {
        console.log('\n🔗 Validating API Endpoints...');
        
        const endpoints = [
            { path: '/health', method: 'GET', expected: 200 },
            { path: '/api/system/health', method: 'GET', expected: 200 },
            { path: '/api/profiles', method: 'GET', expected: 200 },
            { path: '/api/mode', method: 'GET', expected: 200 },
            { path: '/api/proxy', method: 'GET', expected: 200 }
        ];

        for (const endpoint of endpoints) {
            try {
                const result = await this.makeRequest(endpoint.path, endpoint.method);
                const success = result.statusCode === endpoint.expected;
                
                this.results.api.push({
                    endpoint: endpoint.path,
                    method: endpoint.method,
                    expected: endpoint.expected,
                    actual: result.statusCode,
                    success,
                    responseTime: result.responseTime
                });

                console.log(`  ${success ? '✅' : '❌'} ${endpoint.method} ${endpoint.path} - ${result.statusCode} (${result.responseTime}ms)`);
            } catch (error) {
                this.results.api.push({
                    endpoint: endpoint.path,
                    method: endpoint.method,
                    success: false,
                    error: error.message
                });
                console.log(`  ❌ ${endpoint.method} ${endpoint.path} - ${error.message}`);
            }
        }
    }

    async validateSecurity() {
        console.log('\n🔐 Validating Security Features...');
        
        try {
            // Test rate limiting headers
            const response = await this.makeRequest('/api/profiles');
            const hasRateLimitHeaders = response.headers['x-ratelimit-limit'] !== undefined;
            
            this.results.security.push({
                feature: 'Rate Limiting Headers',
                success: hasRateLimitHeaders,
                details: hasRateLimitHeaders ? 'Present' : 'Missing'
            });

            // Test request tracking
            const hasRequestId = response.headers['x-request-id'] !== undefined;
            
            this.results.security.push({
                feature: 'Request Tracking',
                success: hasRequestId,
                details: hasRequestId ? 'Present' : 'Missing'
            });

            console.log(`  ${hasRateLimitHeaders ? '✅' : '❌'} Rate Limiting Headers`);
            console.log(`  ${hasRequestId ? '✅' : '❌'} Request Tracking`);

        } catch (error) {
            console.log(`  ❌ Security validation failed: ${error.message}`);
        }
    }

    async validatePerformance() {
        console.log('\n🚀 Validating Performance...');
        
        try {
            // Test response times
            const startTime = Date.now();
            await this.makeRequest('/api/profiles');
            const responseTime = Date.now() - startTime;
            
            const fastResponse = responseTime < 1000;
            this.results.performance.push({
                metric: 'Response Time',
                value: responseTime,
                unit: 'ms',
                success: fastResponse,
                threshold: 1000
            });

            // Test concurrent requests
            const concurrentStart = Date.now();
            const promises = Array(5).fill().map(() => this.makeRequest('/health'));
            await Promise.all(promises);
            const concurrentTime = Date.now() - concurrentStart;
            
            const goodConcurrency = concurrentTime < 2000;
            this.results.performance.push({
                metric: 'Concurrent Handling',
                value: concurrentTime,
                unit: 'ms',
                success: goodConcurrency,
                threshold: 2000
            });

            console.log(`  ${fastResponse ? '✅' : '❌'} Response Time: ${responseTime}ms`);
            console.log(`  ${goodConcurrency ? '✅' : '❌'} Concurrent Handling: ${concurrentTime}ms`);

        } catch (error) {
            console.log(`  ❌ Performance validation failed: ${error.message}`);
        }
    }

    async validateFeatures() {
        console.log('\n🎯 Validating Core Features...');
        
        const features = [
            { name: 'Mode Switching', path: '/api/mode' },
            { name: 'Profile Management', path: '/api/profiles' },
            { name: 'Proxy Pool', path: '/api/proxy' },
            { name: 'System Health', path: '/api/system/health' }
        ];

        for (const feature of features) {
            try {
                const response = await this.makeRequest(feature.path);
                const success = response.statusCode === 200 && response.data.success !== false;
                
                this.results.features.push({
                    feature: feature.name,
                    success,
                    statusCode: response.statusCode
                });

                console.log(`  ${success ? '✅' : '❌'} ${feature.name}`);
            } catch (error) {
                this.results.features.push({
                    feature: feature.name,
                    success: false,
                    error: error.message
                });
                console.log(`  ❌ ${feature.name} - ${error.message}`);
            }
        }
    }

    async makeRequest(path, method = 'GET') {
        return new Promise((resolve, reject) => {
            const startTime = Date.now();
            const url = new URL(path, this.baseUrl);
            
            const req = http.request({
                hostname: url.hostname,
                port: url.port,
                path: url.pathname + url.search,
                method: method,
                headers: {
                    'User-Agent': 'BrowserShield-Validator/1.0'
                }
            }, (res) => {
                let data = '';
                
                res.on('data', (chunk) => {
                    data += chunk;
                });
                
                res.on('end', () => {
                    try {
                        const parsedData = data ? JSON.parse(data) : {};
                        resolve({
                            statusCode: res.statusCode,
                            headers: res.headers,
                            data: parsedData,
                            responseTime: Date.now() - startTime
                        });
                    } catch (error) {
                        resolve({
                            statusCode: res.statusCode,
                            headers: res.headers,
                            data: data,
                            responseTime: Date.now() - startTime
                        });
                    }
                });
            });

            req.on('error', (error) => {
                reject(error);
            });

            req.setTimeout(10000, () => {
                req.destroy();
                reject(new Error('Request timeout'));
            });

            req.end();
        });
    }

    generateReport() {
        console.log('\n' + '=' * 60);
        console.log('📊 Deployment Validation Results');
        console.log('=' * 60);

        const categories = ['api', 'security', 'performance', 'features'];
        let totalPassed = 0;
        let totalTests = 0;

        categories.forEach(category => {
            const results = this.results[category];
            if (results.length > 0) {
                const passed = results.filter(r => r.success).length;
                const total = results.length;
                totalPassed += passed;
                totalTests += total;
                
                console.log(`\n${category.toUpperCase()}: ${passed}/${total} passed`);
                
                results.forEach(result => {
                    if (!result.success) {
                        console.log(`  ❌ ${result.feature || result.endpoint || result.metric}: ${result.error || result.details || 'Failed'}`);
                    }
                });
            }
        });

        const successRate = Math.round((totalPassed / totalTests) * 100);
        console.log(`\n📈 Overall Success Rate: ${successRate}%`);
        console.log(`✅ Passed: ${totalPassed}`);
        console.log(`❌ Failed: ${totalTests - totalPassed}`);

        if (successRate >= 90) {
            console.log('\n🎉 Deployment validation successful! BrowserShield is ready for production.');
        } else if (successRate >= 75) {
            console.log('\n⚠️  Deployment has some issues but is functional. Review failed tests.');
        } else {
            console.log('\n❌ Deployment validation failed. Critical issues need to be resolved.');
            process.exit(1);
        }
    }
}

// Run validation if called directly
if (require.main === module) {
    const validator = new DeploymentValidator();
    validator.validateDeployment().catch(console.error);
}

module.exports = DeploymentValidator;