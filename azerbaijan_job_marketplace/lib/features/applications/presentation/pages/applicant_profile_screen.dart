import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplicantProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ApplicantProfileScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final String fullName = userData['fullName'] ?? 'Bilinməyən Aday';
    final String phone = userData['phone'] ?? 'Nömrə yoxdur';
    final String city = userData['city'] ?? 'Şəhər qeyd olunmayıb';
    final String title = userData['title'] ?? 'Ünvan qeyd olunmayıb';
    final String bio = userData['bio'] ?? 'Haqqımda məlumat yoxdur.';
    final String gender = userData['gender'] ?? 'Qeyd olunmayıb';
    
    // Extracted arrays if available (can be extended based on your db structure)
    final skillsRaw = userData['skills'];
    final expRaw = userData['experience'];
    final eduRaw = userData['education'];

    final Timestamp? dobTimestamp = userData['birthDate'] as Timestamp?;
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
        title: const Text('Aday Profili'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar & Name Card
            Center(
              child: Column(
                children: [
                   CircleAvatar(
                     radius: 50,
                     backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                     backgroundImage: userData['photoUrl'] != null && (userData['photoUrl'] as String).isNotEmpty
                         ? NetworkImage(userData['photoUrl'] as String)
                         : null,
                     child: userData['photoUrl'] == null || (userData['photoUrl'] as String).isEmpty
                         ? Text(
                             fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A',
                             style: const TextStyle(
                               color: AppTheme.primaryColor,
                               fontWeight: FontWeight.bold,
                               fontSize: 40,
                             ),
                           )
                         : null,
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
                     title,
                     style: TextStyle(
                       fontSize: 16,
                       color: context.textSecondaryColor,
                       fontWeight: FontWeight.w500,
                     ),
                     textAlign: TextAlign.center,
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact Actions
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
                     icon: const Icon(Icons.phone),
                     label: const Text('Zəng et'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppTheme.successColor,
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 14),
                     ),
                   ),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: OutlinedButton.icon(
                     onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text('Nömrə: $phone')),
                         );
                     },
                     icon: const Icon(Icons.copy),
                     label: const Text('Nüsxələ'),
                     style: OutlinedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 14),
                     ),
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 24),
             
             // Info Section
             _buildSectionTitle(context, 'Haqqında'),
             const SizedBox(height: 8),
              Text(
                bio,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              if (birthDate != null && age != null) ...[
                Row(
                  children: [
                    const Icon(Icons.cake_outlined, size: 18, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text('Yaş: $age (${DateFormat('dd.MM.yyyy').format(birthDate)})', style: TextStyle(color: context.textSecondaryColor, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text('Cinsiyyət: $gender', style: TextStyle(color: context.textSecondaryColor, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text('Şəhər: $city', style: TextStyle(color: context.textSecondaryColor, fontSize: 13)),
                ],
              ),
             const SizedBox(height: 24),

             if (skillsRaw != null && skillsRaw.toString().trim().isNotEmpty) ...[
               _buildSectionTitle(context, 'Bacarıqlar'),
               const SizedBox(height: 12),
               if (skillsRaw is List)
                 Wrap(
                   spacing: 8,
                   runSpacing: 8,
                   children: (skillsRaw as List).map((skill) => _buildChip(context, skill.toString())).toList(),
                 )
               else
                 Text(skillsRaw.toString(), style: TextStyle(color: context.textSecondaryColor, fontSize: 14, height: 1.5)),
               const SizedBox(height: 24),
             ],

             if (expRaw != null && expRaw.toString().trim().isNotEmpty) ...[
               _buildSectionTitle(context, 'İş Təcrübəsi'),
               const SizedBox(height: 12),
               if (expRaw is List)
                 ...(expRaw as List).map((exp) => _buildExperienceCard(context, exp))
               else
                 Text(expRaw.toString(), style: TextStyle(color: context.textSecondaryColor, fontSize: 14, height: 1.5)),
               const SizedBox(height: 24),
             ],
             
             if (eduRaw != null && eduRaw.toString().trim().isNotEmpty) ...[
               _buildSectionTitle(context, 'Təhsil'),
               const SizedBox(height: 12),
               if (eduRaw is List)
                 ...(eduRaw as List).map((edu) => _buildEducationCard(context, edu))
               else
                 Text(eduRaw.toString(), style: TextStyle(color: context.textSecondaryColor, fontSize: 14, height: 1.5)),
               const SizedBox(height: 24),
             ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: context.textPrimaryColor,
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildExperienceCard(BuildContext context, dynamic expData) {
     final map = expData as Map<String, dynamic>;
     final title = map['title'] ?? 'Vəzifə';
     final company = map['company'] ?? 'Şirkət';
     final dates = map['dates'] ?? '';
     return Padding(
       padding: const EdgeInsets.only(bottom: 12),
       child: Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: context.cardColor,
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: context.dividerColor),
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
             const SizedBox(height: 4),
             Text(company, style: TextStyle(color: context.textSecondaryColor, fontSize: 13)),
             const SizedBox(height: 4),
             Text(dates, style: TextStyle(color: context.textHintColor, fontSize: 12)),
           ],
         ),
       ),
     );
  }
  
  Widget _buildEducationCard(BuildContext context, dynamic eduData) {
     final map = eduData as Map<String, dynamic>;
     final degree = map['degree'] ?? 'Dərəcə';
     final school = map['school'] ?? 'Təhsil Müəssisəsi';
     final dates = map['dates'] ?? '';
     return Padding(
       padding: const EdgeInsets.only(bottom: 12),
       child: Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: AppTheme.accentColor.withValues(alpha: 0.05),
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.2)),
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(degree, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.accentColor)),
             const SizedBox(height: 4),
             Text(school, style: TextStyle(color: context.textSecondaryColor, fontSize: 13)),
             const SizedBox(height: 4),
             Text(dates, style: TextStyle(color: context.textHintColor, fontSize: 12)),
           ],
         ),
       ),
     );
  }
}
