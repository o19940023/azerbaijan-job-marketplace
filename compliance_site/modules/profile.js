/**
 * İş Tap AI — Profile Module
 * User Profile View & Edit Management
 */

export const ProfileModule = {
    db: null,

    init(db) {
        this.db = db;
    },

    async updateProfile(userId, updateData) {
        try {
            await this.db.collection('users').doc(userId).update(updateData);
            return { success: true };
        } catch (err) {
            console.error('Update profile error:', err);
            return { success: false, error: err.message };
        }
    },

    async uploadAvatar(userId, file) {
        try {
            if (!file) return { success: false, error: 'Fayl seçilməyib.' };

            const storageRef = firebase.storage().ref();
            const avatarRef = storageRef.child(`avatars/${userId}_${Date.now()}`);

            const snapshot = await avatarRef.put(file);
            const downloadUrl = await snapshot.ref.getDownloadURL();

            await this.db.collection('users').doc(userId).update({
                avatarUrl: downloadUrl
            });

            return { success: true, avatarUrl: downloadUrl };
        } catch (err) {
            console.error('Upload avatar error:', err);
            return { success: false, error: err.message };
        }
    },

    async deleteAccount(userId) {
        try {
            // Delete user doc
            await this.db.collection('users').doc(userId).delete();
            // Delete Firebase auth user
            const user = firebase.auth().currentUser;
            if (user) {
                await user.delete();
            }
            return { success: true };
        } catch (err) {
            console.error('Delete account error:', err);
            return { success: false, error: err.message };
        }
    }
};


