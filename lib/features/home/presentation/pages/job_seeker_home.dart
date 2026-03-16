import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/job_categories.dart';
import '../../../../features/applications/data/models/application_model.dart';
import '../../../../features/applications/data/repositories/applications_repository.dart';
import '../../../jobs/data/models/job_model.dart';
import '../../../jobs/presentation/widgets/job_list_card.dart';
import '../../../jobs/presentation/pages/job_detail_screen.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../chat/presentation/pages/chat_detail_screen.dart';
import '../../../map/presentation/pages/map_view_screen.dart';
import '../../../chat/presentation/pages/chat_list_screen.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import '../../../ai_assistant/presentation/ai_assistant_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class JobSeekerHome extends StatefulWidget {
  const JobSeekerHome({super.key});

  @override
  State<JobSeekerHome> createState() => _JobSeekerHomeState();
}

class _JobSeekerHomeState extends State<JobSeekerHome> {
  int _currentIndex = 0;
  String? _selectedCategory;
  String? _selectedJobType;
  final _searchController = TextEditingController();

  String _selectedSortMode = 'newest';
  Position? _userPosition;

  // Extended Filters
  String? _filterSalaryRange;
  String? _filterEducation;
  String? _filterCity;
  String? _filterExperience;

  // Search history & focus
  List<String> _searchHistory = [];
  final FocusNode _searchFocusNode = FocusNode();

