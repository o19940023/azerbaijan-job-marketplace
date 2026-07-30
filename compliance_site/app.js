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
    { id: 'it', name: 'İT və Texnologiya', icon: '💻' },
    { id: 'finance', name: 'Maliyyə və Mühasibatlıq', icon: '💰' },
    { id: 'sales', name: 'Satış və Kommersiya', icon: '🛍️' },
    { id: 'service', name: 'Xidmət və HORECA', icon: '🍽️' },
    { id: 'admin', name: 'İnzibati və Ofis', icon: '🏢' },
    { id: 'logistics', name: 'Logistika və Nəqliyyat', icon: '🛵' },
    { id: 'healthcare', name: 'Səhiyyə və Aptek', icon: '🏥' },
    { id: 'education', name: 'Təhsil və Təlim', icon: '🎓' },
    { id: 'construction', name: 'Tikinti və Sənaye', icon: '🏗️' },
    { id: 'security', name: 'Mühafizə və Xidmət', icon: '🛡️' },
    { id: 'cashier', name: 'Kassir və Qəbul', icon: '💳' },
    { id: 'driver', name: 'Sürücü və Çatdırılma', icon: '🚗' },
    { id: 'beauty', name: 'Gözəllik və Qulluq', icon: '✂️' },
    { id: 'other', name: 'Digər Vakansiyalar', icon: '💼' }
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

    async registerWithEmail({ email, password, userType }) {
        try {
            const userCredential = await this.auth.createUserWithEmailAndPassword(email, password);
            const user = userCredential.user;

            const userData = {
                email: email || '',
                userType: userType || 'job_seeker',
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            };

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
                    createdAt: firebase.firestore.FieldValue.serverTimestamp(),
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
            console.error('Google Auth Error:', err);
            let msg = err.message;
            if (err.code === 'auth/unauthorized-domain') {
                msg = 'Bu domen (istapapp.netlify.app) Firebase-də icazə verilənlər siyahısında deyil. Firebase Console > Authentication > Settings > Authorized domains bölməsinə əlavə edin.';
            } else if (err.code === 'auth/popup-blocked') {
                msg = 'Giriş pəncərəsi brauzer tərəfindən bloklandı. Lütfən pop-up icazəsini verin.';
            } else if (err.code === 'auth/popup-closed-by-user') {
                msg = 'Giriş pəncərəsi bağlandı.';
            }
            return { success: false, error: msg };
        }
    },

    async loginWithApple(userType = 'job_seeker') {
        try {
            const provider = new firebase.auth.OAuthProvider('apple.com');
            const result = await this.auth.signInWithPopup(provider);
            const user = result.user;

            let profile = await this.fetchUserProfile(user.uid);

            if (!profile) {
                const userData = {
                    fullName: user.displayName || 'Apple İstifadəçisi',
                    phone: user.phoneNumber || '',
                    email: user.email || '',
                    userType: userType,
                    avatarUrl: user.photoURL || null,
                    createdAt: firebase.firestore.FieldValue.serverTimestamp(),
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
            console.error('Apple Auth Error:', err);
            let msg = err.message;
            if (err.code === 'auth/unauthorized-domain') {
                msg = 'Bu domen (istapapp.netlify.app) Firebase-də icazə verilənlər siyahısında deyil.';
            }
            return { success: false, error: msg };
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

            let nowTime = new Date().getTime();

            // Filter out deleted/inactive jobs for seekers unless employerId filter is set
            if (!employerId) {
                jobs = jobs.filter(j => j.isActive !== false);
            }

            // Expiration check helper
            jobs.forEach(j => {
                const expires = j.expiresAt ? new Date(j.expiresAt).getTime() : (j.createdAtDate ? j.createdAtDate.getTime() + (30*86400*1000) : 0);
                j.isExpired = expires > 0 && expires < nowTime;
            });

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
                // Sorting rules matching mobile app:
                // Active jobs first, Expired jobs at the bottom
                // Among active: Urgent first, then newest createdAt
                jobs.sort((a, b) => {
                    if (a.isExpired !== b.isExpired) return a.isExpired ? 1 : -1;
                    const aU = (a.isUrgent && !a.isExpired) ? 1 : 0;
                    const bU = (b.isUrgent && !b.isExpired) ? 1 : 0;
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

            const data = doc.data();

            // Track views per unique browser/user (1 view per device)
            const viewedKey = `viewed_job_${id}`;
            if (!localStorage.getItem(viewedKey)) {
                localStorage.setItem(viewedKey, 'true');
                try {
                    this.db.collection('jobs').doc(id).update({
                        viewCount: firebase.firestore.FieldValue.increment(1)
                    });
                    data.viewCount = (data.viewCount || 0) + 1;
                } catch (_) {}
            }

            // Real-time calculated application count from applications collection
            try {
                const appSnapshot = await this.db.collection('applications').where('jobId', '==', id).get();
                data.applicationCount = appSnapshot.size;
            } catch (_) {}

            return { id: doc.id, ...data };
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
                workingHours: jobData.workingHours || '',
                requirements: jobData.requirements ? (Array.isArray(jobData.requirements) ? jobData.requirements : jobData.requirements.split('\n').filter(r => r.trim())) : [],
                benefits: jobData.benefits ? (Array.isArray(jobData.benefits) ? jobData.benefits : jobData.benefits.split(',').map(b => b.trim()).filter(Boolean)) : [],
                contactPhone: jobData.contactPhone || employer.phone || '',
                employerId: employer.id,
                createdAt: now.toISOString(),
                expiresAt: expires.toISOString(),
                isUrgent: false,
                isActive: true,
                viewCount: 0,
                applicationCount: 0,
                educationLevel: jobData.educationLevel || 'Vacib deyil',
                experienceLevel: jobData.experienceLevel || 'Təcrübəsiz',
                allowCallIfAccepted: jobData.allowCallIfAccepted !== undefined ? Boolean(jobData.allowCallIfAccepted) : true,
                applicationMethod: jobData.applicationMethod || 'in_app'
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
                const tA = a.lastMessageTime?.toDate ? a.lastMessageTime.toDate() : (a.lastMessageTime ? new Date(a.lastMessageTime) : new Date(0));
                const tB = b.lastMessageTime?.toDate ? b.lastMessageTime.toDate() : (b.lastMessageTime ? new Date(b.lastMessageTime) : new Date(0));
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

            const now = firebase.firestore.FieldValue.serverTimestamp();
            const newChat = {
                employerId,
                employerName: employerName || 'İşəgötürən',
                jobSeekerId,
                jobSeekerName: jobSeekerName || 'Namizəd',
                jobId,
                jobTitle: jobTitle || 'İş elanı',
                participantIds: [employerId, jobSeekerId],
                lastMessage: 'Söhbət başladı',
                lastMessageTime: now,
                updatedAt: now,
                lastSenderId: '',
                createdAt: now
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
            let messages = snapshot.docs.map(doc => {
                const data = doc.data();
                const createdAtDate = data.createdAt?.toDate ? data.createdAt.toDate() : (data.createdAt ? new Date(data.createdAt) : new Date());
                return { id: doc.id, ...data, createdAtDate };
            });
            messages.sort((a, b) => (a.createdAtDate || 0) - (b.createdAtDate || 0));
            onUpdate(messages);
        });

        return this.unsubscribeMessages;
    },

    async sendMessage(chatId, senderId, text) {
        if (!text || !text.trim()) return { success: false };

        try {
            const now = firebase.firestore.FieldValue.serverTimestamp();
            await this.db.collection('chats').doc(chatId).collection('messages').add({
                senderId,
                text: text.trim(),
                createdAt: now
            });

            await this.db.collection('chats').doc(chatId).update({
                lastMessage: text.trim(),
                lastMessageTime: now,
                updatedAt: now,
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
        this.checkAndShowAppBanner();

        // Subscribe & initialize auth in background without blocking initial render
        AuthModule.subscribe(state => {
            this.updateNavbar(state);
        });
        AuthModule.init(this.auth, this.db).catch(err => console.error('Auth init error:', err));
    },

    checkAndShowAppBanner() {
        const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
        if (!isMobile) return;
        if (sessionStorage.getItem('app_banner_closed') === 'true') return;

        const isIOS = /iPhone|iPad|iPod/i.test(navigator.userAgent);
        const appUrl = isIOS 
            ? 'https://apps.apple.com/us/app/i-%C5%9F-tap-ai-i-%C5%9F-elanlar%C4%B1-cv/id6760608748' 
            : 'https://play.google.com/store/apps/details?id=com.is.tap';

        const banner = document.createElement('div');
        banner.id = 'appInstallBanner';
        banner.className = 'app-install-banner';
        banner.innerHTML = `
            <div class="app-banner-left">
                <img src="Logo.png" class="app-banner-logo" alt="İş Tap AI Logo">
                <div class="app-banner-text">
                    <div class="app-banner-title">İş Tap AI Mobil Tətbiqi</div>
                    <div class="app-banner-subtitle">${isIOS ? '📱 App Store-dan Yüklə' : '🤖 Google Play-dən Yüklə'}</div>
                </div>
            </div>
            <div class="app-banner-right">
                <a href="${appUrl}" target="_blank" rel="noopener noreferrer" class="app-banner-btn">Tətbiqi Endir</a>
                <button type="button" class="app-banner-close" id="closeAppBannerBtn" aria-label="Bağla">✕</button>
            </div>
        `;

        document.body.prepend(banner);
        document.body.classList.add('has-app-banner');

        document.getElementById('closeAppBannerBtn')?.addEventListener('click', () => {
            banner.remove();
            document.body.classList.remove('has-app-banner');
            sessionStorage.setItem('app_banner_closed', 'true');
        });
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

            const avatarSrc = profile.photoUrl || profile.avatarUrl || 'Logo.png';
            navRight.innerHTML = `
                <div style="display: flex; align-items: center; gap: 12px;">
                    <a href="#/profile" style="text-decoration: none; display: flex; align-items: center; gap: 8px;">
                        <img src="${avatarSrc}" class="nav-avatar" alt="Avatar" onerror="this.src='Logo.png'">
                        <span style="font-size: 13px; font-weight: 600; color: #fff;">${profile.fullName || profile.companyName || 'Profil'}</span>
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

        const isExpired = job.isExpired || (job.expiresAt ? new Date(job.expiresAt).getTime() < new Date().getTime() : false);

        return `
            <div class="job-card ${isExpired ? 'expired' : (job.isUrgent ? 'urgent' : '')}" data-id="${job.id}" style="${isExpired ? 'opacity: 0.75; filter: grayscale(0.2);' : ''}">
                <div class="job-card-header">
                    <div class="job-logo">
                        ${job.companyLogo ? `<img src="${job.companyLogo}" alt="Logo">` : '💼'}
                    </div>
                    <div class="job-card-info">
                        <div class="job-card-title">${job.title} ${isExpired ? '<span style="color:#ef4444;font-size:12px;font-weight:600;">(Müddəti bitib)</span>' : ''}</div>
                        <div class="job-company">${job.companyName}</div>
                    </div>
                </div>
                <div class="job-card-badges">
                    ${isExpired ? `<span class="job-badge" style="background:rgba(239,68,68,0.2);color:#ef4444;font-weight:700;">⌛ MÜDDƏTİ BİTİB</span>` : (job.isUrgent ? `<span class="job-badge urgent-badge">⚡ TƏCİLİ</span>` : '')}
                    <span class="job-badge">📍 ${job.district || job.city}</span>
                    <span class="job-badge">🕒 ${this.translateJobType(job.jobType)}</span>
                </div>
                <div class="job-card-meta">
                    <div class="job-salary">${salaryText}</div>
                    <div class="job-time">${isExpired ? 'Elan bitib' : timeAgo}</div>
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

        // Check if user has applied and get application details
        let hasApplied = false;
        let applicationStatus = null;

        if (user && !isEmployer) {
            try {
                const snapshot = await this.db.collection('applications')
                    .where('jobId', '==', job.id)
                    .where('applicantId', '==', user.uid)
                    .get();
                if (!snapshot.empty) {
                    hasApplied = true;
                    applicationStatus = snapshot.docs[0].data().status;
                }
            } catch (err) {
                console.error('Check application status error:', err);
            }
        }

        const isSaved = user ? await JobsModule.checkIfSaved(user.uid, job.id) : false;

        const timeAgo = this.formatTimeAgo(job.createdAt);
        const salaryText = job.salaryMax ? `${job.salaryMin}–${job.salaryMax} ₼ / ${job.salaryPeriod || 'aylıq'}` : `${job.salaryMin} ₼ / ${job.salaryPeriod || 'aylıq'}`;

        const isExpired = job.isExpired || (job.expiresAt ? new Date(job.expiresAt).getTime() < new Date().getTime() : false);

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
                            ` : isEmployer ? `
                                <button id="employerNoticeBtn" class="btn btn-secondary btn-lg" style="opacity: 0.8;">⚠️ İşəgötürən Hesabı İlə Müraciət Etmək Olmaz</button>
                            ` : isExpired ? `
                                <button class="btn btn-danger" disabled style="opacity:0.7;">⌛ Elanın Müddəti Bitib</button>
                            ` : user ? `
                                ${hasApplied ? `
                                    <button class="btn btn-success" disabled>✓ Müraciət Etmisiniz (${applicationStatus === 'accepted' ? 'Qəbul Olundu' : applicationStatus === 'rejected' ? 'Rədd Edildi' : 'Gözləmədə'})</button>
                                ` : `
                                    <button id="applyBtn" class="btn btn-primary btn-lg">⚡ İndi Müraciət Et</button>
                                `}
                                <button id="saveJobBtn" class="btn btn-secondary">${isSaved ? '★ Yadda Saxlanılıb' : '☆ Yadda Saxla'}</button>
                                ${applicationStatus === 'accepted' ? `
                                    <button id="chatBtn" class="btn btn-primary">💬 İşəgötürənlə Çatlaş</button>
                                ` : `
                                    <button id="chatDisabledBtn" class="btn btn-secondary" style="opacity:0.7;">💬 Çat (Müraciət qəbul edildikdən sonra)</button>
                                `}
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

        document.getElementById('employerNoticeBtn')?.addEventListener('click', () => {
            alert('İşəgötürən hesabınızla iş müraciəti edə bilməzsiniz. Müraciət etmək üçün hesabınızdan çıxış edib İş Axtaran profili yaradın.');
        });

        document.getElementById('chatDisabledBtn')?.addEventListener('click', () => {
            this.showToast('İşəgötürənlə çatlaşmaq üçün müraciətinizin qəbul edilməsi lazımdır.', 'warning');
        });

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

                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Təhsil Səviyyəsi</label>
                                <select id="jobEducation" class="form-select">
                                    <option value="Vacib deyil">Vacib deyil</option>
                                    <option value="Ali">Ali</option>
                                    <option value="Orta">Orta</option>
                                    <option value="Orta ixtisas">Orta ixtisas</option>
                                    <option value="Bakalavr">Bakalavr</option>
                                    <option value="Magistr">Magistr</option>
                                </select>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Təcrübə Səviyyəsi</label>
                                <select id="jobExperience" class="form-select">
                                    <option value="Təcrübəsiz">Təcrübəsiz</option>
                                    <option value="1 ildən az">1 ildən az</option>
                                    <option value="1-3 il">1-3 il</option>
                                    <option value="3-5 il">3-5 il</option>
                                    <option value="5 ildən çox">5 ildən çox</option>
                                </select>
                            </div>
                        </div>

                        <div class="form-group">
                            <label class="form-label">İş Qrafiki / Saatları</label>
                            <input type="text" id="jobWorkingHours" class="form-input" placeholder="məs: 09:00 - 18:00">
                        </div>

                        <div class="form-group">
                            <label class="form-label">İş Haqqında Məlumat *</label>
                            <textarea id="jobDescription" class="form-textarea" placeholder="Vakansiyanın təfərrüatları..." required></textarea>
                        </div>

                        <div class="form-group">
                            <label class="form-label">Tələblər (Hər sətirdə 1 tələb)</label>
                            <textarea id="jobRequirements" class="form-textarea" placeholder="• 2 il təcrübə&#10;• Rus dili biliyi"></textarea>
                        </div>

                        <div class="form-group">
                            <label class="form-label">Əlavə İmkanlar / Təminatlar</label>
                            <input type="text" id="jobBenefits" class="form-input" placeholder="məs: Yemək, Yol, Sığorta, Bonus (vergüllə ayırın)">
                        </div>

                        <div class="form-group">
                            <label class="form-label">Əlaqə Telefonu *</label>
                            <input type="tel" id="jobContactPhone" class="form-input" value="${profile.phone || ''}" required>
                        </div>

                        <div class="form-group d-flex align-center gap-8 mt-12 mb-12">
                            <input type="checkbox" id="jobAllowCall" checked style="width: 18px; height: 18px; cursor: pointer;">
                            <label for="jobAllowCall" style="color: #fff; font-size: 14px; cursor: pointer; user-select: none;">
                                Müraciəti qəbul etdikdən sonra namizədin zəng etməsinə icazə verilsin
                            </label>
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
                educationLevel: document.getElementById('jobEducation').value,
                experienceLevel: document.getElementById('jobExperience').value,
                workingHours: document.getElementById('jobWorkingHours').value,
                description: document.getElementById('jobDescription').value,
                requirements: document.getElementById('jobRequirements').value,
                benefits: document.getElementById('jobBenefits').value,
                contactPhone: document.getElementById('jobContactPhone').value,
                allowCallIfAccepted: document.getElementById('jobAllowCall').checked,
                applicationMethod: 'in_app'
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
                        const jobApps = applications.filter(a => String(a.jobId) === String(job.id));
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

                    // Use already-fetched applications filtered by jobId (String comparison for type safety)
                    const applicants = applications.filter(a => String(a.jobId) === String(jobId));
                    if (applicants.length === 0) {
                        sec.innerHTML = `<div class="text-gray text-sm">Bu elana hələ müraciət olunmayıb.</div>`;
                        return;
                    }

                    sec.innerHTML = `
                        <div class="d-grid gap-12 mt-12">
                            ${applicants.map(app => `
                                <div class="card card-body" style="background:rgba(255,255,255,0.02);">
                                    <div class="d-flex justify-between align-center flex-wrap gap-12">
                                        <div>
                                            <div style="font-weight:700;color:#fff;font-size:16px;">${app.applicantName || 'Namizəd'}</div>
                                            <div class="text-gray text-sm">${app.applicantPhone ? '📞 ' + app.applicantPhone : ''} ${app.applicantEmail ? '· ✉️ ' + app.applicantEmail : ''}</div>
                                            ${app.applicantSkills ? `<div class="text-xs text-primary mt-8">Bacarıqlar: ${app.applicantSkills}</div>` : ''}
                                            ${app.applicantBio ? `<div class="text-sm text-gray mt-8">"${app.applicantBio}"</div>` : ''}
                                        </div>
                                        <div class="d-flex align-center gap-8 flex-wrap">
                                            <span class="job-badge" style="background:${app.status === 'accepted' ? 'rgba(34,197,94,0.2)' : app.status === 'rejected' ? 'rgba(239,68,68,0.2)' : 'rgba(255,140,0,0.2)'}">
                                                ${app.status === 'accepted' ? 'Qəbul edildi' : app.status === 'rejected' ? 'Rədd edildi' : 'Gözləmədə'}
                                            </span>
                                            <button class="btn btn-success btn-sm status-btn" data-id="${app.id}" data-status="accepted">Qəbul et</button>
                                            <button class="btn btn-danger btn-sm status-btn" data-id="${app.id}" data-status="rejected">Rədd et</button>
                                            <button class="btn btn-secondary btn-sm chat-applicant-btn" data-applicant-id="${app.applicantId}" data-applicant-name="${app.applicantName || 'Namizəd'}" data-job-id="${jobId}" data-job-title="${app.jobTitle || ''}">Mesaj yaz</button>
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
                            // Refresh the applications list
                            const freshApps = await ApplicationsModule.getEmployerApplications(user.uid);
                            applications.length = 0;
                            applications.push(...freshApps);
                            btn.click(); // close
                            btn.click(); // reopen with fresh data
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
                ${apps.map(a => {
                    const statusBg = a.status === 'accepted' ? 'rgba(34,197,94,0.2)' : a.status === 'rejected' ? 'rgba(239,68,68,0.2)' : 'rgba(255,140,0,0.2)';
                    const statusColor = a.status === 'accepted' ? '#22c55e' : a.status === 'rejected' ? '#ef4444' : '#FF8C00';

                    return `
                        <div class="card card-body">
                            <div class="d-flex justify-between align-center flex-wrap gap-12">
                                <div>
                                    <h3 style="font-family:'Syne',sans-serif;font-size:18px;color:#fff;">${a.jobTitle}</h3>
                                    <div class="text-gray text-sm mt-8">🏢 ${a.companyName} · 📅 ${this.formatTimeAgo(a.createdAt)}</div>
                                </div>
                                <div class="d-flex align-center gap-12">
                                    <span class="job-badge" style="background:${statusBg}; color:${statusColor}; font-size:13px; padding:6px 14px;">
                                        ${a.status === 'accepted' ? '🎉 Qəbul Olundu!' : a.status === 'rejected' ? '❌ Rədd Edildi' : '⏳ Gözləmədə'}
                                    </span>
                                    <a href="#/jobs/${a.jobId}" class="btn btn-secondary btn-sm">Elana Bax</a>
                                </div>
                            </div>
                        </div>
                    `;
                }).join('')}
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
            <div class="chat-layout ${chatId ? 'has-chat' : ''}">
                <div class="chat-sidebar" id="chatSidebar">
                    <div class="chat-sidebar-header">
                        <div class="chat-sidebar-title">💬 Mesajlar</div>
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
                            <div class="chat-item-name">${escapeHTML(otherName || 'İstifadəçi')}</div>
                            <div class="chat-item-last">${escapeHTML(c.lastMessage || '')}</div>
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
                        <button type="button" class="chat-back-btn" id="chatBackBtn">← Söhbətlər</button>
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

                document.getElementById('chatBackBtn')?.addEventListener('click', () => {
                    window.location.hash = '#/chat';
                });

                ChatModule.listenToMessages(chatId, (messages) => {
                    const msgEl = document.getElementById('chatMessages');
                    if (!msgEl) return;

                    msgEl.innerHTML = messages.map(m => `
                        <div class="chat-msg ${m.senderId === user.uid ? 'sent' : 'received'}">
                            <div>${m.text}</div>
                            <div class="chat-msg-time">${m.createdAtDate ? m.createdAtDate.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : ''}</div>
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

        const userAvatar = profile.photoUrl || profile.avatarUrl;

        container.innerHTML = `
            <div class="app-container narrow">
                <div class="profile-header-card">
                    <div class="profile-avatar">
                        ${userAvatar ? `<img src="${userAvatar}" onerror="this.onerror=null; this.src='Logo.png';">` : '👤'}
                    </div>
                    <div>
                        <h1 class="profile-name">${profile.fullName || profile.companyName || 'İstifadəçi'}</h1>
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
                            <label class="form-label">Profil Şəkli (İmage URL / Keçid)</label>
                            <input type="url" id="profPhotoUrl" class="form-input" placeholder="https://..." value="${userAvatar || ''}">
                        </div>
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

            const photoUrlVal = document.getElementById('profPhotoUrl')?.value?.trim();
            const updates = {
                fullName: document.getElementById('profFullName').value,
                phone: document.getElementById('profPhone').value,
            };
            if (photoUrlVal !== undefined) {
                updates.photoUrl = photoUrlVal || null;
                updates.avatarUrl = photoUrlVal || null;
            }

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

                    <div class="tab-group">
                        <button id="loginTabSeeker" class="tab-btn active">👤 İş Axtaran</button>
                        <button id="loginTabEmployer" class="tab-btn">🏢 İşəgötürən</button>
                    </div>
                    <input type="hidden" id="loginUserType" value="job_seeker">

                    <form id="loginForm">
                        <div class="form-group">
                            <label class="form-label">Email Ünvanı</label>
                            <input type="email" id="loginEmail" class="form-input" placeholder="nümunə@mail.com" required>
                        </div>
                        <div class="form-group">
                            <div class="d-flex justify-between align-center mb-4">
                                <label class="form-label mb-0">Şifrə</label>
                                <a href="javascript:void(0)" id="forgotPasswordBtn" style="font-size: 13px; color: var(--accent-orange); text-decoration: none;">Şifrəni unutmusunuz?</a>
                            </div>
                            <input type="password" id="loginPassword" class="form-input" placeholder="••••••••" required>
                        </div>
                        <button type="submit" class="btn btn-primary btn-full btn-lg mt-16">Giriş Et</button>
                    </form>

                    <div class="auth-divider">və ya</div>

                    <div style="display: flex; flex-direction: column; gap: 10px;">
                        <button id="googleLoginBtn" class="google-btn">
                            <span>🔍</span> Google ilə Giriş Et
                        </button>
                        <button id="appleLoginBtn" class="google-btn" style="background: #000; color: #fff; border: 1px solid #333;">
                            <span>🍎</span> Apple ilə Giriş Et
                        </button>
                    </div>

                    <div class="auth-footer">
                        Hesabınız yoxdur? <a href="#/register">Qeydiyyatdan keçin</a>
                    </div>
                </div>
            </div>
        `;

        const loginTabSeeker = document.getElementById('loginTabSeeker');
        const loginTabEmployer = document.getElementById('loginTabEmployer');
        const loginUserType = document.getElementById('loginUserType');

        loginTabSeeker?.addEventListener('click', () => {
            loginTabSeeker.classList.add('active');
            loginTabEmployer.classList.remove('active');
            loginUserType.value = 'job_seeker';
        });

        loginTabEmployer?.addEventListener('click', () => {
            loginTabEmployer.classList.add('active');
            loginTabSeeker.classList.remove('active');
            loginUserType.value = 'employer';
        });

        document.getElementById('forgotPasswordBtn')?.addEventListener('click', async () => {
            const email = prompt('Şifrənizi sıfırlamaq üçün email ünvanınızı daxil edin:');
            if (email && email.trim()) {
                try {
                    await firebase.auth().sendPasswordResetEmail(email.trim());
                    this.showToast('Şifrə sıfırlama meyli göndərildi! Emaillərinizi yoxlayın. 📧', 'success');
                } catch (err) {
                    this.showToast('Xəta: ' + (err.message || 'Email tapılmadı'), 'error');
                }
            }
        });

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
            const userType = document.getElementById('loginUserType')?.value || 'job_seeker';
            const res = await AuthModule.loginWithGoogle(userType);
            if (res.success) {
                this.showToast('Google ilə giriş edildi! 🎉', 'success');
                window.location.hash = '#/jobs';
            } else {
                this.showToast(res.error || 'Google giriş xətası', 'error');
            }
        });

        document.getElementById('appleLoginBtn')?.addEventListener('click', async () => {
            const userType = document.getElementById('loginUserType')?.value || 'job_seeker';
            const res = await AuthModule.loginWithApple(userType);
            if (res.success) {
                this.showToast('Apple ilə giriş edildi! 🎉', 'success');
                window.location.hash = '#/jobs';
            } else {
                this.showToast(res.error || 'Apple giriş xətası', 'error');
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
                    <h1 class="auth-title">Hesab yarat</h1>
                    <p class="auth-subtitle">Pulsuz qeydiyyatdan keçin</p>

                    <div class="tab-group">
                        <button id="tabJobSeeker" class="tab-btn active">👤 İş Axtaran</button>
                        <button id="tabEmployer" class="tab-btn">🏢 İşəgötürən</button>
                    </div>

                    <form id="registerForm">
                        <input type="hidden" id="regUserType" value="job_seeker">

                        <div class="form-group">
                            <label class="form-label">E-poçt *</label>
                            <input type="email" id="regEmail" class="form-input" placeholder="nümunə@email.com" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Şifrə *</label>
                            <input type="password" id="regPassword" class="form-input" placeholder="••••••••" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Şifrəni təsdiqləyin *</label>
                            <input type="password" id="regConfirmPassword" class="form-input" placeholder="••••••••" required>
                        </div>

                        <button type="submit" class="btn btn-primary btn-full btn-lg mt-16">Qeydiyyatdan keç</button>
                    </form>

                    <div class="auth-divider">və ya</div>

                    <div style="display: flex; flex-direction: column; gap: 10px;">
                        <button id="googleRegisterBtn" class="google-btn">
                            <span>🔍</span> Google ilə qeydiyyat
                        </button>
                        <button id="appleRegisterBtn" class="google-btn" style="background: #000; color: #fff; border: 1px solid #333;">
                            <span>🍎</span> Apple ilə qeydiyyat
                        </button>
                    </div>

                    <div class="auth-footer">
                        Artıq hesabınız var? <a href="#/login">Daxil olun</a>
                    </div>
                </div>
            </div>
        `;

        const tabSeeker = document.getElementById('tabJobSeeker');
        const tabEmp = document.getElementById('tabEmployer');
        const userTypeInput = document.getElementById('regUserType');

        tabSeeker?.addEventListener('click', () => {
            tabSeeker.classList.add('active');
            tabEmp.classList.remove('active');
            userTypeInput.value = 'job_seeker';
        });

        tabEmp?.addEventListener('click', () => {
            tabEmp.classList.add('active');
            tabSeeker.classList.remove('active');
            userTypeInput.value = 'employer';
        });

        document.getElementById('googleRegisterBtn')?.addEventListener('click', async () => {
            const userType = userTypeInput?.value || 'job_seeker';
            const res = await AuthModule.loginWithGoogle(userType);
            if (res.success) {
                this.showToast('Google ilə qeydiyyat uğurludur! 🎉', 'success');
                window.location.hash = '#/jobs';
            } else {
                this.showToast(res.error || 'Google xətası', 'error');
            }
        });

        document.getElementById('appleRegisterBtn')?.addEventListener('click', async () => {
            const userType = userTypeInput?.value || 'job_seeker';
            const res = await AuthModule.loginWithApple(userType);
            if (res.success) {
                this.showToast('Apple ilə qeydiyyat uğurludur! 🎉', 'success');
                window.location.hash = '#/jobs';
            } else {
                this.showToast(res.error || 'Apple xətası', 'error');
            }
        });

        document.getElementById('registerForm')?.addEventListener('submit', async (e) => {
            e.preventDefault();

            const password = document.getElementById('regPassword').value;
            const confirmPassword = document.getElementById('regConfirmPassword').value;

            if (password !== confirmPassword) {
                this.showToast('Şifrələr uyğun gəlmir', 'error');
                return;
            }

            const regData = {
                email: document.getElementById('regEmail').value,
                password: password,
                userType: userTypeInput.value,
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

// ===== 9. DISCOVERABILITY, FILTERING & MOBILE EXPERIENCE =====
// These enhancements live in the website bundle only. The Flutter application
// keeps using its existing screens and data model.
const normalizeSearchText = (value) => String(value || '')
    .toLocaleLowerCase('az')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/ə/g, 'e')
    .replace(/ı/g, 'i')
    .replace(/ş/g, 's')
    .replace(/ç/g, 'c')
    .replace(/ğ/g, 'g')
    .replace(/ö/g, 'o')
    .replace(/ü/g, 'u');

const escapeHTML = (value) => String(value || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');

// Firestore's simple client queries are intentionally broad. Filtering the
// received public records lets visitors combine filters without requiring an
// index for every possible filter combination.
const baseListenToJobs = JobsModule.listenToJobs.bind(JobsModule);
JobsModule.listenToJobs = function(filters = {}, onUpdate, onError) {
    const searchQuery = normalizeSearchText(filters.searchQuery);
    const minSalary = Number(filters.minSalary) || 0;
    const maxSalary = Number(filters.maxSalary) || 0;

    return baseListenToJobs({ ...filters, searchQuery: '' }, (jobs) => {
        const result = jobs.filter((job) => {
            const searchable = normalizeSearchText([
                job.title,
                job.companyName,
                job.description,
                job.city,
                job.district,
                job.categoryId,
                Array.isArray(job.requirements) ? job.requirements.join(' ') : job.requirements
            ].join(' '));

            if (searchQuery && !searchable.includes(searchQuery)) return false;

            const jobMin = Number(job.salaryMin) || 0;
            const jobMax = Number(job.salaryMax) || jobMin;
            if (minSalary && jobMax < minSalary) return false;
            if (maxSalary && jobMin > maxSalary) return false;
            return true;
        });
        onUpdate(result);
    }, onError);
};

App.updateNavbar = function({ user, profile }) {
    const navRight = document.getElementById('navRight');
    const navLinks = document.getElementById('navLinks');
    if (!navRight || !navLinks) return;

    const isEmployer = profile?.userType === 'employer';
    const links = user && profile ? `
        <li><a href="#/jobs" class="nav-link ${this.currentRoute === 'jobs' ? 'active' : ''}"><span class="nav-icon">💼</span> İş elanları</a></li>
        <li><a href="#/map" class="nav-link ${this.currentRoute === 'map' ? 'active' : ''}"><span class="nav-icon">🗺️</span> Xəritə</a></li>
        ${isEmployer ? `
            <li><a href="#/create-job" class="nav-link ${this.currentRoute === 'create-job' ? 'active' : ''}"><span class="nav-icon">➕</span> Elan yerləşdir</a></li>
            <li><a href="#/my-jobs" class="nav-link ${this.currentRoute === 'my-jobs' ? 'active' : ''}"><span class="nav-icon">📋</span> İlanlarım</a></li>
        ` : `
            <li><a href="#/applications" class="nav-link ${this.currentRoute === 'applications' ? 'active' : ''}"><span class="nav-icon">📝</span> Müraciətlərim</a></li>
            <li><a href="#/saved-jobs" class="nav-link ${this.currentRoute === 'saved-jobs' ? 'active' : ''}"><span class="nav-icon">⭐</span> Saxlanılanlar</a></li>
        `}
        <li><a href="#/chat" class="nav-link ${this.currentRoute === 'chat' ? 'active' : ''}"><span class="nav-icon">💬</span> Mesajlar</a></li>
    ` : `
        <li><a href="#/jobs" class="nav-link ${this.currentRoute === 'jobs' ? 'active' : ''}"><span class="nav-icon">💼</span> İş elanları</a></li>
        <li><a href="#/map" class="nav-link ${this.currentRoute === 'map' ? 'active' : ''}"><span class="nav-icon">🗺️</span> Xəritə</a></li>
    `;
    navLinks.innerHTML = links;

    if (user && profile) {
        const avatarSrc = profile.photoUrl || profile.avatarUrl || 'Logo.png';
        navRight.innerHTML = `
            <a href="#/profile" class="nav-profile-link">
                <img src="${escapeHTML(avatarSrc)}" class="nav-avatar" alt="Profil şəkli" onerror="this.src='Logo.png'">
                <span>${escapeHTML(profile.fullName || profile.companyName || 'Profil')}</span>
            </a>
            <button id="logoutBtn" class="btn btn-secondary btn-sm">Çıxış</button>
        `;
        document.getElementById('logoutBtn')?.addEventListener('click', async () => {
            await AuthModule.logout();
            this.showToast('Hesabdan çıxış edildi', 'info');
            window.location.hash = '#/login';
        });
    } else {
        navRight.innerHTML = '<a href="#/login" class="nav-auth-btn secondary">Giriş</a><a href="#/register" class="nav-auth-btn">Qeydiyyat</a>';
    }

    let toggle = document.getElementById('navToggle');
    if (!toggle) {
        toggle = document.createElement('button');
        toggle.id = 'navToggle';
        toggle.className = 'nav-toggle';
        toggle.type = 'button';
        toggle.setAttribute('aria-label', 'Menyunu aç');
        toggle.setAttribute('aria-expanded', 'false');
        toggle.textContent = '☰';
        document.querySelector('.nav-inner')?.appendChild(toggle);
    }
    toggle.onclick = () => {
        const open = navLinks.classList.toggle('open');
        toggle.setAttribute('aria-expanded', String(open));
        toggle.textContent = open ? '✕' : '☰';
    };
    navLinks.querySelectorAll('a').forEach(link => link.addEventListener('click', () => navLinks.classList.remove('open')));

    // Render / update mobile bottom tab bar
    this.renderMobileNav({ user, profile });
};

App.renderMobileNav = function({ user, profile }) {
    let mobileNav = document.getElementById('mobileBottomNav');
    if (!mobileNav) {
        mobileNav = document.createElement('nav');
        mobileNav.id = 'mobileBottomNav';
        mobileNav.className = 'mobile-bottom-nav';
        mobileNav.setAttribute('aria-label', 'Mobil naviqasiya');
        document.body.appendChild(mobileNav);
    }

    const route = this.currentRoute || 'jobs';
    const isEmployer = profile?.userType === 'employer';

    if (user && profile) {
        if (isEmployer) {
            mobileNav.innerHTML = `
                <a href="#/jobs" class="mobile-nav-item ${route === 'jobs' ? 'active' : ''}">
                    <span class="mobile-icon">💼</span>
                    <span>Elanlar</span>
                </a>
                <a href="#/my-jobs" class="mobile-nav-item ${route === 'my-jobs' ? 'active' : ''}">
                    <span class="mobile-icon">📋</span>
                    <span>İlanlarım</span>
                </a>
                <a href="#/create-job" class="mobile-nav-item ${route === 'create-job' ? 'active' : ''}">
                    <span class="mobile-icon">➕</span>
                    <span>İlan Ver</span>
                </a>
                <a href="#/chat" class="mobile-nav-item ${route === 'chat' ? 'active' : ''}">
                    <span class="mobile-icon">💬</span>
                    <span>Çat</span>
                </a>
                <a href="#/profile" class="mobile-nav-item ${route === 'profile' ? 'active' : ''}">
                    <span class="mobile-icon">👤</span>
                    <span>Profil</span>
                </a>
            `;
        } else {
            mobileNav.innerHTML = `
                <a href="#/jobs" class="mobile-nav-item ${route === 'jobs' ? 'active' : ''}">
                    <span class="mobile-icon">💼</span>
                    <span>Elanlar</span>
                </a>
                <a href="#/applications" class="mobile-nav-item ${route === 'applications' ? 'active' : ''}">
                    <span class="mobile-icon">📝</span>
                    <span>Müraciətlər</span>
                </a>
                <a href="#/chat" class="mobile-nav-item ${route === 'chat' ? 'active' : ''}">
                    <span class="mobile-icon">💬</span>
                    <span>Çat</span>
                </a>
                <a href="#/saved-jobs" class="mobile-nav-item ${route === 'saved-jobs' ? 'active' : ''}">
                    <span class="mobile-icon">⭐</span>
                    <span>Saxlananlar</span>
                </a>
                <a href="#/profile" class="mobile-nav-item ${route === 'profile' ? 'active' : ''}">
                    <span class="mobile-icon">👤</span>
                    <span>Profil</span>
                </a>
            `;
        }
    } else {
        mobileNav.innerHTML = `
            <a href="#/jobs" class="mobile-nav-item ${route === 'jobs' ? 'active' : ''}">
                <span class="mobile-icon">💼</span>
                <span>Elanlar</span>
            </a>
            <a href="#/map" class="mobile-nav-item ${route === 'map' ? 'active' : ''}">
                <span class="mobile-icon">🗺️</span>
                <span>Xəritə</span>
            </a>
            <a href="#/login" class="mobile-nav-item ${route === 'login' ? 'active' : ''}">
                <span class="mobile-icon">🔑</span>
                <span>Giriş</span>
            </a>
            <a href="#/register" class="mobile-nav-item ${route === 'register' ? 'active' : ''}">
                <span class="mobile-icon">📝</span>
                <span>Qeydiyyat</span>
            </a>
        `;
    }
};

App.renderJobsList = function(container) {
    const app = this;
    const urlFilters = new URLSearchParams(window.location.search);
    const filterState = {
        categoryId: urlFilters.get('category') || 'all',
        city: urlFilters.get('city') || 'all',
        jobType: urlFilters.get('type') || 'all',
        minSalary: urlFilters.get('minSalary') || '',
        maxSalary: urlFilters.get('maxSalary') || '',
        searchQuery: urlFilters.get('q') || '',
        sortBy: urlFilters.get('sort') || 'newest'
    };

    container.innerHTML = `
        <div class="app-container">
            <section class="jobs-hero" aria-labelledby="jobs-heading">
                <div>
                    <p class="eyebrow">AZƏRBAYCAN ÜZRƏ AKTUAL VAKANSİYALAR VƏ İŞ ELANLARI</p>
                    <h1 id="jobs-heading" class="page-title">Azərbaycanda İş Elanları və Vakansiyalar 2026</h1>
                    <p class="page-subtitle">Bakı, Sumqayıt, Gəncə və bütün regionlarda ən yeni iş elanları. Peşə, şəhər, iş rejimi və maaşa görə filtrləyin, birbaşa müraciət edin.</p>
                </div>
                ${AuthModule.userProfile?.userType === 'employer' ? '<a href="#/create-job" class="btn btn-primary">➕ İş elanı yerləşdir</a>' : '<a href="#/register" class="btn btn-primary">Pulsuz hesab yarat</a>'}
            </section>

            <!-- BOSS.AZ STYLE CATEGORY CARDS GRID -->
            <div class="categories-grid" id="categoriesGrid" aria-label="Klassik iş kateqoriyaları">
                ${CATEGORIES.map(c => `
                    <div class="category-card ${filterState.categoryId === c.id ? 'active' : ''}" data-category-id="${c.id}">
                        <div class="category-card-icon">${c.icon}</div>
                        <div class="category-card-name">${c.name}</div>
                    </div>
                `).join('')}
            </div>

            <nav class="quick-filter-links" aria-label="Populyar axtarışlar">
                <span>Populyar axtarışlar:</span>
                <button type="button" data-category="it">💻 İT vakansiyaları</button>
                <button type="button" data-category="sales">🛍️ Satış mütəxəssisi</button>
                <button type="button" data-category="driver">🚗 Sürücü işi</button>
                <button type="button" data-category="service">🍽️ Ofisant & Barista</button>
                <button type="button" data-city="Bakı">📍 Bakı iş elanları</button>
                <button type="button" data-city="Gəncə">📍 Gəncə vakansiyaları</button>
            </nav>

            <section class="filters-panel" aria-label="Vakansiya filtrləri">
                <div class="search-input-wrap">
                    <span class="search-icon">🔍</span>
                    <input type="search" id="searchInput" value="${escapeHTML(filterState.searchQuery)}" placeholder="Peşə, şirkət, şəhər və ya açar söz yazın (məs: sürücü, proqramçı, kassir)" autocomplete="off">
                </div>
                <div class="filter-row">
                    <label>Kateqoriya
                        <select id="categoryFilter" class="filter-select">${CATEGORIES.map(c => `<option value="${c.id}" ${filterState.categoryId === c.id ? 'selected' : ''}>${c.icon} ${c.name}</option>`).join('')}</select>
                    </label>
                    <label>Şəhər
                        <select id="cityFilter" class="filter-select"><option value="all">📍 Bütün şəhərlər</option>${CITIES.map(c => `<option value="${c}" ${filterState.city === c ? 'selected' : ''}>${c}</option>`).join('')}</select>
                    </label>
                    <label>İş rejimi
                        <select id="jobTypeFilter" class="filter-select">
                            <option value="all">⏱️ Bütün rejimlər</option>
                            <option value="fullTime" ${filterState.jobType === 'fullTime' ? 'selected' : ''}>Tam iş günü</option>
                            <option value="partTime" ${filterState.jobType === 'partTime' ? 'selected' : ''}>Yarım gün (Part-time)</option>
                            <option value="daily" ${filterState.jobType === 'daily' ? 'selected' : ''}>Gündəlik iş</option>
                            <option value="hourly" ${filterState.jobType === 'hourly' ? 'selected' : ''}>Saatlıq iş</option>
                            <option value="freelance" ${filterState.jobType === 'freelance' ? 'selected' : ''}>Freelance / Distant</option>
                        </select>
                    </label>
                    <label>Maaş (AZN)
                        <div class="salary-inputs"><input type="number" min="0" id="minSalaryFilter" value="${escapeHTML(filterState.minSalary)}" placeholder="Min ₼"><input type="number" min="0" id="maxSalaryFilter" value="${escapeHTML(filterState.maxSalary)}" placeholder="Max ₼"></div>
                    </label>
                    <label>Sıralama
                        <select id="sortFilter" class="filter-select"><option value="newest">Ən yeni</option><option value="highestPay" ${filterState.sortBy === 'highestPay' ? 'selected' : ''}>Yüksək maaş</option><option value="lowestPay" ${filterState.sortBy === 'lowestPay' ? 'selected' : ''}>Aşağı maaş</option></select>
                    </label>
                    <button type="button" id="clearFiltersBtn" class="btn btn-secondary btn-sm clear-filters">Filtrləri təmizlə</button>
                </div>
            </section>

            <div class="results-heading"><h2>Aktual Vakansiyalar</h2><span id="jobsCount" aria-live="polite">Axtarılır…</span></div>
            <div id="jobsGridContainer"><div class="loading-spinner"><div class="spinner"></div></div></div>

            <section class="seo-content" aria-label="İş Tap AI haqqında SEO məlumatı">
                <h2>Azərbaycanda İş Elanları və Vakansiyalar Platforması</h2>
                <p>İş Tap AI iş axtaranları və işəgötürənləri Azərbaycanda bir araya gətirən müasir vakansiya portalıdır. Elanları Bakı, Gəncə, Sumqayıt və digər şəhərlərə; İT, mühasibatlıq, xidmət, satış, sürücülük, aşpazlıq və başqa sahələrə görə Boss.az üslubunda filtrləyin.</p>
                <div class="seo-faq-grid">
                    <article>
                        <h3>İş axtaranlar üçün necə iş tapmaq olar?</h3>
                        <p>Kateqoriyalar bölməsindən maraqlandığınız peşəni seçin, maaş və şəhər filtrini tətbiq edin. Qeydiyyatdan keçərək 1 kliklə müraciət edin və işəgötürənlə dərhal çatda yazışın.</p>
                    </article>
                    <article>
                        <h3>İşəgötürənlər üçün elan yerləşdirmək</h3>
                        <p>Hesab yaradın, vakansiya tələblərini daxil edin və pulsuz elan yerləşdirin. Namizədlərin müraciətlərini "İlanlarım" bölməsindən idarə edin və uyğun şəxslərlə birbaşa əlaqə saxlayın.</p>
                    </article>
                </div>
            </section>
        </div>`;

    let searchTimer;
    const syncUrl = () => {
        const params = new URLSearchParams();
        if (filterState.searchQuery) params.set('q', filterState.searchQuery);
        if (filterState.categoryId !== 'all') params.set('category', filterState.categoryId);
        if (filterState.city !== 'all') params.set('city', filterState.city);
        if (filterState.jobType !== 'all') params.set('type', filterState.jobType);
        if (filterState.minSalary) params.set('minSalary', filterState.minSalary);
        if (filterState.maxSalary) params.set('maxSalary', filterState.maxSalary);
        if (filterState.sortBy !== 'newest') params.set('sort', filterState.sortBy);
        const nextUrl = `${window.location.pathname}${params.toString() ? '?' + params.toString() : ''}#/jobs`;
        window.history.replaceState({}, '', nextUrl);
    };

    const updateJobs = () => {
        JobsModule.listenToJobs(filterState, (jobs) => {
            const grid = document.getElementById('jobsGridContainer');
            const count = document.getElementById('jobsCount');
            if (!grid) return;
            if (count) count.textContent = `${jobs.length} elan tapıldı`;
            if (!jobs.length) {
                grid.innerHTML = '<div class="empty-state card"><div class="empty-icon">🔎</div><div class="empty-title">Uyğun elan tapılmadı</div><div class="empty-desc">Açar sözü və ya filtr seçimlərinizi dəyişib yenidən yoxlayın.</div></div>';
                return;
            }
            grid.innerHTML = `<div class="job-grid stagger">${jobs.map(job => app.createJobCardHTML(job)).join('')}</div>`;
            grid.querySelectorAll('.job-card').forEach(card => card.addEventListener('click', () => window.location.hash = `#/jobs/${card.dataset.id}`));
        });

        // Highlight active category card in grid
        document.querySelectorAll('.category-card').forEach(card => {
            card.classList.toggle('active', card.dataset.categoryId === filterState.categoryId);
        });

        syncUrl();
    };

    // Category Grid click handler
    document.querySelectorAll('.category-card').forEach(card => {
        card.addEventListener('click', () => {
            filterState.categoryId = card.dataset.categoryId;
            const catSelect = document.getElementById('categoryFilter');
            if (catSelect) catSelect.value = filterState.categoryId;
            updateJobs();
        });
    });

    const bindFilter = (id, key, delayed = false) => document.getElementById(id)?.addEventListener('input', event => {
        filterState[key] = event.target.value;
        if (delayed) { clearTimeout(searchTimer); searchTimer = setTimeout(updateJobs, 220); } else updateJobs();
    });
    bindFilter('searchInput', 'searchQuery', true);
    ['categoryFilter', 'cityFilter', 'jobTypeFilter', 'sortFilter'].forEach((id) => document.getElementById(id)?.addEventListener('change', event => {
        filterState[id === 'categoryFilter' ? 'categoryId' : id === 'cityFilter' ? 'city' : id === 'jobTypeFilter' ? 'jobType' : 'sortBy'] = event.target.value;
        updateJobs();
    }));
    bindFilter('minSalaryFilter', 'minSalary', true);
    bindFilter('maxSalaryFilter', 'maxSalary', true);
    document.querySelectorAll('.quick-filter-links button').forEach(button => button.addEventListener('click', () => {
        if (button.dataset.category) {
            filterState.categoryId = button.dataset.category;
            const catSelect = document.getElementById('categoryFilter');
            if (catSelect) catSelect.value = filterState.categoryId;
        }
        if (button.dataset.city) {
            filterState.city = button.dataset.city;
            const citySelect = document.getElementById('cityFilter');
            if (citySelect) citySelect.value = filterState.city;
        }
        updateJobs();
    }));
    document.getElementById('clearFiltersBtn')?.addEventListener('click', () => {
        Object.assign(filterState, { categoryId: 'all', city: 'all', jobType: 'all', minSalary: '', maxSalary: '', searchQuery: '', sortBy: 'newest' });
        ['searchInput', 'minSalaryFilter', 'maxSalaryFilter'].forEach(id => {
            const el = document.getElementById(id);
            if (el) el.value = '';
        });
        document.getElementById('categoryFilter').value = 'all';
        document.getElementById('cityFilter').value = 'all';
        document.getElementById('jobTypeFilter').value = 'all';
        document.getElementById('sortFilter').value = 'newest';
        updateJobs();
    });
    updateJobs();
};

App.renderMyApplications = async function(container) {
    const user = AuthModule.currentUser;
    const profile = AuthModule.userProfile;
    if (!user || profile?.userType === 'employer') { window.location.hash = '#/login'; return; }
    container.innerHTML = '<div class="app-container"><div class="page-header"><h1 class="page-title">Mənim Müraciətlərim</h1><p class="page-subtitle">Göndərdiyiniz müraciətlərin vəziyyəti və işəgötürən mesajları</p></div><div id="myAppsContainer" class="loading-spinner"><div class="spinner"></div></div></div>';
    const apps = await ApplicationsModule.getMyApplications(user.uid);
    const list = document.getElementById('myAppsContainer');
    if (!list) return;
    if (!apps.length) {
        list.innerHTML = '<div class="empty-state card"><div class="empty-icon">📝</div><div class="empty-title">Hələ müraciətiniz yoxdur</div><div class="empty-desc">Uyğun vakansiyanı seçib bir neçə addımda müraciət edin.</div><a href="#/jobs" class="btn btn-primary">Elanlara bax</a></div>';
        return;
    }
    const statusText = { accepted: '🎉 Qəbul Edildi', rejected: '❌ Rədd Edildi', pending: '⏳ Gözləmədə' };
    list.innerHTML = `<div class="d-grid gap-16 stagger">${apps.map(appItem => `<article class="card card-body application-card"><div><h2>${escapeHTML(appItem.jobTitle)}</h2><p class="text-gray text-sm mt-8">🏢 ${escapeHTML(appItem.companyName)} · ${app.formatTimeAgo(appItem.createdAt)}</p></div><div class="application-actions"><span class="application-status ${appItem.status || 'pending'}">${statusText[appItem.status] || statusText.pending}</span><a href="#/jobs/${encodeURIComponent(appItem.jobId)}" class="btn btn-secondary btn-sm">Elana bax</a><button type="button" class="btn btn-primary btn-sm application-chat-btn" data-employer-id="${escapeHTML(appItem.employerId)}" data-employer-name="${escapeHTML(appItem.companyName)}" data-job-id="${escapeHTML(appItem.jobId)}" data-job-title="${escapeHTML(appItem.jobTitle)}">💬 Mesaj yaz</button></div></article>`).join('')}</div>`;
    list.querySelectorAll('.application-chat-btn').forEach(button => button.addEventListener('click', async () => {
        const result = await ChatModule.getOrCreateChat({ employerId: button.dataset.employerId, employerName: button.dataset.employerName, jobSeekerId: user.uid, jobSeekerName: profile.fullName, jobId: button.dataset.jobId, jobTitle: button.dataset.jobTitle });
        if (result.success) window.location.hash = `#/chat/${result.chatId}`;
        else app.showToast('Mesajlaşma başladılarkən xəta baş verdi.', 'error');
    }));
};

// Safe initialization
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => App.init());
} else {
    App.init();
}

