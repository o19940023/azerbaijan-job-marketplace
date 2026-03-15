import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/application_model.dart';
import '../../data/repositories/applications_repository.dart';
import '../../../jobs/data/models/job_model.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../chat/presentation/pages/chat_detail_screen.dart';
import 'applicant_profile_screen.dart';

class ApplicantsListScreen extends StatelessWidget {
  final JobModel job;

  const ApplicantsListScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müraciətlər'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              job.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.textPrimaryColor,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ApplicationModel>>(
              stream: ApplicationsRepository().getJobApplications(job.id),
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
                          Icons.people_outline_rounded,
                          size: 80,
                          color: context.textHintColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hələ müraciət yoxdur',
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: applications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final app = applications[index];
                    if (app.applicantId.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(app.applicantId).get(),
                      builder: (ctx, userSnapshot) {
                        if (!userSnapshot.hasData) return const SizedBox.shrink();

                        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                        if (userData == null) return const SizedBox.shrink();

                        final applicantName = userData['fullName'] ?? 'Bilinməyən Aday';
                        final applicantCity = userData['city'] ?? 'Şəhər qeyd olunmayıb';
                        final applicantPhone = userData['phone'] ?? '';

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
                                  child: Text(
                                    applicantName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
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
                                         applicantCity,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: context.textSecondaryColor,
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
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (applicantPhone.isNotEmpty) ...[
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
                                            const SizedBox(width: 8),
                                          ],
                                          InkWell(
                                            onTap: () async {
                                              try {
                                                final currentEmployerId = FirebaseAuth.instance.currentUser?.uid;
                                                if (currentEmployerId == null) throw Exception('Təsdiqlənmədi');

                                                final employerDoc = await FirebaseFirestore.instance.collection('users').doc(currentEmployerId).get();
                                                final employerName = employerDoc.data()?['fullName'] ?? 'İşəgötürən';

                                                final chatId = await ChatRepository().createOrGetChat(
                                                  employerId: currentEmployerId,
                                                  jobSeekerId: app.applicantId,
                                                  jobId: app.jobId,
                                                  jobTitle: job.title,
                                                  employerName: employerName,
                                                  jobSeekerName: applicantName,
                                                );

                                                if (context.mounted) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => ChatDetailScreen(
                                                        chatId: chatId,
                                                        otherUserName: applicantName,
                                                        otherUserId: app.applicantId,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Xəta baş verdi: $e')),
                                                  );
                                                }
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.white),
                                                ],
                                              ),
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
          ),
        ],
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
                if (app.status == 'accepted')
                  ListTile(
                    leading: const Icon(Icons.message_rounded, color: AppTheme.primaryColor),
                    title: const Text('Mesaj yaz'),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        // Show loading indicator or block UI briefly
                        final currentEmployerId = FirebaseAuth.instance.currentUser?.uid;
                        if (currentEmployerId == null) throw Exception('Təsdiqlənmədi');
                        
                        final employerDoc = await FirebaseFirestore.instance.collection('users').doc(currentEmployerId).get();
                        final employerName = employerDoc.data()?['fullName'] ?? 'İşəgötürən';

                        final chatId = await ChatRepository().createOrGetChat(
                          employerId: currentEmployerId,
                          jobSeekerId: app.applicantId,
                          jobId: app.jobId,
                          jobTitle: job.title,
                          employerName: employerName,
                          jobSeekerName: applicantName,
                        );
                        
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                chatId: chatId,
                                otherUserName: applicantName,
                                otherUserId: app.applicantId,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Mesajlaşma yaradıla bilmədi: $e')),
                          );
                        }
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
