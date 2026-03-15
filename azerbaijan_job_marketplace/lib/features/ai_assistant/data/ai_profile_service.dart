import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AiProfileService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// İstifadəçinin profil məlumatlarını oxuyur
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  /// AI-nin topladığı məlumatları profildə yeniləyir
  Future<bool> updateProfileFromAi(Map<String, dynamic> aiData) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      final Map<String, dynamic> updateData = {};

      if (aiData.containsKey('fullName') && aiData['fullName'] != null) {
        updateData['fullName'] = aiData['fullName'];
      }
      if (aiData.containsKey('bio') && aiData['bio'] != null) {
        updateData['bio'] = aiData['bio'];
      }
      if (aiData.containsKey('experience') && aiData['experience'] != null) {
        updateData['experience'] = aiData['experience'];
      }
      if (aiData.containsKey('education') && aiData['education'] != null) {
        updateData['education'] = aiData['education'];
      }
      if (aiData.containsKey('skills') && aiData['skills'] != null) {
        updateData['skills'] = aiData['skills'];
      }
      if (aiData.containsKey('gender') && aiData['gender'] != null) {
        updateData['gender'] = aiData['gender'];
      }
      if (aiData.containsKey('city') && aiData['city'] != null) {
        updateData['city'] = aiData['city'];
      }
      if (aiData.containsKey('birthDate') && aiData['birthDate'] != null) {
        try {
          final dateStr = aiData['birthDate'] as String;
          DateTime? date;
          // Try different date formats
          final formats = ['dd.MM.yyyy', 'yyyy-MM-dd', 'dd/MM/yyyy'];
          for (final fmt in formats) {
            try {
              date = DateFormat(fmt).parseStrict(dateStr);
              break;
            } catch (_) {}
          }
          if (date != null) {
            updateData['birthDate'] = Timestamp.fromDate(date);
          }
        } catch (_) {}
      }

      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updateData);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Profil məlumatlarını AI üçün hazır mətn formatına çevirir
  Future<String> getProfileSummary() async {
    final data = await getUserProfile();
    if (data == null) return 'Profil məlumatı tapılmadı.';

    final parts = <String>[];
    if (data['fullName'] != null) parts.add('Ad: ${data['fullName']}');
    if (data['bio'] != null) parts.add('Haqqında: ${data['bio']}');
    if (data['experience'] != null) parts.add('Təcrübə: ${data['experience']}');
    if (data['education'] != null) parts.add('Təhsil: ${data['education']}');
    if (data['skills'] != null) parts.add('Bacarıqlar: ${data['skills']}');
    if (data['gender'] != null) parts.add('Cinsiyyət: ${data['gender']}');
    if (data['city'] != null) parts.add('Şəhər: ${data['city']}');
    if (data['phone'] != null) parts.add('Telefon: ${data['phone']}');

    if (parts.isEmpty) return 'Profil boşdur, heç bir məlumat daxil edilməyib.';
    return parts.join('\n');
  }
}
