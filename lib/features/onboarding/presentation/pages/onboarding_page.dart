import 'package:animate_do/animate_do.dart';
import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';
import 'package:emlakmaster_mobile/core/services/login_entry_store.dart';
import 'package:emlakmaster_mobile/core/services/onboarding_store.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/login_entry_persona.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/widgets/auth_entry_persona_selector.dart';
import 'package:emlakmaster_mobile/features/onboarding/domain/onboarding_copy.dart';
import 'package:emlakmaster_mobile/features/onboarding/domain/onboarding_slide_model.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/widgets/onboarding_ui_mockups.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

/// İlk açılış tanıtımı — ürün panelleri ve özelliklerini vurgular.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.initialPage = 0});

  /// Test veya derin link ile belirli slayttan başlatma.
  final int initialPage;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _pageController;
  late int _currentPage;
  LoginEntryPersona? _persona;
  String? _personaHint;

  List<OnboardingSlideModel> _slides(BuildContext context) =>
      buildOnboardingSlides(AppLocalizations.of(context));

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAlreadyCompleted();
      _loadPersona();
      _logSlideView(_currentPage);
    });
  }

  Future<void> _loadPersona() async {
    final saved = await LoginEntryStore.instance.loadPersona();
    if (mounted && saved != null) {
      setState(() => _persona = saved);
    }
  }

  Future<void> _checkAlreadyCompleted() async {
    if (!mounted) return;
    if (OnboardingStore.instance.completedSync) {
      context.go(AppRouter.routeLogin);
    }
  }

  void _logSlideView(int index) {
    if (!mounted) return;
    final slides = _slides(context);
    if (index < 0 || index >= slides.length) return;
    final slide = slides[index];
    AnalyticsService.instance.logEvent(
      AnalyticsEvents.onboardingSlideView,
      {
        AnalyticsEvents.paramSlideIndex: index,
        AnalyticsEvents.paramSlideId: slide.analyticsId,
      },
    );
  }

  Future<void> _complete({required bool skipped}) async {
    if (!skipped && _persona == null) {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _personaHint = l10n.t('onboarding_persona_required');
      });
      return;
    }

    final slides = _slides(context);

    if (_persona != null) {
      await LoginEntryStore.instance.setPersona(_persona!);
    }

    AppFeedback.mediumImpact();
    await OnboardingStore.instance.setCompleted();

    if (skipped) {
      AnalyticsService.instance.logEvent(
        AnalyticsEvents.onboardingSkip,
        {
          AnalyticsEvents.paramSkippedAtIndex: _currentPage,
          AnalyticsEvents.paramSlideId: slides[_currentPage].analyticsId,
          if (_persona != null)
            AnalyticsEvents.paramPersona: _persona!.id,
        },
      );
    } else {
      AnalyticsService.instance.logEvent(
        AnalyticsEvents.onboardingComplete,
        {
          AnalyticsEvents.paramSlideIndex: _currentPage,
          AnalyticsEvents.paramSlideId: slides[_currentPage].analyticsId,
          if (_persona != null)
            AnalyticsEvents.paramPersona: _persona!.id,
        },
      );
    }

    if (!mounted) return;
    context.go(AppRouter.routeLogin);
  }

  Future<void> _onPersonaSelected(LoginEntryPersona persona) async {
    setState(() {
      _persona = persona;
      _personaHint = null;
    });
    await LoginEntryStore.instance.setPersona(persona);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    final slides = _slides(context);
    final isLast = _currentPage >= slides.length - 1;
    if (isLast) {
      _complete(skipped: false);
      return;
    }
    _pageController.nextPage(
      duration: DesignTokens.durationNormal,
      curve: Curves.easeOutCubic,
    );
  }

  Color _accentForSlide(OnboardingSlideModel slide, AppThemeExtension ext) {
    if (slide.accent != null) return slide.accent!;
    if (_persona == LoginEntryPersona.consultant &&
        slide.visual == OnboardingVisualKind.messagesOfficeReady) {
      return Color.lerp(ext.brandPrimary, ext.info, 0.45)!;
    }
    return ext.brandPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    final slides = _slides(context);
    final slide = slides[_currentPage];
    final accent = _accentForSlide(slide, ext);
    final isLast = _currentPage >= slides.length - 1;

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
              _buildTopBar(context, ext, l10n, slides.length),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) {
                    setState(() => _currentPage = i);
                    _logSlideView(i);
                  },
                  itemCount: slides.length,
                  itemBuilder: (context, index) {
                    final s = slides[index];
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
              if (isLast) _buildPersonaPicker(ext, accent),
              _buildIndicators(ext, accent, slides.length),
              _buildButton(ext, accent, isLast, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AppThemeExtension ext,
    AppLocalizations l10n,
    int slideCount,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
      child: Row(
        children: [
          if (_currentPage > 0)
            IconButton(
              onPressed: () {
                AppFeedback.selectionClick();
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
              l10n.tArgs('onboarding_page_of', [
                '${_currentPage + 1}',
                '$slideCount',
              ]),
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
            onPressed: () => _complete(skipped: true),
            style: TextButton.styleFrom(
              foregroundColor: ext.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              l10n.t('onboarding_skip'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaPicker(AppThemeExtension ext, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthEntryPersonaSelector(
            selected: _persona,
            onSelected: _onPersonaSelected,
            compact: true,
          ),
          if (_personaHint != null) ...[
            const SizedBox(height: DesignTokens.space2),
            Text(
              _personaHint!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ext.danger.withValues(alpha: 0.95),
                fontSize: DesignTokens.fontSizeSm,
              ),
            ),
          ],
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

  Widget _buildIndicators(AppThemeExtension ext, Color accent, int slideCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          slideCount,
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

  Widget _buildButton(
    AppThemeExtension ext,
    Color accent,
    bool isLast,
    AppLocalizations l10n,
  ) {
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
          label: isLast ? l10n.t('onboarding_finish') : l10n.t('onboarding_next'),
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
              isLast ? l10n.t('onboarding_finish') : l10n.t('onboarding_next'),
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
