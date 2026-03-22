import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _MapViewScreenState extends State<MapViewScreen>
    with TickerProviderStateMixin {
  int? _selectedJobIndex;
  late AnimationController _cardCtrl;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    super.dispose();
  }

  void _selectJob(int? idx) {
    setState(() => _selectedJobIndex = idx);
    if (idx != null) {
      _cardCtrl.forward(from: 0);
    } else {
      _cardCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('jobs')
            .where('isActive', isEqualTo: true)
            .get(const GetOptions(source: Source.serverAndCache)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return _buildLoading(isDark);
          }

          final now = DateTime.now();
          final jobs = snapshot.data?.docs
                  .where((d) => d.data() != null)
                  .map((d) => JobModel.fromMap(
                      d.data() as Map<String, dynamic>, d.id))
                  .where((job) => job.expiresAt.isAfter(now))
                  .toList() ??
              [];

          return Stack(
            children: [
              // ── Map ─────────────────────────────────────────────
              FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(40.4093, 49.8671),
                  initialZoom: 12.0,
                  onTap: (_, __) => _selectJob(null),
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.is.tap',
                  ),
                  MarkerLayer(
                    markers: jobs.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final job = entry.value;
                      final cat = JobCategories.getById(job.categoryId);
                      final isSelected = _selectedJobIndex == idx;

                      final lat = job.latitude != 0
                          ? job.latitude
                          : 40.4093 + (idx * 0.005);
                      final lng = job.longitude != 0
                          ? job.longitude
                          : 49.8671 + (idx * 0.005);

                      return Marker(
                        point: LatLng(lat, lng),
                        width: isSelected ? 60 : 50,
                        height: isSelected ? 60 : 50,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _selectJob(idx);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutBack,
                            decoration: BoxDecoration(
                              color: isSelected ? cat.color : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cat.color,
                                width: isSelected ? 0 : 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: cat.color.withOpacity(
                                      isSelected ? 0.55 : 0.25),
                                  blurRadius: isSelected ? 18 : 8,
                                  spreadRadius: isSelected ? 2 : 0,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                cat.icon,
                                size: isSelected ? 28 : 22,
                                color: isSelected ? Colors.white : cat.color,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // ── Search bar ───────────────────────────────────────
              Positioned(
                top: 14,
                left: 16,
                right: 16,
                child: _buildSearchBar(context, isDark),
              ),

              // ── Job count badge ──────────────────────────────────
              Positioned(
                top: 80,
                right: 16,
                child: _buildCountBadge(jobs.length, isDark),
              ),

              // ── Job card ─────────────────────────────────────────
              if (_selectedJobIndex != null &&
                  _selectedJobIndex! < jobs.length)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobDetailScreen(
                                  job: jobs[_selectedJobIndex!]),
                            ),
                          );
                        },
                        child: _buildJobCard(
                            context, jobs[_selectedJobIndex!], isDark),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Xəritə yüklənir...',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black38,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C2E).withOpacity(0.95)
            : Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.search_rounded,
            size: 20,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Bu ərazidə axtar...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white30 : Colors.black26,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 22,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.tune_rounded,
            size: 18,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C2E).withOpacity(0.92)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.successColor,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.successColor.withOpacity(0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '$count elan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, JobModel job, bool isDark) {
    final cat = JobCategories.getById(job.categoryId);
    final nowUtc = DateTime.now().toUtc();
    final urgentUntilUtc = job.urgentUntil?.toUtc();
    final isUrgentActive = job.isUrgent &&
        urgentUntilUtc != null &&
        urgentUntilUtc.isAfter(nowUtc);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: cat.color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Category icon box
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: cat.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: cat.color.withOpacity(0.2),
              ),
            ),
            child: Icon(cat.icon, color: cat.color, size: 26),
          ),
          const SizedBox(width: 14),

          // Info
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUrgentActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Text(
                          '🔥 Təcili',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  job.companyName,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Salary
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        job.salaryText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Distance
                    Row(
                      children: [
                        Icon(
                          Icons.near_me_outlined,
                          size: 12,
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          job.distanceText,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Arrow
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}