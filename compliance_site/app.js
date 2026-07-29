/**
 * İş Tap AI — Web App Main Bundle & SPA Controller
 * Qaf Studio © 2026
 * Cross-Platform Web Client sharing Firebase backend with Flutter Mobile App
 */

// Firebase config matching firebase_options.dart
const firebaseConfig = {
    apiKey: 'AIzaSyDbgfPFFe6GdRdEfC0b56qf5WgCtY-VXv8',
    authDomain: 'jobmarketplaceaz.firebaseapp.com',
    projectId: 'jobmarketplaceaz',
    storageBucket: 'jobmarketplaceaz.firebasestorage.app',
    messagingSenderId: '591328908781',
    appId: '1:591328908781:web:ddc036782df1ffd84043e4',
    measurementId: 'G-EGKX8DNBDS'
};

const CATEGORIES = [
    { id: 'all', name: 'Bütün Kateqoriyalar', icon: '⚡' },
    { id: 'waiter', name: 'Ofisant', icon: '🍽️' },
    { id: 'courier', name: 'Kuryer', icon: '🛵' },
    { id: 'sales', name: 'Satıcı', icon: '🛍️' },
    { id: 'cleaner', name: 'Təmizlikçi', icon: '🧹' },
    { id: 'cook', name: 'Aşpaz', icon: '🍳' },
    { id: 'security', name: 'Mühafizəçi', icon: '🛡️' },
    { id: 'driver', name: 'Sürücü', icon: '🚗' },
    { id: 'cashier', name: 'Kassir', icon: '💳' },
    { id: 'warehouse', name: 'Anbardar', icon: '📦' },
    { id: 'construction', name: 'Tikinti işçisi', icon: '🏗️' },
    { id: 'barista', name: 'Barista', icon: '☕' },
    { id: 'mechanic', name: 'Mexanik', icon: '🔧' },
    { id: 'hairdresser', name: 'Bərbər', icon: '✂️' },
    { id: 'teacher', name: 'Müəllim', icon: '🎓' },
    { id: 'it', name: 'IT mütəxəssis', icon: '💻' },
    { id: 'other', name: 'Digər', icon: '💼' }
];

const CITIES = [
    'Bakı', 'Gəncə', 'Sumqayıt', 'Mingəçevir', 'Şirvan',
    'Naxçıvan', 'Şəki', 'Lənkəran', 'Yevlax', 'Xaçmaz',
    'Şamaxı', 'Quba', 'Qəbələ', 'Zaqatala', 'Bərdə',
    'Ağdam', 'Ağcabədi', 'Göyçay', 'Masallı', 'Sabirabad'
];

const BAKU_DISTRICTS = [
    'Nəsimi', 'Yasamal', 'Xətai', 'Səbail', 'Nizami',
    'Binəqədi', 'Nərimanov', 'Suraxanı', 'Xəzər', 'Qaradağ',
    'Sabunçu', 'Pirallahı', 'Abşeron'
];

// ===== 1. AUTH MODULE =====
const AuthModule = {
    currentUser: null,
    userProfile: null,
    listeners: [],

    init(auth, db) {
        this.auth = auth;
        this.db = db;
        return new Promise((resolve) => {
            this.auth.onAuthStateChanged(async (user) => {
                this.currentUser = user;
                if (user) {
                    await this.fetchUserProfile(user.uid);
                } else {
                    this.userProfile = null;
                }
                this.notifyListeners();
                resolve(user);
            });
        });
    },

    subscribe(callback) {
        this.listeners.push(callback);
        callback({ user: this.currentUser, profile: this.userProfile });
    },

    notifyListeners() {
        this.listeners.forEach(cb => cb({ user: this.currentUser, profile: this.userProfile }));
    },

    async fetchUserProfile(uid) {
        try {
            const doc = await this.db.collection('users').doc(uid).get();
            if (doc.exists) {
                this.userProfile = { id: doc.id, ...doc.data() };
            } else {
                this.userProfile = null;
            }
        } catch (err) {
            console.error('Error fetching profile:', err);
            this.userProfile = null;
        }
        return this.userProfile;
    },

    async registerWithEmail({ email, password, fullName, phone, userType, companyName }) {
        try {
            const userCredential = await this.auth.createUserWithEmailAndPassword(email, password);
            const user = userCredential.user;

            const userData = {
                fullName: fullName || '',
                phone: phone || '',
                email: email || '',
                userType: userType || 'job_seeker',
                avatarUrl: null,
                createdAt: new Date().toISOString(),
            };

            if (userType === 'employer') {
                userData.companyName = companyName || '';
                userData.companyAddress = '';
                userData.sector = '';
            } else {
                userData.experience = '';
                userData.education = '';
                userData.skills = '';
                userData.bio = '';
            }

            await this.db.collection('users').doc(user.uid).set(userData);
            this.userProfile = { id: user.uid, ...userData };
            this.notifyListeners();
            return { success: true, user: this.userProfile };
        } catch (err) {
            return { success: false, error: this.getErrorMessage(err.code) };
        }
    },

    async loginWithEmail(email, password) {
        try {
            const userCredential = await this.auth.signInWithEmailAndPassword(email, password);
            await this.fetchUserProfile(userCredential.user.uid);
            this.notifyListeners();
            return { success: true, user: this.userProfile };
        } catch (err) {
            return { success: false, error: this.getErrorMessage(err.code) };
        }
    },

    async loginWithGoogle(userType = 'job_seeker') {
        try {
            const provider = new firebase.auth.GoogleAuthProvider();
            const result = await this.auth.signInWithPopup(provider);
            const user = result.user;

            let profile = await this.fetchUserProfile(user.uid);

            if (!profile) {
                const userData = {
                    fullName: user.displayName || 'İstifadəçi',
                    phone: user.phoneNumber || '',
                    email: user.email || '',
                    userType: userType,
                    avatarUrl: user.photoURL || null,
                    createdAt: new Date().toISOString(),
                };

                if (userType === 'employer') {
                    userData.companyName = user.displayName || 'Şirkət';
                }

                await this.db.collection('users').doc(user.uid).set(userData);
                this.userProfile = { id: user.uid, ...userData };
            }

            this.notifyListeners();
            return { success: true, user: this.userProfile };
        } catch (err) {
            return { success: false, error: err.message };
        }
    },

    async logout() {
        try {
            await this.auth.signOut();
            this.currentUser = null;
            this.userProfile = null;
            this.notifyListeners();
            return { success: true };
        } catch (err) {
            return { success: false, error: err.message };
        }
    },

    getErrorMessage(code) {
        switch (code) {
            case 'auth/email-already-in-use': return 'Bu email ünvanı artıq istifadə olunur.';
            case 'auth/invalid-email': return 'Düzgün email ünvanı daxil edin.';
            case 'auth/weak-password': return 'Şifrə ən azı 6 simvoldan ibarət olmalıdır.';
            case 'auth/user-not-found':
            case 'auth/wrong-password': return 'Email və ya şifrə yanlışdır.';
            default: return 'Xəta baş verdi. Yenidən cəhd edin.';
        }
    }
};

