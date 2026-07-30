/**
 * İş Tap AI — Applications Module
 * Job Applications Management (Submit, View status, Accept/Reject)
 * Optimized for Firestore single-field queries without composite index requirements
 */

export const ApplicationsModule = {
    db: null,

    init(db) {
        this.db = db;
    },

    async applyToJob({ job, applicant }) {
        try {
            if (!applicant || !job) {
                return { success: false, error: 'İstifadəçi və ya iş məlumatı tapılmadı.' };
            }

            // Check if already applied
            const hasApplied = await this.checkHasApplied(job.id, applicant.id);
            if (hasApplied) {
                return { success: false, error: 'Bu işə artıq müraciət etmisiniz.' };
            }

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
                status: 'pending', // pending, accepted, rejected
                createdAt: new Date().toISOString(),
                statusNotificationSent: false
            };

            await this.db.collection('applications').add(applicationData);

            // Increment job application count
            try {
                await this.db.collection('jobs').doc(job.id).update({
                    applicationCount: firebase.firestore.FieldValue.increment(1)
                });
            } catch (_) {}

            return { success: true };
        } catch (err) {
            console.error('Apply to job error:', err);
            return { success: false, error: err.message };
        }
    },

    async checkHasApplied(jobId, applicantId) {
        if (!jobId || !applicantId) return false;
        try {
            // Single field query + in-memory check to prevent Firestore index requirements
            const snapshot = await this.db.collection('applications')
                .where('applicantId', '==', applicantId)
                .get();
            return snapshot.docs.some(doc => doc.data().jobId === jobId);
        } catch (err) {
            console.error('Check has applied error:', err);
            return false;
        }
    },

    // Job Seeker: Get my applications
    async getMyApplications(applicantId) {
        try {
            const snapshot = await this.db.collection('applications')
                .where('applicantId', '==', applicantId)
                .get();
            
            const list = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            list.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
            return list;
        } catch (err) {
            console.error('Error fetching my applications:', err);
            return [];
        }
    },

    // Employer: Get applications for a specific job
    async getJobApplicants(jobId) {
        try {
            const snapshot = await this.db.collection('applications')
                .where('jobId', '==', jobId)
                .get();
            
            const list = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            list.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
            return list;
        } catch (err) {
            console.error('Error fetching job applicants:', err);
            return [];
        }
    },

    // Employer: Get all applications for my posted jobs
    async getEmployerApplications(employerId) {
        try {
            const snapshot = await this.db.collection('applications')
                .where('employerId', '==', employerId)
                .get();
            
            const list = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            list.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
            return list;
        } catch (err) {
            console.error('Error fetching employer applications:', err);
            return [];
        }
    },

    // Update application status
    async updateStatus(applicationId, newStatus) {
        try {
            await this.db.collection('applications').doc(applicationId).update({
                status: newStatus
            });
            return { success: true };
        } catch (err) {
            return { success: false, error: err.message };
        }
    }
};

