#!/usr/bin/env node
/**
 * Comprehensive test suite runner for BrowserShield
 * Validates all critical improvements and system functionality
 */

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

class TestSuiteRunner {
    constructor() {
        this.results = {
            unit: { passed: 0, failed: 0, tests: [] },
            integration: { passed: 0, failed: 0, tests: [] },
            load: { passed: 0, failed: 0, tests: [] },
            performance: { passed: 0, failed: 0, tests: [] }
        };
        this.startTime = Date.now();
    }

    async runAllTests() {
        console.log('🧪 Starting BrowserShield Comprehensive Test Suite');
        console.log('=' * 60);

        try {
            await this.runUnitTests();
            await this.runIntegrationTests();
            await this.runLoadTests();
            await this.runPerformanceTests();
            
            this.generateReport();
        } catch (error) {
            console.error('❌ Test suite failed:', error.message);
            process.exit(1);
        }
    }

    async runUnitTests() {
        console.log('\n📋 Running Unit Tests...');
        
        const testFiles = this.getTestFiles('tests/unit');
        for (const testFile of testFiles) {
            try {
                console.log(`  Testing: ${path.basename(testFile)}`);
                const result = await this.runTestFile(testFile);
                this.results.unit.tests.push({ file: testFile, result });
                if (result.success) {
                    this.results.unit.passed++;
                } else {
                    this.results.unit.failed++;
                }
            } catch (error) {
                console.error(`    ❌ Failed: ${error.message}`);
                this.results.unit.failed++;
                this.results.unit.tests.push({ file: testFile, result: { success: false, error: error.message } });
            }
        }
    }

    async runIntegrationTests() {
        console.log('\n🔗 Running Integration Tests...');
        
        // Start test server
        const server = this.startTestServer();
        
        try {
            const testFiles = this.getTestFiles('tests/integration');
            for (const testFile of testFiles) {
                try {
                    console.log(`  Testing: ${path.basename(testFile)}`);
                    const result = await this.runTestFile(testFile);
                    this.results.integration.tests.push({ file: testFile, result });
                    if (result.success) {
                        this.results.integration.passed++;
                    } else {
                        this.results.integration.failed++;
                    }
                } catch (error) {
                    console.error(`    ❌ Failed: ${error.message}`);
                    this.results.integration.failed++;
                }
            }
        } finally {
            this.stopTestServer(server);
        }
    }

    async runLoadTests() {
        console.log('\n⚡ Running Load Tests...');
        
        const testFiles = this.getTestFiles('tests/load');
        for (const testFile of testFiles) {
            try {
                console.log(`  Testing: ${path.basename(testFile)}`);
                const result = await this.runTestFile(testFile, 180000); // 3 minute timeout
                this.results.load.tests.push({ file: testFile, result });
                if (result.success) {
                    this.results.load.passed++;
                } else {
                    this.results.load.failed++;
                }
            } catch (error) {
                console.error(`    ❌ Failed: ${error.message}`);
                this.results.load.failed++;
            }
        }
    }

    async runPerformanceTests() {
        console.log('\n🚀 Running Performance Tests...');
        
        try {
            // Memory usage test
            const memoryResult = await this.testMemoryUsage();
            this.results.performance.tests.push({ test: 'Memory Usage', result: memoryResult });
            
            // Response time test
            const responseResult = await this.testResponseTimes();
            this.results.performance.tests.push({ test: 'Response Times', result: responseResult });
            
            // Concurrent handling test
            const concurrentResult = await this.testConcurrentHandling();
            this.results.performance.tests.push({ test: 'Concurrent Handling', result: concurrentResult });
            
            this.results.performance.passed = this.results.performance.tests.filter(t => t.result.success).length;
            this.results.performance.failed = this.results.performance.tests.filter(t => !t.result.success).length;
            
        } catch (error) {
            console.error(`    ❌ Performance tests failed: ${error.message}`);
            this.results.performance.failed++;
        }
    }

    async testMemoryUsage() {
        console.log('  Testing memory usage...');
        const initialMemory = process.memoryUsage();
        
        // Simulate memory-intensive operations
        const BrowserService = require('../services/BrowserService');
        const browserService = new BrowserService();
        
        // Create and destroy multiple sessions
        for (let i = 0; i < 5; i++) {
            try {
                await browserService.startBrowser('test-profile');
                await browserService.stopBrowser('test-profile');
            } catch (error) {
                // Expected to fail in test environment
            }
        }
        
        const finalMemory = process.memoryUsage();
        const memoryIncrease = finalMemory.heapUsed - initialMemory.heapUsed;
        
        return {
            success: memoryIncrease < 50 * 1024 * 1024, // Less than 50MB increase
            memoryIncrease,
            details: `Memory increase: ${Math.round(memoryIncrease / 1024 / 1024)}MB`
        };
    }

