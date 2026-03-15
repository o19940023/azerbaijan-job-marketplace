import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/job_categories.dart';
import '../../../jobs/data/models/job_model.dart';

class JobListCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback? onTap;

  const JobListCard({super.key, required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    final category = JobCategories.getById(job.categoryId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: job.isUrgent
                    ? AppTheme.accentColor.withValues(alpha: 0.3)
                    : const Color(0xFFF0F0F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: company + urgent badge
                Row(
                  children: [
                    // Company logo or category icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        image: job.companyLogo != null && job.companyLogo!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(job.companyLogo!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: job.companyLogo == null || job.companyLogo!.isEmpty
                          ? Icon(
                              category.icon,
                              color: category.color,
                              size: 22,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            job.companyName,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (job.isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Təcili 🔥',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Info chips row
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _InfoChip(
                      icon: Icons.monetization_on_outlined,
                      text: job.salaryText,
                      color: AppTheme.successColor,
                    ),
                    _InfoChip(
                      icon: Icons.location_on_outlined,
                      text: job.locationText,
                      color: AppTheme.primaryColor,
                    ),
                    if (job.distance != null && job.distance! > 0)
                      _InfoChip(
                        icon: Icons.near_me_outlined,
                        text: job.distanceText,
                        color: AppTheme.infoColor,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Bottom row: job type + time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getJobTypeLabel(job.jobType),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    Text(
                      job.timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
      case 'urgent':
        return 'Təcili';
      default:
        return type;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
