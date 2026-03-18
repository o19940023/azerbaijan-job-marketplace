class JobModel {
  final String id;
  final String title;
  final String companyName;
  final String? companyLogo;
  final String categoryId;
  final String description;
  final double salaryMin;
  final double? salaryMax;
  final String salaryPeriod; // 'aylıq', 'günlük', 'saatlıq'
  final String jobType; // fullTime, partTime, daily, hourly, freelance, urgent
  final String city;
  final String district;
  final String? address;
  final double latitude;
  final double longitude;
  final double? distance; // km cinsinden
  final String? workingHours;
  final List<String> requirements;
  final List<String> benefits;
  final String contactPhone;
  final String employerId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUrgent;
  final DateTime? urgentUntil;
  final bool isActive;
  final int viewCount;
  final int applicationCount;
  final String? educationLevel;
  final String? experienceLevel;
  final bool allowCallIfAccepted;
  final String applicationMethod; // 'in_app' or 'redirect'
  final String? externalUrl;
  final int? matchPercentage; // AI tarafından hesaplanan eşleşme yüzdesi (0-100)

  const JobModel({
    required this.id,
    required this.title,
    required this.companyName,
    this.companyLogo,
    required this.categoryId,
    required this.description,
    required this.salaryMin,
    this.salaryMax,
    required this.salaryPeriod,
    required this.jobType,
    required this.city,
    required this.district,
    this.address,
    required this.latitude,
    required this.longitude,
    this.distance,
    this.workingHours,
    this.requirements = const [],
    this.benefits = const [],
    required this.contactPhone,
    required this.employerId,
    required this.createdAt,
    required this.expiresAt,
    this.isUrgent = false,
    this.urgentUntil,
    this.isActive = true,
    this.viewCount = 0,
    this.applicationCount = 0,
    this.educationLevel,
    this.experienceLevel,
    this.allowCallIfAccepted = true,
    this.applicationMethod = 'in_app',
    this.externalUrl,
    this.matchPercentage,
  });

  String get salaryText {
    if (salaryMax != null && salaryMax! > salaryMin) {
      return '${salaryMin.toInt()}-${salaryMax!.toInt()} ₼ / $salaryPeriod';
    }
    return '${salaryMin.toInt()} ₼ / $salaryPeriod';
  }

  String get locationText => '$district, $city';

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} dəq əvvəl';
    if (diff.inHours < 24) return '${diff.inHours} saat əvvəl';
    if (diff.inDays < 7) return '${diff.inDays} gün əvvəl';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} həftə əvvəl';
    return '${(diff.inDays / 30).floor()} ay əvvəl';
  }

  String get distanceText {
    if (distance == null) return '';
    if (distance! < 1) return '${(distance! * 1000).toInt()} m';
    return '${distance!.toStringAsFixed(1)} km';
  }

  JobModel copyWith({
    String? id,
    String? title,
    String? companyName,
    String? companyLogo,
    String? categoryId,
    String? description,
    double? salaryMin,
    double? salaryMax,
    String? salaryPeriod,
    String? jobType,
    String? city,
    String? district,
    String? address,
    double? latitude,
    double? longitude,
    double? distance,
    String? workingHours,
    List<String>? requirements,
    List<String>? benefits,
    String? contactPhone,
    String? employerId,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isUrgent,
    DateTime? urgentUntil,
    bool? isActive,
    int? viewCount,
    int? applicationCount,
    String? educationLevel,
    String? experienceLevel,
    bool? allowCallIfAccepted,
    String? applicationMethod,
    String? externalUrl,
    int? matchPercentage,
  }) {
    return JobModel(
      id: id ?? this.id,
      title: title ?? this.title,
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      salaryPeriod: salaryPeriod ?? this.salaryPeriod,
      jobType: jobType ?? this.jobType,
      city: city ?? this.city,
      district: district ?? this.district,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      workingHours: workingHours ?? this.workingHours,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      contactPhone: contactPhone ?? this.contactPhone,
      employerId: employerId ?? this.employerId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isUrgent: isUrgent ?? this.isUrgent,
      urgentUntil: urgentUntil ?? this.urgentUntil,
      isActive: isActive ?? this.isActive,
      applicationCount: applicationCount ?? this.applicationCount,
      educationLevel: educationLevel ?? this.educationLevel,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      allowCallIfAccepted: allowCallIfAccepted ?? this.allowCallIfAccepted,
      applicationMethod: applicationMethod ?? this.applicationMethod,
      externalUrl: externalUrl ?? this.externalUrl,
      matchPercentage: matchPercentage ?? this.matchPercentage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'categoryId': categoryId,
      'description': description,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryPeriod': salaryPeriod,
      'jobType': jobType,
      'city': city,
      'district': district,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'workingHours': workingHours,
      'requirements': requirements,
      'benefits': benefits,
      'contactPhone': contactPhone,
      'employerId': employerId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isUrgent': isUrgent,
      'urgentUntil': urgentUntil?.toUtc().toIso8601String(),
      'isActive': isActive,
      'viewCount': viewCount,
      'applicationCount': applicationCount,
      'educationLevel': educationLevel,
      'experienceLevel': experienceLevel,
      'allowCallIfAccepted': allowCallIfAccepted,
      'applicationMethod': applicationMethod,
      'externalUrl': externalUrl,
    };
  }

  factory JobModel.fromMap(Map<String, dynamic> map, String docId) {
    return JobModel(
      id: docId,
      title: map['title'] ?? '',
      companyName: map['companyName'] ?? '',
      companyLogo: map['companyLogo'],
      categoryId: map['categoryId'] ?? '',
      description: map['description'] ?? '',
      salaryMin: (map['salaryMin'] ?? 0).toDouble(),
      salaryMax: map['salaryMax']?.toDouble(),
      salaryPeriod: map['salaryPeriod'] ?? '',
      jobType: map['jobType'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      address: map['address'],
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      distance: map['distance']?.toDouble(),
      workingHours: map['workingHours'],
      requirements: List<String>.from(map['requirements'] ?? []),
      benefits: List<String>.from(map['benefits'] ?? []),
      contactPhone: map['contactPhone'] ?? '',
      employerId: map['employerId'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      expiresAt: map['expiresAt'] != null ? DateTime.parse(map['expiresAt']) : DateTime.now(),
      isUrgent: map['isUrgent'] ?? false,
      urgentUntil: map['urgentUntil'] != null ? DateTime.tryParse(map['urgentUntil'].toString()) : null,
      isActive: map['isActive'] ?? true,
      viewCount: map['viewCount']?.toInt() ?? 0,
      applicationCount: map['applicationCount']?.toInt() ?? 0,
      educationLevel: map['educationLevel'],
      experienceLevel: map['experienceLevel'],
      allowCallIfAccepted: map['allowCallIfAccepted'] ?? true,
      applicationMethod: map['applicationMethod'] ?? 'in_app',
      externalUrl: map['externalUrl'],
    );
  }
}

class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String userType; // 'job_seeker' or 'employer'
  final String? city;
  final String? district;

  // Job Seeker specific
  final String? experience;
  final String? education;
  final String? skills;
  final String? bio;

  // Employer specific
  final String? companyName;
  final String? companyAddress;
  final String? companyDescription;
  final String? sector;

  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.avatarUrl,
    required this.userType,
    this.city,
    this.district,
    this.experience,
    this.education,
    this.skills,
    this.bio,
    this.companyName,
    this.companyAddress,
    this.companyDescription,
    this.sector,
    required this.createdAt,
  });

  bool get isJobSeeker => userType == 'job_seeker';
  bool get isEmployer => userType == 'employer';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'avatarUrl': avatarUrl,
      'userType': userType,
      'city': city,
      'district': district,
      'experience': experience,
      'education': education,
      'skills': skills,
      'bio': bio,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyDescription': companyDescription,
      'sector': sector,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      avatarUrl: map['avatarUrl'],
      userType: map['userType'] ?? '',
      city: map['city'],
      district: map['district'],
      experience: map['experience'],
      education: map['education'],
      skills: map['skills'],
      bio: map['bio'],
      companyName: map['companyName'],
      companyAddress: map['companyAddress'],
      companyDescription: map['companyDescription'],
      sector: map['sector'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
