import 'package:emlakmaster_mobile/core/onboarding/tour_target.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/tour/coach_mark_tour.dart';
import 'package:flutter/material.dart';

/// Yönetici / admin kabuğunun tüm ana ekranlarını gezen kapsamlı tur adımları.
///
/// Admin kabuğundaki sekme indeksleri özellik bayraklarına göre dinamiktir
/// (Savaş Odası, Çağrı Merkezi, Ekonomi koşullu). Bu yüzden adımlar sekme
/// indeksini sabit tutmaz; çağıran [tabIndexForKey] ile sekme **anahtarından**
/// (enum `.name`) o anki indeksi çözer. Sekme yoksa (indeks < 0) ilgili adım
/// turdan çıkarılır. Hedefi o an ekranda olmayan adımlar zaten tur tarafından
/// zarifçe atlanır.
List<CoachMarkStep> buildManagerTourSteps(
  int Function(String tabKey) tabIndexForKey,
) {
  final dashboardIndex = tabIndexForKey('dashboard');
  final messagesIndex = tabIndexForKey('messages');
  final warRoomIndex = tabIndexForKey('warRoom');
  final commandCenterIndex = tabIndexForKey('commandCenter');
  final reportsIndex = tabIndexForKey('reports');
  final settingsIndex = tabIndexForKey('settings');

  return <CoachMarkStep>[
    CoachMarkStep(
      tabIndex: dashboardIndex >= 0 ? dashboardIndex : null,
      targetId: TourTargetId.managerCommandDeck,
      icon: Icons.dashboard_rounded,
      title: 'Yönetici Paneli',
      body: 'Ofisinin komuta merkezine hoş geldin. Buradan ofis sağlığını, '
          'ekip aktivitesini ve operasyonu tek panelden yönetirsin.',
    ),
    CoachMarkStep(
      tabIndex: dashboardIndex >= 0 ? dashboardIndex : null,
      targetId: TourTargetId.managerOfficeMomentum,
      icon: Icons.speed_rounded,
      title: 'Ofis momentumu',
      body: 'Günlük ofis performansını ve temel göstergeleri tek bakışta '
          'buradan görürsün.',
    ),
    CoachMarkStep(
      tabIndex: dashboardIndex >= 0 ? dashboardIndex : null,
      targetId: TourTargetId.managerOperations,
      icon: Icons.bolt_rounded,
      title: 'Operasyonel müdahale',
      body: 'Gerçek kuyruklar, ekip sinyalleri ve akıllı görev önerileri '
          'burada toplanır; müdahale gereken yerlere hızla yönelirsin.',
    ),
    CoachMarkStep(
      tabIndex: messagesIndex >= 0 ? messagesIndex : null,
      targetId: TourTargetId.messagesHeader,
      icon: Icons.forum_rounded,
      title: 'Mesaj Merkezi',
      body: 'Ekip sohbeti canlı; harici kanallar bağlandığında müşteri '
          'mesajları da burada toplanır.',
    ),
    if (warRoomIndex >= 0)
      CoachMarkStep(
        tabIndex: warRoomIndex,
        targetId: TourTargetId.managerWarRoom,
        icon: Icons.military_tech_rounded,
        title: 'Komuta Odası',
        body: 'Savaş Odası: kritik operasyon müdahale merkezi. Riskli '
            'durumlar ve canlandırma fırsatları burada önceliklenir.',
      ),
    if (commandCenterIndex >= 0)
      CoachMarkStep(
        tabIndex: commandCenterIndex,
        targetId: TourTargetId.managerCommandCenter,
        icon: Icons.call_rounded,
        title: 'Çağrı Merkezi',
        body: 'Ofis genelindeki tüm görüşme kayıtları burada. Tarihe göre '
            'sırala, filtrele ve menüden CSV olarak dışa aktar.',
      ),
    if (reportsIndex >= 0)
      CoachMarkStep(
        tabIndex: reportsIndex,
        targetId: TourTargetId.managerReports,
        icon: Icons.analytics_rounded,
        title: 'Raporlar',
        body: 'Yönetici raporları ve içgörü yüzeyleri tek navigasyon altında '
            'toplanır; performansı buradan derinlemesine incelersin.',
      ),
    const CoachMarkStep(
      targetId: TourTargetId.shellBottomNav,
      icon: Icons.dashboard_customize_rounded,
      title: 'Panel menüsü',
      body: 'Bölümler arasında buradan geçersin: Komuta Merkezi, Mesaj '
          'Merkezi, raporlar ve ayarlar tek dokunuş uzağında.',
    ),
    CoachMarkStep(
      tabIndex: settingsIndex >= 0 ? settingsIndex : null,
      targetId: TourTargetId.settingsHeader,
      icon: Icons.settings_rounded,
      title: 'Ayarlar',
      body: 'Ofis ve şirket ayarları, entegrasyonlar ve hesap güvenliği '
          'burada. Bu turu istediğin zaman "Turu tekrar göster" ile yeniden '
          'başlatabilirsin.',
    ),
  ];
}