    async testResponseTimes() {
        console.log('  Testing API response times...');
        const request = require('supertest');
        const app = require('../server');
        
        const startTime = Date.now();
        
        try {
            await request(app).get('/api/profiles').expect(200);
            const responseTime = Date.now() - startTime;
            
            return {
                success: responseTime < 1000, // Less than 1 second
                responseTime,
                details: `Response time: ${responseTime}ms`
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                details: 'API response test failed'
            };
        }
    }

    async testConcurrentHandling() {
        console.log('  Testing concurrent request handling...');
        const request = require('supertest');
        const app = require('../server');
        
        const startTime = Date.now();
        const concurrentRequests = 10;
        
        try {
            const promises = Array(concurrentRequests).fill().map(() =>
                request(app).get('/api/profiles')
            );
            
            const results = await Promise.allSettled(promises);
            const successful = results.filter(r => r.status === 'fulfilled').length;
            const totalTime = Date.now() - startTime;
            
            return {
                success: successful === concurrentRequests && totalTime < 5000,
                successful,
                totalTime,
                details: `${successful}/${concurrentRequests} requests successful in ${totalTime}ms`
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                details: 'Concurrent handling test failed'
            };
        }
    }

    getTestFiles(directory) {
        try {
            return fs.readdirSync(directory)
                .filter(file => file.endsWith('.test.js'))
                .map(file => path.join(directory, file));
        } catch (error) {
            console.log(`  No tests found in ${directory}`);
            return [];
        }
    }

    async runTestFile(testFile, timeout = 60000) {
        return new Promise((resolve, reject) => {
            const child = spawn('node', [testFile], {
                stdio: 'pipe',
                timeout
            });

            let output = '';
            child.stdout.on('data', (data) => {
                output += data.toString();
            });

            child.stderr.on('data', (data) => {
                output += data.toString();
            });

            child.on('close', (code) => {
                resolve({
                    success: code === 0,
                    output,
                    exitCode: code
                });
            });

            child.on('error', (error) => {
                reject(error);
            });
        });
    }

    startTestServer() {
        console.log('  Starting test server...');
        const server = spawn('node', ['server.js'], {
            stdio: 'pipe',
            env: { ...process.env, NODE_ENV: 'test', PORT: '5001' }
        });

        // Wait for server to start
        return new Promise((resolve) => {
            setTimeout(() => resolve(server), 2000);
        });
    }

    stopTestServer(server) {
        console.log('  Stopping test server...');
        if (server && server.kill) {
            server.kill();
        }
    }

    generateReport() {
        const totalTime = Date.now() - this.startTime;
        const totalPassed = Object.values(this.results).reduce((sum, category) => sum + category.passed, 0);
        const totalFailed = Object.values(this.results).reduce((sum, category) => sum + category.failed, 0);
        const totalTests = totalPassed + totalFailed;

        console.log('\n' + '=' * 60);
        console.log('📊 Test Suite Results');
        console.log('=' * 60);
        
        console.log(`\n⏱️  Total Time: ${Math.round(totalTime / 1000)}s`);
        console.log(`✅ Total Passed: ${totalPassed}`);
        console.log(`❌ Total Failed: ${totalFailed}`);
        console.log(`📈 Success Rate: ${Math.round((totalPassed / totalTests) * 100)}%\n`);

        // Category breakdown
        Object.entries(this.results).forEach(([category, result]) => {
            const total = result.passed + result.failed;
            if (total > 0) {
                console.log(`${category.toUpperCase()}: ${result.passed}/${total} passed`);
            }
        });

        // Save detailed report
        const reportData = {
            timestamp: new Date().toISOString(),
            duration: totalTime,
            summary: { totalPassed, totalFailed, totalTests },
            categories: this.results
        };

        fs.writeFileSync('test-report.json', JSON.stringify(reportData, null, 2));
        console.log('\n📄 Detailed report saved to test-report.json');

        if (totalFailed === 0) {
            console.log('\n🎉 All tests passed! BrowserShield is ready for deployment.');
        } else {
            console.log(`\n⚠️  ${totalFailed} test(s) failed. Please review the issues above.`);
            process.exit(1);
        }
    }
}

// Run the test suite if called directly
if (require.main === module) {
    const runner = new TestSuiteRunner();
    runner.runAllTests().catch(console.error);
}

module.exports = TestSuiteRunner;