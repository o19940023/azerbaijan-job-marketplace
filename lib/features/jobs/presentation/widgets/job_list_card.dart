import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/job_categories.dart';
import '../../../jobs/data/models/job_model.dart';

class JobListCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback? onTap;

  const JobListCard({super.key, required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Determine category if available, otherwise use a default fallback
    final category = JobCategories.getById(job.categoryId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            if (job.isUrgent)
              BoxShadow(
                color: AppTheme.accentColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: AppTheme.primaryColor.withValues(alpha: 0.05),
            highlightColor: AppTheme.primaryColor.withValues(alpha: 0.02),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Company Logo + Title/Company Name + Urgent Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company Logo
                      Hero(
                        tag: 'job_logo_${job.id}',
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: category.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.04),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: job.companyLogo != null && job.companyLogo!.isNotEmpty
                                ? Image.network(
                                    job.companyLogo!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Icon(
                                      category.icon,
                                      color: category.color,
                                      size: 26,
                                    ),
                                  )
                                : Icon(
                                    category.icon,
                                    color: category.color,
                                    size: 26,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      
                      // Job Title & Company Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimaryColor,
                                height: 1.2,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.business_rounded,
                                  size: 14,
                                  color: context.textSecondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    job.companyName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.textSecondaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Urgent Badge
                      if (job.isUrgent)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.accentColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 14,
                                color: AppTheme.accentColor,
                              ).animate(onPlay: (c) => c.repeat()).shimmer(
                                duration: 1500.ms,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Təcili',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 18),
                  
                  // Info Chips Row (Salary, Location, Distance)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _ModernInfoChip(
                          icon: Icons.payments_outlined,
                          text: job.salaryText,
                          color: AppTheme.successColor,
                          backgroundColor: AppTheme.successColor.withValues(alpha: 0.08),
                        ),
                        const SizedBox(width: 8),
                        _ModernInfoChip(
                          icon: Icons.location_on_outlined,
                          text: job.city,
                          color: AppTheme.primaryColor,
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
                        ),
                        if (job.distance != null && job.distance! > 0) ...[
                          const SizedBox(width: 8),
                          _ModernInfoChip(
                            icon: Icons.near_me_rounded,
                            text: '${job.distance!.toStringAsFixed(1)} km',
                            color: AppTheme.infoColor,
                            backgroundColor: AppTheme.infoColor.withValues(alpha: 0.08),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Divider
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: context.dividerColor.withValues(alpha: 0.5),
                  ),
                  
                  const SizedBox(height: 14),
                  
                  // Bottom Row: Job Type + Posted Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.isDarkMode 
                              ? Colors.white.withValues(alpha: 0.05) 
                              : Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getJobTypeLabel(job.jobType),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: context.textSecondaryColor.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTimeAgo(job.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondaryColor.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
  }

  String _getJobTypeLabel(String type) {
    switch (type) {
      case 'full_time':
        return 'Tam ştat';
      case 'part_time':
        return 'Yarım ştat';
      case 'freelance':
        return 'Freelance';
      case 'internship':
        return 'Təcrübəçi';
      default:
        return 'Tam ştat';
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün əvvəl';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat əvvəl';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dəqiqə əvvəl';
    } else {
      return 'İndi';
    }
  }
}

class _ModernInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color backgroundColor;

  const _ModernInfoChip({
    required this.icon,
    required this.text,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
