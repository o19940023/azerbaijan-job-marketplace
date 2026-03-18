import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/job_categories.dart';
import '../../../jobs/data/models/job_model.dart';
import '../../../jobs/presentation/pages/job_detail_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  int? _selectedJobIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobs = snapshot.data!.docs
              .where((d) => d.data() != null)
              .map(
                (d) => JobModel.fromMap(d.data() as Map<String, dynamic>, d.id),
              )
              .toList();

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(
                    40.4093,
                    49.8671,
                  ), // Default center
                  initialZoom: 12.0,
                  onTap: (_, __) => setState(() => _selectedJobIndex = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.is.tap',
                  ),
                  MarkerLayer(
                    markers: jobs.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final job = entry.value;
                      final cat = JobCategories.getById(job.categoryId);
                      final isSelected = _selectedJobIndex == idx;

                      // Use actual job coordinates, fallback to mock near center if missing
                      final lat = job.latitude != 0
                          ? job.latitude
                          : 40.4093 + (idx * 0.005);
                      final lng = job.longitude != 0
                          ? job.longitude
                          : 49.8671 + (idx * 0.005);

                      return Marker(
                        point: LatLng(lat, lng),
                        width: isSelected ? 56 : 48,
                        height: isSelected ? 56 : 48,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedJobIndex = idx),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? cat.color : context.cardColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? context.scaffoldBackgroundColor
                                    : cat.color,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: cat.color.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              cat.icon,
                              size: isSelected ? 28 : 24,
                              color: isSelected ? context.cardColor : cat.color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Search bar at top
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Bu ərazidə axtar...',
                      hintStyle: TextStyle(color: context.textHintColor),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: context.textHintColor,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),

              // Selected Job Card at bottom
              if (_selectedJobIndex != null && _selectedJobIndex! < jobs.length)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              JobDetailScreen(job: jobs[_selectedJobIndex!]),
                        ),
                      );
                    },
                    child: _buildJobCard(jobs[_selectedJobIndex!]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildJobCard(job) {
    final cat = JobCategories.getById(job.categoryId);
    final nowUtc = DateTime.now().toUtc();
    final urgentUntilUtc = job.urgentUntil?.toUtc();
    final isUrgentActive =
        job.isUrgent &&
        urgentUntilUtc != null &&
        urgentUntilUtc.isAfter(nowUtc);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(cat.icon, color: cat.color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        job.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimaryColor,
                        ),
                      ),
                    ),
                    if (isUrgentActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
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
                const SizedBox(height: 4),
                Text(
                  job.companyName,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on_outlined,
                      size: 14,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      job.salaryText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.near_me_outlined,
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      job.distanceText,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.textHintColor),
        ],
      ),
    );
  }
}