// ===== 2. JOBS MODULE =====
const JobsModule = {
    db: null,
    unsubscribeJobs: null,

    init(db) { this.db = db; },

    listenToJobs({ categoryId, city, jobType, searchQuery, sortBy, employerId }, onUpdate, onError) {
        if (this.unsubscribeJobs) this.unsubscribeJobs();

        let query = this.db.collection('jobs');
        if (employerId) {
            query = query.where('employerId', '==', employerId);
        }

        let hasReceivedData = false;

        const processDocs = (docs) => {
            hasReceivedData = true;
            let jobs = docs.map(doc => ({
                id: doc.id,
                ...doc.data(),
                createdAtDate: doc.data().createdAt ? new Date(doc.data().createdAt) : new Date()
            }));

            if (!employerId) {
                jobs = jobs.filter(j => j.isActive !== false);
            }
            if (categoryId && categoryId !== 'all') {
                jobs = jobs.filter(j => j.categoryId === categoryId);
            }
            if (city && city !== 'all') {
                jobs = jobs.filter(j => j.city === city);
            }
            if (jobType && jobType !== 'all') {
                jobs = jobs.filter(j => j.jobType === jobType);
            }
            if (searchQuery && searchQuery.trim() !== '') {
                const q = searchQuery.toLowerCase().trim();
                jobs = jobs.filter(j =>
                    (j.title && j.title.toLowerCase().includes(q)) ||
                    (j.companyName && j.companyName.toLowerCase().includes(q)) ||
                    (j.description && j.description.toLowerCase().includes(q))
                );
            }

            if (sortBy === 'highestPay') {
                jobs.sort((a, b) => (Number(b.salaryMin) || 0) - (Number(a.salaryMin) || 0));
            } else if (sortBy === 'lowestPay') {
                jobs.sort((a, b) => (Number(a.salaryMin) || 0) - (Number(b.salaryMin) || 0));
            } else {
                jobs.sort((a, b) => {
                    const aU = a.isUrgent ? 1 : 0;
                    const bU = b.isUrgent ? 1 : 0;
                    if (aU !== bU) return bU - aU;
                    return (b.createdAtDate || 0) - (a.createdAtDate || 0);
                });
            }

            onUpdate(jobs);
        };

        // Safety fallback timer if onSnapshot hangs on initial load
        setTimeout(async () => {
            if (!hasReceivedData) {
                console.log('onSnapshot pending > 3.5s, forcing HTTPS query.get() fallback...');
                try {
                    const snapshot = await query.get();
                    if (!hasReceivedData) {
                        processDocs(snapshot.docs);
                    }
                } catch (err) {
                    console.error('Safety HTTPS fallback error:', err);
                    if (!hasReceivedData) onUpdate([]);
                }
            }
        }, 3500);

        this.unsubscribeJobs = query.onSnapshot((snapshot) => {
            processDocs(snapshot.docs);
        }, async (err) => {
            console.warn('onSnapshot error, executing HTTPS query.get():', err);
            try {
                const snapshot = await query.get();
                processDocs(snapshot.docs);
            } catch (fallbackErr) {
                console.error('query.get() fallback error:', fallbackErr);
                if (!hasReceivedData) onUpdate([]);
            }
        });

        return this.unsubscribeJobs;
    },

    async getJobById(id) {
        try {
            const doc = await this.db.collection('jobs').doc(id).get();
            if (!doc.exists) return null;

            try {
                this.db.collection('jobs').doc(id).update({
                    viewCount: firebase.firestore.FieldValue.increment(1)
                });
            } catch (_) {}

            return { id: doc.id, ...doc.data() };
        } catch (err) {
            return null;
        }
    },

    async createJob(jobData, employer) {
        try {
            const now = new Date();
            const expires = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
            const docId = Date.now().toString();

            const newJob = {
                id: docId,
                title: jobData.title || '',
                companyName: employer.companyName || employer.fullName || 'Şirkət',
                companyLogo: employer.avatarUrl || null,
                categoryId: jobData.categoryId || 'other',
                description: jobData.description || '',
                salaryMin: Number(jobData.salaryMin) || 0,
                salaryMax: jobData.salaryMax ? Number(jobData.salaryMax) : null,
                salaryPeriod: jobData.salaryPeriod || 'aylıq',
                jobType: jobData.jobType || 'fullTime',
                city: jobData.city || 'Bakı',
                district: jobData.district || '',
                address: jobData.address || '',
                latitude: Number(jobData.latitude) || 40.4093,
                longitude: Number(jobData.longitude) || 49.8671,
                workingHours: '',
                requirements: jobData.requirements ? jobData.requirements.split('\n').filter(r => r.trim()) : [],
                benefits: jobData.benefits ? jobData.benefits.split('\n').filter(b => b.trim()) : [],
                contactPhone: jobData.contactPhone || employer.phone || '',
                employerId: employer.id,
                createdAt: now.toISOString(),
                expiresAt: expires.toISOString(),
                isUrgent: false,
                isActive: true,
                viewCount: 0,
                applicationCount: 0,
                educationLevel: 'Tələb olunmur',
                experienceLevel: 'Təcrübəsiz',
                allowCallIfAccepted: true,
                applicationMethod: 'in_app'
            };

            await this.db.collection('jobs').doc(docId).set(newJob);
            return { success: true, id: docId };
        } catch (err) {
            return { success: false, error: err.message };
        }
    },

    async deleteJob(jobId) {
        try {
            await this.db.collection('jobs').doc(jobId).delete();
            return { success: true };
        } catch (err) {
            return { success: false, error: err.message };
        }
    },

    async toggleSavedJob(userId, jobId) {
        try {
            const ref = this.db.collection('users').doc(userId).collection('savedJobs').doc(jobId);
            const doc = await ref.get();
            if (doc.exists) {
                await ref.delete();
                return { success: true, saved: false };
            } else {
                await ref.set({ savedAt: new Date().toISOString() });
                return { success: true, saved: true };
            }
        } catch (err) {
            return { success: false, error: err.message };
        }
    },

    async checkIfSaved(userId, jobId) {
        if (!userId) return false;
        try {
            const doc = await this.db.collection('users').doc(userId).collection('savedJobs').doc(jobId).get();
            return doc.exists;
        } catch (_) {
            return false;
        }
    },

    async getSavedJobs(userId) {
        try {
            const snapshot = await this.db.collection('users').doc(userId).collection('savedJobs').get();
            const jobIds = snapshot.docs.map(d => d.id);
            if (jobIds.length === 0) return [];
            const jobPromises = jobIds.map(id => this.db.collection('jobs').doc(id).get());
            const docs = await Promise.all(jobPromises);
            return docs.filter(d => d.exists).map(d => ({ id: d.id, ...d.data() }));
        } catch (err) {
            return [];
        }
    }
};

// ===== 3. APPLICATIONS MODULE =====
const ApplicationsModule = {
    db: null,

    init(db) { this.db = db; },

    async applyToJob({ job, applicant }) {
        try {
            if (!applicant || !job) return { success: false, error: 'Məlumat tapılmadı.' };

            const hasApplied = await this.checkHasApplied(job.id, applicant.id);
            if (hasApplied) return { success: false, error: 'Bu işə artıq müraciət etmisiniz.' };

            const applicationData = {
                jobId: job.id,
                jobTitle: job.title || '',
                companyName: job.companyName || '',
                applicantId: applicant.id,
                applicantName: applicant.fullName || 'Namizəd',
                applicantPhone: applicant.phone || '',
                applicantEmail: applicant.email || '',
                applicantBio: applicant.bio || '',
                applicantSkills: applicant.skills || '',
                applicantExperience: applicant.experience || '',
                applicantEducation: applicant.education || '',
                applicantAvatar: applicant.avatarUrl || null,
                employerId: job.employerId,
                status: 'pending',
                createdAt: new Date().toISOString(),
                statusNotificationSent: false
            };

            await this.db.collection('applications').add(applicationData);

            try {
                await this.db.collection('jobs').doc(job.id).update({
                    applicationCount: firebase.firestore.FieldValue.increment(1)
                });
            } catch (_) {}

            return { success: true };
        } catch (err) {
            return { success: false, error: err.message };
        }
    },

    async checkHasApplied(jobId, applicantId) {
        if (!jobId || !applicantId) return false;
        try {
            const snapshot = await this.db.collection('applications').where('applicantId', '==', applicantId).get();
            return snapshot.docs.some(doc => doc.data().jobId === jobId);
        } catch (err) {
            return false;
        }
    },

    async getMyApplications(applicantId) {
        try {
            const snapshot = await this.db.collection('applications').where('applicantId', '==', applicantId).get();
            const list = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            list.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
            return list;
        } catch (err) {
            return [];
        }
    },

    async getJobApplicants(jobId) {
        try {
            const snapshot = await this.db.collection('applications').where('jobId', '==', jobId).get();
            const list = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            list.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
            return list;
        } catch (err) {
            return [];
        }
    },

    async getEmployerApplications(employerId) {
        try {
            const snapshot = await this.db.collection('applications').where('employerId', '==', employerId).get();
            const list = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            list.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
            return list;
        } catch (err) {
            return [];
        }
    },

    async updateStatus(applicationId, newStatus) {
        try {
            await this.db.collection('applications').doc(applicationId).update({ status: newStatus });
            return { success: true };
        } catch (err) {
            return { success: false, error: err.message };
        }
    }
};

// ===== 4. CHAT MODULE =====
const ChatModule = {
    db: null,
    unsubscribeChats: null,
    unsubscribeMessages: null,

    init(db) { this.db = db; },

    listenToChats(userId, onUpdate) {
        if (this.unsubscribeChats) this.unsubscribeChats();
        const query = this.db.collection('chats').where('participantIds', 'array-contains', userId);

        this.unsubscribeChats = query.onSnapshot(snapshot => {
            let chats = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            chats.sort((a, b) => {
                const tA = a.lastMessageTime ? new Date(a.lastMessageTime) : new Date(0);
                const tB = b.lastMessageTime ? new Date(b.lastMessageTime) : new Date(0);
                return tB - tA;
            });
            onUpdate(chats);
        }, err => console.error('Error in chats listener:', err));

        return this.unsubscribeChats;
    },

    async getOrCreateChat({ employerId, employerName, jobSeekerId, jobSeekerName, jobId, jobTitle }) {
        try {
            const snapshot = await this.db.collection('chats').where('participantIds', 'array-contains', employerId).get();
            const existing = snapshot.docs.find(doc => {
                const d = doc.data();
                return d.jobSeekerId === jobSeekerId && d.jobId === jobId;
            });

            if (existing) {
                return { success: true, chatId: existing.id, chat: { id: existing.id, ...existing.data() } };
            }

            const newChat = {
                employerId,
                employerName: employerName || 'İşəgötürən',
                jobSeekerId,
                jobSeekerName: jobSeekerName || 'Namizəd',
                jobId,
                jobTitle: jobTitle || 'İş elanı',
                participantIds: [employerId, jobSeekerId],
                lastMessage: 'Söhbət başladı',
                lastMessageTime: new Date().toISOString(),
                lastSenderId: '',
                createdAt: new Date().toISOString()
            };

            const docRef = await this.db.collection('chats').add(newChat);
            return { success: true, chatId: docRef.id, chat: { id: docRef.id, ...newChat } };
        } catch (err) {
            return { success: false, error: err.message };
        }
    },

    listenToMessages(chatId, onUpdate) {
        if (this.unsubscribeMessages) this.unsubscribeMessages();
        const query = this.db.collection('chats').doc(chatId).collection('messages');

        this.unsubscribeMessages = query.onSnapshot(snapshot => {
            let messages = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            messages.sort((a, b) => new Date(a.createdAt || 0) - new Date(b.createdAt || 0));
            onUpdate(messages);
        });

        return this.unsubscribeMessages;
    },

    async sendMessage(chatId, senderId, text) {
        if (!text || !text.trim()) return { success: false };

        try {
            const now = new Date().toISOString();
            await this.db.collection('chats').doc(chatId).collection('messages').add({
                senderId,
                text: text.trim(),
                createdAt: now
            });

            await this.db.collection('chats').doc(chatId).update({
                lastMessage: text.trim(),
                lastMessageTime: now,
                lastSenderId: senderId
            });

            return { success: true };
        } catch (err) {
            return { success: false, error: err.message };
        }
    }
};