  // Cached jobs (one-time fetch, no auto-refresh)
  List<JobModel>? _cachedJobs;
  bool _isLoadingJobs = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    if (!mounted) return;
    setState(() => _isLoadingJobs = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('jobs').get();
      if (!mounted) return;
      setState(() {
        _cachedJobs = snapshot.docs
            .map((d) => JobModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList();
        _isLoadingJobs = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingJobs = false);
      }
    }
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('searchHistory') ?? [];
    });
  }

  Future<void> _saveSearchTerm(String term) async {
    if (term.trim().isEmpty) return;
    _searchHistory.remove(term);
    _searchHistory.insert(0, term);
    if (_searchHistory.length > 10) _searchHistory = _searchHistory.sublist(0, 10);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('searchHistory', _searchHistory);
    setState(() {});
  }

  Future<void> _handleLocationSort() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zəhmət olmasa, məkan xidmətlərini aktivləşdirin')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Məkan icazəsi verilmədi')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Məkan icazələri həmişəlik rədd edilib')),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _userPosition = position;
        _selectedSortMode = 'location';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Məkan əldə edilə bilmədi')),
        );
      }
    }
  }

  void _showDetailedFilterOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildSectionTitle(String title) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 16),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
              );
            }

            Widget buildDropdown(String hint, List<String> items, String? currentValue, Function(String?) onChanged) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: context.inputFillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text(hint, style: TextStyle(color: context.textHintColor, fontSize: 14)),
                    value: currentValue,
                    items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: onChanged,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.textSecondaryColor),
                  ),
                ),
              );
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ətraflı Filtrlər',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _filterSalaryRange = null;
                                _filterEducation = null;
                                _filterCity = null;
                                _filterExperience = null;
                                _selectedCategory = null;
                                _selectedJobType = null;
                              });
                              setState(() {
                                _filterSalaryRange = null;
                                _filterEducation = null;
                                _filterCity = null;
                                _filterExperience = null;
                                _selectedCategory = null;
                                _selectedJobType = null;
                              });
                            },
                            child: const Text('Təmizlə', style: TextStyle(color: AppTheme.errorColor)),
                          ),
                        ],
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            buildSectionTitle('Maaş Aralığı (₼)'),
                            buildDropdown('Seçin', ['0-500', '500-1000', '1000-2000', '2000+'], _filterSalaryRange, (v) => setModalState(() => _filterSalaryRange = v)),
                            
                            buildSectionTitle('Təhsil'),
                            buildDropdown('Seçin', ['Vacib deyil', 'Orta', 'Peşə', 'Natamam ali', 'Ali'], _filterEducation, (v) => setModalState(() => _filterEducation = v)),
                            
                            buildSectionTitle('Şəhər'),
                            buildDropdown('Seçin', ['Bakı', 'Sumqayıt', 'Gəncə', 'Mingəçevir', 'Lənkəran', 'Digər'], _filterCity, (v) => setModalState(() => _filterCity = v)),
                            
                            buildSectionTitle('İş Təcrübəsi'),
                            buildDropdown('Seçin', ['Təcrübəsiz', '1 ildən aşağı', '1 ildən 3 ilə qədər', '3 ildən 5 ilə qədər', '5 ildən artıq'], _filterExperience, (v) => setModalState(() => _filterExperience = v)),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 52,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Trigger rebuild with filters
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Tətbiq Et', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Sıralama Seçimi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.access_time_rounded),
                title: const Text('Ən yenidən köhnəyə'),
                trailing: _selectedSortMode == 'newest' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  setState(() {
                    _selectedSortMode = 'newest';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money_rounded),
                title: const Text('Ən yüksək maaş'),
                trailing: _selectedSortMode == 'salary' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  setState(() {
                    _selectedSortMode = 'salary';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on_rounded),
                title: const Text('Ən yaxın konum'),
                trailing: _selectedSortMode == 'location' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  Navigator.pop(context);
                  _handleLocationSort();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      const MapViewScreen(),
      _buildApplicationsPage(),
      const ChatListScreen(),
      const ProfileScreen(),
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
              color: context.isDarkMode ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.06),
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
            return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Ana Səhifə',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined),
                  activeIcon: Icon(Icons.map_rounded),
                  label: 'Xəritə',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.assignment_outlined),
                  activeIcon: Icon(Icons.assignment_rounded),
                  label: 'Müraciətlər',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount', style: const TextStyle(fontSize: 10, color: Colors.white)),
                    child: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount', style: const TextStyle(fontSize: 10, color: Colors.white)),
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
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (_cachedJobs == null && _isLoadingJobs) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchJobs,
        color: AppTheme.primaryColor,
        child: FutureBuilder<DocumentSnapshot>(
          future: currentUser != null 
              ? FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get()
              : Future.value(null),
          builder: (context, userSnapshot) {
            // Extract blocked users array
            List<String> blockedUsers = [];
            if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
              if (userData != null && userData.containsKey('blockedUsers')) {
                blockedUsers = List<String>.from(userData['blockedUsers'] ?? []);
              }
            }

            var jobs = (_cachedJobs ?? [])
                // Filter out blocked users
                .where((j) => !blockedUsers.contains(j.employerId))
                .toList();
              
              if (_selectedCategory != null) {
                jobs = jobs.where((j) => j.categoryId == _selectedCategory).toList();
              }
              if (_selectedJobType != null) {
                jobs = jobs.where((j) => j.jobType == _selectedJobType).toList();
              }
              if (_searchController.text.isNotEmpty) {
                final query = _searchController.text.toLowerCase();
                jobs = jobs.where((j) =>
                    j.title.toLowerCase().contains(query) ||
                    j.companyName.toLowerCase().contains(query) ||
                    j.city.toLowerCase().contains(query)).toList();
              }
              
              if (_filterCity != null && _filterCity!.isNotEmpty) {
                jobs = jobs.where((j) => j.city == _filterCity).toList();
              }
              if (_filterEducation != null && _filterEducation!.isNotEmpty) {
                if (_filterEducation == 'Vacib deyil') {
                  jobs = jobs.where((j) => j.educationLevel == null || j.educationLevel == 'Vacib deyil').toList();
                } else {
                  jobs = jobs.where((j) => j.educationLevel == _filterEducation).toList();
                }
              }
              if (_filterExperience != null && _filterExperience!.isNotEmpty) {
                if (_filterExperience == 'Təcrübəsiz') {
                  jobs = jobs.where((j) => j.experienceLevel == null || j.experienceLevel == 'Təcrübəsiz').toList();
                } else {
                  jobs = jobs.where((j) => j.experienceLevel == _filterExperience).toList();
                }
              }
              if (_filterSalaryRange != null && _filterSalaryRange!.isNotEmpty) {
                jobs = jobs.where((j) {
                  final salary = (j.salaryMax ?? j.salaryMin).toDouble();
                  if (_filterSalaryRange == '0-500') return salary <= 500;
                  if (_filterSalaryRange == '500-1000') return salary > 500 && salary <= 1000;
                  if (_filterSalaryRange == '1000-2000') return salary > 1000 && salary <= 2000;
                  if (_filterSalaryRange == '2000+') return salary > 2000;
                  return true;
                }).toList();
              }

          if (_selectedSortMode == 'newest') {
            jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          } else if (_selectedSortMode == 'salary') {
            jobs.sort((a, b) {
              final aSalary = (a.salaryMax ?? a.salaryMin);
              final bSalary = (b.salaryMax ?? b.salaryMin);
              return bSalary.compareTo(aSalary);
            });
          } else if (_selectedSortMode == 'location' && _userPosition != null) {
            jobs.sort((a, b) {
              final distA = Geolocator.distanceBetween(
                _userPosition!.latitude, _userPosition!.longitude,
                a.latitude, a.longitude
              );
              final distB = Geolocator.distanceBetween(
                _userPosition!.latitude, _userPosition!.longitude,
                b.latitude, b.longitude
              );
              return distA.compareTo(distB);
            });
          } else {
             jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }

          return CustomScrollView(
            slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            'İş axtarışı',
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
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search Bar & Filter Button
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.inputFillColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (val) {
                              _saveSearchTerm(val);
                              _searchFocusNode.unfocus();
                            },
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Vəzifə, şirkət və ya şəhər...',
                              hintStyle: TextStyle(
                                color: context.textHintColor,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: context.textHintColor,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.close, size: 20),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: (_filterSalaryRange != null || _filterEducation != null || _filterCity != null || _filterExperience != null)
                              ? AppTheme.primaryColor
                              : context.scaffoldBackgroundColor,
                          border: Border.all(
                            color: (_filterSalaryRange != null || _filterEducation != null || _filterCity != null || _filterExperience != null)
                                ? AppTheme.primaryColor
                                : context.dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          onPressed: _showDetailedFilterOptions,
                          icon: Icon(
                            Icons.tune_rounded,
                            color: (_filterSalaryRange != null || _filterEducation != null || _filterCity != null || _filterExperience != null)
                                ? Colors.white
                                : context.textPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ListenableBuilder(
                    listenable: _searchFocusNode,
                    builder: (context, _) {
                      if (_searchFocusNode.hasFocus && _searchHistory.isNotEmpty && _searchController.text.isEmpty) {
                        return Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Son axtarışlar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimaryColor,
                                    ),
                                  ),
                                  if (_searchHistory.isNotEmpty)
                                    InkWell(
                                      onTap: () async {
                                        final prefs = await SharedPreferences.getInstance();
                                        await prefs.remove('searchHistory');
                                        setState(() => _searchHistory.clear());
                                      },
                                      child: const Text(
                                        'Təmizlə',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.errorColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _searchHistory.map((term) {
                                  return InkWell(
                                    onTap: () {
                                      _searchController.text = term;
                                      _saveSearchTerm(term);
                                      _searchFocusNode.unfocus();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: context.inputFillColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.history, size: 14, color: context.textSecondaryColor),
                                          const SizedBox(width: 6),
                                          Text(
                                            term,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: context.textPrimaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'Kateqoriyalar',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
                SizedBox(
                  height: 95,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: JobCategories.all.length,
                    itemBuilder: (context, index) {
                      final cat = JobCategories.all[index];
                      final isSelected = _selectedCategory == cat.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory =
                                isSelected ? null : cat.id;
                          });
                        },
                        child: Container(
                          width: 75,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? cat.color
                                      : cat.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  cat.icon,
                                  color: isSelected
                                      ? Colors.white
                                      : cat.color,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? cat.color
                                      : context.textSecondaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Job Type Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Hamısı', null),
                    _buildFilterChip('Tam gün', 'fullTime'),
                    _buildFilterChip('Yarım gün', 'partTime'),
                    _buildFilterChip('Günlük', 'daily'),
                    _buildFilterChip('Saatlıq', 'hourly'),
                    _buildFilterChip('Təcili 🔥', 'urgent'),
                    _buildFilterChip('Freelance', 'freelance'),
                  ],
                ),
              ),
            ),
          ),

          // Job Count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${jobs.length} elan tapıldı',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showSortOptions,
                    icon: const Icon(Icons.sort_rounded, size: 18),
                    label: const Text('Sırala'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Job List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final job = jobs[index];
                return JobListCard(
                  job: job,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobDetailScreen(job: job),
                      ),
                    );
                  },
                );
              },
              childCount: jobs.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? type) {
    final isSelected = _selectedJobType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedJobType = isSelected ? null : type);
        },
        backgroundColor: context.scaffoldBackgroundColor,
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.12),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : context.textSecondaryColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                : context.dividerColor,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildApplicationsPage() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return const Center(child: Text('Daxil olun'));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Müraciətlərim',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Göndərdiyiniz müraciətlər burada görünəcək',
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<ApplicationModel>>(
                stream: ApplicationsRepository().getApplicantApplications(currentUserId),
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
                            Icons.assignment_outlined,
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
                          const SizedBox(height: 8),
                          Text(
                            'Elanlara baxıb müraciət edə bilərsiniz',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textHintColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: applications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final app = applications[index];
                      // Fetch job details for displaying name and company
                      if (app.jobId.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('jobs').doc(app.jobId).get(),
                        builder: (ctx, jobSnapshot) {
                          if (!jobSnapshot.hasData) return const SizedBox.shrink();
                          
                          final jobData = jobSnapshot.data!.data() as Map<String, dynamic>?;
                          if (jobData == null) return const SizedBox.shrink();

                          String title = jobData['title'] ?? 'Bilinməyən Elan';
                          String company = jobData['companyName'] ?? 'Bilinməyən Şirkət';
                          String contactPhone = jobData['contactPhone'] ?? '';
                          bool allowCall = jobData['allowCallIfAccepted'] ?? true;

                          Color statusColor = AppTheme.warningColor;
                          String statusText = 'Müraciətiniz gözləmədədir';
                          IconData statusIcon = Icons.hourglass_top_rounded;

                          if (app.status == 'accepted') {
                            statusColor = AppTheme.successColor;
                            statusText = 'Müraciətiniz qəbul olundu';
                            statusIcon = Icons.check_circle_rounded;
                          } else if (app.status == 'rejected') {
                            statusColor = AppTheme.errorColor;
                            statusText = 'Müraciətiniz rədd edildi';
                            statusIcon = Icons.cancel_rounded;
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(statusIcon, color: statusColor, size: 24),
                                ),
                                const SizedBox(width: 16),
                                // Details
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
                                      const SizedBox(height: 2),
                                      Text(
                                        company,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: context.textSecondaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('dd MMM yyyy').format(app.appliedAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.textHintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Status badge
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    if (app.status == 'accepted') ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          if (contactPhone.isNotEmpty && allowCall)
                                            InkWell(
                                            onTap: () async {
                                              final Uri url = Uri(scheme: 'tel', path: contactPhone);
                                              try {
                                                await launchUrl(url);
                                              } catch (e) {
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
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () async {
                                              try {
                                                final employerDoc = await FirebaseFirestore.instance.collection('users').doc(app.employerId).get();
                                                final employerName = employerDoc.data()?['fullName'] ?? 'İşəgötürən';
 
                                                final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
                                                final seekerName = userDoc.data()?['fullName'] ?? 'Namizəd';
 
                                                final chatId = await ChatRepository().createOrGetChat(
                                                  employerId: app.employerId,
                                                  jobSeekerId: currentUserId,
                                                  jobId: app.jobId,
                                                  jobTitle: title,
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
                                                        otherUserId: app.employerId,
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
                                      )
                                    ]
                                  ],
                                ),
                              ],
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
      ),
    );
  }
}
