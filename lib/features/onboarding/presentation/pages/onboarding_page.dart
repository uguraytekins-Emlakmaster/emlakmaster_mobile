import 'package:animate_do/animate_do.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/onboarding_store.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/onboarding/domain/onboarding_slide_model.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/widgets/onboarding_ui_mockups.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// İlk açılış tanıtımı — ürün panelleri ve özelliklerini vurgular.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _slides = kOnboardingSlides;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkAlreadyCompleted());
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

  void _onNext() {
    if (_currentPage >= _slides.length - 1) {
      _complete();
    } else {
      _pageController.nextPage(
        duration: DesignTokens.durationNormal,
        curve: Curves.easeOutCubic,
      );
    }
  }

  Color _accentForSlide(OnboardingSlideModel slide, AppThemeExtension ext) {
    return slide.accent ?? ext.brandPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final slide = _slides[_currentPage];
    final accent = _accentForSlide(slide, ext);

    return Scaffold(
      backgroundColor: ext.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ext.background,
              Color.lerp(ext.background, accent, 0.06)!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(context, ext),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final s = _slides[index];
                    final slideAccent = _accentForSlide(s, ext);
                    return _OnboardingSlideView(
                      key: ValueKey(s.visual),
                      slide: s,
                      accent: slideAccent,
                    );
                  },
                ),
              ),
              _buildHighlights(slide, accent, ext),
              _buildIndicators(ext, accent),
              _buildButton(ext, accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppThemeExtension ext) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
      child: Row(
        children: [
          if (_currentPage > 0)
            IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                _pageController.previousPage(
                  duration: DesignTokens.durationNormal,
                  curve: Curves.easeOutCubic,
                );
              },
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: ext.textSecondary),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              '${_currentPage + 1} / ${_slides.length}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ext.textTertiary,
                fontSize: DesignTokens.fontSizeSm,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          TextButton(
            onPressed: _complete,
            style: TextButton.styleFrom(
              foregroundColor: ext.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text(
              'Atla',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights(
    OnboardingSlideModel slide,
    Color accent,
    AppThemeExtension ext,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: slide.highlights
            .map(
              (h) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                  border: Border.all(color: accent.withValues(alpha: 0.28)),
                ),
                child: Text(
                  h,
                  style: TextStyle(
                    color: ext.textPrimary,
                    fontSize: DesignTokens.fontSizeXs,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildIndicators(AppThemeExtension ext, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _slides.length,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == i ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentPage == i
                  ? accent
                  : ext.textTertiary.withValues(alpha: 0.45),
              boxShadow: _currentPage == i
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
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

  Widget _buildButton(AppThemeExtension ext, Color accent) {
    final isLast = _currentPage >= _slides.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Semantics(
          button: true,
          label: isLast ? 'Tanıtımı bitir ve girişe geç' : 'Sonraki slayt',
          child: FilledButton(
            onPressed: _onNext,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: ext.onBrand,
              minimumSize: const Size(double.infinity, 56),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
            ),
            child: Text(
              isLast ? 'Girişe geç' : 'İleri',
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

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({
    super.key,
    required this.slide,
    required this.accent,
  });

  final OnboardingSlideModel slide;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final visualHeight = (constraints.maxHeight * 0.48).clamp(200.0, 320.0);
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 8),
            child: Column(
              children: [
                SizedBox(
                  height: visualHeight,
                  child: FadeIn(
                    duration: const Duration(milliseconds: 320),
                    child: OnboardingSlideVisual(
                      kind: slide.visual,
                      accent: accent,
                      assetPath: slide.assetPath,
                      legacyAssetPaths:
                          kOnboardingLegacyAssetPaths[slide.visual] ?? const [],
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.space6),
                FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  delay: const Duration(milliseconds: 60),
                  child: Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ext.textPrimary,
                      fontSize: DesignTokens.fontSize2xl,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.space3),
                FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    slide.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ext.textSecondary,
                      fontSize: DesignTokens.fontSizeMd,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
