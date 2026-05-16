import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:emlakmaster_mobile/features/onboarding/domain/onboarding_copy.dart';
import 'package:emlakmaster_mobile/features/onboarding/domain/onboarding_slide_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildOnboardingSlides', () {
    test('returns seven slides with stable analytics ids', () {
      final l10n = AppLocalizations(const Locale('tr'));
      final slides = buildOnboardingSlides(l10n);

      expect(slides, hasLength(7));
      expect(
        slides.map((s) => s.analyticsId).toList(),
        [
          'welcome',
          'multi_platform',
          'manager_workspace',
          'consultant_workspace',
          'calls_meetings',
          'market_listings',
          'office_ready',
        ],
      );
    });

    test('splits pipe-separated highlights', () {
      final l10n = AppLocalizations(const Locale('tr'));
      final welcome = buildOnboardingSlides(l10n).first;

      expect(welcome.highlights, isNotEmpty);
      expect(welcome.highlights.every((h) => !h.contains('|')), isTrue);
    });

    test('English locale uses EN copy', () {
      final l10n = AppLocalizations(const Locale('en'));
      final welcome = buildOnboardingSlides(l10n).first;

      expect(welcome.title, contains('Welcome'));
      expect(welcome.visual, OnboardingVisualKind.welcome);
    });

    test('multi-platform slide uses multiPlatform visual', () {
      final l10n = AppLocalizations(const Locale('tr'));
      final platform = buildOnboardingSlides(l10n)[1];

      expect(platform.analyticsId, 'multi_platform');
      expect(platform.visual, OnboardingVisualKind.multiPlatform);
    });
  });
}
