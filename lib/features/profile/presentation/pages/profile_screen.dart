import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/cloudinary_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_cubit.dart';

class ProfileScreen extends StatefulWidget {
  final bool isEmployerView;
  const ProfileScreen({super.key, this.isEmployerView = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    if (picked == null) return;

    setState(() => _isUploading = true);

    final imageFile = File(picked.path);
    final url = await CloudinaryService.uploadImage(imageFile);

    if (url != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'photoUrl': url,
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şəkil yüklənərkən xəta baş verdi.')),
        );
      }
    }

    if (mounted) setState(() => _isUploading = false);
  }

  String _getThemeName(BuildContext context) {
    final mode = context.watch<ThemeCubit>().state;
    if (mode == ThemeMode.light) return 'Açıq';
    if (mode == ThemeMode.dark) return 'Qaranlıq';
    return 'Sistem';
  }

  void _showThemeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, currentMode) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: context.textHintColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      'Tətbiq Rejimi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ThemeOptionTile(
                      title: 'Açıq (Light)',
                      icon: Icons.light_mode_rounded,
                      isSelected: currentMode == ThemeMode.light,
                      onTap: () {
                        context.read<ThemeCubit>().setThemeMode(ThemeMode.light);
                        Navigator.pop(context);
                      },
                    ),
                    _ThemeOptionTile(
                      title: 'Qaranlıq (Dark)',
                      icon: Icons.dark_mode_rounded,
                      isSelected: currentMode == ThemeMode.dark,
                      onTap: () {
                        context.read<ThemeCubit>().setThemeMode(ThemeMode.dark);
                        Navigator.pop(context);
                      },
                    ),
                    _ThemeOptionTile(
                      title: 'Sistem',
                      icon: Icons.settings_brightness_rounded,
                      isSelected: currentMode == ThemeMode.system,
                      onTap: () {
                        context.read<ThemeCubit>().setThemeMode(ThemeMode.system);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Zəhmət olmasa daxil olun'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final fullName = userData['fullName'] as String? ?? (widget.isEmployerView ? 'Şirkət' : 'İstifadəçi');
        final phone = userData['phone'] as String? ?? 'Nömrə yoxdur';
        final photoUrl = userData['photoUrl'] as String?;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Avatar
                GestureDetector(
                  onTap: _isUploading ? null : _pickAndUploadPhoto,
                  child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: photoUrl == null ? AppTheme.primaryGradient : null,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    image: photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : photoUrl == null
                          ? const Icon(Icons.person_rounded, size: 50, color: Colors.white)
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
                ),
            const SizedBox(height: 16),
            Text(
              fullName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              phone,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.isEmployerView ? 'İşverən' : 'İş axtaran',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Profile completion - dynamic calculation
            if (!widget.isEmployerView) ...[
              Builder(
                builder: (context) {
                  int filledCount = 0;
                  int totalFields = 5; // fullName, phone, experience, education, skills
                  
                  if ((userData['fullName'] as String?)?.isNotEmpty == true) filledCount++;
                  if ((userData['phone'] as String?)?.isNotEmpty == true) filledCount++;
                  if ((userData['experience'] as String?)?.isNotEmpty == true) filledCount++;
                  if ((userData['education'] as String?)?.isNotEmpty == true) filledCount++;
                  if ((userData['skills'] as String?)?.isNotEmpty == true) filledCount++;
                  
                  final completionPercent = filledCount / totalFields;
                  final completionInt = (completionPercent * 100).round();
                  
                  // 100% olduqda banneri gizlə
                  if (completionInt >= 100) return const SizedBox.shrink();
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.warningColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircularProgressIndicator(
                          value: completionPercent,
                          strokeWidth: 5,
                          backgroundColor: AppTheme.warningColor.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation(AppTheme.warningColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profil $completionInt% tamamdır',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Profilini tamamla, daha çox iş tap!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, AppRouter.editProfile);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.warningColor),
                              foregroundColor: AppTheme.warningColor,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text('Tamamla', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            // Menu items
            _MenuItem(
              icon: widget.isEmployerView ? Icons.business_rounded : Icons.person_outline_rounded,
              title: widget.isEmployerView ? 'Şirkət məlumatları' : 'Məlumatlarım',
              subtitle: 'Ad, telefon, şəhər',
              onTap: () {
                Navigator.pushNamed(context, AppRouter.editProfile);
              },
            ),
            if (!widget.isEmployerView) ...[
              _MenuItem(
                icon: Icons.work_outline_rounded,
                title: 'Təcrübə',
                subtitle: userData['experience']?.toString().isNotEmpty == true 
                    ? userData['experience'] 
                    : 'Əlavə edilməyib',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.editProfile);
                },
              ),
              _MenuItem(
                icon: Icons.school_outlined,
                title: 'Təhsil',
                subtitle: userData['education']?.toString().isNotEmpty == true 
                    ? userData['education'] 
                    : 'Əlavə edilməyib',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.editProfile);
                },
              ),
              _MenuItem(
                icon: Icons.star_outline_rounded,
                title: 'Bacarıqlar',
                subtitle: userData['skills']?.toString().isNotEmpty == true 
                    ? userData['skills'] 
                    : 'Əlavə edilməyib',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.editProfile);
                },
              ),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),

            if (!widget.isEmployerView) ...[
              _MenuItem(
                icon: Icons.bookmark_outline_rounded,
                title: 'Saxlanmış elanlar',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.history_rounded,
                title: 'Baxış tarixçəsi',
                onTap: () {},
              ),
            ],
            _MenuItem(
              icon: Icons.color_lens_outlined,
              title: 'Rejim (Dark/Light)',
              subtitle: _getThemeName(context),
              onTap: () => _showThemeBottomSheet(context),
            ),
            _MenuItem(
              icon: Icons.notifications_outlined,
              title: 'Bildirişlər',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.language_rounded,
              title: 'Dil',
              subtitle: 'Azərbaycan',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Kömək',
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: context.scaffoldBackgroundColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: context.textHintColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Text(
                            'Kömək və Qaydalar',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryColor),
                            title: const Text('Məxfilik Siyasəti (Privacy Policy)'),
                            trailing: Icon(Icons.open_in_new_rounded, size: 16, color: context.textHintColor),
                            onTap: () async {
                              final Uri url = Uri.parse('https://istapapp.netlify.app/privacy.html');
                              if (!await launchUrl(url)) {
                                debugPrint('Could not launch \$url');
                              }
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.description_outlined, color: AppTheme.primaryColor),
                            title: const Text('İstifadəçi Şərtləri (EULA)'),
                            trailing: Icon(Icons.open_in_new_rounded, size: 16, color: context.textHintColor),
                            onTap: () async {
                              final Uri url = Uri.parse('https://istapapp.netlify.app/terms.html');
                              if (!await launchUrl(url)) {
                                debugPrint('Could not launch \$url');
                              }
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.support_agent_rounded, color: AppTheme.primaryColor),
                            title: const Text('Dəstək (Support)'),
                            trailing: Icon(Icons.open_in_new_rounded, size: 16, color: context.textHintColor),
                            onTap: () async {
                              final Uri url = Uri.parse('https://istapapp.netlify.app/support.html');
                              if (!await launchUrl(url)) {
                                debugPrint('Could not launch \$url');
                              }
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRouter.roleSelection,
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
                label: const Text(
                  'Çıxış',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppTheme.errorColor.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Delete Account
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hesabı Sil', style: TextStyle(color: AppTheme.errorColor)),
                      content: const Text(
                        'Hesabınızı silmək istədiyinizə əminsiniz? Bu əməliyyat geri alına bilməz və bütün məlumatlarınız həmişəlik silinəcək.',
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Ləğv et'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Sil'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    // Loading göstər
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final uid = user.uid;
                        final batch = FirebaseFirestore.instance.batch();

                        // 1. İstifadəçinin elanlarını sil
                        final jobsSnapshot = await FirebaseFirestore.instance
                            .collection('jobs')
                            .where('employerId', isEqualTo: uid)
                            .get();
                        for (var doc in jobsSnapshot.docs) {
                          batch.delete(doc.reference);
                        }

                        // 2. İstifadəçinin müraciətlərini sil
                        final applicationsSnapshot = await FirebaseFirestore.instance
                            .collection('applications')
                            .where('applicantId', isEqualTo: uid)
                            .get();
                        for (var doc in applicationsSnapshot.docs) {
                          batch.delete(doc.reference);
                        }

                        // 3. İstifadəçinin işəgötürən olaraq aldığı müraciətləri sil
                        final employerApplicationsSnapshot = await FirebaseFirestore.instance
                            .collection('applications')
                            .where('employerId', isEqualTo: uid)
                            .get();
                        for (var doc in employerApplicationsSnapshot.docs) {
                          batch.delete(doc.reference);
                        }

                        // 4. İstifadəçinin mesajlarını sil
                        final chatsSnapshot = await FirebaseFirestore.instance
                            .collection('chats')
                            .where('participants', arrayContains: uid)
                            .get();
                        for (var doc in chatsSnapshot.docs) {
                          batch.delete(doc.reference);
                        }

                        // 5. İstifadəçi məlumatlarını sil
                        batch.delete(FirebaseFirestore.instance.collection('users').doc(uid));

                        // Batch commit
                        await batch.commit();
                        
                        // 6. Auth-dan sil
                        await user.delete();
                      }
                    } catch (e) {
                      // Ignore errors
                    }

                    // Navigation
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRouter.roleSelection,
                        (route) => false,
                      );
                    }
                  }
                },
                icon: Icon(Icons.delete_forever_rounded, color: context.textHintColor),
                label: Text(
                  'Hesabı Sil',
                  style: TextStyle(color: context.textHintColor),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            Text(
              'Versiya 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: context.textHintColor,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
          ),
        );
      },
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.iconContainerColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryLight, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: context.textHintColor,
                ),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: context.textHintColor,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isSelected ? AppTheme.primaryColor : context.textSecondaryColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppTheme.primaryColor : context.textPrimaryColor,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
