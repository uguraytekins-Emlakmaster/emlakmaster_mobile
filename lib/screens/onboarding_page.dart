import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'dart:ui';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/onboarding_store.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
/// Onboarding asset paths (PNG/WebP, 1600x1600 or 2048x2048). Omit file to use premium placeholder.
const List<String> _onboardingImagePaths = [
  'assets/onboarding/crm_dashboard.png',
  'assets/onboarding/market_analytics.png',
  'assets/onboarding/ai_insights.png',
  'assets/onboarding/war_room.png',
];

/// İlk açılışta premium tanıtım; "Başla" ile tamamlanır, bir daha gösterilmez.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingSlideData> _slides = [
    _OnboardingSlideData(
      title: 'EmlakMaster\'a hoş geldiniz',
      subtitle: 'Tek ekrandan tüm operasyonlarınızı yönetin: CRM dashboard, War Room, çağrı merkezi ve raporlar. Profesyonel gayrimenkul yönetimi artık elinizin altında.',
      icon: Icons.dashboard_rounded,
    ),
    _OnboardingSlideData(
      title: 'Market Pulse & ilanlar',
      subtitle: 'Şehir seçin; sahibinden, emlakjet ve hepsi emlak ilanları otomatik çekilir. İlanları anlık güncelleyebilir, piyasa analitiği ile karar verebilirsiniz.',
      icon: Icons.show_chart_rounded,
    ),
    _OnboardingSlideData(
      title: 'Yapay zeka & analitik',
      subtitle: 'AI destekli öngörüler, portföy eşleştirme ve raporlarla daha akıllı kararlar alın. Verileriniz güçlü görselleştirmelerle sunulur.',
      icon: Icons.insights_rounded,
    ),
    _OnboardingSlideData(
      title: 'War Room & ekip merkezi',
      subtitle: 'Çağrı merkezi, müşteri takibi ve ekip koordinasyonu tek yerden. Gerçek zamanlı komuta merkezi ile her şeyi kontrol edin.',
      icon: Icons.military_tech_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAlreadyCompleted());
  }

  Future<void> _checkAlreadyCompleted() async {
    if (!mounted) return;
    if (OnboardingStore.instance.completedSync) {
      context.go(AppRouter.routeLogin);
    }
  }

  Future<void> _complete() async {
    HapticFeedback.mediumImpact();
    await OnboardingStore.instance.setCompleted();
    if (!mounted) return;
    context.go(AppRouter.routeLogin);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeExtension.of(context).background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppThemeExtension.of(context).background,
              AppThemeExtension.of(context).background,
              AppThemeExtension.of(context).accent.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    final imagePath = index < _onboardingImagePaths.length
                        ? _onboardingImagePaths[index]
                        : null;
                    return _OnboardingSlide(
                      key: ValueKey(index),
                      data: slide,
                      imagePath: imagePath,
                      isActive: _currentPage == index,
                    );
                  },
                ),
              ),
              _buildBottomIndicators(),
              _buildButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomIndicators() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _slides.length,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == i ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentPage == i
                  ? AppThemeExtension.of(context).accent
                  : AppThemeExtension.of(context).textTertiary.withValues(alpha: 0.5),
              boxShadow: _currentPage == i
                  ? [
                      BoxShadow(
                        color: AppThemeExtension.of(context).accent.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  void _onNext() {
    if (_currentPage >= _slides.length - 1) {
      _complete();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _buildButton() {
    final isLastPage = _currentPage >= _slides.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppThemeExtension.of(context).accent.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Semantics(
          button: true,
          label: isLastPage ? 'Onboardingi bitir ve başla' : 'Sonraki slayt',
          child: FilledButton(
            onPressed: _onNext,
            style: FilledButton.styleFrom(
              backgroundColor: AppThemeExtension.of(context).accent,
              foregroundColor: AppThemeExtension.of(context).onBrand,
              minimumSize: const Size(double.infinity, 56),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
            ),
            child: Text(
              isLastPage ? 'Başla' : 'İleri',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    super.key,
    required this.data,
    this.imagePath,
    required this.isActive,
  });

  final _OnboardingSlideData data;
  final String? imagePath;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minH = constraints.maxHeight;
        final visualH = (minH * 0.38).clamp(220.0, 360.0);
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minH),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeIn(
                    duration: const Duration(milliseconds: 280),
                    child: _buildVisualArea(context, visualH),
                  ),
                  const SizedBox(height: 28),
                  FadeInUp(
                    duration: const Duration(milliseconds: 280),
                    delay: const Duration(milliseconds: 80),
                    child: Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppThemeExtension.of(context).textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeInUp(
                    duration: const Duration(milliseconds: 280),
                    delay: const Duration(milliseconds: 120),
                    child: Text(
                      data.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppThemeExtension.of(context).textSecondary,
                        fontSize: 15,
                        height: 1.45,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisualArea(BuildContext context, double visualHeight) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
        child: Container(
          width: double.infinity,
          height: visualHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            boxShadow: [
              BoxShadow(
                color: AppThemeExtension.of(context).accent.withValues(alpha: 0.08),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppThemeExtension.of(context).surfaceElevated,
                AppThemeExtension.of(context).surface,
                AppThemeExtension.of(context).accent.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(
              color: AppThemeExtension.of(context).border.withValues(alpha: 0.8),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            child: _buildVisualContent(context, visualHeight),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualContent(BuildContext context, double height) {
    if (imagePath != null && imagePath!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            imagePath!,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _buildPlaceholderVisual(context, height),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppThemeExtension.of(context).surface.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return _buildPlaceholderVisual(context, height);
  }

  Widget _buildPlaceholderVisual(BuildContext context, double height) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: -20,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppThemeExtension.of(context).accent.withValues(alpha: 0.2),
                  AppThemeExtension.of(context).accent.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: height * 0.22,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppThemeExtension.of(context).surface,
              border: Border.all(
                color: AppThemeExtension.of(context).accent.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppThemeExtension.of(context).accent.withValues(alpha: 0.15),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Icon(
              data.icon,
              size: 48,
              color: AppThemeExtension.of(context).accent.withValues(alpha: 0.95),
            ),
          ),
        ),
        Positioned(
          left: 24,
          top: height * 0.32,
          child: const _FloatingCard(icon: Icons.analytics_rounded, label: 'Veri'),
        ),
        Positioned(
          right: 20,
          top: height * 0.38,
          child: const _FloatingCard(icon: Icons.trending_up_rounded, label: 'Trend'),
        ),
        Positioned(
          left: 32,
          bottom: height * 0.22,
          child: const _FloatingCard(icon: Icons.pie_chart_rounded, label: 'Rapor'),
        ),
        Positioned(
          right: 28,
          bottom: height * 0.28,
          child: const _FloatingCard(icon: Icons.insights_rounded, label: 'AI'),
        ),
      ],
    );
  }
}

class _FloatingCard extends StatelessWidget {
  const _FloatingCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 320),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppThemeExtension.of(context).surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          border: Border.all(color: AppThemeExtension.of(context).border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppThemeExtension.of(context).accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AppThemeExtension.of(context).textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
