/**
 * İş Tap AI — Auth Module
 * Firebase Auth & User Profile Management
 */

export const AuthModule = {
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
        // Call immediately with current state
        callback({ user: this.currentUser, profile: this.userProfile });
    },

    notifyListeners() {
        this.listeners.forEach(cb => cb({ user: this.currentUser, profile: this.userProfile }));
    },

    async fetchUserProfile(uid) {
        try {
            const docRef = this.db.collection('users').doc(uid);
            const doc = await docRef.get();
            if (doc.exists) {
                this.userProfile = { id: doc.id, ...doc.data() };
            } else {
                this.userProfile = null;
            }
        } catch (err) {
            console.error('Error fetching user profile:', err);
            this.userProfile = null;
        }
        return this.userProfile;
    },

    async registerWithEmail({ email, password, fullName, phone, userType, companyName, companyAddress, sector }) {
        try {
            const userCredential = await this.auth.createUserWithEmailAndPassword(email, password);
            const user = userCredential.user;

            const userData = {
                fullName: fullName || '',
                phone: phone || '',
                email: email || '',
                userType: userType || 'job_seeker', // 'job_seeker' or 'employer'
                avatarUrl: null,
                createdAt: new Date().toISOString(),
            };

            if (userType === 'employer') {
                userData.companyName = companyName || '';
                userData.companyAddress = companyAddress || '';
                userData.sector = sector || '';
                userData.companyDescription = '';
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
            console.error('Registration error:', err);
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
            console.error('Login error:', err);
            return { success: false, error: this.getErrorMessage(err.code) };
        }
    },

    async loginWithGoogle(userType = 'job_seeker') {
        try {
            const provider = new firebase.auth.GoogleAuthProvider();
            const result = await this.auth.signInWithPopup(provider);
            const user = result.user;

            // Check if profile exists
            let profile = await this.fetchUserProfile(user.uid);

            if (!profile) {
                // Create new profile
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
                    userData.companyAddress = '';
                    userData.sector = '';
                }

                await this.db.collection('users').doc(user.uid).set(userData);
                this.userProfile = { id: user.uid, ...userData };
            }

            this.notifyListeners();
            return { success: true, user: this.userProfile };
        } catch (err) {
            console.error('Google Sign-in error:', err);
            return { success: false, error: err.message };
        }
    },

    async sendPasswordReset(email) {
        try {
            await this.auth.sendPasswordResetEmail(email);
            return { success: true };
        } catch (err) {
            return { success: false, error: this.getErrorMessage(err.code) };
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
            case 'auth/email-already-in-use':
                return 'Bu email ünvanı artıq istifadə olunur.';
            case 'auth/invalid-email':
                return 'Düzgün email ünvanı daxil edin.';
            case 'auth/weak-password':
                return 'Şifrə ən azı 6 simvoldan ibarət olmalıdır.';
            case 'auth/user-not-found':
            case 'auth/wrong-password':
                return 'Email və ya şifrə yanlışdır.';
            case 'auth/too-many-requests':
                return 'Çoxlu uğursuz cəhd. Zəhmət olmasa bir az gözləyin.';
            default:
                return 'Xəta baş verdi. Zəhmət olmasa yenidən cəhd edin.';
        }
    }
};


