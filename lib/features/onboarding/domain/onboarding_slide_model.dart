import 'package:flutter/material.dart';

/// Tanıtım slaytı görsel türü — her biri uygulama arayüzü önizlemesi çizer.
enum OnboardingVisualKind {
  welcome,
  managerWorkspace,
  consultantWorkspace,
  callsAndMeetings,
  marketAndListings,
  messagesOfficeReady,
}

/// İlk açılış tanıtım slaytı verisi.
class OnboardingSlideModel {
  const OnboardingSlideModel({
    required this.title,
    required this.subtitle,
    required this.highlights,
    required this.visual,
    this.accent,
    this.assetPath,
  });

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

/// Ürün özelliklerine göre tanıtım akışı (sıra önemli).
const List<OnboardingSlideModel> kOnboardingSlides = [
  OnboardingSlideModel(
    title: 'EmlakMaster\'a hoş geldiniz',
    subtitle:
        'Gayrimenkul operasyonunuz tek platformda: yönetici komuta masası ve danışman saha paneli aynı ekosistemde.',
    highlights: ['Yönetici Paneli', 'Danışman Paneli', 'Tek hesap'],
    visual: OnboardingVisualKind.welcome,
  ),
  OnboardingSlideModel(
    title: 'Yönetici: komuta ve görünürlük',
    subtitle:
        'Komuta Merkezi özetleri, Komuta Odası canlı durum, Çağrı Merkezi ve Raporlar ile ekibi ve performansı izleyin.',
    highlights: [
      'Komuta Merkezi',
      'Komuta Odası',
      'Çağrı Merkezi',
      'Raporlar',
    ],
    visual: OnboardingVisualKind.managerWorkspace,
    assetPath: 'assets/onboarding/manager_command.png',
  ),
  OnboardingSlideModel(
    title: 'Danışman: Günüm ve saha akışı',
    subtitle:
        'Günüm ekranından güne başlayın; müşteriler, ilanlar, takip ve görevler tek çalışma alanında.',
    highlights: [
      'Günüm',
      'Müşterilerim',
      'İlanlar',
      'Takip',
      'Görevlerim',
    ],
    visual: OnboardingVisualKind.consultantWorkspace,
    assetPath: 'assets/onboarding/consultant_gunum.png',
  ),
  OnboardingSlideModel(
    title: 'Akıllı görüşme ve çağrılar',
    subtitle:
        'Çağrılarım, görüşme sonrası kayıt ve yönetici çağrı merkezi ile her temas izlenebilir; Akıllı Görüşme ile hızlı arama.',
    highlights: [
      'Akıllı Görüşme',
      'Çağrılarım',
      'Görüşme özeti',
      'Çağrı Merkezi',
    ],
    visual: OnboardingVisualKind.callsAndMeetings,
    assetPath: 'assets/onboarding/smart_calls.png',
  ),
  OnboardingSlideModel(
    title: 'Piyasa, ilan ve içgörü',
    subtitle:
        'İlan portföyünüzü yönetin; bölge içgörüsü ve analitik raporlarla piyasa nabzını takip edin.',
    highlights: [
      'İlanlar',
      'Bölge içgörüsü',
      'Analitik',
      'İçe aktarma',
    ],
    visual: OnboardingVisualKind.marketAndListings,
    assetPath: 'assets/onboarding/market_listings.png',
  ),
  OnboardingSlideModel(
    title: 'Ofis, mesajlar ve hazırsınız',
    subtitle:
        'Ofis oluşturun veya katılın; Mesaj Merkezi ve senkron ile ekip uyumlu çalışsın. Girişte rolünüzü seçerek başlayın.',
    highlights: [
      'Ofis masası',
      'Mesaj Merkezi',
      'Senkron',
      'Rol seçimi',
    ],
    visual: OnboardingVisualKind.messagesOfficeReady,
    assetPath: 'assets/onboarding/office_messages.png',
  ),
];

/// Eski dosya adları (geriye uyum); yeni PNG yoksa bunlar da denenir.
const Map<OnboardingVisualKind, List<String>> kOnboardingLegacyAssetPaths = {
  OnboardingVisualKind.managerWorkspace: [
    'assets/onboarding/crm_dashboard.png',
    'assets/onboarding/war_room.png',
  ],
  OnboardingVisualKind.consultantWorkspace: [
    'assets/onboarding/crm_dashboard.png',
  ],
  OnboardingVisualKind.callsAndMeetings: [
    'assets/onboarding/ai_insights.png',
  ],
  OnboardingVisualKind.marketAndListings: [
    'assets/onboarding/market_analytics.png',
  ],
  OnboardingVisualKind.messagesOfficeReady: [
    'assets/onboarding/war_room.png',
  ],
};