// ===== 5. PROFILE MODULE =====
const ProfileModule = {
    db: null,
    init(db) { this.db = db; },

    async updateProfile(userId, updateData) {
        try {
            await this.db.collection('users').doc(userId).update(updateData);
            return { success: true };
        } catch (err) {
            return { success: false, error: err.message };
        }
    }
};

// ===== 6. MAP MODULE =====
const MapModule = {
    map: null,
    markers: [],

    init(containerId, initialLat = 40.4093, initialLng = 49.8671, zoom = 11) {
        const container = document.getElementById(containerId);
        if (!container || typeof L === 'undefined') return;

        if (this.map) {
            this.map.remove();
            this.markers = [];
        }

        this.map = L.map(containerId).setView([initialLat, initialLng], zoom);

        L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
            attribution: '&copy; OpenStreetMap',
            subdomains: 'abcd',
            maxZoom: 19
        }).addTo(this.map);
    },

    renderJobs(jobs, onJobSelect) {
        if (!this.map || typeof L === 'undefined') return;

        this.markers.forEach(m => this.map.removeLayer(m));
        this.markers = [];

        const customIcon = L.divIcon({
            className: 'custom-map-pin',
            html: `<div style="width:32px;height:32px;background:linear-gradient(135deg,#FF8C00,#FFA500);border:2px solid #fff;border-radius:50% 50% 50% 0;transform:rotate(-45deg);box-shadow:0 4px 14px rgba(255,140,0,0.5);display:flex;align-items:center;justify-content:center;"><span style="transform:rotate(45deg);font-size:14px;">💼</span></div>`,
            iconSize: [32, 32],
            iconAnchor: [16, 32],
            popupAnchor: [0, -32]
        });

        jobs.forEach(job => {
            const lat = Number(job.latitude) || 40.4093;
            const lng = Number(job.longitude) || 49.8671;

            const marker = L.marker([lat, lng], { icon: customIcon }).addTo(this.map);
            const popupContent = `
                <div style="font-family:'DM Sans',sans-serif;color:#fff;padding:4px;">
                    <div style="font-weight:700;font-size:15px;margin-bottom:4px;color:#FF8C00;">${job.title || 'İş elanı'}</div>
                    <div style="font-size:13px;color:#aaa;margin-bottom:8px;">${job.companyName || ''} · ${job.district || job.city || ''}</div>
                    <div style="font-weight:700;font-size:14px;margin-bottom:10px;">${job.salaryMin || 0} ₼ / ${job.salaryPeriod || 'aylıq'}</div>
                    <button id="map-job-btn-${job.id}" style="width:100%;padding:6px 12px;background:#FF8C00;color:#000;border:none;border-radius:8px;font-weight:600;font-size:12px;cursor:pointer;">Ətraflı Bax</button>
                </div>
            `;

            marker.bindPopup(popupContent);
            marker.on('popupopen', () => {
                document.getElementById(`map-job-btn-${job.id}`)?.addEventListener('click', () => {
                    if (onJobSelect) onJobSelect(job);
                });
            });

            this.markers.push(marker);
        });
    }
};

// ===== 7. AI ASSISTANT MODULE =====
const AIAssistantModule = {
    isOpen: false,
    messages: [],

    init() {
        this.messages = [{
            role: 'assistant',
            text: 'Salam! Mən İş Tap AI köməkçisiyəm. Sizə iş axtarışında, CV hazırlanmasında və ya vakansiya yerləşdirilməsində necə kömək edə bilərəm?'
        }];
    },

    toggle() {
        this.isOpen = !this.isOpen;
        const overlay = document.getElementById('aiOverlay');
        if (overlay) {
            if (this.isOpen) overlay.classList.add('open');
            else overlay.classList.remove('open');
        }
    },

    async sendMessage(userMessage, onUpdate) {
        if (!userMessage || !userMessage.trim()) return;

        const text = userMessage.trim();
        this.messages.push({ role: 'user', text });
        onUpdate([...this.messages]);

        const resp = await this.generateResponse(text);
        this.messages.push({ role: 'assistant', text: resp });
        onUpdate([...this.messages]);
    },

    async generateResponse(prompt) {
        const p = prompt.toLowerCase();
        if (p.includes('cv') || p.includes('rezume')) {
            return 'Yaxşı bir CV hazırlanması üçün:\n1. Təhsil və iş təcrübənizi ardıcıllıqla qeyd edin.\n2. Bacarıqlarınızı (məs: Proqramlaşdırma, Ofis proqramları) yazın.\n3. Əlaqə məlumatlarınızı daxil edin.\n\nİş Tap AI platformasında profilinizi tam dolduraraq avtomatik peşəkar CV əldə edə bilərsiniz!';
        }
        if (p.includes('maaş') || p.includes('maas')) {
            return 'Azərbaycanda əmək haqqı sektordan asılı olaraq dəyişir:\n• İT: 1000 - 3000+ AZN\n• Xidmət/Satış: 500 - 1200 AZN\n• Mühasibat: 800 - 2000 AZN';
        }
        return `Təşəkkür edirəm! "${prompt}" sualınızla bağlı: İş Tap AI platformasında ən aktual vakansiyaları araşdıra, profilinizi yeniləyə və işəgötürənlərlə birbaşa əlaqə saxlaya bilərsiniz.`;
    }
};

