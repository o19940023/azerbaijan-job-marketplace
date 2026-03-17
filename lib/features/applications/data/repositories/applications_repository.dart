import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/application_model.dart';
import '../../../jobs/data/models/job_model.dart';

class ApplicationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // İş başvurusu oluştur
  Future<void> submitApplication({
    required String jobId,
    required String employerId,
    required String applicantId,
  }) async {
    final newAppRef = _firestore.collection('applications').doc();

    final application = ApplicationModel(
      id: newAppRef.id,
      jobId: jobId,
      employerId: employerId,
      applicantId: applicantId,
      status: 'pending',
      appliedAt: DateTime.now(),
    );

    // Başvuruyu kaydet (Sadece müraciəti qeyd edirik)
    await _firestore.collection('applications').doc(newAppRef.id).set(application.toMap());
    
    // Elanın müraciət sayını artırırıq
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'applicationCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Warning: Could not increment application count: $e');
      // İcazə xətası olsa belə müraciət tamamlanmış sayılır
    }
  }

  // İş arayanın yaptığı başvuruları getir
  Stream<List<ApplicationModel>> getApplicantApplications(String applicantId) {
    return _firestore
        .collection('applications')
        .where('applicantId', isEqualTo: applicantId)
        .snapshots()
        .map((snapshot) {
          final apps = snapshot.docs
              .map((doc) => ApplicationModel.fromMap(doc.data(), doc.id))
              .toList();
          apps.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
          return apps;
        });
  }

  // İşverenin elanına gelen başvuruları getir
  Stream<List<ApplicationModel>> getJobApplications(String jobId) {
    return _firestore
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map((snapshot) {
          final apps = snapshot.docs
              .map((doc) => ApplicationModel.fromMap(doc.data(), doc.id))
              .toList();
          apps.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
          return apps;
        });
  }

  // İşverenin tüm elanlarına gelen başvuruları getir (Genel Müraciətlər sekmesi üçün)
  Stream<List<ApplicationModel>> getEmployerApplications(String employerId) {
    return _firestore
        .collection('applications')
        .where('employerId', isEqualTo: employerId)
        .snapshots()
        .map((snapshot) {
          final apps = snapshot.docs
              .map((doc) => ApplicationModel.fromMap(doc.data(), doc.id))
              .toList();
          apps.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
          return apps;
        });
  }

  // İşverenin okunmamış başvuru sayısını getir
  Stream<int> getUnreadApplicationsCount(String employerId) {
    return _firestore
        .collection('applications')
        .where('employerId', isEqualTo: employerId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Tüm başvuruları okundu olarak işaretle (Müraciətlər ekranına girildiyinde)
  Future<void> markAllApplicationsAsRead(String employerId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('applications')
        .where('employerId', isEqualTo: employerId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Başvuru durumunu güncelle
  Future<void> updateApplicationStatus(String applicationId, String status) async {
    try {
      // Sadece status sahasını yeniləyirik, ən sadə şəkildə
      await _firestore.collection('applications').doc(applicationId).update({
        'status': status,
      });
    } catch (e) {
      print('Error updating application status: $e');
      rethrow;
    }
  }

  // İş arayanın bu elana daha önce başvurup başvurmadığını kontrol et
  Future<bool> hasAppliedToJob(String applicantId, String jobId) async {
    final querySnapshot = await _firestore
        .collection('applications')
        .where('applicantId', isEqualTo: applicantId)
        .where('jobId', isEqualTo: jobId)
        .limit(1)
        .get();
        
    return querySnapshot.docs.isNotEmpty;
  }
}
