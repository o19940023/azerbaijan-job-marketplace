import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sends a message to a specific chat room
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    
    final message = MessageModel(
      id: messageRef.id,
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
    );

    // Get chat to find the recipient
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final chatData = chatDoc.data();
    String? recipientId;
    if (chatData != null) {
      final participants = List<String>.from(chatData['participantIds'] ?? []);
      recipientId = participants.firstWhere((id) => id != senderId, orElse: () => '');
    }

    // Run in transaction to update message, lastMessage, and unread count
    await _firestore.runTransaction((transaction) async {
      transaction.set(messageRef, message.toMap());
      
      final chatRef = _firestore.collection('chats').doc(chatId);
      final updateData = <String, dynamic>{
        'lastMessage': text,
        'lastSenderId': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Qarşı tərəfin oxunmamış sayını artır
      if (recipientId != null && recipientId.isNotEmpty) {
        updateData['unreadCount_$recipientId'] = FieldValue.increment(1);
      }
      
      transaction.update(chatRef, updateData);
    });
  }

  // Mesajları oxunmuş kimi işarələ
  Future<void> markAsRead(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount_$userId': 0,
    });
  }

  // Bütün çatlardakı oxunmamış mesaj sayını dinlə
  Stream<int> getTotalUnreadCount(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data['unreadCount_$userId'] as num?)?.toInt() ?? 0;
      }
      return total;
    });
  }

  // Get or Create a Chat session between Employer and Job Seeker
  Future<String> createOrGetChat({
    required String employerId,
    required String jobSeekerId,
    required String jobId,
    required String jobTitle,
    required String employerName,
    required String jobSeekerName,
  }) async {
    // Check if chat already exists for this exact pair and job
    final querySnapshot = await _firestore
        .collection('chats')
        .where('jobId', isEqualTo: jobId)
        .where('participantIds', arrayContains: employerId)
        .get();

    // Filter locally to ensure it truly matches both participants
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final participants = List<String>.from(data['participantIds'] ?? []);
      if (participants.contains(jobSeekerId)) {
        return doc.id; // Existing chat room
      }
    }

    // Create a new chat room
    final newChatRef = _firestore.collection('chats').doc();
    final newChat = ChatModel(
      id: newChatRef.id,
      participantIds: [employerId, jobSeekerId],
      jobId: jobId,
      jobTitle: jobTitle,
      employerId: employerId,
      jobSeekerId: jobSeekerId,
      employerName: employerName,
      jobSeekerName: jobSeekerName,
      lastMessage: '',
      updatedAt: DateTime.now(),
    );

    await newChatRef.set(newChat.toMap());
    return newChatRef.id;
  }

  // Listen to User Chats
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort locally to avoid needing a composite indexing
      chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return chats;
    });
  }

  // Listen to specific Chat Messages
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Delete a specific message
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // Delete/hide an entire chat for the current user
  Future<void> hideChat(String chatId, String currentUserId) async {
    // To properly "hide" a chat for one user without deleting it for the other,
    // we remove the currentUser's ID from the participantIds array.
    await _firestore.collection('chats').doc(chatId).update({
      'participantIds': FieldValue.arrayRemove([currentUserId]),
    });
  }

  // Block user
  Future<void> toggleBlockUser(String currentUserId, String targetUserId, bool isBlocking) async {
    final userRef = _firestore.collection('users').doc(currentUserId);
    if (isBlocking) {
      await userRef.update({
        'blockedUsers': FieldValue.arrayUnion([targetUserId])
      });
    } else {
      await userRef.update({
        'blockedUsers': FieldValue.arrayRemove([targetUserId])
      });
    }
  }

  // Report user or content
  Future<void> submitReport({
    required String reporterId,
    required String targetId,
    required String targetType,
    required String reason,
    String? additionalDetails,
  }) async {
    await _firestore.collection('reports').add({
      'reporterId': reporterId,
      'targetId': targetId,
      'targetType': targetType,
      'reason': reason,
      'details': additionalDetails ?? '',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
