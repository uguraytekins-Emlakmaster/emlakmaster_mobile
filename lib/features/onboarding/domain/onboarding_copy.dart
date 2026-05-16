import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/features/onboarding/domain/onboarding_slide_model.dart';

/// Tanıtım slaytları — metinler [AppLocalizations] üzerinden (TR/EN + diğer dillerde EN yedeği).
List<OnboardingSlideModel> buildOnboardingSlides(AppLocalizations l10n) {
  return [
    OnboardingSlideModel(
      analyticsId: 'welcome',
      title: l10n.t('onboarding_welcome_title'),
      subtitle: l10n.t('onboarding_welcome_subtitle'),
      highlights: _split(l10n.t('onboarding_welcome_highlights')),
      visual: OnboardingVisualKind.welcome,
    ),
    OnboardingSlideModel(
      analyticsId: 'multi_platform',
      title: l10n.t('onboarding_platform_title'),
      subtitle: l10n.t('onboarding_platform_subtitle'),
      highlights: _split(l10n.t('onboarding_platform_highlights')),
      visual: OnboardingVisualKind.multiPlatform,
    ),
    OnboardingSlideModel(
      analyticsId: 'manager_workspace',
      title: l10n.t('onboarding_manager_title'),
      subtitle: l10n.t('onboarding_manager_subtitle'),
      highlights: _split(l10n.t('onboarding_manager_highlights')),
      visual: OnboardingVisualKind.managerWorkspace,
      assetPath: 'assets/onboarding/manager_command.png',
    ),
    OnboardingSlideModel(
      analyticsId: 'consultant_workspace',
      title: l10n.t('onboarding_consultant_title'),
      subtitle: l10n.t('onboarding_consultant_subtitle'),
      highlights: _split(l10n.t('onboarding_consultant_highlights')),
      visual: OnboardingVisualKind.consultantWorkspace,
      assetPath: 'assets/onboarding/consultant_gunum.png',
    ),
    OnboardingSlideModel(
      analyticsId: 'calls_meetings',
      title: l10n.t('onboarding_calls_title'),
      subtitle: l10n.t('onboarding_calls_subtitle'),
      highlights: _split(l10n.t('onboarding_calls_highlights')),
      visual: OnboardingVisualKind.callsAndMeetings,
      assetPath: 'assets/onboarding/smart_calls.png',
    ),
    OnboardingSlideModel(
      analyticsId: 'market_listings',
      title: l10n.t('onboarding_market_title'),
      subtitle: l10n.t('onboarding_market_subtitle'),
      highlights: _split(l10n.t('onboarding_market_highlights')),
      visual: OnboardingVisualKind.marketAndListings,
      assetPath: 'assets/onboarding/market_listings.png',
    ),
    OnboardingSlideModel(
      analyticsId: 'office_ready',
      title: l10n.t('onboarding_office_title'),
      subtitle: l10n.t('onboarding_office_subtitle'),
      highlights: _split(l10n.t('onboarding_office_highlights')),
      visual: OnboardingVisualKind.messagesOfficeReady,
      assetPath: 'assets/onboarding/office_messages.png',
    ),
  ];
}

List<String> _split(String pipeSeparated) {
  return pipeSeparated
      .split('|')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
