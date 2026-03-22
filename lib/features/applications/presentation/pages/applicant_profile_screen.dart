import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplicantProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ApplicantProfileScreen({super.key, required this.userData});

  @override
  State<ApplicantProfileScreen> createState() => _ApplicantProfileScreenState();
}

class _ApplicantProfileScreenState extends State<ApplicantProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String fullName = widget.userData['fullName'] ?? 'Bilinməyən Namizəd';
    final String phone = widget.userData['phone'] ?? 'Nömrə yoxdur';
    final String city = widget.userData['city'] ?? 'Şəhər qeyd olunmayıb';
    final String title = widget.userData['title'] ?? 'Ünvan qeyd olunmayıb';
    final String bio = widget.userData['bio'] ?? 'Haqqımda məlumat yoxdur.';
    final String gender = widget.userData['gender'] ?? 'Qeyd olunmayıb';
    
    final skillsRaw = widget.userData['skills'];
    final expRaw = widget.userData['experience'];
    final eduRaw = widget.userData['education'];

    final Timestamp? dobTimestamp = widget.userData['birthDate'] as Timestamp?;
    DateTime? birthDate;
    int? age;
    if (dobTimestamp != null) {
      birthDate = dobTimestamp.toDate();
      final now = DateTime.now();
      age = now.year - birthDate.year;
      if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Namizəd Profili'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Profile Card
                _buildHeroCard(context, fullName, title, phone),
                const SizedBox(height: 20),

                // Quick Info Cards
                _buildQuickInfoSection(context, age, birthDate, gender, city),
                const SizedBox(height: 20),

                // About Section
                if (bio.isNotEmpty && bio != 'Haqqımda məlumat yoxdur.')
                  _buildSectionCard(
                    context,
                    title: 'Haqqında',
                    icon: Icons.info_outline_rounded,
                    child: Text(
                      bio,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ),

                // Skills Section
                if (skillsRaw != null && skillsRaw.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: 'Bacarıqlar',
                    icon: Icons.star_rounded,
                    child: skillsRaw is List
                        ? Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (skillsRaw as List)
                                .map((skill) => _buildSkillChip(context, skill.toString()))
                                .toList(),
                          )
                        : Text(
                            skillsRaw.toString(),
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                  ),
                ],

                // Experience Section
                if (expRaw != null && expRaw.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: 'İş Təcrübəsi',
                    icon: Icons.work_outline_rounded,
                    child: expRaw is List
                        ? Column(
                            children: (expRaw as List)
                                .map((exp) => _buildExperienceItem(context, exp))
                                .toList(),
                          )
                        : Text(
                            expRaw.toString(),
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                  ),
                ],

                // Education Section
                if (eduRaw != null && eduRaw.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: 'Təhsil',
                    icon: Icons.school_outlined,
                    child: eduRaw is List
                        ? Column(
                            children: (eduRaw as List)
                                .map((edu) => _buildEducationItem(context, edu))
                                .toList(),
                          )
                        : Text(
                            eduRaw.toString(),
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, String fullName, String title, String phone) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Hero(
            tag: 'profile_${widget.userData['uid'] ?? 'unknown'}',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: widget.userData['photoUrl'] != null &&
                        (widget.userData['photoUrl'] as String).isNotEmpty
                    ? NetworkImage(widget.userData['photoUrl'] as String)
                    : null,
                child: widget.userData['photoUrl'] == null ||
                        (widget.userData['photoUrl'] as String).isEmpty
                    ? Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'N',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 36,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final Uri url = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
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
                  icon: const Icon(Icons.phone_rounded, size: 20),
                  label: const Text('Zəng et'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Nömrə: $phone'),
                        backgroundColor: Colors.white,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.content_copy_rounded, size: 20),
                  label: const Text('Nüsxələ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoSection(
      BuildContext context, int? age, DateTime? birthDate, String gender, String city) {
    return Row(
      children: [
        if (age != null && birthDate != null)
          Expanded(
            child: _buildInfoCard(
              context,
              icon: Icons.cake_rounded,
              label: 'Yaş',
              value: '$age',
              color: AppTheme.accentColor,
            ),
          ),
        if (age != null && birthDate != null) const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            context,
            icon: Icons.person_rounded,
            label: 'Cinsiyyət',
            value: gender,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            context,
            icon: Icons.location_on_rounded,
            label: 'Şəhər',
            value: city,
            color: AppTheme.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
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

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSkillChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.15),
            AppTheme.primaryColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildExperienceItem(BuildContext context, dynamic expData) {
    final map = expData as Map<String, dynamic>;
    final title = map['title'] ?? 'Vəzifə';
    final company = map['company'] ?? 'Şirkət';
    final dates = map['dates'] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  company,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (dates.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dates,
                    style: TextStyle(
                      color: context.textHintColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationItem(BuildContext context, dynamic eduData) {
    final map = eduData as Map<String, dynamic>;
    final degree = map['degree'] ?? 'Dərəcə';
    final school = map['school'] ?? 'Təhsil Müəssisəsi';
    final dates = map['dates'] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  degree,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  school,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (dates.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dates,
                    style: TextStyle(
                      color: context.textHintColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
