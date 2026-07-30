/**
 * İş Tap AI — Jobs Module
 * Jobs Listing, Search, Filters, Detail, Posting, and Saved Jobs
 * Matching Flutter Mobile App Logic (Client-side filtering to avoid Firestore Index errors)
 */

export const JobsModule = {
    db: null,
    unsubscribeJobs: null,

    init(db) {
        this.db = db;
    },

    // Realtime jobs listener matching Flutter mobile app strategy
    listenToJobs({ categoryId, city, jobType, searchQuery, sortBy, employerId }, onUpdate, onError) {
        if (this.unsubscribeJobs) {
            this.unsubscribeJobs();
        }

        // Simple query without multiple where clauses to avoid Firestore Composite Index errors
        let query = this.db.collection('jobs');

        if (employerId) {
            query = query.where('employerId', '==', employerId);
        }

        this.unsubscribeJobs = query.onSnapshot((snapshot) => {
            let jobs = snapshot.docs.map(doc => {
                const data = doc.data();
                return {
                    id: doc.id,
                    ...data,
                    createdAtDate: data.createdAt ? new Date(data.createdAt) : new Date(),
                };
            });

            // Filter active jobs (unless employer viewing their own jobs)
            if (!employerId) {
                jobs = jobs.filter(j => j.isActive !== false);
            }

            // Category filter
            if (categoryId && categoryId !== 'all') {
                jobs = jobs.filter(j => j.categoryId === categoryId);
            }

            // City filter
            if (city && city !== 'all') {
                jobs = jobs.filter(j => j.city === city);
            }

            // JobType filter
            if (jobType && jobType !== 'all') {
                jobs = jobs.filter(j => j.jobType === jobType);
            }

            // Search query filter
            if (searchQuery && searchQuery.trim() !== '') {
                const q = searchQuery.toLowerCase().trim();
                jobs = jobs.filter(j => 
                    (j.title && j.title.toLowerCase().includes(q)) ||
                    (j.companyName && j.companyName.toLowerCase().includes(q)) ||
                    (j.description && j.description.toLowerCase().includes(q)) ||
                    (j.district && j.district.toLowerCase().includes(q))
                );
            }

            // Client-side sorting
            if (sortBy === 'highestPay') {
                jobs.sort((a, b) => (Number(b.salaryMin) || 0) - (Number(a.salaryMin) || 0));
            } else if (sortBy === 'lowestPay') {
                jobs.sort((a, b) => (Number(a.salaryMin) || 0) - (Number(b.salaryMin) || 0));
            } else {
                // Default: Urgent jobs first, then newest
                jobs.sort((a, b) => {
                    const aUrgent = a.isUrgent ? 1 : 0;
                    const bUrgent = b.isUrgent ? 1 : 0;
                    if (aUrgent !== bUrgent) return bUrgent - aUrgent;
                    return (b.createdAtDate || 0) - (a.createdAtDate || 0);
                });
            }

            onUpdate(jobs);
        }, err => {
            console.error('Error fetching jobs:', err);
            if (onError) onError(err);
        });

        return this.unsubscribeJobs;
    },

    async getJobById(id) {
        try {
            const doc = await this.db.collection('jobs').doc(id).get();
            if (!doc.exists) return null;
            
            // Increment view count
            try {
                this.db.collection('jobs').doc(id).update({
                    viewCount: firebase.firestore.FieldValue.increment(1)
                });
            } catch (_) {}

            return { id: doc.id, ...doc.data() };
        } catch (err) {
            console.error('Error getting job:', err);
            return null;
        }
    },

    async createJob(jobData, employer) {
        try {
            const now = new Date();
            const expires = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000); // 30 days
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
                educationLevel: jobData.educationLevel || 'Tələb olunmur',
                experienceLevel: jobData.experienceLevel || 'Təcrübəsiz',
                allowCallIfAccepted: jobData.allowCallIfAccepted !== false,
                applicationMethod: 'in_app'
            };

            await this.db.collection('jobs').doc(docId).set(newJob);
            return { success: true, id: docId };
        } catch (err) {
            console.error('Error creating job:', err);
            return { success: false, error: err.message };
        }
    },

    async updateJob(jobId, jobData) {
        try {
            await this.db.collection('jobs').doc(jobId).update(jobData);
            return { success: true };
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

    async toggleJobActive(jobId, currentStatus) {
        try {
            await this.db.collection('jobs').doc(jobId).update({
                isActive: !currentStatus
            });
            return { success: true };
        } catch (err) {
            return { success: false, error: err.message };
        }
    },

    // Saved Jobs functionality
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
            console.error('Error fetching saved jobs:', err);
            return [];
        }
    }
};


