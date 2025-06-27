const request = require('supertest');
const path = require('path');

// Import the app
const app = require('../../server');

describe('API Integration Tests', () => {
    let testProfile;
    
    beforeAll(async () => {
        // Wait for server to be ready
        await new Promise(resolve => setTimeout(resolve, 1000));
    });

    describe('Profile Management API', () => {
        test('should create a new profile', async () => {
            const profileData = {
                name: `Test Profile ${Date.now()}`,
                userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                timezone: 'America/New_York',
                viewport: { width: 1920, height: 1080 },
                proxy: {
                    host: '127.0.0.1',
                    port: 8080,
                    type: 'http'
                }
            };

            const response = await request(app)
                .post('/api/profiles')
                .send(profileData)
                .expect(201);

            expect(response.body.success).toBe(true);
            expect(response.body.data).toMatchObject({
                name: profileData.name,
                userAgent: profileData.userAgent,
                timezone: profileData.timezone
            });
            expect(response.body.data.id).toBeDefined();

            testProfile = response.body.data;
        });

        test('should get all profiles', async () => {
            const response = await request(app)
                .get('/api/profiles')
                .expect(200);

            expect(response.body.success).toBe(true);
            expect(Array.isArray(response.body.data)).toBe(true);
            expect(response.body.count).toBeGreaterThan(0);
        });

        test('should get profile by ID', async () => {
            const response = await request(app)
                .get(`/api/profiles/${testProfile.id}`)
                .expect(200);

            expect(response.body.success).toBe(true);
            expect(response.body.data.id).toBe(testProfile.id);
        });

        test('should update profile', async () => {
            const updates = {
                timezone: 'Europe/London',
                viewport: { width: 1366, height: 768 }
            };

            const response = await request(app)
                .put(`/api/profiles/${testProfile.id}`)
                .send(updates)
                .expect(200);

            expect(response.body.success).toBe(true);
            expect(response.body.data.timezone).toBe(updates.timezone);
        });
    });

    describe('Browser Session API', () => {
        test('should start browser session', async () => {
            const response = await request(app)
                .post(`/api/profiles/${testProfile.id}/start`)
                .send({ autoNavigateUrl: 'https://httpbin.org/headers' })
                .expect(200);

            expect(response.body.success).toBe(true);
            expect(response.body.data.status).toBe('running');
            expect(response.body.data.profileId).toBe(testProfile.id);
        });

        test('should get session status', async () => {
            const response = await request(app)
                .get(`/api/profiles/${testProfile.id}/status`)
                .expect(200);

            expect(response.body.success).toBe(true);
            expect(response.body.data.status).toBe('running');
        });

        test('should get active sessions', async () => {
            const response = await request(app)
                .get('/api/profiles/sessions/active')
                .expect(200);

            expect(response.body.success).toBe(true);
            expect(Array.isArray(response.body.data)).toBe(true);
            expect(response.body.data.length).toBeGreaterThan(0);
        });

        test('should navigate browser to URL', async () => {
            const response = await request(app)
                .post(`/api/profiles/${testProfile.id}/navigate`)
                .send({ url: 'https://httpbin.org/user-agent' })
                .expect(200);

            expect(response.body.success).toBe(true);
            expect(response.body.data.success).toBe(true);
        });

        test('should execute JavaScript in browser', async () => {
            const response = await request(app)
                .post(`/api/profiles/${testProfile.id}/execute`)
                .send({ script: 'return document.title;' })
                .expect(200);

            expect(response.body.success).toBe(true);
            expect(response.body.data).toBeDefined();
        });

        test('should stop browser session', async () => {
            const response = await request(app)
                .post(`/api/profiles/${testProfile.id}/stop`)
                .expect(200);

            expect(response.body.success).toBe(true);
            expect(response.body.message).toContain('stopped');
        });
    });

    describe('System API', () => {
        test('should get system statistics', async () => {
            const response = await request(app)
                .get('/api/profiles/system/stats')
                .expect(200);

            expect(response.body.success).toBe(true);
            expect(response.body.data.profiles).toBeDefined();
            expect(response.body.data.sessions).toBeDefined();
            expect(response.body.data.system).toBeDefined();
        });

        test('should get activity logs', async () => {
            const response = await request(app)
                .get('/api/profiles/system/logs')
                .expect(200);

            expect(response.body.success).toBe(true);
            expect(Array.isArray(response.body.data)).toBe(true);
        });
    });

    describe('Error Handling', () => {
        test('should handle invalid profile ID', async () => {
            const response = await request(app)
                .get('/api/profiles/invalid-id')
                .expect(404);

            expect(response.body.success).toBe(false);
        });

        test('should handle missing required fields', async () => {
            const response = await request(app)
                .post('/api/profiles')
                .send({})
                .expect(400);

            expect(response.body.success).toBe(false);
        });

        test('should handle duplicate profile names', async () => {
            const profileData = {
                name: testProfile.name, // Use existing name
                userAgent: 'Mozilla/5.0...'
            };

            const response = await request(app)
                .post('/api/profiles')
                .send(profileData)
                .expect(400);

            expect(response.body.success).toBe(false);
        });
    });

    afterAll(async () => {
        // Cleanup test profile
        if (testProfile) {
            await request(app)
                .delete(`/api/profiles/${testProfile.id}`)
                .expect(200);
        }
    });
});