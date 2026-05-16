import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/features/onboarding/domain/onboarding_slide_model.dart';
import 'package:flutter/material.dart';

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
      accent: const Color(0xFFD4AF37),
    ),
    OnboardingSlideModel(
      analyticsId: 'consultant_workspace',
      title: l10n.t('onboarding_consultant_title'),
      subtitle: l10n.t('onboarding_consultant_subtitle'),
      highlights: _split(l10n.t('onboarding_consultant_highlights')),
      visual: OnboardingVisualKind.consultantWorkspace,
      accent: const Color(0xFF5B9BD5),
    ),
    OnboardingSlideModel(
      analyticsId: 'calls_meetings',
      title: l10n.t('onboarding_calls_title'),
      subtitle: l10n.t('onboarding_calls_subtitle'),
      highlights: _split(l10n.t('onboarding_calls_highlights')),
      visual: OnboardingVisualKind.callsAndMeetings,
      accent: const Color(0xFF6BCB77),
    ),
    OnboardingSlideModel(
      analyticsId: 'market_listings',
      title: l10n.t('onboarding_market_title'),
      subtitle: l10n.t('onboarding_market_subtitle'),
      highlights: _split(l10n.t('onboarding_market_highlights')),
      visual: OnboardingVisualKind.marketAndListings,
      accent: const Color(0xFFB388FF),
    ),
    OnboardingSlideModel(
      analyticsId: 'office_ready',
      title: l10n.t('onboarding_office_title'),
      subtitle: l10n.t('onboarding_office_subtitle'),
      highlights: _split(l10n.t('onboarding_office_highlights')),
      visual: OnboardingVisualKind.messagesOfficeReady,
      accent: const Color(0xFFE8A87C),
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
