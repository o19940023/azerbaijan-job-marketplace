/**
 * İş Tap AI — Chat Module
 * Realtime Chat & Messaging System
 * Optimized for Firestore single-field queries without composite index requirements
 */

export const ChatModule = {
    db: null,
    unsubscribeChats: null,
    unsubscribeMessages: null,

    init(db) {
        this.db = db;
    },

    // Listen to all chats for a user
    listenToChats(userId, onUpdate) {
        if (this.unsubscribeChats) {
            this.unsubscribeChats();
        }

        const query = this.db.collection('chats')
            .where('participantIds', 'array-contains', userId);

        this.unsubscribeChats = query.onSnapshot(snapshot => {
            let chats = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));

            // Sort by lastMessageTime descending
            chats.sort((a, b) => {
                const timeA = a.lastMessageTime ? new Date(a.lastMessageTime) : new Date(0);
                const timeB = b.lastMessageTime ? new Date(b.lastMessageTime) : new Date(0);
                return timeB - timeA;
            });

            onUpdate(chats);
        }, err => {
            console.error('Error listening to chats:', err);
        });

        return this.unsubscribeChats;
    },

    // Get or create chat session
    async getOrCreateChat({ employerId, employerName, jobSeekerId, jobSeekerName, jobId, jobTitle }) {
        try {
            // Check if chat already exists (in-memory check to prevent composite index requirement)
            const snapshot = await this.db.collection('chats')
                .where('participantIds', 'array-contains', employerId)
                .get();

            const existingDoc = snapshot.docs.find(doc => {
                const data = doc.data();
                return data.jobSeekerId === jobSeekerId && data.jobId === jobId;
            });

            if (existingDoc) {
                return { success: true, chatId: existingDoc.id, chat: { id: existingDoc.id, ...existingDoc.data() } };
            }

            // Create new chat
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
            console.error('Get or create chat error:', err);
            return { success: false, error: err.message };
        }
    },

    // Listen to messages in a specific chat
    listenToMessages(chatId, onUpdate) {
        if (this.unsubscribeMessages) {
            this.unsubscribeMessages();
        }

        const query = this.db.collection('chats').doc(chatId)
            .collection('messages');

        this.unsubscribeMessages = query.onSnapshot(snapshot => {
            let messages = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));

            // Sort in memory by createdAt
            messages.sort((a, b) => {
                const timeA = a.createdAt ? new Date(a.createdAt) : new Date(0);
                const timeB = b.createdAt ? new Date(b.createdAt) : new Date(0);
                return timeA - timeB;
            });

            onUpdate(messages);
        }, err => {
            console.error('Error listening to messages:', err);
        });

        return this.unsubscribeMessages;
    },

    // Send a message
    async sendMessage(chatId, senderId, text) {
        if (!text || !text.trim()) return { success: false };

        try {
            const now = new Date().toISOString();
            const messageData = {
                senderId,
                text: text.trim(),
                createdAt: now
            };

            // Add message to subcollection
            await this.db.collection('chats').doc(chatId)
                .collection('messages')
                .add(messageData);

            // Update last message in parent chat document
            await this.db.collection('chats').doc(chatId).update({
                lastMessage: text.trim(),
                lastMessageTime: now,
                lastSenderId: senderId
            });

            return { success: true };
        } catch (err) {
            console.error('Send message error:', err);
            return { success: false, error: err.message };
        }
    },

    // Submit report for job or user
    async submitReport({ reporterId, targetId, targetType, reason, details }) {
        try {
            await this.db.collection('reports').add({
                reporterId,
                targetId,
                targetType, // 'job' or 'user'
                reason,
                details: details || '',
                createdAt: new Date().toISOString(),
                status: 'pending'
            });
            return { success: true };
        } catch (err) {
            return { success: false, error: err.message };
        }
    }
};
