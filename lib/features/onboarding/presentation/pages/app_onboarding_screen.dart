import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';

const _kBg       = Color(0xFF07070F);
const _kAccent   = Color(0xFF5B5FEF);
const _kAccent2  = Color(0xFF38BDF8);
const _kSurface  = Color(0xFF12121F);
const _kBorder   = Color(0xFF1E1E32);

class AppOnboardingScreen extends StatefulWidget {
  final bool isEmployer;
  const AppOnboardingScreen({super.key, required this.isEmployer});

  @override
  State<AppOnboardingScreen> createState() => _AppOnboardingScreenState();
}

class _AppOnboardingScreenState extends State<AppOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _entryCtrl;
  late final AnimationController _iconCtrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _entryCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _iconCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entryCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  List<OnboardingItem> get _items => widget.isEmployer
      ? [
          OnboardingItem(
            title: 'İşçi Tapmağın\nƏn Sürətli Yolu',
            description:
                'Vakansiyanızı asanlıqla yaradın və minlərlə potensial namizədə dərhal çatdırın. 1 dəqiqədə pulsuz elan yerləşdirin.',
            icon: Icons.post_add_rounded,
            color: _kAccent,
          ),
          OnboardingItem(
            title: 'Müraciətləri\nAsanlıqla İdarə Edin',
            description:
                'Gələn bütün CV-ləri və müraciətləri tək paneldən rahatlıqla izləyin, statuslarını dəyişin.',
            icon: Icons.assignment_ind_rounded,
            color: const Color(0xFF10B981),
          ),
          OnboardingItem(
            title: 'Namizədlərlə\nBirbaşa Əlaqə',
            description:
                'Tətbiq daxili mesajlaşma sistemi və ya birbaşa zənglə namizədlərlə sürətli əlaqə qurun.',
            icon: Icons.chat_rounded,
            color: _kAccent2,
          ),
          OnboardingItem(
            title: 'Profilinizi\nTamamlayın',
            description:
                'Şirkət məlumatlarınızı əlavə edərək daha çox namizədin etibarını qazanın.',
            icon: Icons.business_rounded,
            color: const Color(0xFFFF6D00),
            isProfile: true,
          ),
        ]
      : [
          OnboardingItem(
            title: 'Sənə Özəl\nİşlər',
            description:
                'İşçi AI sənin bacarıqlarını analiz edərək minlərlə elan arasından yalnız sənə uyğun olanları tapır.',
            icon: Icons.auto_awesome_rounded,
            color: _kAccent,
            isAi: true,
          ),
          OnboardingItem(
            title: 'Xəritədə\nKəşf Et',
            description:
                'Xəritə funksiyası ilə sənə ən yaxın iş yerlərini gör və dərhal müraciət et.',
            icon: Icons.map_rounded,
            color: const Color(0xFF10B981),
          ),
          OnboardingItem(
            title: 'Profilini\nGücləndir',
            description:
                'İşəgötürənlərin diqqətini çəkmək üçün profilini tam doldur. AI sənə peşəkar bio hazırlamaqda kömək edəcək.',
            icon: Icons.person_rounded,
            color: _kAccent2,
            isProfile: true,
          ),
        ];

  bool get _isLastPage => _currentPage == _items.length - 1;

  Future<void> _onNext() async {
    if (_isLastPage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding_v2', true);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _onSkip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding_v2', true);
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Subtle bg glow
          Positioned(
            top: -100, right: -60,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: _kAccent.withOpacity(0.06),
                  blurRadius: 150, spreadRadius: 60)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page counter
                      Text(
                        '${_currentPage + 1}/${_items.length}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      if (!_isLastPage)
                        GestureDetector(
                          onTap: _onSkip,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Text('Keç',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                        )
                      else
                        const SizedBox(width: 60),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _buildPage(item);
                    },
                  ),
                ),

                // Bottom controls
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Icon card
          AnimatedBuilder(
            animation: _iconCtrl,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, -6 + _iconCtrl.value * 12),
              child: child,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow
                Container(
                  width: 180, height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: item.color.withOpacity(0.2),
                      blurRadius: 60, spreadRadius: 10)],
                  ),
                ),
                // Card
                Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    color: _kSurface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.color.withOpacity(0.25), width: 1.5),
                  ),
                  child: item.isAi
                      ? Padding(
                          padding: const EdgeInsets.all(36),
                          child: Image.asset('assets/images/AiLogo.png',
                              fit: BoxFit.contain),
                        )
                      : Icon(item.icon, size: 70, color: item.color),
                ),
              ],
            ),
          ),

          const Spacer(flex: 1),

          // Text block
          Column(
            children: [
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: [Colors.white, item.color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(b),
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w800,
                    color: Colors.white, height: 1.2, letterSpacing: -0.8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.4),
                  height: 1.65),
              ),
            ],
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
      child: Column(
        children: [
          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_items.length, (i) {
              final isActive = _currentPage == i;
              final color = _items[i].color;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? color
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isActive
                      ? [BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 8)]
                      : [],
                ),
              );
            }),
          ),
          const SizedBox(height: 28),

          // CTA button
          _OnboardingButton(
            label: _isLastPage ? 'Profilimi Doldur' : 'Növbəti',
            color: _items[_currentPage].color,
            onTap: _onNext,
          ),
        ],
      ),
    );
  }
}

// ── Onboarding Button ─────────────────────────────────────────────

class _OnboardingButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OnboardingButton({
    required this.label, required this.color, required this.onTap});

  @override
  State<_OnboardingButton> createState() => _OnboardingButtonState();
}

class _OnboardingButtonState extends State<_OnboardingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 100),
    lowerBound: 0.96, upperBound: 1.0, value: 1.0,
  );

  @override
  void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { HapticFeedback.mediumImpact(); _press.reverse(); },
      onTapUp: (_) { _press.forward(); widget.onTap(); },
      onTapCancel: () => _press.forward(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) => Transform.scale(scale: _press.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 56, width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color, widget.color.withOpacity(0.7)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4),
                blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Center(
            child: Text(widget.label,
              style: const TextStyle(
                color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}

// ── Data Model ────────────────────────────────────────────────────

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isAi;
  final bool isProfile;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isAi = false,
    this.isProfile = false,
  });
}