import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/job_categories.dart';
import '../../../jobs/presentation/pages/create_job_screen.dart';
import '../../../jobs/presentation/pages/job_detail_screen.dart';
import '../../../chat/presentation/pages/chat_list_screen.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import '../../../jobs/data/models/job_model.dart';
import '../../../../features/applications/data/repositories/applications_repository.dart';
import '../../../../features/applications/presentation/pages/applicants_list_screen.dart';
import '../../../../features/applications/presentation/pages/employer_applications_screen.dart';
import '../../../ai_assistant/presentation/ai_assistant_overlay.dart';
import '../../../onboarding/presentation/pages/app_onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmployerHome extends StatefulWidget {
  const EmployerHome({super.key});

  @override
  State<EmployerHome> createState() => _EmployerHomeState();
}

class _EmployerHomeState extends State<EmployerHome> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_onboarding_v2') ?? false;

    if (!hasSeen && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const AppOnboardingScreen(isEmployer: true),
          fullscreenDialog: true,
        ),
      );

      if (result == true && mounted) {
        setState(() {
          _currentIndex = 5; // Switch to Profile tab for Employer
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboard(),
      const CreateJobScreen(),
      _buildMyJobs(),
      const EmployerApplicationsScreen(),
      const ChatListScreen(),
      const ProfileScreen(isEmployerView: true),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.02, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: SizedBox(
          key: ValueKey<int>(_currentIndex),
          child: pages[_currentIndex],
        ),
      ),
      floatingActionButton: const AiAssistantFab(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: StreamBuilder<int>(
          stream: ChatRepository().getTotalUnreadCount(
            FirebaseAuth.instance.currentUser?.uid ?? '',
          ),
          builder: (context, unreadSnapshot) {
            final unreadCount = unreadSnapshot.data ?? 0;

            return StreamBuilder<int>(
              stream: ApplicationsRepository().getUnreadApplicationsCount(
                FirebaseAuth.instance.currentUser?.uid ?? '',
              ),
              builder: (context, appUnreadSnapshot) {
                final appUnreadCount = appUnreadSnapshot.data ?? 0;

                return BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: _currentIndex,
                  onTap: (i) {
                    if (i == 3) {
                      ApplicationsRepository().markAllApplicationsAsRead(
                        FirebaseAuth.instance.currentUser?.uid ?? '',
                      );
                    }
                    setState(() => _currentIndex = i);
                  },
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard_rounded),
                      label: 'Panel',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.add_circle_outline_rounded),
                      activeIcon: Icon(Icons.add_circle_rounded),
                      label: 'Elan Ver',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.list_alt_rounded),
                      label: 'Elanlarım',
                    ),
                    BottomNavigationBarItem(
                      icon: Badge(
                        isLabelVisible: appUnreadCount > 0,
                        label: Text(
                          '$appUnreadCount',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                        child: const Icon(Icons.inbox_outlined),
                      ),
                      activeIcon: Badge(
                        isLabelVisible: appUnreadCount > 0,
                        label: Text(
                          '$appUnreadCount',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                        child: const Icon(Icons.inbox_rounded),
                      ),
                      label: 'Müraciətlər',
                    ),
                    BottomNavigationBarItem(
                      icon: Badge(
                        isLabelVisible: unreadCount > 0,
                        label: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded),
                      ),
                      activeIcon: Badge(
                        isLabelVisible: unreadCount > 0,
                        label: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                        child: const Icon(Icons.chat_bubble_rounded),
                      ),
                      label: 'Mesajlar',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline_rounded),
                      activeIcon: Icon(Icons.person_rounded),
                      label: 'Profil',
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final stream = FirebaseFirestore.instance
        .collection('jobs')
        .where('employerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final myJobs = snapshot.data!.docs
            .where((d) => d.data() != null) // Silinen ilanları filtrele
            .map(
              (d) => JobModel.fromMap(d.data() as Map<String, dynamic>, d.id),
            )
            .toList();
        myJobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final recentJobs = myJobs.take(4).toList();

        int totalViews = myJobs.fold(0, (sum, job) => sum + job.viewCount);
        int totalApps = myJobs.fold(
          0,
          (sum, job) => sum + job.applicationCount,
        );

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Salam! 👋',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'İşverən paneli',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimaryColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.description_rounded,
                        title: 'Aktiv elanlar',
                        value: '${myJobs.length}',
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people_rounded,
                        title: 'Müraciətlər',
                        value: '$totalApps',
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.visibility_rounded,
                        title: 'Baxış sayı',
                        value: '$totalViews',
                        color: AppTheme.infoColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StreamBuilder<int>(
                        stream: ChatRepository().getTotalUnreadCount(
                          FirebaseAuth.instance.currentUser?.uid ?? '',
                        ),
                        builder: (context, msgSnapshot) {
                          final msgCount = msgSnapshot.data ?? 0;
                          return _StatCard(
                            icon: Icons.chat_rounded,
                            title: 'Mesajlar',
                            value: '$msgCount',
                            color: AppTheme.accentColor,
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Quick Add Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _currentIndex = 1),
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text(
                      'Yeni elan ver',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Recent Jobs
                Text(
                  'Son elanlarım',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                if (recentJobs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Center(
                      child: Text(
                        'Heç bir elanınız yoxdur',
                        style: TextStyle(color: context.textHintColor),
                      ),
                    ),
                  ),
                ...recentJobs.map((job) {
                  final cat = JobCategories.getById(job.categoryId);
                  final nowUtc = DateTime.now().toUtc();
                  final urgentUntilUtc = job.urgentUntil?.toUtc();
                  final isUrgentActive =
                      job.isUrgent &&
                      urgentUntilUtc != null &&
                      urgentUntilUtc.isAfter(nowUtc);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUrgentActive
                            ? AppTheme.accentColor.withValues(alpha: 0.3)
                            : context.dividerColor,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 22),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              job.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (isUrgentActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Təcili',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '${job.applicationCount} müraciət · ${job.viewCount} baxış',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textHintColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: context.textHintColor,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                JobDetailScreen(job: job, isEmployerView: true),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyJobs() {
    final stream = FirebaseFirestore.instance
        .collection('jobs')
        .where('employerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final jobs = snapshot.data!.docs
            .where((d) => d.data() != null) // Silinen ilanları filtrele
            .map(
              (d) => JobModel.fromMap(d.data() as Map<String, dynamic>, d.id),
            )
            .toList();
        jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Text(
                  'Elanlarım',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    final cat = JobCategories.getById(job.categoryId);
                    final nowUtc = DateTime.now().toUtc();
                    final urgentUntilUtc = job.urgentUntil?.toUtc();
                    final isUrgentActive =
                        job.isUrgent &&
                        urgentUntilUtc != null &&
                        urgentUntilUtc.isAfter(nowUtc);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isUrgentActive
                              ? AppTheme.accentColor.withValues(alpha: 0.3)
                              : context.dividerColor,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 22),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                job.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (isUrgentActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Təcili',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: job.isActive
                                    ? AppTheme.successColor.withValues(
                                        alpha: 0.1,
                                      )
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                job.isActive ? 'Aktiv' : 'Deaktiv',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: job.isActive
                                      ? AppTheme.successColor
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              job.timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textHintColor,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: context.textHintColor,
                          ),
                          onSelected: (value) {
                            if (value == 'delete') {
                              FirebaseFirestore.instance
                                  .collection('jobs')
                                  .doc(job.id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Elan silindi')),
                              );
                            } else if (value == 'edit') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Redaktə səhifəsi tezliklə!'),
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Redaktə et'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_rounded,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Sil',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ApplicantsListScreen(job: job),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}
