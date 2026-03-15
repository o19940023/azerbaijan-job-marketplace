import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../data/models/application_model.dart';
import '../../data/repositories/applications_repository.dart';
import 'applicant_profile_screen.dart';

class EmployerApplicationsScreen extends StatelessWidget {
  const EmployerApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Giriş edilməyib'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ümumi Müraciətlər'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ApplicationModel>>(
        stream: ApplicationsRepository().getEmployerApplications(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final applications = snapshot.data ?? [];

          if (applications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 80,
                    color: context.textHintColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Heç bir müraciət tapılmadı',
                    style: TextStyle(
                      fontSize: 16,
                      color: context.textHintColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: applications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final app = applications[index];

              if (app.applicantId.isEmpty || app.jobId.isEmpty) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<List<DocumentSnapshot>>(
                future: Future.wait([
                  FirebaseFirestore.instance.collection('users').doc(app.applicantId).get(),
                  FirebaseFirestore.instance.collection('jobs').doc(app.jobId).get(),
                ]),
                builder: (ctx, futuresSnapshot) {
                  if (!futuresSnapshot.hasData) return const SizedBox.shrink();

                  final userDoc = futuresSnapshot.data![0];
                  final jobDoc = futuresSnapshot.data![1];

                  final userData = userDoc.data() as Map<String, dynamic>?;
                  final jobData = jobDoc.data() as Map<String, dynamic>?;

                  if (userData == null || jobData == null) return const SizedBox.shrink();

                  final applicantName = userData['fullName'] ?? 'Bilinməyən Aday';
                  final applicantPhone = userData['phone'] ?? '';
                  final jobTitle = jobData['title'] ?? 'Silinmiş Elan';

                  Color statusColor = AppTheme.warningColor;
                  String statusText = 'Gözləmədə';

                  if (app.status == 'accepted') {
                    statusColor = AppTheme.successColor;
                    statusText = 'Qəbul edildi';
                  } else if (app.status == 'rejected') {
                    statusColor = AppTheme.errorColor;
                    statusText = 'Rədd edildi';
                  }

                  return InkWell(
                    onTap: () {
                      _showApplicationOptions(context, app, applicantName, userData);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.dividerColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            backgroundImage: userData['photoUrl'] != null && (userData['photoUrl'] as String).isNotEmpty
                                ? NetworkImage(userData['photoUrl'] as String)
                                : null,
                            child: userData['photoUrl'] == null || (userData['photoUrl'] as String).isEmpty
                                ? Text(
                                    applicantName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  applicantName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Elan: $jobTitle',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.textSecondaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tarix: ${DateFormat('dd MMM yyyy, HH:mm').format(app.appliedAt)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textHintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (app.status == 'accepted') ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (applicantPhone.isNotEmpty)
                                      InkWell(
                                        onTap: () async {
                                          final Uri url = Uri(scheme: 'tel', path: applicantPhone.replaceAll(' ', ''));
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url);
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Zəng etmək mümkün deyil')),
                                              );
                                            }
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.successColor,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.phone, size: 14, color: Colors.white),
                                              SizedBox(width: 4),
                                              Text('Zəng et', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () async {
                                        final currentUser = FirebaseAuth.instance.currentUser;
                                        if (currentUser == null) return;
                                        final chatRepo = ChatRepository();
                                        final employerDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
                                        final employerName = (employerDoc.data()?['fullName'] ?? 'İşverən') as String;
                                        final chatId = await chatRepo.createOrGetChat(
                                          employerId: currentUser.uid,
                                          employerName: employerName,
                                          jobSeekerId: app.applicantId,
                                          jobSeekerName: applicantName,
                                          jobId: app.jobId,
                                          jobTitle: jobTitle,
                                        );
                                        if (context.mounted) {
                                          Navigator.pushNamed(context, AppRouter.chatDetail, arguments: {
                                            'chatId': chatId,
                                            'name': applicantName,
                                            'otherUserId': app.applicantId,
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.chat_bubble_rounded, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showApplicationOptions(BuildContext context, ApplicationModel app, String applicantName, Map<String, dynamic> userData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$applicantName üçün Əməliyyatlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryColor),
                  title: const Text('Profilinə bax'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ApplicantProfileScreen(userData: userData),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.successColor),
                  title: const Text('Qəbul et'),
                  onTap: () async {
                    Navigator.pop(context);
                    await ApplicationsRepository().updateApplicationStatus(app.id, 'accepted');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status yeniləndi: Qəbul edildi')));
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel_outlined, color: AppTheme.errorColor),
                  title: const Text('Rədd et'),
                  onTap: () async {
                    Navigator.pop(context);
                    await ApplicationsRepository().updateApplicationStatus(app.id, 'rejected');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status yeniləndi: Rədd edildi')));
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
