import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../profile/presentation/pages/profile_screen.dart';

class AppOnboardingScreen extends StatefulWidget {
  final bool isEmployer;
  const AppOnboardingScreen({super.key, required this.isEmployer});

  @override
  State<AppOnboardingScreen> createState() => _AppOnboardingScreenState();
}

class _AppOnboardingScreenState extends State<AppOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingItem> get _items => widget.isEmployer
      ? [
          OnboardingItem(
            title: 'İşçi Tapmağın Ən Sürətli Yolu',
            description:
                'Vakansiyanızı asanlıqla yaradın və minlərlə potensial namizədə dərhal çatdırın. 1 dəqiqədə pulsuz elan yerləşdirin.',
            icon: Icons.post_add_rounded,
          ),
          OnboardingItem(
            title: 'Müraciətləri Asanlıqla İdarə Edin',
            description:
                'Gələn bütün CV-ləri və müraciətləri tək paneldən rahatlıqla izləyin, statuslarını dəyişin və dəyərləndirin.',
            icon: Icons.assignment_ind_rounded,
          ),
          OnboardingItem(
            title: 'Namizədlərlə Birbaşa Əlaqə',
            description:
                'Tətbiq daxili mesajlaşma sistemi və ya birbaşa zənglə namizədlərlə sürətli əlaqə qurun.',
            icon: Icons.chat_rounded,
          ),
          OnboardingItem(
            title: 'Profilinizi Tamamlayın',
            description:
                'Şirkət məlumatlarınızı və logonuzu əlavə edərək daha çox namizədin etibarını qazanın və müraciət sayını artırın.',
            icon: Icons.business_rounded,
            isProfile: true,
          ),
        ]
      : [
          OnboardingItem(
            title: 'Sənə Özəl İşlər',
            description:
                'İşçi AI sənin bacarıqlarını, təcrübəni və istəklərini analiz edərək, minlərlə elan arasından yalnız sənə uyğun olanları tapır.',
            icon: Icons.search_rounded,
            isAi: true,
          ),
          OnboardingItem(
            title: 'Xəritədə Kəşf Et',
            description:
                'Evindən uzağa getmək istəmirsən? Xəritə funksiyası ilə sənə ən yaxın iş yerlərini gör və dərhal müraciət et.',
            icon: Icons.map_rounded,
          ),
          OnboardingItem(
            title: 'Profilini Gücləndir',
            description:
                'İşəgötürənlərin diqqətini çəkmək üçün profilini tam doldur. AI sənə peşəkar bio və CV hazırlamaqda kömək edəcək.',
            icon: Icons.person_rounded,
            isProfile: true,
          ),
        ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildImage(item),
                        const SizedBox(height: 40),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: context.textSecondaryColor,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppTheme.primaryColor
                              : context.textHintColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                      ),
                      child: Text(
                        _isLastPage ? 'Profilimi Doldur' : 'Növbəti',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (!_isLastPage)
                    const SizedBox(
                      height: 16,
                    ), // Placeholder for layout stability
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(OnboardingItem item) {
    if (item.isAi) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(30),
        child: Image.asset('assets/images/AiLogo.png', fit: BoxFit.contain),
      );
    }

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(item.icon, size: 80, color: AppTheme.primaryColor),
    );
  }

  bool get _isLastPage => _currentPage == _items.length - 1;

  Future<void> _onNext() async {
    if (_currentPage == _items.length - 1) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding_v2', true);

      if (!mounted) return;

      // Pop the onboarding screen and return true to indicate "Fill Profile" was clicked
      Navigator.of(context).pop(true);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onSkip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding_v2', true);
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final bool isAi;
  final bool isProfile;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    this.isAi = false,
    this.isProfile = false,
  });
}
