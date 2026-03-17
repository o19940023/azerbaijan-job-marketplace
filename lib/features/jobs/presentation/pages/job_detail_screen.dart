import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/constants/job_categories.dart';
import '../../../map/presentation/pages/map_view_screen.dart';
import '../../../../features/applications/data/repositories/applications_repository.dart';
import '../../../../features/applications/presentation/pages/applicants_list_screen.dart';
import '../../data/models/job_model.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../chat/presentation/pages/chat_detail_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'create_job_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final JobModel job;
  final bool isEmployerView;

  const JobDetailScreen({
    super.key, 
    required this.job,
    this.isEmployerView = false,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  JobModel get job => widget.job;
  bool get isEmployerView => widget.isEmployerView;

  @override
  void initState() {
    super.initState();
    // Hər açılışda baxış sayını 1 artır
    _incrementViewCount();
  }

  Future<void> _incrementViewCount() async {
    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(job.id)
          .update({'viewCount': FieldValue.increment(1)});
    } catch (_) {}
  }

  void _showReportDialog() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şikayət etmək üçün daxil olmalısınız.')),
      );
      return;
    }

    String selectedReason = 'Spam';
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Şikayət Et', style: TextStyle(color: AppTheme.errorColor)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Zəhmət olmasa şikayət səbəbini seçin:'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      items: const [
                        DropdownMenuItem(value: 'Spam', child: Text('Spam və ya Reklam')),
                        DropdownMenuItem(value: 'Təhqiramiz məzmun', child: Text('Təhqiramiz məzmun')),
                        DropdownMenuItem(value: 'Saxtakarlıq', child: Text('Saxtakarlıq / Fırıldaqçılıq')),
                        DropdownMenuItem(value: 'Digər', child: Text('Digər')),
                      ],
                      onChanged: (val) {
                        setState(() => selectedReason = val!);
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: detailsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Əlavə məlumat (İstəyə bağlı)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Ləğv et', style: TextStyle(color: context.textHintColor)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog
                    try {
                      await ChatRepository().submitReport(
                        reporterId: currentUserId,
                        targetId: job.id,
                        targetType: 'job',
                        reason: selectedReason,
                        additionalDetails: detailsController.text.trim(),
                      );
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Şikayətiniz uğurla göndərildi. 24 saat ərzində baxılacaq.')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Şikayət göndərilərkən xəta baş verdi.')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Göndər'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = JobCategories.getById(job.categoryId);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('jobs').doc(job.id).snapshots(),
        builder: (context, snapshot) {
          final currentJob = snapshot.hasData 
              ? JobModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id)
              : job;

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: category.color,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GlassContainer(
                    blur: 10,
                    opacity: 0.2,
                    borderRadius: BorderRadius.circular(12),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                      color: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: GlassContainer(
                      blur: 10,
                      opacity: 0.2,
                      borderRadius: BorderRadius.circular(12),
                      child: IconButton(
                        onPressed: () {
                          final shareText = '''
${currentJob.title} - ${currentJob.companyName}

Maaş: ${currentJob.salaryText}
Şəhər: ${currentJob.city}
İş növü: ${_getJobTypeLabel(currentJob.jobType)}

Daha ətraflı məlumat üçün Azərbaycan İş Bazarı (İş Tap AI) tətbiqini yükləyin!
''';
                          Share.share(shareText, subject: currentJob.title);
                        },
                        icon: const Icon(Icons.share_rounded, size: 20),
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (!isEmployerView) Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: GlassContainer(
                      blur: 10,
                      opacity: 0.2,
                      borderRadius: BorderRadius.circular(12),
                      child: _BookmarkButton(jobId: currentJob.id),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, right: 12, top: 8, bottom: 8),
                    child: GlassContainer(
                      blur: 10,
                      opacity: 0.2,
                      borderRadius: BorderRadius.circular(12),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        color: Colors.white,
                        onSelected: (value) {
                          if (value == 'report') {
                            _showReportDialog();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.report_problem_rounded, color: AppTheme.errorColor, size: 20),
                                SizedBox(width: 8),
                                Text('Şikayət Et', style: TextStyle(color: AppTheme.errorColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Gradient Background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              category.color,
                              category.color.withValues(alpha: 0.6),
                              AppTheme.primaryColor.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      // Mesh Pattern Overlay
                      Positioned(
                        top: -100,
                        right: -100,
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -50,
                        left: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            Hero(
                              tag: 'job_logo_${currentJob.id}',
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: currentJob.companyLogo != null && currentJob.companyLogo!.isNotEmpty
                                      ? Image.network(currentJob.companyLogo!, fit: BoxFit.cover)
                                      : Icon(category.icon, color: category.color, size: 40),
                                ),
                              ),
                            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                currentJob.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                            const SizedBox(height: 8),
                            GlassContainer(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              borderRadius: BorderRadius.circular(20),
                              opacity: 0.15,
                              child: Text(
                                currentJob.companyName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ).animate().fadeIn(delay: 300.ms),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick info cards
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.cardShadow,
                        border: Border.all(color: context.dividerColor.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _QuickInfo(
                                icon: Icons.monetization_on_rounded,
                                title: 'Maaş',
                                value: currentJob.salaryText,
                                color: AppTheme.successColor,
                              ),
                              _VerticalDivider(),
                              _QuickInfo(
                                icon: Icons.schedule_rounded,
                                title: 'İş növü',
                                value: _getJobTypeLabel(currentJob.jobType),
                                color: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(color: context.dividerColor.withValues(alpha: 0.5), height: 1),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _QuickInfo(
                                icon: Icons.location_on_rounded,
                                title: 'Şəhər',
                                value: currentJob.city,
                                color: AppTheme.accentColor,
                              ),
                              _VerticalDivider(),
                              _QuickInfo(
                                icon: Icons.work_rounded,
                                title: 'Təcrübə',
                                value: currentJob.experienceLevel ?? 'Təcrübəsiz',
                                color: AppTheme.infoColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                    // Urgent badge
                    if (currentJob.isUrgent)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Təcili vakansiya - Tezliklə cavab veriləcək!',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 1) İş haqqında (Description)
                    _SectionCard(
                      title: 'İş haqqında',
                      child: Text(
                        currentJob.description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),

                    // 2) Tələblər (Requirements)
                    if (currentJob.requirements.isNotEmpty)
                      _SectionCard(
                        title: 'Tələblər',
                        child: Column(
                          children: currentJob.requirements
                              .map((r) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppTheme.successColor,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            r,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: context.textSecondaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),

                    // 3) Yan haqlar (Benefits)
                    if (currentJob.benefits.isNotEmpty)
                      _SectionCard(
                        title: 'Yan haqlar',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: currentJob.benefits.map((benefit) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                benefit,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    // 4) Detallar (Details)
                    _SectionCard(
                      title: 'Detallar',
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.business_rounded,
                            label: 'Şirkət',
                            value: currentJob.companyName,
                          ),
                          _DetailRow(
                            icon: Icons.location_city_rounded,
                            label: 'Şəhər',
                            value: currentJob.city,
                          ),
                          if (currentJob.district != null && currentJob.district!.isNotEmpty)
                            _DetailRow(
                              icon: Icons.map_rounded,
                              label: 'Rayon',
                              value: currentJob.district!,
                            ),
                          if (currentJob.address != null && currentJob.address!.isNotEmpty)
                            _DetailRow(
                              icon: Icons.pin_drop_rounded,
                              label: 'Ünvan',
                              value: currentJob.address!,
                            ),
                          if (currentJob.workingHours != null)
                            _DetailRow(
                              icon: Icons.schedule_rounded,
                              label: 'İş saatı',
                              value: currentJob.workingHours!,
                            ),
                          _DetailRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Tarix',
                            value: currentJob.timeAgo,
                          ),
                        ],
                      ),
                    ),

                    // 5) İşin Mövqeyi (Location Map) — en sonda
                    if (currentJob.latitude != 0 && currentJob.longitude != 0)
                      _SectionCard(
                        title: 'İşin Mövqeyi',
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.dividerColor),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: IgnorePointer(
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(currentJob.latitude, currentJob.longitude),
                                  initialZoom: 15.0,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.is.tap',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(currentJob.latitude, currentJob.longitude),
                                        width: 40,
                                        height: 40,
                                        child: const Icon(
                                          Icons.location_on,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Stats
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: Icons.visibility_outlined,
                            value: '${currentJob.viewCount}',
                            label: 'Baxış',
                          ),
                          _StatItem(
                            icon: Icons.people_outline_rounded,
                            value: '${currentJob.applicationCount}',
                            label: 'Müraciət',
                          ),
                          _StatItem(
                            icon: Icons.timer_outlined,
                            value: '${currentJob.expiresAt.difference(DateTime.now()).inDays}',
                            label: 'Gün qalıb',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        }
      ),

      // Bottom Action Bar
      bottomNavigationBar: isEmployerView 
          ? _buildEmployerViewActions(context)
          : _SeekerActionButtons(job: job),
    );
  }



  Widget _buildEmployerViewActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Edit button
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateJobScreen(existingJob: job),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
                  label: const Text(
                    'Redaktə et',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Delete button
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Just show a dialogue simulating delete for the mock scenario
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text('Diqqət'),
                        content: const Text(
                          'Bu elanı silmək istədiyinizə əminsiniz?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Ləğv et'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx); // Close dialog
                              await FirebaseFirestore.instance.collection('jobs').doc(job.id).delete();
                              
                              if (context.mounted) {
                                Navigator.pop(context); // Close details page
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Elan silindi'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Sil', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_rounded, color: Colors.white),
                  label: const Text(
                    'Sil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getJobTypeLabel(String type) {
    switch (type) {
      case 'fullTime':
        return 'Tam gün';
      case 'partTime':
        return 'Yarım gün';
      case 'daily':
        return 'Günlük';
      case 'hourly':
        return 'Saatlıq';
      case 'freelance':
        return 'Freelance';
      default:
        return type;
    }
  }
}

class _SeekerActionButtons extends StatefulWidget {
  final JobModel job;
  const _SeekerActionButtons({required this.job});

  @override
  State<_SeekerActionButtons> createState() => _SeekerActionButtonsState();
}

class _SeekerActionButtonsState extends State<_SeekerActionButtons> {
  bool _hasApplied = false;
  bool _isLoading = true;
  String _applicationStatus = '';

  @override
  void initState() {
    super.initState();
    _checkApplicationStatus();
  }

  Future<void> _checkApplicationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final appsSnapshot = await FirebaseFirestore.instance
          .collection('applications')
          .where('jobId', isEqualTo: widget.job.id)
          .where('applicantId', isEqualTo: user.uid)
          .get();

      if (appsSnapshot.docs.isNotEmpty) {
        final data = appsSnapshot.docs.first.data();
        if (mounted) {
          setState(() {
            _hasApplied = true;
            _applicationStatus = data['status'] ?? 'pending';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasApplied = false;
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAccepted = _applicationStatus == 'accepted';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Call button
            if (isAccepted && widget.job.allowCallIfAccepted) ...[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () async {
                    if (widget.job.contactPhone.isNotEmpty) {
                      final Uri url = Uri(scheme: 'tel', path: widget.job.contactPhone);
                      try {
                        await launchUrl(url);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Zəng etmək mümkün deyil')),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(
                    Icons.phone_rounded,
                    color: AppTheme.successColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Chat button
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () async {
                    try {
                      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                      if (currentUserId == null) return;

                      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
                      final seekerName = userDoc.data()?['fullName'] ?? 'Namizəd';

                      // Employer info via the job itself
                      final employerDoc = await FirebaseFirestore.instance.collection('users').doc(widget.job.employerId).get();
                      final employerName = employerDoc.data()?['fullName'] ?? 'İşəgötürən';

                      final chatId = await ChatRepository().createOrGetChat(
                        employerId: widget.job.employerId,
                        jobSeekerId: currentUserId,
                        jobId: widget.job.id,
                        jobTitle: widget.job.title,
                        employerName: employerName,
                        jobSeekerName: seekerName,
                      );

                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              chatId: chatId,
                              otherUserName: employerName,
                              otherUserId: widget.job.employerId,
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
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            // Apply button
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading || _hasApplied 
                    ? null 
                    : () async {
                        // Check if this job uses external redirect
                        if (widget.job.applicationMethod == 'redirect' && 
                            widget.job.externalUrl != null && 
                            widget.job.externalUrl!.isNotEmpty) {
                          final uri = Uri.parse(widget.job.externalUrl!);
                          try {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Link açıla bilmədi')),
                              );
                            }
                          }
                          return;
                        }

                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Zəhmət olmasa daxil olun')),
                          );
                          return;
                        }

                        setState(() { _isLoading = true; });

                        try {
                          await ApplicationsRepository().submitApplication(
                            jobId: widget.job.id,
                            employerId: widget.job.employerId,
                            applicantId: currentUser.uid,
                          );
                          
                          if (mounted) {
                            setState(() { 
                              _isLoading = false; 
                              _hasApplied = true;
                              _applicationStatus = 'pending';
                            });
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text('Müraciət göndərildi! ✅'),
                                content: const Text(
                                  'Müraciət etdiniz. Müraciətinizin nəticəsini müraciətlər ekranından izləyə bilərsiniz.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Tamam'),
                                  ),
                                ],
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() { _isLoading = false; });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Səhv baş verdi: $e')),
                            );
                          }
                        }
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasApplied ? Colors.grey : AppTheme.primaryColor,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : Text(
                        _hasApplied 
                          ? (isAccepted ? 'Qəbul edildi' : (_applicationStatus == 'rejected' ? 'Rədd edildi' : 'Müraciət edilib')) 
                          : 'Müraciət et',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _hasApplied ? Colors.white70 : Colors.white,
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _QuickInfo extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _QuickInfo({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: context.textHintColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: context.dividerColor,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.textHintColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: context.textHintColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: context.textHintColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.textPrimaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.textHintColor,
          ),
        ),
      ],
    );
  }
}

class _BookmarkButton extends StatefulWidget {
  final String jobId;
  const _BookmarkButton({required this.jobId});

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton> {
  bool _isSaved = false;
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    if (_currentUser == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final savedJobs = List<String>.from(data['savedJobs'] ?? []);
        if (mounted) {
          setState(() {
            _isSaved = savedJobs.contains(widget.jobId);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleSaved() async {
    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yadda saxlamaq üçün daxil olmalısınız.')),
        );
      }
      return;
    }

    final newStatus = !_isSaved;
    setState(() => _isSaved = newStatus);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(_currentUser.uid);
      if (newStatus) {
        await userRef.set({
          'savedJobs': FieldValue.arrayUnion([widget.jobId])
        }, SetOptions(merge: true));
      } else {
        await userRef.set({
          'savedJobs': FieldValue.arrayRemove([widget.jobId])
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Revert if API call fails
      setState(() => _isSaved = !_isSaved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xəta baş verdi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggleSaved,
      icon: Icon(
        _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        color: _isSaved ? AppTheme.primaryColor : Colors.white,
      ),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
      ),
    );
  }
}
