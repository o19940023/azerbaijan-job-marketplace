import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participantIds;
  final String jobId;
  final String jobTitle;
  final String jobSeekerName;
  final String employerName;
  final String employerId;
  final String jobSeekerId;
  final String lastMessage;
  final String lastSenderId;
  final DateTime updatedAt;
  final Map<String, int> unreadCounts;

  ChatModel({
    required this.id,
    required this.participantIds,
    required this.jobId,
    required this.jobTitle,
    required this.jobSeekerName,
    required this.employerName,
    required this.employerId,
    required this.jobSeekerId,
    required this.lastMessage,
    this.lastSenderId = '',
    required this.updatedAt,
    this.unreadCounts = const {},
  });

  int getUnreadCount(String userId) {
    return unreadCounts['unreadCount_$userId'] ?? 0;
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    // Extract unread counts from the map
    final unreadCounts = <String, int>{};
    map.forEach((key, value) {
      if (key.startsWith('unreadCount_') && value is num) {
        unreadCounts[key] = value.toInt();
      }
    });

    return ChatModel(
      id: id,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      jobId: map['jobId'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      jobSeekerName: map['jobSeekerName'] ?? '',
      employerName: map['employerName'] ?? '',
      employerId: map['employerId'] ?? '',
      jobSeekerId: map['jobSeekerId'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastSenderId: map['lastSenderId'] ?? '',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCounts: unreadCounts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'jobSeekerName': jobSeekerName,
      'employerName': employerName,
      'employerId': employerId,
      'jobSeekerId': jobSeekerId,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
