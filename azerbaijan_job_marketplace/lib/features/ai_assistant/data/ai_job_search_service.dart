import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:azerbaijan_job_marketplace/features/jobs/data/models/job_model.dart';

class AiJobSearchService {
  final _firestore = FirebaseFirestore.instance;

  /// İstifadəçinin profilinə uyğun iş elanlarını axtarır
  /// sortBy: 'relevance' (default), 'salary', 'date'
  Future<List<JobModel>> searchJobsForProfile(Map<String, dynamic>? profile, {String? query, int limit = 5, String sortBy = 'relevance', bool ignoreProfile = false}) async {
    try {
      final snapshot = await _firestore.collection('jobs').get();
      var jobs = snapshot.docs
          .map((d) => JobModel.fromMap(d.data(), d.id))
          .where((j) => j.isActive)
          .toList();

      if (jobs.isEmpty) return [];

      // Create a list of scored jobs
      List<Map<String, dynamic>> scoredJobs = [];

      final userSkills = (profile?['skills'] ?? '').toString().toLowerCase();
      final userCity = (profile?['city'] ?? '').toString().toLowerCase();
      final userExperience = (profile?['experience'] ?? '').toString().toLowerCase();
      final userEducation = (profile?['education'] ?? '').toString().toLowerCase();
      final userBio = (profile?['bio'] ?? '').toString().toLowerCase();

      for (var job in jobs) {
        if (ignoreProfile) {
          // ignoreProfile=true: Bütün işləri daxil et, süzgəcsiz
          int score = _calculateMatchScore(job, userSkills, userCity, userExperience, userEducation, userBio, query);
          scoredJobs.add({'job': job, 'score': score > 0 ? score : 1});
        } else {
          int score = _calculateMatchScore(job, userSkills, userCity, userExperience, userEducation, userBio, query);
          if (score > 0 || ((userSkills.isEmpty && userExperience.isEmpty && userBio.isEmpty) && query == null)) {
            scoredJobs.add({'job': job, 'score': score});
          }
        }
      }

      // If strict filter removed all jobs, return empty
      if (scoredJobs.isEmpty) return [];

      // Sort based on the requested criteria
      if (sortBy == 'salary') {
        // Sort by salary descending (highest first)
        scoredJobs.sort((a, b) {
          final jobA = a['job'] as JobModel;
          final jobB = b['job'] as JobModel;
          return jobB.salaryMin.compareTo(jobA.salaryMin);
        });
      } else if (sortBy == 'date') {
        // Sort by date descending (newest first)
        scoredJobs.sort((a, b) {
          final jobA = a['job'] as JobModel;
          final jobB = b['job'] as JobModel;
          return jobB.createdAt.compareTo(jobA.createdAt);
        });
      } else {
        // Default: sort by relevance score descending
        scoredJobs.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      }

      return scoredJobs.map((e) => e['job'] as JobModel).take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  int _calculateMatchScore(JobModel job, String userSkills, String userCity, String userExperience, String userEducation, String userBio, String? query) {
    int cityScore = 0;
    int keywordScore = 0;

    // City match
    if (userCity.isNotEmpty && job.city.toLowerCase().contains(userCity)) {
      cityScore += 30;
    }

    String allProfileText = "\$userSkills \$userExperience \$userEducation \$userBio".trim();

    // Profile text match (Skills, Bio, Experience)
    if (allProfileText.isNotEmpty) {
      final profileWords = allProfileText.replaceAll(',', ' ').replaceAll(';', ' ').split(RegExp(r'\s+'));
      for (final word in profileWords) {
        final w = word.trim();
        if (w.length > 2) { 
          if (job.title.toLowerCase().contains(w)) {
            keywordScore += 40;
          } else if (job.description.toLowerCase().contains(w)) {
            keywordScore += 20;
          }
        }
      }
    }

    // Query match (What the user explicitly asked AI for)
    bool hasQuery = false;
    if (query != null && query.isNotEmpty) {
      hasQuery = true;
      final queryWords = query.toLowerCase().split(RegExp(r'\s+'));
      for (final q in queryWords) {
        final qw = q.trim();
        if (qw.length > 2) {
          if (job.title.toLowerCase().contains(qw)) keywordScore += 50;
          if (job.description.toLowerCase().contains(qw)) keywordScore += 25;
        }
      }
    }

    // ƏN VACİB QAYDA: Əgər profil dolu və ya query varsa, amma keywordScore 0-dırsa
    // demək ki bu iş qətiyyən əlaqəli deyil (sadəcə şəhəri eyni ola bilər). Onu ləğv et!
    if ((allProfileText.isNotEmpty || hasQuery) && keywordScore == 0) {
      return 0; 
    }

    int bonusScore = 0;
    // Date bonus — newer jobs ranked higher
    final daysSinceCreated = DateTime.now().difference(job.createdAt).inDays;
    if (daysSinceCreated < 3) bonusScore += 15;
    else if (daysSinceCreated < 7) bonusScore += 10;
    else if (daysSinceCreated < 14) bonusScore += 5;

    // Urgent jobs get a boost
    if (job.isUrgent) bonusScore += 10;

    // Yekun xal (əgər keywordScore > 0 dursa və ya profil/query TAMAMİLƏ boşdursa keçərlidir)
    return (keywordScore > 0 || (allProfileText.isEmpty && !hasQuery)) 
        ? keywordScore + cityScore + bonusScore 
        : 0;
  }

  /// İş elanlarını AI-yə müxtəsər forma halında qaytarır
  String formatJobsForAi(List<JobModel> jobs) {
    if (jobs.isEmpty) return 'Heç bir uyğun elan tapılmadı.';

    final buffer = StringBuffer();
    for (int i = 0; i < jobs.length; i++) {
      final j = jobs[i];
      buffer.writeln('${i + 1}. ${j.title} — ${j.companyName}');
      buffer.writeln('   Maaş: ${j.salaryText}');
      buffer.writeln('   Şəhər: ${j.city}, ${j.district}');
      buffer.writeln('   Növ: ${j.jobType}');
      if (j.experienceLevel != null) buffer.writeln('   Təcrübə: ${j.experienceLevel}');
      if (j.educationLevel != null) buffer.writeln('   Təhsil: ${j.educationLevel}');
      buffer.writeln();
    }
    return buffer.toString();
  }
}
