import 'package:flutter/material.dart';

/// Tanıtım slaytı görsel türü — her biri uygulama arayüzü önizlemesi çizer.
enum OnboardingVisualKind {
  welcome,
  multiPlatform,
  managerWorkspace,
  consultantWorkspace,
  callsAndMeetings,
  marketAndListings,
  messagesOfficeReady,
}

/// İlk açılış tanıtım slaytı verisi.
class OnboardingSlideModel {
  const OnboardingSlideModel({
    required this.analyticsId,
    required this.title,
    required this.subtitle,
    required this.highlights,
    required this.visual,
    this.accent,
    this.assetPath,
  });

  /// Analytics `slide_id` parametresi.
  final String analyticsId;
  final String title;
  final String subtitle;

  /// Kısa özellik etiketleri (slayt altında chip olarak).
  final List<String> highlights;
  final OnboardingVisualKind visual;

  /// Slayta özel vurgu rengi; null ise tema marka rengi.
  final Color? accent;

  /// İsteğe bağlı ekran görüntüsü (`assets/onboarding/…`). Yoksa kod mock’u gösterilir.
  final String? assetPath;
}

/// Tanıtım artık kod mock’ları kullanır; PNG yolu verilmez.
const Map<OnboardingVisualKind, List<String>> kOnboardingLegacyAssetPaths = {};
