import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationModel {
  final String id;
  final String jobId;
  final String employerId;
  final String applicantId;
  final String status; // pending, accepted, rejected
  final bool isRead; // okunup okunmadığı
  final DateTime appliedAt;

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.employerId,
    required this.applicantId,
    required this.status,
    this.isRead = false,
    required this.appliedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobId': jobId,
      'employerId': employerId,
      'applicantId': applicantId,
      'status': status,
      'isRead': isRead,
      'appliedAt': Timestamp.fromDate(appliedAt),
    };
  }

  factory ApplicationModel.fromMap(Map<String, dynamic> map, String id) {
    return ApplicationModel(
      id: id,
      jobId: map['jobId'] ?? '',
      employerId: map['employerId'] ?? '',
      applicantId: map['applicantId'] ?? '',
      status: map['status'] ?? 'pending',
      isRead: map['isRead'] ?? false,
      appliedAt: (map['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
