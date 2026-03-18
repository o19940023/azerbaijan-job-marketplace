import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/job_model.dart';
import '../widgets/job_list_card.dart';
import 'job_detail_screen.dart';

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;

  Future<List<JobModel>> _fetchSavedJobs(List<String> ids) async {
    if (ids.isEmpty) return [];
    List<JobModel> jobs = [];
    for (int i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, (i + 10 > ids.length) ? ids.length : i + 10);
      final querySnapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      jobs.addAll(querySnapshot.docs
          .where((d) => d.data() != null)
          .map((d) => JobModel.fromMap(d.data(), d.id)));
    }
    return jobs;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: Text('Daxil olmalısınız'));
    }

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Seçilmiş İşlər',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: context.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return const Center(child: Text('Xəta baş verdi'));
          }
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
          final savedJobsIds = List<String>.from(userData?['savedJobs'] ?? []);

          if (savedJobsIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border_rounded,
                      size: 64, color: context.textHintColor),
                  const SizedBox(height: 16),
                  Text(
                    'Hələ seçilmiş iş yoxdur',
                    style: TextStyle(
                      fontSize: 16,
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<List<JobModel>>(
            future: _fetchSavedJobs(savedJobsIds),
            builder: (context, jobsSnapshot) {
              if (jobsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (jobsSnapshot.hasError) {
                return const Center(child: Text('Xəta baş verdi'));
              }

              final jobs = jobsSnapshot.data ?? [];
              if (jobs.isEmpty) {
                return Center(
                  child: Text(
                    'İşlər tapılmadı',
                    style: TextStyle(color: context.textSecondaryColor),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return JobListCard(
                    job: job,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobDetailScreen(
                            job: job,
                            isEmployerView: false,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
