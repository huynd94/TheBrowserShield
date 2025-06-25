// Anti-Detect Browser Profile Manager - Frontend
class ProfileManager {
    constructor() {
        this.profiles = [];
        this.activeSessions = [];
        this.proxyPool = [];
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.loadProfiles();
        this.loadActiveSessions();
        
        // Auto refresh every 30 seconds
        setInterval(() => {
            this.loadActiveSessions();
        }, 30000);
    }

    setupEventListeners() {
        // Create profile form
        document.getElementById('createProfileForm').addEventListener('submit', (e) => {
            e.preventDefault();
            this.createProfile();
        });

        // Proxy settings toggle
        document.getElementById('enableProxy').addEventListener('change', (e) => {
            document.getElementById('proxySettings').style.display = e.target.checked ? 'block' : 'none';
            if (e.target.checked) {
                this.loadProxyPool();
            }
        });

        // Proxy source change
        document.getElementById('proxySource').addEventListener('change', (e) => {
            const manual = document.getElementById('manualProxySettings');
            const pool = document.getElementById('poolProxySettings');
            
            if (e.target.value === 'manual') {
                manual.style.display = 'block';
                pool.style.display = 'none';
            } else {
                manual.style.display = 'none';
                pool.style.display = 'block';
            }
        });
    }

    async loadProfiles() {
        try {
            const response = await fetch('/api/profiles');
            const data = await response.json();
            this.profiles = data.data;
            this.renderProfiles();
        } catch (error) {
            this.showError('Không thể tải danh sách profiles');
        }
    }

    async loadActiveSessions() {
        try {
            const response = await fetch('/api/profiles/sessions/active');
            const data = await response.json();
            this.activeSessions = data.data;
            this.updateActiveSessionsDisplay();
        } catch (error) {
            console.error('Error loading active sessions:', error);
        }
    }