// ===== 8. MAIN APP CONTROLLER =====
const App = {
    auth: null,
    db: null,
    currentRoute: '',
    routeParams: {},

    async init() {
        if (typeof firebase === 'undefined') {
            console.error('Firebase JS SDK not loaded');
            const grid = document.getElementById('jobsGridContainer') || document.getElementById('app-root');
            if (grid) {
                grid.innerHTML = `
                    <div class="empty-state card" style="margin: 40px auto; max-width: 500px;">
                        <div class="empty-icon">⚠️</div>
                        <div class="empty-title">Yüklənmə Xətası</div>
                        <div class="empty-desc">Firebase xidmətinə qoşulmaq mümkün olmadı. Zəhmət olmasa internet bağlantınızı yoxlayın.</div>
                        <button onclick="window.location.reload()" class="btn btn-primary mt-16">🔄 Yenidən Cəhd Et</button>
                    </div>
                `;
            }
            return;
        }

        if (!firebase.apps.length) {
            firebase.initializeApp(firebaseConfig);
        }
        this.auth = firebase.auth();
        this.db = firebase.firestore();

        // Initialize modules immediately
        JobsModule.init(this.db);
        ApplicationsModule.init(this.db);
        ChatModule.init(this.db);
        ProfileModule.init(this.db);
        AIAssistantModule.init();

        // Setup routing and render page IMMEDIATELY
        window.addEventListener('hashchange', () => this.handleRoute());
        this.handleRoute();
        this.setupAIWidget();

        // Subscribe & initialize auth in background without blocking initial render
        AuthModule.subscribe(state => {
            this.updateNavbar(state);
        });
        AuthModule.init(this.auth, this.db).catch(err => console.error('Auth init error:', err));
    },

    showToast(message, type = 'info') {
        let container = document.getElementById('toast-container');
        if (!container) {
            container = document.createElement('div');
            container.id = 'toast-container';
            container.className = 'toast-container';
            document.body.appendChild(container);
        }

        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        const iconMap = { success: '✓', error: '✕', info: 'ℹ', warning: '⚠' };
        toast.innerHTML = `<span>${iconMap[type] || 'ℹ'}</span> <span>${message}</span>`;
        container.appendChild(toast);

        setTimeout(() => {
            if (toast.parentNode) toast.parentNode.removeChild(toast);
        }, 4000);
    },

    updateNavbar({ user, profile }) {
        const navRight = document.getElementById('navRight');
        const navLinks = document.getElementById('navLinks');

        if (!navRight || !navLinks) return;

        if (user && profile) {
            const isEmployer = profile.userType === 'employer';

            navLinks.innerHTML = `
                <li><a href="#/jobs" class="nav-link ${this.currentRoute === 'jobs' ? 'active' : ''}"><span class="nav-icon">💼</span> İş Elanları</a></li>
                <li><a href="#/map" class="nav-link ${this.currentRoute === 'map' ? 'active' : ''}"><span class="nav-icon">🗺️</span> Harita</a></li>
                ${isEmployer ? `
                    <li><a href="#/create-job" class="nav-link ${this.currentRoute === 'create-job' ? 'active' : ''}"><span class="nav-icon">➕</span> İlan Yerləşdir</a></li>
                    <li><a href="#/my-jobs" class="nav-link ${this.currentRoute === 'my-jobs' ? 'active' : ''}"><span class="nav-icon">📋</span> İlanlarım</a></li>
                ` : `
                    <li><a href="#/applications" class="nav-link ${this.currentRoute === 'applications' ? 'active' : ''}"><span class="nav-icon">📝</span> Müraciətlərim</a></li>
                    <li><a href="#/saved-jobs" class="nav-link ${this.currentRoute === 'saved-jobs' ? 'active' : ''}"><span class="nav-icon">⭐</span> Yadda Qalanlar</a></li>
                `}
                <li><a href="#/chat" class="nav-link ${this.currentRoute === 'chat' ? 'active' : ''}"><span class="nav-icon">💬</span> Çat</a></li>
            `;

            const avatarSrc = profile.avatarUrl || 'Logo.png';
            navRight.innerHTML = `
                <div style="display: flex; align-items: center; gap: 12px;">
                    <a href="#/profile" style="text-decoration: none; display: flex; align-items: center; gap: 8px;">
                        <img src="${avatarSrc}" class="nav-avatar" alt="Avatar" onerror="this.src='Logo.png'">
                        <span style="font-size: 13px; font-weight: 600; color: #fff;">${profile.fullName || 'Profil'}</span>
                    </a>
                    <button id="logoutBtn" class="btn btn-secondary btn-sm">Çıxış</button>
                </div>
            `;

            document.getElementById('logoutBtn')?.addEventListener('click', async () => {
                await AuthModule.logout();
                this.showToast('Hesabdan çıxış edildi', 'info');
                window.location.hash = '#/login';
            });
        } else {
            navLinks.innerHTML = `
                <li><a href="#/jobs" class="nav-link ${this.currentRoute === 'jobs' ? 'active' : ''}"><span class="nav-icon">💼</span> İş Elanları</a></li>
                <li><a href="#/map" class="nav-link ${this.currentRoute === 'map' ? 'active' : ''}"><span class="nav-icon">🗺️</span> Harita</a></li>
            `;

            navRight.innerHTML = `
                <a href="#/login" class="nav-auth-btn secondary">Giriş</a>
                <a href="#/register" class="nav-auth-btn">Qeydiyyat</a>
            `;
        }
    },

    handleRoute() {
        const hash = window.location.hash || '#/jobs';
        const parts = hash.slice(2).split('/');
        this.currentRoute = parts[0] || 'jobs';
        this.routeParams = { id: parts[1] };

        this.updateNavbar({ user: AuthModule.currentUser, profile: AuthModule.userProfile });

        const appRoot = document.getElementById('app-root');
        if (!appRoot) return;

        switch (this.currentRoute) {
            case 'jobs':
                if (this.routeParams.id) {
                    this.renderJobDetail(appRoot, this.routeParams.id);
                } else {
                    this.renderJobsList(appRoot);
                }
                break;
            case 'login':
                this.renderLogin(appRoot);
                break;
            case 'register':
                this.renderRegister(appRoot);
                break;
            case 'create-job':
                this.renderCreateJob(appRoot);
                break;
            case 'my-jobs':
                this.renderMyJobs(appRoot);
                break;
            case 'applications':
                this.renderMyApplications(appRoot);
                break;
            case 'saved-jobs':
                this.renderSavedJobs(appRoot);
                break;
            case 'chat':
                this.renderChat(appRoot, this.routeParams.id);
                break;
            case 'profile':
                this.renderProfile(appRoot);
                break;
            case 'map':
                this.renderMap(appRoot);
                break;
            default:
                this.renderJobsList(appRoot);
                break;
        }

        window.scrollTo(0, 0);
    },

    renderJobsList(container) {
        container.innerHTML = `
            <div class="app-container">
                <div class="page-header d-flex justify-between align-center flex-wrap gap-12">
                    <div>
                        <h1 class="page-title">Vakansiyalar və İş Elanları</h1>
                        <p class="page-subtitle">Azərbaycanda ən yeni AI dəstəkli iş elanlarını kəşf edin</p>
                    </div>
                    ${AuthModule.userProfile?.userType === 'employer' ? `
                        <a href="#/create-job" class="btn btn-primary">➕ Yeni İş Elanı Yerləşdir</a>
                    ` : ''}
                </div>

                <div class="filters-bar">
                    <div class="search-input-wrap">
                        <span class="search-icon">🔍</span>
                        <input type="text" id="searchInput" placeholder="İş adı, şirkət və ya açar söz axtar...">
                    </div>
                    <select id="categoryFilter" class="filter-select">
                        ${CATEGORIES.map(c => `<option value="${c.id}">${c.icon} ${c.name}</option>`).join('')}
                    </select>
                    <select id="cityFilter" class="filter-select">
                        <option value="all">📍 Bütün Şəhərlər</option>
                        ${CITIES.map(c => `<option value="${c}">${c}</option>`).join('')}
                    </select>
                    <select id="sortFilter" class="filter-select">
                        <option value="newest">⏱️ Ən yeni</option>
                        <option value="highestPay">💰 Ən yüksək maaş</option>
                        <option value="lowestPay">💵 Ən aşağı maaş</option>
                    </select>
                </div>

                <div id="jobsGridContainer">
                    <div class="loading-spinner"><div class="spinner"></div></div>
                </div>
            </div>
        `;

        const filterState = {
            categoryId: 'all',
            city: 'all',
            jobType: 'all',
            searchQuery: '',
            sortBy: 'newest'
        };

        const updateJobs = () => {
            JobsModule.listenToJobs(filterState, (jobs) => {
                const grid = document.getElementById('jobsGridContainer');
                if (!grid) return;

                if (jobs.length === 0) {
                    grid.innerHTML = `
                        <div class="empty-state card">
                            <div class="empty-icon">🔎</div>
                            <div class="empty-title">Axtarışa uyğun elan tapılmadı</div>
                            <div class="empty-desc">Zəhmət olmasa filtrləri dəyişərək yenidən cəhd edin.</div>
                        </div>
                    `;
                    return;
                }

                grid.innerHTML = `
                    <div class="job-grid stagger">
                        ${jobs.map(j => this.createJobCardHTML(j)).join('')}
                    </div>
                `;

                grid.querySelectorAll('.job-card').forEach(card => {
                    card.addEventListener('click', () => {
                        window.location.hash = `#/jobs/${card.dataset.id}`;
                    });
                });
            });
        };

        document.getElementById('searchInput')?.addEventListener('input', (e) => {
            filterState.searchQuery = e.target.value;
            updateJobs();
        });
        document.getElementById('categoryFilter')?.addEventListener('change', (e) => {
            filterState.categoryId = e.target.value;
            updateJobs();
        });
        document.getElementById('cityFilter')?.addEventListener('change', (e) => {
            filterState.city = e.target.value;
            updateJobs();
        });
        document.getElementById('sortFilter')?.addEventListener('change', (e) => {
            filterState.sortBy = e.target.value;
            updateJobs();
        });

        updateJobs();
    },

    createJobCardHTML(job) {
        const timeAgo = this.formatTimeAgo(job.createdAt);
        const salaryText = job.salaryMax ? `${job.salaryMin}–${job.salaryMax} ₼ / ${job.salaryPeriod || 'aylıq'}` : `${job.salaryMin} ₼ / ${job.salaryPeriod || 'aylıq'}`;

        return `
            <div class="job-card ${job.isUrgent ? 'urgent' : ''}" data-id="${job.id}">
                <div class="job-card-header">
                    <div class="job-logo">
                        ${job.companyLogo ? `<img src="${job.companyLogo}" alt="Logo">` : '💼'}
                    </div>
                    <div class="job-card-info">
                        <div class="job-card-title">${job.title}</div>
                        <div class="job-company">${job.companyName}</div>
                    </div>
                </div>
                <div class="job-card-badges">
                    ${job.isUrgent ? `<span class="job-badge urgent-badge">⚡ TƏCİLİ</span>` : ''}
                    <span class="job-badge">📍 ${job.district || job.city}</span>
                    <span class="job-badge">🕒 ${this.translateJobType(job.jobType)}</span>
                </div>
                <div class="job-card-meta">
                    <div class="job-salary">${salaryText}</div>
                    <div class="job-time">${timeAgo}</div>
                </div>
            </div>
        `;
    },

    async renderJobDetail(container, jobId) {
        container.innerHTML = `<div class="loading-spinner"><div class="spinner"></div></div>`;

        const job = await JobsModule.getJobById(jobId);
        if (!job) {
            container.innerHTML = `
                <div class="app-container narrow text-center" style="padding-top: 60px;">
                    <div class="empty-icon">❌</div>
                    <h2>İş elanı tapılmadı</h2>
                    <p class="text-gray mb-24">Bu elan silinmiş və ya mövcud olmaya bilər.</p>
                    <a href="#/jobs" class="btn btn-primary">İş Elanlarına Qayıt</a>
                </div>
            `;
            return;
        }

        const user = AuthModule.currentUser;
        const profile = AuthModule.userProfile;
        const isEmployer = profile?.userType === 'employer';
        const isOwner = isEmployer && job.employerId === user?.uid;
        const hasApplied = user ? await ApplicationsModule.checkHasApplied(job.id, user.uid) : false;
        const isSaved = user ? await JobsModule.checkIfSaved(user.uid, job.id) : false;

        const timeAgo = this.formatTimeAgo(job.createdAt);
        const salaryText = job.salaryMax ? `${job.salaryMin}–${job.salaryMax} ₼ / ${job.salaryPeriod || 'aylıq'}` : `${job.salaryMin} ₼ / ${job.salaryPeriod || 'aylıq'}`;

        container.innerHTML = `
            <div class="app-container">
                <button id="backBtn" class="back-btn">← Elanlara qayıt</button>

                <div class="job-detail">
                    <div class="job-detail-hero">
                        <div class="job-detail-header">
                            <div class="job-detail-logo">
                                ${job.companyLogo ? `<img src="${job.companyLogo}" style="width:100%;height:100%;border-radius:14px;object-fit:cover;">` : '💼'}
                            </div>
                            <div>
                                <h1 class="job-detail-title">${job.title}</h1>
                                <div class="job-detail-company">${job.companyName} · 📍 ${job.district ? job.district + ', ' : ''}${job.city}</div>
                            </div>
                        </div>

                        <div class="job-detail-stats">
                            <div class="job-stat">
                                <div class="job-stat-value">${salaryText}</div>
                                <div class="job-stat-label">Əmək haqqı</div>
                            </div>
                            <div class="job-stat">
                                <div class="job-stat-value">${this.translateJobType(job.jobType)}</div>
                                <div class="job-stat-label">İş rejimi</div>
                            </div>
                            <div class="job-stat">
                                <div class="job-stat-value">${job.viewCount || 0}</div>
                                <div class="job-stat-label">Baxış sayı</div>
                            </div>
                            <div class="job-stat">
                                <div class="job-stat-value">${job.applicationCount || 0}</div>
                                <div class="job-stat-label">Müraciət sayı</div>
                            </div>
                        </div>

                        <div class="job-detail-actions">
                            ${isOwner ? `
                                <button id="deleteJobBtn" class="btn btn-danger">İlanı Sil</button>
                                <a href="#/my-jobs" class="btn btn-secondary">Müraciətlərə Bax</a>
                            ` : user ? `
                                ${hasApplied ? `
                                    <button class="btn btn-success" disabled>✓ Müraciət Etmisiniz</button>
                                ` : `
                                    <button id="applyBtn" class="btn btn-primary btn-lg">⚡ İndi Müraciət Et</button>
                                `}
                                <button id="saveJobBtn" class="btn btn-secondary">${isSaved ? '★ Yadda Saxlanılıb' : '☆ Yadda Saxla'}</button>
                                <button id="chatBtn" class="btn btn-secondary">💬 İşəgötürənlə Çat</button>
                            ` : `
                                <a href="#/login" class="btn btn-primary btn-lg">Müraciət Etmək Üçün Giriş Edin</a>
                            `}
                        </div>
                    </div>

                    <div class="job-detail-section">
                        <h3>📋 İş haqqında məlumat</h3>
                        <p>${job.description || 'Məlumat qeyd olunmayıb.'}</p>
                    </div>

                    ${(() => {
                        const reqList = Array.isArray(job.requirements) ? job.requirements : (typeof job.requirements === 'string' ? job.requirements.split('\n').filter(r => r.trim()) : []);
                        if (reqList.length === 0) return '';
                        return `
                            <div class="job-detail-section">
                                <h3>🎯 Tələblər</h3>
                                <ul>
                                    ${reqList.map(r => `<li>${r}</li>`).join('')}
                                </ul>
                            </div>
                        `;
                    })()}

                    <div class="job-detail-section">
                        <h3>📞 Əlaqə məlumatları</h3>
                        <p><strong>Telefon:</strong> ${job.contactPhone || 'Qeyd olunmayıb'}</p>
                        <p><strong>Elan tarixi:</strong> ${timeAgo}</p>
                    </div>
                </div>
            </div>
        `;

        document.getElementById('backBtn')?.addEventListener('click', () => window.history.back());

        document.getElementById('applyBtn')?.addEventListener('click', async () => {
            if (!user || !profile) { window.location.hash = '#/login'; return; }
            const res = await ApplicationsModule.applyToJob({ job, applicant: profile });
            if (res.success) {
                this.showToast('Müraciətiniz uğurla göndərildi! 🎉', 'success');
                this.renderJobDetail(container, jobId);
            } else {
                this.showToast(res.error, 'error');
            }
        });

        document.getElementById('saveJobBtn')?.addEventListener('click', async () => {
            if (!user) return;
            const res = await JobsModule.toggleSavedJob(user.uid, job.id);
            if (res.success) {
                this.showToast(res.saved ? 'İş yadda saxlanıldı ★' : 'Yadda qalanlardan çıxarıldı', 'info');
                this.renderJobDetail(container, jobId);
            }
        });

        document.getElementById('chatBtn')?.addEventListener('click', async () => {
            if (!user || !profile) return;
            const res = await ChatModule.getOrCreateChat({
                employerId: job.employerId,
                employerName: job.companyName,
                jobSeekerId: user.uid,
                jobSeekerName: profile.fullName,
                jobId: job.id,
                jobTitle: job.title
            });
            if (res.success) {
                window.location.hash = `#/chat/${res.chatId}`;
            } else {
                this.showToast('Çat başladılarkən xəta baş verdi', 'error');
            }
        });

        document.getElementById('deleteJobBtn')?.addEventListener('click', async () => {
            if (confirm('Bu iş elanını silmək istədiyinizdən əminsiniz?')) {
                const res = await JobsModule.deleteJob(job.id);
                if (res.success) {
                    this.showToast('İş elanı silindi', 'success');
                    window.location.hash = '#/my-jobs';
                }
            }
        });
    },

    renderCreateJob(container) {
        const user = AuthModule.currentUser;
        const profile = AuthModule.userProfile;

        if (!user || profile?.userType !== 'employer') {
            container.innerHTML = `
                <div class="app-container narrow text-center" style="padding-top:60px;">
                    <h2>İcazə Verilmir</h2>
                    <p class="text-gray mb-24">İş elanı yerləşdirmək üçün işəgötürən hesabı ilə daxil olmalısınız.</p>
                    <a href="#/login" class="btn btn-primary">Giriş Et</a>
                </div>
            `;
            return;
        }

        container.innerHTML = `
            <div class="app-container narrow">
                <div class="card card-body">
                    <h1 class="page-title mb-8">Yeni İş Elanı Yerləşdir</h1>
                    <p class="page-subtitle mb-24">Vakansiyanızı yaradaraq minlərlə namizədə çatın</p>

                    <form id="createJobForm">
                        <div class="form-group">
                            <label class="form-label">Vakansiya Adı *</label>
                            <input type="text" id="jobTitle" class="form-input" placeholder="məs: Baş Mühasib, Kuryer..." required>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Kateqoriya *</label>
                                <select id="jobCategory" class="form-select" required>
                                    ${CATEGORIES.filter(c => c.id !== 'all').map(c => `<option value="${c.id}">${c.icon} ${c.name}</option>`).join('')}
                                </select>
                            </div>
                            <div class="form-group">
                                <label class="form-label">İş Rejimi *</label>
                                <select id="jobType" class="form-select" required>
                                    <option value="fullTime">Tam iş günü</option>
                                    <option value="partTime">Yarım gün</option>
                                    <option value="daily">Günlük</option>
                                    <option value="hourly">Saatlıq</option>
                                    <option value="freelance">Freelance</option>
                                </select>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Minimum Maaş (AZN) *</label>
                                <input type="number" id="salaryMin" class="form-input" placeholder="800" required>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Maksimum Maaş (AZN)</label>
                                <input type="number" id="salaryMax" class="form-input" placeholder="1200">
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Şəhər *</label>
                                <select id="jobCity" class="form-select" required>
                                    ${CITIES.map(c => `<option value="${c}">${c}</option>`).join('')}
                                </select>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Rayon / Qəsəbə</label>
                                <select id="jobDistrict" class="form-select">
                                    <option value="">Seçin...</option>
                                    ${BAKU_DISTRICTS.map(d => `<option value="${d}">${d}</option>`).join('')}
                                </select>
                            </div>
                        </div>

                        <div class="form-group">
                            <label class="form-label">İş Haqqında Məlumat *</label>
                            <textarea id="jobDescription" class="form-textarea" placeholder="Vakansiyanın təfərrüatları..." required></textarea>
                        </div>

                        <div class="form-group">
                            <label class="form-label">Tələblər (Hər sətirdə 1 tələb)</label>
                            <textarea id="jobRequirements" class="form-textarea" placeholder="• 2 il təcrübə"></textarea>
                        </div>

                        <div class="form-group">
                            <label class="form-label">Əlaqə Telefonu *</label>
                            <input type="tel" id="jobContactPhone" class="form-input" value="${profile.phone || ''}" required>
                        </div>

                        <button type="submit" class="btn btn-primary btn-full btn-lg mt-16">Dərc Et</button>
                    </form>
                </div>
            </div>
        `;

        document.getElementById('createJobForm')?.addEventListener('submit', async (e) => {
            e.preventDefault();

            const jobData = {
                title: document.getElementById('jobTitle').value,
                categoryId: document.getElementById('jobCategory').value,
                jobType: document.getElementById('jobType').value,
                salaryMin: document.getElementById('salaryMin').value,
                salaryMax: document.getElementById('salaryMax').value,
                salaryPeriod: 'aylıq',
                city: document.getElementById('jobCity').value,
                district: document.getElementById('jobDistrict').value,
                description: document.getElementById('jobDescription').value,
                requirements: document.getElementById('jobRequirements').value,
                contactPhone: document.getElementById('jobContactPhone').value,
            };

            const res = await JobsModule.createJob(jobData, profile);
            if (res.success) {
                this.showToast('İş elanı uğurla yerləşdirildi! 🎉', 'success');
                window.location.hash = '#/my-jobs';
            } else {
                this.showToast(res.error, 'error');
            }
        });
    },

    async renderMyJobs(container) {
        const user = AuthModule.currentUser;
        const profile = AuthModule.userProfile;

        if (!user || profile?.userType !== 'employer') {
            window.location.hash = '#/login';
            return;
        }

        container.innerHTML = `
            <div class="app-container">
                <div class="page-header d-flex justify-between align-center flex-wrap gap-12">
                    <div>
                        <h1 class="page-title">Mənim İş Elanlarım</h1>
                        <p class="page-subtitle">Dərc etdiyiniz elanlar və gələn müraciətlər</p>
                    </div>
                    <a href="#/create-job" class="btn btn-primary">➕ Yeni Elan</a>
                </div>

                <div id="myJobsContainer">
                    <div class="loading-spinner"><div class="spinner"></div></div>
                </div>
            </div>
        `;

        JobsModule.listenToJobs({ employerId: user.uid }, async (jobs) => {
            const listEl = document.getElementById('myJobsContainer');
            if (!listEl) return;

            if (jobs.length === 0) {
                listEl.innerHTML = `
                    <div class="empty-state card">
                        <div class="empty-icon">📋</div>
                        <div class="empty-title">Hələ heç bir iş elanınız yoxdur</div>
                        <div class="empty-desc">Yeni namizədlər tapmaq üçün dərhal iş elanı yerləşdirin.</div>
                        <a href="#/create-job" class="btn btn-primary">İş Elanı Yerləşdir</a>
                    </div>
                `;
                return;
            }

            const applications = await ApplicationsModule.getEmployerApplications(user.uid);

            listEl.innerHTML = `
                <div class="d-grid gap-16 stagger">
                    ${jobs.map(job => {
                        const jobApps = applications.filter(a => a.jobId === job.id);
                        return `
                            <div class="card card-body">
                                <div class="d-flex justify-between align-center flex-wrap gap-12">
                                    <div>
                                        <h3 style="font-family:'Syne',sans-serif;font-size:20px;color:#fff;">${job.title}</h3>
                                        <div class="text-gray text-sm mt-8">📍 ${job.city} · 💰 ${job.salaryMin} AZN · 👁️ ${job.viewCount || 0} baxış · 📝 ${jobApps.length} müraciət</div>
                                    </div>
                                    <div class="d-flex gap-8">
                                        <a href="#/jobs/${job.id}" class="btn btn-secondary btn-sm">Bax</a>
                                        <button class="btn btn-primary btn-sm view-applicants-btn" data-id="${job.id}">Müraciətlər (${jobApps.length})</button>
                                    </div>
                                </div>
                                <div id="applicants-section-${job.id}" class="mt-16 hidden" style="border-top:1px solid rgba(255,140,0,0.1);padding-top:16px;"></div>
                            </div>
                        `;
                    }).join('')}
                </div>
            `;

            listEl.querySelectorAll('.view-applicants-btn').forEach(btn => {
                btn.addEventListener('click', async () => {
                    const jobId = btn.dataset.id;
                    const sec = document.getElementById(`applicants-section-${jobId}`);
                    if (!sec) return;

                    if (!sec.classList.contains('hidden')) {
                        sec.classList.add('hidden');
                        return;
                    }

                    sec.innerHTML = `<div class="loading-spinner"><div class="spinner"></div></div>`;
                    sec.classList.remove('hidden');

                    const applicants = await ApplicationsModule.getJobApplicants(jobId);
                    if (applicants.length === 0) {
                        sec.innerHTML = `<div class="text-gray text-sm">Bu elana henüz müraciət olunmayıb.</div>`;
                        return;
                    }

                    sec.innerHTML = `
                        <div class="d-grid gap-12 mt-12">
                            ${applicants.map(app => `
                                <div class="card card-body" style="background:rgba(255,255,255,0.02);">
                                    <div class="d-flex justify-between align-center flex-wrap gap-12">
                                        <div>
                                            <div style="font-weight:700;color:#fff;font-size:16px;">${app.applicantName}</div>
                                            <div class="text-gray text-sm">📞 ${app.applicantPhone} ${app.applicantEmail ? '· ✉️ ' + app.applicantEmail : ''}</div>
                                            ${app.applicantSkills ? `<div class="text-xs text-primary mt-8">Bacarıqlar: ${app.applicantSkills}</div>` : ''}
                                            ${app.applicantBio ? `<div class="text-sm text-gray mt-8">"${app.applicantBio}"</div>` : ''}
                                        </div>
                                        <div class="d-flex align-center gap-8">
                                            <span class="job-badge" style="background:${app.status === 'accepted' ? 'rgba(34,197,94,0.2)' : app.status === 'rejected' ? 'rgba(239,68,68,0.2)' : 'rgba(255,140,0,0.2)'}">
                                                ${app.status === 'accepted' ? 'Qəbul edildi' : app.status === 'rejected' ? 'Rədd edildi' : 'Gözləmədə'}
                                            </span>
                                            <button class="btn btn-success btn-sm status-btn" data-id="${app.id}" data-status="accepted">Kabul Et</button>
                                            <button class="btn btn-danger btn-sm status-btn" data-id="${app.id}" data-status="rejected">Rədd Et</button>
                                            <button class="btn btn-secondary btn-sm chat-applicant-btn" data-applicant-id="${app.applicantId}" data-applicant-name="${app.applicantName}" data-job-id="${jobId}" data-job-title="${app.jobTitle}">Çat Başlat</button>
                                        </div>
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                    `;

                    sec.querySelectorAll('.status-btn').forEach(sBtn => {
                        sBtn.addEventListener('click', async () => {
                            const appId = sBtn.dataset.id;
                            const status = sBtn.dataset.status;
                            await ApplicationsModule.updateStatus(appId, status);
                            this.showToast(status === 'accepted' ? 'Müraciət qəbul edildi 🎉' : 'Müraciət rədd edildi', status === 'accepted' ? 'success' : 'info');
                            btn.click();
                        });
                    });

                    sec.querySelectorAll('.chat-applicant-btn').forEach(cBtn => {
                        cBtn.addEventListener('click', async () => {
                            const res = await ChatModule.getOrCreateChat({
                                employerId: user.uid,
                                employerName: profile.companyName || profile.fullName,
                                jobSeekerId: cBtn.dataset.applicantId,
                                jobSeekerName: cBtn.dataset.applicantName,
                                jobId: cBtn.dataset.jobId,
                                jobTitle: cBtn.dataset.jobTitle
                            });
                            if (res.success) {
                                window.location.hash = `#/chat/${res.chatId}`;
                            }
                        });
                    });
                });
            });
        });
    },

    async renderMyApplications(container) {
        const user = AuthModule.currentUser;
        if (!user) {
            window.location.hash = '#/login';
            return;
        }

        container.innerHTML = `
            <div class="app-container">
                <div class="page-header">
                    <h1 class="page-title">Mənim Müraciətlərim</h1>
                    <p class="page-subtitle">Göndərdiyiniz bütün iş müraciətləri və onların statusu</p>
                </div>
                <div id="myAppsContainer"><div class="loading-spinner"><div class="spinner"></div></div></div>
            </div>
        `;

        const apps = await ApplicationsModule.getMyApplications(user.uid);
        const el = document.getElementById('myAppsContainer');
        if (!el) return;

        if (apps.length === 0) {
            el.innerHTML = `
                <div class="empty-state card">
                    <div class="empty-icon">📝</div>
                    <div class="empty-title">Hələ heç bir müraciətiniz yoxdur</div>
                    <div class="empty-desc">İş elanlarına göz gəzdirərək 1 kliklə müraciət edə bilərsiniz.</div>
                    <a href="#/jobs" class="btn btn-primary">Vakansiyalara Bax</a>
                </div>
            `;
            return;
        }

        el.innerHTML = `
            <div class="d-grid gap-16 stagger">
                ${apps.map(a => `
                    <div class="card card-body">
                        <div class="d-flex justify-between align-center flex-wrap gap-12">
                            <div>
                                <h3 style="font-family:'Syne',sans-serif;font-size:18px;color:#fff;">${a.jobTitle}</h3>
                                <div class="text-gray text-sm mt-8">🏢 ${a.companyName} · 📅 ${this.formatTimeAgo(a.createdAt)}</div>
                            </div>
                            <div class="d-flex align-center gap-12">
                                <span class="job-badge" style="background:${a.status === 'accepted' ? 'rgba(34,197,94,0.2)' : a.status === 'rejected' ? 'rgba(239,68,68,0.2)' : 'rgba(255,140,0,0.2)';color:${a.status === 'accepted' ? '#22c55e' : a.status === 'rejected' ? '#ef4444' : '#FF8C00'};font-size:13px;padding:6px 14px;">
                                    ${a.status === 'accepted' ? '🎉 Qəbul Olundu!' : a.status === 'rejected' ? '❌ Rədd Edildi' : '⏳ Gözləmədə'}
                                </span>
                                <a href="#/jobs/${a.jobId}" class="btn btn-secondary btn-sm">Elana Bax</a>
                            </div>
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
    },

    async renderSavedJobs(container) {
        const user = AuthModule.currentUser;
        if (!user) { window.location.hash = '#/login'; return; }

        container.innerHTML = `
            <div class="app-container">
                <div class="page-header">
                    <h1 class="page-title">Yadda Qalan İlanlar</h1>
                    <p class="page-subtitle">Saxladığınız iş elanları</p>
                </div>
                <div id="savedJobsContainer"><div class="loading-spinner"><div class="spinner"></div></div></div>
            </div>
        `;

        const jobs = await JobsModule.getSavedJobs(user.uid);
        const el = document.getElementById('savedJobsContainer');
        if (!el) return;

        if (jobs.length === 0) {
            el.innerHTML = `
                <div class="empty-state card">
                    <div class="empty-icon">⭐</div>
                    <div class="empty-title">Yadda saxlanılan elan yoxdur</div>
                    <div class="empty-desc">Bəyəndiyiniz elanları "Yadda Saxla" düyməsi ilə bura əlavə edin.</div>
                    <a href="#/jobs" class="btn btn-primary">Elanları Araşdır</a>
                </div>
            `;
            return;
        }

        el.innerHTML = `
            <div class="job-grid stagger">
                ${jobs.map(j => this.createJobCardHTML(j)).join('')}
            </div>
        `;

        el.querySelectorAll('.job-card').forEach(card => {
            card.addEventListener('click', () => {
                window.location.hash = `#/jobs/${card.dataset.id}`;
            });
        });
    },

    renderChat(container, chatId) {
        const user = AuthModule.currentUser;

        if (!user) {
            window.location.hash = '#/login';
            return;
        }

        container.innerHTML = `
            <div class="chat-layout">
                <div class="chat-sidebar" id="chatSidebar">
                    <div class="chat-sidebar-header">
                        <div class="chat-sidebar-title">Mesajlar</div>
                    </div>
                    <ul class="chat-list" id="chatList">
                        <div class="loading-spinner"><div class="spinner"></div></div>
                    </ul>
                </div>

                <div class="chat-main" id="chatMain">
                    <div class="chat-empty">
                        <div class="chat-empty-icon">💬</div>
                        <div>Danışığa başlamaq üçün soldan bir çat seçin.</div>
                    </div>
                </div>
            </div>
        `;

        ChatModule.listenToChats(user.uid, (chats) => {
            const listEl = document.getElementById('chatList');
            if (!listEl) return;

            if (chats.length === 0) {
                listEl.innerHTML = `<div class="p-20 text-gray text-center text-sm" style="padding:20px;">Hələ heç bir söhbətiniz yoxdur.</div>`;
                return;
            }

            listEl.innerHTML = chats.map(c => {
                const otherName = user.uid === c.employerId ? c.jobSeekerName : c.employerName;
                const timeAgo = c.lastMessageTime ? this.formatTimeAgo(c.lastMessageTime) : '';
                const isActive = c.id === chatId;

                return `
                    <li class="chat-item ${isActive ? 'active' : ''}" data-id="${c.id}">
                        <div class="chat-avatar">${otherName ? otherName[0].toUpperCase() : '👤'}</div>
                        <div class="chat-item-info">
                            <div class="chat-item-name">${otherName}</div>
                            <div class="chat-item-last">${c.lastMessage || ''}</div>
                        </div>
                        <div class="chat-item-time">${timeAgo}</div>
                    </li>
                `;
            }).join('');

            listEl.querySelectorAll('.chat-item').forEach(item => {
                item.addEventListener('click', () => {
                    window.location.hash = `#/chat/${item.dataset.id}`;
                });
            });
        });

        if (chatId) {
            const mainEl = document.getElementById('chatMain');
            if (mainEl) {
                mainEl.innerHTML = `
                    <div class="chat-main-header">
                        <div id="chatHeaderName" class="chat-main-name">Söhbət</div>
                    </div>
                    <div class="chat-messages" id="chatMessages">
                        <div class="loading-spinner"><div class="spinner"></div></div>
                    </div>
                    <div class="chat-input-bar">
                        <textarea id="chatInput" class="chat-input" placeholder="Mesajınızı yazın..." rows="1"></textarea>
                        <button id="sendMsgBtn" class="chat-send-btn">➤</button>
                    </div>
                `;

                ChatModule.listenToMessages(chatId, (messages) => {
                    const msgEl = document.getElementById('chatMessages');
                    if (!msgEl) return;

                    msgEl.innerHTML = messages.map(m => `
                        <div class="chat-msg ${m.senderId === user.uid ? 'sent' : 'received'}">
                            <div>${m.text}</div>
                            <div class="chat-msg-time">${m.createdAt ? new Date(m.createdAt).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : ''}</div>
                        </div>
                    `).join('');

                    msgEl.scrollTop = msgEl.scrollHeight;
                });

                const sendBtn = document.getElementById('sendMsgBtn');
                const input = document.getElementById('chatInput');

                const handleSend = async () => {
                    if (!input.value.trim()) return;
                    const text = input.value;
                    input.value = '';
                    await ChatModule.sendMessage(chatId, user.uid, text);
                };

                sendBtn?.addEventListener('click', handleSend);
                input?.addEventListener('keydown', (e) => {
                    if (e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault();
                        handleSend();
                    }
                });
            }
        }
    },

    renderProfile(container) {
        const user = AuthModule.currentUser;
        const profile = AuthModule.userProfile;

        if (!user || !profile) {
            window.location.hash = '#/login';
            return;
        }

        const isEmployer = profile.userType === 'employer';

        container.innerHTML = `
            <div class="app-container narrow">
                <div class="profile-header-card">
                    <div class="profile-avatar">
                        ${profile.avatarUrl ? `<img src="${profile.avatarUrl}">` : '👤'}
                    </div>
                    <div>
                        <h1 class="profile-name">${profile.fullName}</h1>
                        <div class="profile-type">
                            <span class="profile-type-badge">${isEmployer ? '🏢 İşəgötürən' : '👤 İş Axtaran'}</span>
                            ${profile.email ? `<span>· ${profile.email}</span>` : ''}
                        </div>
                    </div>
                </div>

                <div class="card card-body">
                    <h3 class="card-title mb-24">Profil Məlumatlarını Yenilə</h3>
                    <form id="profileForm">
                        <div class="form-group">
                            <label class="form-label">Ad və Soyad *</label>
                            <input type="text" id="profFullName" class="form-input" value="${profile.fullName || ''}" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Telefon Nömrəsi *</label>
                            <input type="tel" id="profPhone" class="form-input" value="${profile.phone || ''}" required>
                        </div>

                        ${isEmployer ? `
                            <div class="form-group">
                                <label class="form-label">Şirkət Adı</label>
                                <input type="text" id="profCompanyName" class="form-input" value="${profile.companyName || ''}">
                            </div>
                            <div class="form-group">
                                <label class="form-label">Şirkət Haqqında Məlumat</label>
                                <textarea id="profCompanyDesc" class="form-textarea">${profile.companyDescription || ''}</textarea>
                            </div>
                        ` : `
                            <div class="form-group">
                                <label class="form-label">Təhsil</label>
                                <input type="text" id="profEducation" class="form-input" placeholder="BDU, Kompüter Elmləri..." value="${profile.education || ''}">
                            </div>
                            <div class="form-group">
                                <label class="form-label">İş Təcrübəsi</label>
                                <input type="text" id="profExperience" class="form-input" placeholder="2 il Kuryer..." value="${profile.experience || ''}">
                            </div>
                            <div class="form-group">
                                <label class="form-label">Bacarıqlar</label>
                                <input type="text" id="profSkills" class="form-input" placeholder="Ofis proqramları, Sürücülük..." value="${profile.skills || ''}">
                            </div>
                            <div class="form-group">
                                <label class="form-label">Haqqımda (Bio)</label>
                                <textarea id="profBio" class="form-textarea" placeholder="Haqqınızda qısa məlumat...">${profile.bio || ''}</textarea>
                            </div>
                        `}

                        <button type="submit" class="btn btn-primary btn-full mt-16">Yadda Saxla</button>
                    </form>
                </div>
            </div>
        `;

        document.getElementById('profileForm')?.addEventListener('submit', async (e) => {
            e.preventDefault();

            const updates = {
                fullName: document.getElementById('profFullName').value,
                phone: document.getElementById('profPhone').value,
            };

            if (isEmployer) {
                updates.companyName = document.getElementById('profCompanyName').value;
                updates.companyDescription = document.getElementById('profCompanyDesc').value;
            } else {
                updates.education = document.getElementById('profEducation').value;
                updates.experience = document.getElementById('profExperience').value;
                updates.skills = document.getElementById('profSkills').value;
                updates.bio = document.getElementById('profBio').value;
            }

            const res = await ProfileModule.updateProfile(user.uid, updates);
            if (res.success) {
                this.showToast('Profil yeniləndi! 🎉', 'success');
                await AuthModule.fetchUserProfile(user.uid);
            } else {
                this.showToast(res.error, 'error');
            }
        });
    },

    renderMap(container) {
        container.innerHTML = `
            <div class="app-container wide">
                <div class="page-header d-flex justify-between align-center">
                    <div>
                        <h1 class="page-title">Xəritədə İş Elanları</h1>
                        <p class="page-subtitle">Sizə ən yaxın vakansiyaları xəritə üzərindən araşdırın</p>
                    </div>
                </div>
                <div class="map-container" id="mapContainer"></div>
            </div>
        `;

        setTimeout(() => {
            MapModule.init('mapContainer');
            JobsModule.listenToJobs({}, (jobs) => {
                MapModule.renderJobs(jobs, (selectedJob) => {
                    window.location.hash = `#/jobs/${selectedJob.id}`;
                });
            });
        }, 100);
    },

    renderLogin(container) {
        container.innerHTML = `
            <div class="auth-container">
                <div class="auth-card">
                    <div class="auth-logo">
                        <img src="Logo.png" alt="Logo">
                    </div>
                    <h1 class="auth-title">Xoş Gəldiniz</h1>
                    <p class="auth-subtitle">İş Tap AI platformasına giriş edin</p>

                    <form id="loginForm">
                        <div class="form-group">
                            <label class="form-label">Email Ünvanı</label>
                            <input type="email" id="loginEmail" class="form-input" placeholder="nümunə@mail.com" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Şifrə</label>
                            <input type="password" id="loginPassword" class="form-input" placeholder="••••••••" required>
                        </div>
                        <button type="submit" class="btn btn-primary btn-full btn-lg mt-16">Giriş Et</button>
                    </form>

                    <div class="auth-divider">və ya</div>

                    <button id="googleLoginBtn" class="google-btn">
                        <span>🔍</span> Google ilə Giriş Et
                    </button>

                    <div class="auth-footer">
                        Hesabınız yoxdur? <a href="#/register">Qeydiyyatdan keçin</a>
                    </div>
                </div>
            </div>
        `;

        document.getElementById('loginForm')?.addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('loginEmail').value;
            const password = document.getElementById('loginPassword').value;

            const res = await AuthModule.loginWithEmail(email, password);
            if (res.success) {
                this.showToast('Giriş uğurludur! 🎉', 'success');
                window.location.hash = '#/jobs';
            } else {
                this.showToast(res.error, 'error');
            }
        });

        document.getElementById('googleLoginBtn')?.addEventListener('click', async () => {
            const res = await AuthModule.loginWithGoogle();
            if (res.success) {
                this.showToast('Google ilə giriş edildi! 🎉', 'success');
                window.location.hash = '#/jobs';
            }
        });
    },

    renderRegister(container) {
        container.innerHTML = `
            <div class="auth-container">
                <div class="auth-card">
                    <div class="auth-logo">
                        <img src="Logo.png" alt="Logo">
                    </div>
                    <h1 class="auth-title">Qeydiyyat</h1>
                    <p class="auth-subtitle">Yeni hesab yaradaraq dərhal başlayın</p>

                    <div class="tab-group">
                        <button id="tabJobSeeker" class="tab-btn active">👤 İş Axtaran</button>
                        <button id="tabEmployer" class="tab-btn">🏢 İşəgötürən</button>
                    </div>

                    <form id="registerForm">
                        <input type="hidden" id="regUserType" value="job_seeker">

                        <div class="form-group">
                            <label class="form-label">Ad və Soyad *</label>
                            <input type="text" id="regFullName" class="form-input" placeholder="Əli Əliyev" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Telefon Nömrəsi *</label>
                            <input type="tel" id="regPhone" class="form-input" placeholder="+994 50 123 45 67" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Email Ünvanı *</label>
                            <input type="email" id="regEmail" class="form-input" placeholder="nümunə@mail.com" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Şifrə *</label>
                            <input type="password" id="regPassword" class="form-input" placeholder="Ən azı 6 simvol" required>
                        </div>

                        <div id="employerFields" class="hidden">
                            <div class="form-group">
                                <label class="form-label">Şirkət Adı *</label>
                                <input type="text" id="regCompanyName" class="form-input" placeholder="məs: Qaf Studio">
                            </div>
                        </div>

                        <button type="submit" class="btn btn-primary btn-full btn-lg mt-16">Qeydiyyatı Tamamla</button>
                    </form>

                    <div class="auth-footer">
                        Artıq hesabınız var? <a href="#/login">Daxil olun</a>
                    </div>
                </div>
            </div>
        `;

        const tabSeeker = document.getElementById('tabJobSeeker');
        const tabEmp = document.getElementById('tabEmployer');
        const userTypeInput = document.getElementById('regUserType');
        const empFields = document.getElementById('employerFields');

        tabSeeker?.addEventListener('click', () => {
            tabSeeker.classList.add('active');
            tabEmp.classList.remove('active');
            userTypeInput.value = 'job_seeker';
            empFields.classList.add('hidden');
        });

        tabEmp?.addEventListener('click', () => {
            tabEmp.classList.add('active');
            tabSeeker.classList.remove('active');
            userTypeInput.value = 'employer';
            empFields.classList.remove('hidden');
        });

        document.getElementById('registerForm')?.addEventListener('submit', async (e) => {
            e.preventDefault();

            const regData = {
                fullName: document.getElementById('regFullName').value,
                phone: document.getElementById('regPhone').value,
                email: document.getElementById('regEmail').value,
                password: document.getElementById('regPassword').value,
                userType: userTypeInput.value,
                companyName: document.getElementById('regCompanyName')?.value || ''
            };

            const res = await AuthModule.registerWithEmail(regData);
            if (res.success) {
                this.showToast('Qeydiyyat uğurla tamamlandı! 🎉', 'success');
                window.location.hash = '#/jobs';
            } else {
                this.showToast(res.error, 'error');
            }
        });
    },

    setupAIWidget() {
        let fab = document.getElementById('aiFab');
        let overlay = document.getElementById('aiOverlay');

        if (!fab) {
            fab = document.createElement('button');
            fab.id = 'aiFab';
            fab.className = 'ai-fab';
            fab.innerHTML = '🤖';
            document.body.appendChild(fab);
        }

        if (!overlay) {
            overlay = document.createElement('div');
            overlay.id = 'aiOverlay';
            overlay.className = 'ai-overlay';
            overlay.innerHTML = `
                <div class="ai-header">
                    <div class="ai-header-title"><span>🤖</span> AI İş Köməkçisi</div>
                    <button class="ai-close" id="aiCloseBtn">✕</button>
                </div>
                <div class="ai-messages" id="aiMessagesContainer"></div>
                <div class="ai-input-bar">
                    <input type="text" id="aiInput" class="ai-input" placeholder="Sualınızı yazın...">
                    <button id="aiSendBtn" class="btn btn-primary btn-sm">➤</button>
                </div>
            `;
            document.body.appendChild(overlay);
        }

        fab.addEventListener('click', () => AIAssistantModule.toggle());
        document.getElementById('aiCloseBtn')?.addEventListener('click', () => AIAssistantModule.toggle());

        const renderAIMessages = (msgs) => {
            const container = document.getElementById('aiMessagesContainer');
            if (!container) return;
            container.innerHTML = msgs.map(m => `<div class="ai-msg ${m.role}">${m.text}</div>`).join('');
            container.scrollTop = container.scrollHeight;
        };

        renderAIMessages(AIAssistantModule.messages);

        const handleAISend = () => {
            const input = document.getElementById('aiInput');
            if (!input || !input.value.trim()) return;
            const text = input.value;
            input.value = '';
            AIAssistantModule.sendMessage(text, renderAIMessages);
        };

        document.getElementById('aiSendBtn')?.addEventListener('click', handleAISend);
        document.getElementById('aiInput')?.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') handleAISend();
        });
    },

    formatTimeAgo(dateStr) {
        if (!dateStr) return '';
        const d = new Date(dateStr);
        const now = new Date();
        const diff = Math.floor((now - d) / 1000);

        if (diff < 60) return 'İndi';
        if (diff < 3600) return `${Math.floor(diff / 60)} dəq əvvəl`;
        if (diff < 86400) return `${Math.floor(diff / 3600)} saat əvvəl`;
        if (diff < 604800) return `${Math.floor(diff / 86400)} gün əvvəl`;
        return `${Math.floor(diff / 604800)} həftə əvvəl`;
    },

    translateJobType(type) {
        const types = {
            fullTime: 'Tam iş günü',
            partTime: 'Yarım gün',
            daily: 'Günlük',
            hourly: 'Saatlıq',
            freelance: 'Freelance',
            urgent: 'Təcili'
        };
        return types[type] || type || 'Tam ştat';
    }
};

// Safe initialization
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => App.init());
} else {
    App.init();
}
