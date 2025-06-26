// BrowserShield Admin Interface JavaScript
class BrowserShieldAdmin {
    constructor() {
        this.baseUrl = window.location.origin;
        this.profiles = [];
        this.sessions = [];
        this.logs = [];
        this.currentSection = 'profiles';
        this.refreshInterval = null;
        
        this.init();
    }

    async init() {
        console.log('Initializing BrowserShield Admin...');
        
        // Setup event handlers
        this.setupEventHandlers();
        
        // Load initial data
        await this.loadInitialData();
        
        // Start auto-refresh
        this.startAutoRefresh();
        
        console.log('Admin interface initialized');
    }

    setupEventHandlers() {
        // Profile form submission
        document.getElementById('profileForm').addEventListener('submit', (e) => {
            e.preventDefault();
            this.createProfile();
        });

        // Navigation clicks
        document.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const section = e.target.getAttribute('href').substring(1);
                this.showSection(section);
            });
        });
    }

    async loadInitialData() {
        await Promise.all([
            this.loadProfiles(),
            this.loadSessions(),
            this.loadLogs(),
            this.updateStats()
        ]);
    }

    async loadProfiles() {
        try {
            console.log('Loading profiles...');
            const response = await fetch(`${this.baseUrl}/api/profiles`);
            const data = await response.json();
            
            // Handle different response formats
            if (data.success && data.data) {
                this.profiles = data.data;
            } else if (data.profiles) {
                this.profiles = data.profiles;
            } else if (Array.isArray(data)) {
                this.profiles = data;
            } else {
                this.profiles = [];
            }
            
            this.renderProfiles();
            console.log(`Loaded ${this.profiles.length} profiles`);
        } catch (error) {
            console.error('Error loading profiles:', error);
            this.showToast('Error loading profiles', 'error');
        }
    }

    async loadSessions() {
        try {
            const response = await fetch(`${this.baseUrl}/api/profiles/sessions/active`);
            const data = await response.json();
            
            // Handle different response formats
            if (data.success && data.data) {
                this.sessions = data.data;
            } else if (data.sessions) {
                this.sessions = data.sessions;
            } else if (Array.isArray(data)) {
                this.sessions = data;
            } else {
                this.sessions = [];
            }
            
            this.renderSessions();
            console.log(`Loaded ${this.sessions.length} active sessions`);
        } catch (error) {
            console.error('Error loading sessions:', error);
            this.showToast('Error loading sessions', 'error');
        }
    }

    async loadLogs() {
        try {
            // Mock logs for demo
            const mockLogs = [
                { timestamp: new Date().toISOString(), action: 'Profile Created', details: 'New profile "Test Profile" created', profileId: 'mock-1' },
                { timestamp: new Date(Date.now() - 300000).toISOString(), action: 'Session Started', details: 'Browser session started for profile "Default"', profileId: 'mock-2' },
                { timestamp: new Date(Date.now() - 600000).toISOString(), action: 'Profile Updated', details: 'Profile settings updated', profileId: 'mock-1' },
                { timestamp: new Date(Date.now() - 900000).toISOString(), action: 'Session Stopped', details: 'Browser session stopped', profileId: 'mock-3' }
            ];
            
            this.logs = mockLogs;
            this.renderLogs();
        } catch (error) {
            console.error('Error loading logs:', error);
        }
    }

    async updateStats() {
        try {
            // Update profile count
            document.getElementById('totalProfiles').textContent = this.profiles.length;
            
            // Update active sessions count
            document.getElementById('activeSessions').textContent = this.sessions.length;
            
            // Mock proxy count
            document.getElementById('totalProxies').textContent = '5';
            
            // Update uptime
            const response = await fetch(`${this.baseUrl}/health`);
            const data = await response.json();
            if (data.uptime) {
                document.getElementById('systemUptime').textContent = this.formatUptime(data.uptime);
            }
        } catch (error) {
            console.error('Error updating stats:', error);
        }
    }

    renderProfiles() {
        const container = document.getElementById('profilesContainer');
        
        if (this.profiles.length === 0) {
            container.innerHTML = `
                <div class="text-center p-4">
                    <i class="fas fa-users fa-3x text-muted mb-3"></i>
                    <h5>No Profiles Found</h5>
                    <p class="text-muted">Create your first browser profile to get started</p>
                    <button class="btn btn-primary" onclick="showCreateProfile()">
                        <i class="fas fa-plus me-2"></i>Create Profile
                    </button>
                </div>
            `;
            return;
        }

        const profilesHtml = this.profiles.map(profile => {
            const isActive = this.sessions.some(session => session.profileId === profile.id);
            const activeSession = this.sessions.find(session => session.profileId === profile.id);
            
            return `
                <div class="profile-card card mb-3 ${isActive ? 'active' : ''}">
                    <div class="card-body">
                        <div class="row align-items-center">
                            <div class="col-md-8">
                                <div class="d-flex align-items-center mb-2">
                                    <span class="session-indicator ${isActive ? 'session-active' : 'session-inactive'}"></span>
                                    <h6 class="mb-0 me-2">${profile.name}</h6>
                                    <span class="badge ${isActive ? 'bg-success' : 'bg-secondary'} status-badge">
                                        ${isActive ? 'Active' : 'Inactive'}
                                    </span>
                                </div>
                                <div class="small text-muted">
                                    <div><strong>User Agent:</strong> ${this.truncateText(profile.userAgent, 50)}</div>
                                    <div><strong>Timezone:</strong> ${profile.timezone}</div>
                                    <div><strong>Viewport:</strong> ${profile.viewport.width}x${profile.viewport.height}</div>
                                    ${profile.proxy ? `<div><strong>Proxy:</strong> <span class="proxy-indicator proxy-active">Enabled</span></div>` : ''}
                                    ${activeSession ? `<div><strong>Uptime:</strong> ${this.formatUptime(activeSession.uptime)}</div>` : ''}
                                </div>
                            </div>
                            <div class="col-md-4 text-end">
                                <div class="btn-group" role="group">
                                    ${isActive ? 
                                        `<button class="btn btn-sm btn-outline-danger btn-action" onclick="browserShieldAdmin.stopSession('${profile.id}')">
                                            <i class="fas fa-stop"></i> Stop
                                        </button>` :
                                        `<button class="btn btn-sm btn-outline-success btn-action" onclick="browserShieldAdmin.startSession('${profile.id}')">
                                            <i class="fas fa-play"></i> Start
                                        </button>`
                                    }
                                    <button class="btn btn-sm btn-outline-primary btn-action" onclick="browserShieldAdmin.showProfileDetails('${profile.id}')">
                                        <i class="fas fa-eye"></i> View
                                    </button>
                                    <button class="btn btn-sm btn-outline-warning btn-action" onclick="browserShieldAdmin.editProfile('${profile.id}')">
                                        <i class="fas fa-edit"></i> Edit
                                    </button>
                                    <button class="btn btn-sm btn-outline-danger btn-action" onclick="browserShieldAdmin.deleteProfile('${profile.id}')">
                                        <i class="fas fa-trash"></i> Delete
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            `;
        }).join('');

        container.innerHTML = profilesHtml;
    }

    renderSessions() {
        const container = document.getElementById('sessionsContainer');
        
        if (this.sessions.length === 0) {
            container.innerHTML = `
                <div class="text-center p-4">
                    <i class="fas fa-desktop fa-3x text-muted mb-3"></i>
                    <h5>No Active Sessions</h5>
                    <p class="text-muted">Start a browser profile to see active sessions here</p>
                </div>
            `;
            return;
        }

        const sessionsHtml = this.sessions.map(session => {
            const profile = this.profiles.find(p => p.id === session.profileId);
            const profileName = profile ? profile.name : 'Unknown Profile';
            
            return `
                <div class="card mb-3">
                    <div class="card-body">
                        <div class="row align-items-center">
                            <div class="col-md-8">
                                <div class="d-flex align-items-center mb-2">
                                    <span class="session-indicator session-active"></span>
                                    <h6 class="mb-0 me-2">${profileName}</h6>
                                    <span class="badge bg-success status-badge">Active</span>
                                </div>
                                <div class="small text-muted">
                                    <div><strong>Session ID:</strong> ${session.sessionId}</div>
                                    <div><strong>Browser:</strong> ${session.browserType}</div>
                                    <div><strong>Current URL:</strong> ${session.currentUrl}</div>
                                    <div><strong>Uptime:</strong> ${this.formatUptime(session.uptime)}</div>
                                    <div><strong>Started:</strong> ${new Date(session.startTime).toLocaleString()}</div>
                                </div>
                            </div>
                            <div class="col-md-4 text-end">
                                <div class="btn-group" role="group">
                                    <button class="btn btn-sm btn-outline-primary btn-action" onclick="browserShieldAdmin.navigateSession('${session.profileId}')">
                                        <i class="fas fa-globe"></i> Navigate
                                    </button>
                                    <button class="btn btn-sm btn-outline-warning btn-action" onclick="browserShieldAdmin.executeScript('${session.profileId}')">
                                        <i class="fas fa-code"></i> Script
                                    </button>
                                    <button class="btn btn-sm btn-outline-danger btn-action" onclick="browserShieldAdmin.stopSession('${session.profileId}')">
                                        <i class="fas fa-stop"></i> Stop
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            `;
        }).join('');

        container.innerHTML = sessionsHtml;
    }

    renderLogs() {
        const container = document.getElementById('activityLogs');
        
        if (this.logs.length === 0) {
            container.innerHTML = `
                <div class="text-center p-4">
                    <i class="fas fa-list fa-3x text-muted mb-3"></i>
                    <h5>No Activity Logs</h5>
                    <p class="text-muted">Activity logs will appear here</p>
                </div>
            `;
            return;
        }

        const logsHtml = this.logs.map(log => `
            <div class="log-entry">
                <div>
                    <div class="fw-bold">${log.action}</div>
                    <div class="text-muted small">${log.details}</div>
                </div>
                <div class="log-time">${new Date(log.timestamp).toLocaleString()}</div>
            </div>
        `).join('');

        container.innerHTML = logsHtml;
    }

    async createProfile() {
        const formData = {
            name: document.getElementById('profileName').value,
            userAgent: document.getElementById('userAgent').value,
            timezone: document.getElementById('timezone').value,
            viewport: {
                width: parseInt(document.getElementById('viewportWidth').value),
                height: parseInt(document.getElementById('viewportHeight').value)
            },
            autoNavigateUrl: document.getElementById('autoNavigateUrl').value || null
        };

        try {
            const response = await fetch(`${this.baseUrl}/api/profiles`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(formData)
            });

            const data = await response.json();
            
            if (data.success) {
                this.showToast('Profile created successfully', 'success');
                this.hideCreateProfile();
                await this.loadProfiles();
                await this.updateStats();
                
                // Add to logs
                this.logs.unshift({
                    timestamp: new Date().toISOString(),
                    action: 'Profile Created',
                    details: `New profile "${formData.name}" created`,
                    profileId: data.profile.id
                });
                this.renderLogs();
            } else {
                this.showToast('Failed to create profile', 'error');
            }
        } catch (error) {
            console.error('Error creating profile:', error);
            this.showToast('Error creating profile', 'error');
        }
    }

    async startSession(profileId) {
        try {
            const response = await fetch(`${this.baseUrl}/api/profiles/${profileId}/start`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    autoNavigateUrl: 'https://bot.sannysoft.com/'
                })
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            console.log('Start session response:', data);
            
            if (data.success) {
                this.showToast(`Browser session started successfully${data.message ? ': ' + data.message : ''}`, 'success');
                await this.loadSessions();
                await this.loadProfiles();
                await this.updateStats();
                
                // Add to logs
                const profile = this.profiles.find(p => p.id === profileId);
                this.logs.unshift({
                    timestamp: new Date().toISOString(),
                    action: 'Session Started',
                    details: `Browser session started for profile "${profile?.name || 'Unknown'}"`,
                    profileId: profileId
                });
                this.renderLogs();
            } else {
                this.showToast(data.message || 'Failed to start session', 'error');
            }
        } catch (error) {
            console.error('Error starting session:', error);
            this.showToast(`Error starting session: ${error.message}`, 'error');
        }
    }

    async stopSession(profileId) {
        try {
            const response = await fetch(`${this.baseUrl}/api/profiles/${profileId}/stop`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            console.log('Stop session response:', data);
            
            if (data.success) {
                this.showToast(`Browser session stopped successfully${data.message ? ': ' + data.message : ''}`, 'success');
                await this.loadSessions();
                await this.loadProfiles();
                await this.updateStats();
                
                // Add to logs
                const profile = this.profiles.find(p => p.id === profileId);
                this.logs.unshift({
                    timestamp: new Date().toISOString(),
                    action: 'Session Stopped',
                    details: `Browser session stopped for profile "${profile?.name || 'Unknown'}"`,
                    profileId: profileId
                });
                this.renderLogs();
            } else {
                this.showToast(data.message || 'Failed to stop session', 'error');
            }
        } catch (error) {
            console.error('Error stopping session:', error);
            this.showToast(`Error stopping session: ${error.message}`, 'error');
        }
    }

    async deleteProfile(profileId) {
        if (!confirm('Are you sure you want to delete this profile?')) {
            return;
        }

        try {
            const response = await fetch(`${this.baseUrl}/api/profiles/${profileId}`, {
                method: 'DELETE'
            });

            const data = await response.json();
            
            if (data.success) {
                this.showToast('Profile deleted successfully', 'success');
                await this.loadProfiles();
                await this.updateStats();
                
                // Add to logs
                this.logs.unshift({
                    timestamp: new Date().toISOString(),
                    action: 'Profile Deleted',
                    details: `Profile deleted`,
                    profileId: profileId
                });
                this.renderLogs();
            } else {
                this.showToast('Failed to delete profile', 'error');
            }
        } catch (error) {
            console.error('Error deleting profile:', error);
            this.showToast('Error deleting profile', 'error');
        }
    }

    showProfileDetails(profileId) {
        const profile = this.profiles.find(p => p.id === profileId);
        if (!profile) return;

        const session = this.sessions.find(s => s.profileId === profileId);
        
        const modalBody = document.getElementById('profileModalBody');
        modalBody.innerHTML = `
            <div class="row">
                <div class="col-md-6">
                    <h6>Basic Information</h6>
                    <table class="table table-sm">
                        <tr><td><strong>Name:</strong></td><td>${profile.name}</td></tr>
                        <tr><td><strong>ID:</strong></td><td>${profile.id}</td></tr>
                        <tr><td><strong>Status:</strong></td><td>${session ? '<span class="badge bg-success">Active</span>' : '<span class="badge bg-secondary">Inactive</span>'}</td></tr>
                        <tr><td><strong>Created:</strong></td><td>${new Date(profile.createdAt).toLocaleString()}</td></tr>
                    </table>
                </div>
                <div class="col-md-6">
                    <h6>Browser Settings</h6>
                    <table class="table table-sm">
                        <tr><td><strong>Timezone:</strong></td><td>${profile.timezone}</td></tr>
                        <tr><td><strong>Viewport:</strong></td><td>${profile.viewport.width}x${profile.viewport.height}</td></tr>
                        <tr><td><strong>Proxy:</strong></td><td>${profile.proxy ? 'Enabled' : 'Disabled'}</td></tr>
                        <tr><td><strong>Auto Navigate:</strong></td><td>${profile.autoNavigateUrl || 'None'}</td></tr>
                    </table>
                </div>
            </div>
            <div class="row mt-3">
                <div class="col-12">
                    <h6>User Agent</h6>
                    <div class="bg-light p-2 rounded small">${profile.userAgent}</div>
                </div>
            </div>
            ${session ? `
                <div class="row mt-3">
                    <div class="col-12">
                        <h6>Session Information</h6>
                        <table class="table table-sm">
                            <tr><td><strong>Session ID:</strong></td><td>${session.sessionId}</td></tr>
                            <tr><td><strong>Browser Type:</strong></td><td>${session.browserType}</td></tr>
                            <tr><td><strong>Current URL:</strong></td><td>${session.currentUrl}</td></tr>
                            <tr><td><strong>Uptime:</strong></td><td>${this.formatUptime(session.uptime)}</td></tr>
                            <tr><td><strong>Started:</strong></td><td>${new Date(session.startTime).toLocaleString()}</td></tr>
                        </table>
                    </div>
                </div>
            ` : ''}
        `;

        const modal = new bootstrap.Modal(document.getElementById('profileModal'));
        modal.show();
    }

    showSection(sectionName) {
        // Hide all sections
        document.querySelectorAll('.section').forEach(section => {
            section.style.display = 'none';
        });

        // Show selected section
        const section = document.getElementById(`${sectionName}-section`);
        if (section) {
            section.style.display = 'block';
        }

        // Update navigation
        document.querySelectorAll('.nav-link').forEach(link => {
            link.classList.remove('active');
        });
        
        const activeLink = document.querySelector(`a[href="#${sectionName}"]`);
        if (activeLink) {
            activeLink.classList.add('active');
        }

        this.currentSection = sectionName;
    }

    showCreateProfile() {
        document.getElementById('createProfileForm').style.display = 'block';
        document.getElementById('profileName').focus();
    }

    hideCreateProfile() {
        document.getElementById('createProfileForm').style.display = 'none';
        document.getElementById('profileForm').reset();
    }

    async refreshProfiles() {
        await this.loadProfiles();
        await this.updateStats();
        this.showToast('Profiles refreshed', 'info');
    }

    startAutoRefresh() {
        this.refreshInterval = setInterval(async () => {
            await this.loadSessions();
            await this.updateStats();
            
            if (this.currentSection === 'profiles') {
                this.renderProfiles();
            } else if (this.currentSection === 'sessions') {
                this.renderSessions();
            }
        }, 30000); // Refresh every 30 seconds
    }

    showToast(message, type = 'info') {
        const toastContainer = document.getElementById('toastContainer');
        const toastId = 'toast-' + Date.now();
        
        const bgClass = {
            'success': 'bg-success',
            'error': 'bg-danger',
            'warning': 'bg-warning',
            'info': 'bg-info'
        }[type] || 'bg-info';

        const toastHtml = `
            <div id="${toastId}" class="toast ${bgClass} text-white" role="alert">
                <div class="toast-body">
                    <i class="fas fa-${type === 'success' ? 'check' : type === 'error' ? 'exclamation-triangle' : 'info'}-circle me-2"></i>
                    ${message}
                </div>
            </div>
        `;
        
        toastContainer.insertAdjacentHTML('beforeend', toastHtml);
        
        const toastElement = document.getElementById(toastId);
        const toast = new bootstrap.Toast(toastElement, { delay: 3000 });
        toast.show();
        
        toastElement.addEventListener('hidden.bs.toast', () => {
            toastElement.remove();
        });
    }

    formatUptime(seconds) {
        if (seconds < 60) return `${seconds}s`;
        if (seconds < 3600) return `${Math.floor(seconds / 60)}m ${seconds % 60}s`;
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return `${hours}h ${minutes}m`;
    }

    truncateText(text, maxLength) {
        if (text.length <= maxLength) return text;
        return text.substring(0, maxLength) + '...';
    }

    // Stub methods for future implementation
    editProfile(profileId) {
        this.showToast('Edit profile feature coming soon', 'info');
    }

    navigateSession(profileId) {
        const url = prompt('Enter URL to navigate to:');
        if (url) {
            this.showToast(`Navigating to ${url} (Mock)`, 'info');
        }
    }

    executeScript(profileId) {
        const script = prompt('Enter JavaScript to execute:');
        if (script) {
            this.showToast(`Executing script (Mock)`, 'info');
        }
    }
}

// Global functions for onclick handlers
window.showSection = (section) => {
    if (window.browserShieldAdmin) {
        window.browserShieldAdmin.showSection(section);
    }
};

window.showCreateProfile = () => {
    if (window.browserShieldAdmin) {
        window.browserShieldAdmin.showCreateProfile();
    }
};

window.hideCreateProfile = () => {
    if (window.browserShieldAdmin) {
        window.browserShieldAdmin.hideCreateProfile();
    }
};

window.refreshProfiles = () => {
    if (window.browserShieldAdmin) {
        window.browserShieldAdmin.refreshProfiles();
    }
};

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.browserShieldAdmin = new BrowserShieldAdmin();
});