    async createProfile() {
        const formData = this.getFormData();
        
        try {
            const response = await fetch('/api/profiles', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(formData)
            });

            if (response.ok) {
                this.showSuccess('Profile đã được tạo thành công!');
                this.resetForm();
                this.loadProfiles();
            } else {
                const error = await response.json();
                this.showError(error.message || 'Không thể tạo profile');
            }
        } catch (error) {
            this.showError('Lỗi kết nối server');
        }
    }

    getFormData() {
        const userAgentMap = {
            'chrome-windows': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'chrome-mac': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'firefox-windows': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:120.0) Gecko/20100101 Firefox/120.0',
            'safari-mac': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15',
            'mobile-ios': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
            'mobile-android': 'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36'
        };

        const data = {
            name: document.getElementById('profileName').value,
            timezone: document.getElementById('timezoneSelect').value,
            viewport: {
                width: parseInt(document.getElementById('viewportWidth').value),
                height: parseInt(document.getElementById('viewportHeight').value)
            },
            spoofFingerprint: document.getElementById('spoofFingerprint').checked
        };

        const userAgentSelect = document.getElementById('userAgentSelect').value;
        if (userAgentSelect && userAgentMap[userAgentSelect]) {
            data.userAgent = userAgentMap[userAgentSelect];
        }

        if (document.getElementById('enableProxy').checked) {
            const proxySource = document.getElementById('proxySource').value;
            
            if (proxySource === 'manual') {
                data.proxy = {
                    host: document.getElementById('proxyHost').value,
                    port: parseInt(document.getElementById('proxyPort').value),
                    type: document.getElementById('proxyType').value
                };

                const username = document.getElementById('proxyUsername').value;
                const password = document.getElementById('proxyPassword').value;
                if (username) {
                    data.proxy.username = username;
                }
                if (password) {
                    data.proxy.password = password;
                }
            } else if (proxySource === 'pool') {
                const selectedProxyId = document.getElementById('proxyPoolSelect').value;
                const selectedProxy = this.proxyPool.find(p => p.id === selectedProxyId);
                if (selectedProxy) {
                    data.proxy = {
                        host: selectedProxy.host,
                        port: selectedProxy.port,
                        type: selectedProxy.type,
                        username: selectedProxy.username,
                        password: selectedProxy.password
                    };
                }
            } else if (proxySource === 'random') {
                data.useRandomProxy = true;
            }
        }

        // Auto navigate URL
        const autoNavUrl = document.getElementById('autoNavigateUrl').value;
        if (autoNavUrl) {
            data.autoNavigateUrl = autoNavUrl;
        }

        return data;
    }

    renderProfiles() {
        const profilesList = document.getElementById('profilesList');
        
        if (this.profiles.length === 0) {
            profilesList.innerHTML = `
                <div class="col-12">
                    <div class="text-center text-muted">
                        <i class="bi bi-inbox" style="font-size: 3rem;"></i>
                        <p>Chưa có profile nào. Tạo profile đầu tiên!</p>
                    </div>
                </div>
            `;
            return;
        }

        profilesList.innerHTML = this.profiles.map(profile => {
            const isRunning = this.activeSessions.some(session => session.profileId === profile.id);
            const statusClass = isRunning ? 'status-running' : 'status-stopped';
            const statusIcon = isRunning ? 'bi-play-circle-fill' : 'bi-stop-circle';
            const statusText = isRunning ? 'Đang chạy' : 'Đã dừng';

            return `
                <div class="col-md-6 col-lg-4 mb-3">
                    <div class="card profile-card h-100">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h6 class="mb-0">${profile.name}</h6>
                            <span class="badge ${profile.spoofFingerprint ? 'bg-success' : 'bg-secondary'} fingerprint-badge">
                                ${profile.spoofFingerprint ? 'Stealth' : 'Normal'}
                            </span>
                        </div>
                        <div class="card-body">
                            <p class="card-text">
                                <small class="text-muted">
                                    <i class="bi bi-globe"></i> ${profile.timezone}<br>
                                    <i class="bi bi-display"></i> ${profile.viewport.width}x${profile.viewport.height}
                                </small>
                            </p>
                            ${profile.proxy ? `
                                <p class="proxy-info">
                                    <i class="bi bi-shield"></i> Proxy: ${profile.proxy.host}:${profile.proxy.port} (${profile.proxy.type.toUpperCase()})
                                </p>
                            ` : ''}
                            <div class="d-flex align-items-center justify-content-between">
                                <span class="${statusClass}">
                                    <i class="bi ${statusIcon}"></i> ${statusText}
                                </span>
                                <div class="btn-group" role="group">
                                    ${!isRunning ? `
                                        <button class="btn btn-success btn-sm" onclick="profileManager.startBrowser('${profile.id}')">
                                            <i class="bi bi-play"></i>
                                        </button>
                                    ` : `
                                        <button class="btn btn-danger btn-sm" onclick="profileManager.stopBrowser('${profile.id}')">
                                            <i class="bi bi-stop"></i>
                                        </button>
                                    `}
                                    <button class="btn btn-info btn-sm" onclick="profileManager.showProfileDetails('${profile.id}')">
                                        <i class="bi bi-info-circle"></i>
                                    </button>
                                    <button class="btn btn-outline-danger btn-sm" onclick="profileManager.deleteProfile('${profile.id}')">
                                        <i class="bi bi-trash"></i>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            `;
        }).join('');
    }

    updateActiveSessionsDisplay() {
        const count = this.activeSessions.length;
        document.getElementById('activeSessionsCount').innerHTML = `
            Active Sessions: <span class="badge bg-${count > 0 ? 'success' : 'secondary'}">${count}</span>
        `;

        const activeSessionsDiv = document.getElementById('activeSessions');
        if (count === 0) {
            activeSessionsDiv.innerHTML = '<p class="text-muted">Không có session nào đang chạy</p>';
        } else {
            activeSessionsDiv.innerHTML = this.activeSessions.map(session => `
                <div class="d-flex justify-content-between align-items-center mb-2">
                    <div>
                        <strong>${session.profileName}</strong><br>
                        <small class="text-muted">Uptime: ${this.formatUptime(session.uptime)}</small>
                    </div>
                    <button class="btn btn-outline-danger btn-sm" onclick="profileManager.stopBrowser('${session.profileId}')">
                        <i class="bi bi-stop"></i>
                    </button>
                </div>
            `).join('');
        }
    }

    async startBrowser(profileId) {
        const autoNavUrl = prompt('Nhập URL để auto navigate (để trống nếu không cần):', 'https://bot.sannysoft.com/');
        
        const requestBody = {};
        if (autoNavUrl && autoNavUrl.trim()) {
            requestBody.autoNavigateUrl = autoNavUrl.trim();
        }

        try {
            const response = await fetch(`/api/profiles/${profileId}/start`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(requestBody)
            });

            if (response.ok) {
                const data = await response.json();
                this.showSuccess(`Browser đã được khởi chạy! ${data.data.mockFeatures?.autoNavigated ? 'Auto navigated: ' + (requestBody.autoNavigateUrl || 'default page') : ''}`);
                this.loadActiveSessions();
                this.renderProfiles();
            } else {
                const error = await response.json();
                this.showError(error.message || 'Không thể khởi chạy browser');
            }
        } catch (error) {
            this.showError('Lỗi kết nối server');
        }
    }

    async stopBrowser(profileId) {
        try {
            const response = await fetch(`/api/profiles/${profileId}/stop`, {
                method: 'POST'
            });

            if (response.ok) {
                this.showSuccess('Browser đã được dừng!');
                this.loadActiveSessions();
                this.renderProfiles();
            } else {
                this.showError('Không thể dừng browser');
            }
        } catch (error) {
            this.showError('Lỗi kết nối server');
        }
    }

    async deleteProfile(profileId) {
        if (!confirm('Bạn có chắc muốn xóa profile này?')) {
            return;
        }

        try {
            const response = await fetch(`/api/profiles/${profileId}`, {
                method: 'DELETE'
            });

            if (response.ok) {
                this.showSuccess('Profile đã được xóa!');
                this.loadProfiles();
                this.loadActiveSessions();
            } else {
                this.showError('Không thể xóa profile');
            }
        } catch (error) {
            this.showError('Lỗi kết nối server');
        }
    }

    async showProfileDetails(profileId) {
        const profile = this.profiles.find(p => p.id === profileId);
        if (!profile) return;

        const isRunning = this.activeSessions.some(session => session.profileId === profileId);
        
        let statusInfo = '';
        if (isRunning) {
            try {
                const response = await fetch(`/api/profiles/${profileId}/status`);
                const data = await response.json();
                if (data.success && data.data) {
                    statusInfo = `
                        <div class="alert alert-success">
                            <h6>Browser Status</h6>
                            <p><strong>Uptime:</strong> ${this.formatUptime(data.data.uptime)}</p>
                            <p><strong>Current URL:</strong> ${data.data.currentUrl || 'N/A'}</p>
                            ${data.data.note ? `<p><small class="text-muted">${data.data.note}</small></p>` : ''}
                        </div>
                    `;
                }
            } catch (error) {
                console.error('Error loading status:', error);
            }
        }

        document.getElementById('modalTitle').textContent = profile.name;
        document.getElementById('modalContent').innerHTML = `
            <div class="mb-3">
                <strong>ID:</strong> ${profile.id}
            </div>
            <div class="mb-3">
                <strong>User Agent:</strong><br>
                <small class="text-muted">${profile.userAgent}</small>
            </div>
            <div class="mb-3">
                <strong>Timezone:</strong> ${profile.timezone}
            </div>
            <div class="mb-3">
                <strong>Viewport:</strong> ${profile.viewport.width}x${profile.viewport.height}
            </div>
            <div class="mb-3">
                <strong>Anti-Detection:</strong> 
                <span class="badge bg-${profile.spoofFingerprint ? 'success' : 'secondary'}">
                    ${profile.spoofFingerprint ? 'Enabled' : 'Disabled'}
                </span>
            </div>
            ${profile.proxy ? `
                <div class="mb-3">
                    <strong>Proxy:</strong> ${profile.proxy.host}:${profile.proxy.port} (${profile.proxy.type.toUpperCase()})
                </div>
            ` : '<div class="mb-3"><strong>Proxy:</strong> <span class="text-muted">Not configured</span></div>'}
            <div class="mb-3">
                <strong>Created:</strong> ${new Date(profile.createdAt).toLocaleString('vi-VN')}
            </div>
            ${statusInfo}
            ${isRunning ? `
                <div class="d-grid gap-2">
                    <button class="btn btn-primary" onclick="profileManager.navigateToUrl('${profileId}')">
                        <i class="bi bi-globe"></i> Navigate to URL
                    </button>
                    <button class="btn btn-secondary" onclick="profileManager.executeScript('${profileId}')">
                        <i class="bi bi-code"></i> Execute Script
                    </button>
                </div>
            ` : ''}
        `;

        new bootstrap.Modal(document.getElementById('profileModal')).show();
    }

    async navigateToUrl(profileId) {
        const url = prompt('Nhập URL để navigate:');
        if (!url) return;

        try {
            const response = await fetch(`/api/profiles/${profileId}/navigate`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ url })
            });

            if (response.ok) {
                const data = await response.json();
                this.showSuccess(`Navigated to: ${data.data.url}`);
            } else {
                this.showError('Navigation failed');
            }
        } catch (error) {
            this.showError('Lỗi kết nối server');
        }
    }

    async executeScript(profileId) {
        const script = prompt('Nhập JavaScript code để execute:', 'navigator.userAgent');
        if (!script) return;

        try {
            const response = await fetch(`/api/profiles/${profileId}/execute`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ script })
            });

            if (response.ok) {
                const data = await response.json();
                alert(`Result: ${JSON.stringify(data.data, null, 2)}`);
            } else {
                this.showError('Script execution failed');
            }
        } catch (error) {
            this.showError('Lỗi kết nối server');
        }
    }

    async loadProxyPool() {
        try {
            const response = await fetch('/api/proxy');
            const data = await response.json();
            this.proxyPool = data.data;
            this.updateProxyPoolSelect();
        } catch (error) {
            console.error('Error loading proxy pool:', error);
        }
    }

    updateProxyPoolSelect() {
        const select = document.getElementById('proxyPoolSelect');
        if (this.proxyPool.length === 0) {
            select.innerHTML = '<option value="">Không có proxy nào trong pool</option>';
        } else {
            select.innerHTML = '<option value="">Chọn proxy...</option>' +
                this.proxyPool
                    .filter(p => p.active)
                    .map(proxy => `
                        <option value="${proxy.id}">
                            ${proxy.host}:${proxy.port} (${proxy.type.toUpperCase()}) - ${proxy.country || 'Unknown'}
                        </option>
                    `).join('');
        }
    }

    resetForm() {
        document.getElementById('createProfileForm').reset();
        document.getElementById('proxySettings').style.display = 'none';
        document.getElementById('manualProxySettings').style.display = 'block';
        document.getElementById('poolProxySettings').style.display = 'none';
        document.getElementById('enableProxy').checked = false;
        document.getElementById('spoofFingerprint').checked = true;
        document.getElementById('viewportWidth').value = '1366';
        document.getElementById('viewportHeight').value = '768';
        document.getElementById('proxySource').value = 'manual';
    }

    formatUptime(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = seconds % 60;
        
        if (hours > 0) {
            return `${hours}h ${minutes}m ${secs}s`;
        } else if (minutes > 0) {
            return `${minutes}m ${secs}s`;
        } else {
            return `${secs}s`;
        }
    }

    showSuccess(message) {
        this.showToast(message, 'success');
    }

    showError(message) {
        this.showToast(message, 'danger');
    }

    showToast(message, type) {
        const toastContainer = document.getElementById('toastContainer') || this.createToastContainer();
        const toast = document.createElement('div');
        toast.className = `toast align-items-center text-bg-${type} border-0`;
        toast.setAttribute('role', 'alert');
        toast.innerHTML = `
            <div class="d-flex">
                <div class="toast-body">${message}</div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
            </div>
        `;
        
        toastContainer.appendChild(toast);
        const bsToast = new bootstrap.Toast(toast);
        bsToast.show();
        
        toast.addEventListener('hidden.bs.toast', () => {
            toast.remove();
        });
    }

    createToastContainer() {
        const container = document.createElement('div');
        container.id = 'toastContainer';
        container.className = 'toast-container position-fixed bottom-0 end-0 p-3';
        document.body.appendChild(container);
        return container;
    }
}

// Global functions
function refreshProfiles() {
    profileManager.loadProfiles();
    profileManager.loadActiveSessions();
}

// Initialize the application
const profileManager = new ProfileManager();