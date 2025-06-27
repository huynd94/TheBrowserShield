const BrowserService = require('../../services/BrowserService');
const ProfileService = require('../../services/ProfileService');

describe('Load Testing - Concurrent Sessions', () => {
    let browserService;
    let testProfiles = [];

    beforeAll(async () => {
        browserService = new BrowserService();
        
        // Create test profiles for load testing
        for (let i = 0; i < 15; i++) {
            const profile = {
                name: `Load Test Profile ${i}`,
                userAgent: `Mozilla/5.0 (Test ${i}) AppleWebKit/537.36`,
                timezone: 'America/New_York',
                viewport: { width: 1920, height: 1080 },
                stealthConfig: { 
                    canvasNoise: true,
                    webrtcProtection: true 
                }
            };
            
            const created = await ProfileService.createProfile(profile);
            testProfiles.push(created);
        }
    });

    afterAll(async () => {
        // Stop all browsers and cleanup
        await browserService.stopAllBrowsers();
        
        // Delete test profiles
        for (const profile of testProfiles) {
            await ProfileService.deleteProfile(profile.id);
        }
    });

    test('should handle 10 concurrent browser sessions', async () => {
        const profilesToTest = testProfiles.slice(0, 10);
        
        // Start all browsers concurrently
        const startPromises = profilesToTest.map(profile => 
            browserService.startBrowser(profile.id, 'https://httpbin.org/headers')
        );

        const results = await Promise.allSettled(startPromises);
        
        // All sessions should start successfully
        const successful = results.filter(r => r.status === 'fulfilled');
        expect(successful.length).toBe(10);
        
        // Verify all sessions are active
        const activeSessions = browserService.getAllActiveSessions();
        expect(activeSessions.length).toBe(10);
        
        // Clean up
        const stopPromises = profilesToTest.map(profile =>
            browserService.stopBrowser(profile.id)
        );
        
        await Promise.allSettled(stopPromises);
    }, 120000);

    test('should handle race conditions gracefully', async () => {
        const profile = testProfiles[1];
        const concurrentRequests = 5;
        
        // Try to start the same browser multiple times simultaneously
        const startPromises = Array(concurrentRequests).fill().map(() =>
            browserService.startBrowser(profile.id)
        );
        
        const results = await Promise.allSettled(startPromises);
        
        // Only one should succeed, others should fail with race condition error
        const successful = results.filter(r => r.status === 'fulfilled');
        const failed = results.filter(r => r.status === 'rejected');
        
        expect(successful.length).toBe(1);
        expect(failed.length).toBe(concurrentRequests - 1);
        
        // Clean up
        await browserService.stopBrowser(profile.id);
    });
});