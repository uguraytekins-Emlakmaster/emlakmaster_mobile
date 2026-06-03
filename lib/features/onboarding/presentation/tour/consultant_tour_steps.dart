import 'package:emlakmaster_mobile/core/onboarding/tour_target.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/tour/coach_mark_tour.dart';
import 'package:flutter/material.dart';

/// Danışman kabuğunun tüm ana ekranlarını gezen kapsamlı tur adımları.
/// [tabIndex] değerleri `ConsultantShellPage` `pages` indeksleridir:
/// 0=Günüm, 1=Mesajlar, 2=Çağrılar, 3=Müşteriler, 6=Görevler, 7=Ayarlar.
/// Hedefi o an ekranda olmayan adımlar tur tarafından zarifçe atlanır.
List<CoachMarkStep> buildConsultantTourSteps() {
  return const [
    CoachMarkStep(
      tabIndex: 0,
      targetId: TourTargetId.gunumCommandDeck,
      icon: Icons.dashboard_rounded,
      title: 'Benim Günüm — komuta merkezi',
      body: 'Günlük özet, aciliyet sinyali ve müşteri baskısını tek bakışta '
          'buradan görürsün. Gün buradan başlar.',
    ),
    CoachMarkStep(
      tabIndex: 0,
      targetId: TourTargetId.gunumQuickAccess,
      icon: Icons.grid_view_rounded,
      title: 'Hızlı erişim',
      body: 'Müşteri, görev, ilan ve mesaj akışına tek dokunuşla geç.',
    ),
    CoachMarkStep(
      tabIndex: 3,
      targetId: TourTargetId.customersHeader,
      icon: Icons.people_rounded,
      title: 'Müşterilerim (CRM)',
      body: 'Müşteri portföyün burada. Üstteki "Müşteri ekle" ile yeni kayıt '
          'aç; arama, teklif ve takip buradan ilerler.',
    ),
    CoachMarkStep(
      tabIndex: 2,
      targetId: TourTargetId.callsHeader,
      icon: Icons.call_rounded,
      title: 'Çağrılarım',
      body: 'Son aramalar, geri dönülmesi gerekenler ve hızlı arama burada. '
          'Kayıttan tek dokunuşla müşteriyi ararsın.',
    ),
    CoachMarkStep(
      tabIndex: 6,
      targetId: TourTargetId.tasksHeader,
      icon: Icons.task_alt_rounded,
      title: 'Görevlerim',
      body: 'Geciken ve bugünkü görevlerin önceliklenmiş halde. Yeni görev '
          'ekleyip müşteriye bağlayabilirsin.',
    ),
    CoachMarkStep(
      tabIndex: 1,
      targetId: TourTargetId.messagesHeader,
      icon: Icons.forum_rounded,
      title: 'Mesaj Merkezi',
      body: 'Ekip sohbeti canlı; harici kanallar bağlandığında müşteri '
          'mesajları da burada toplanır.',
    ),
    CoachMarkStep(
      targetId: TourTargetId.shellBottomNav,
      icon: Icons.dashboard_customize_rounded,
      title: 'Alt menü',
      body: 'Bölümler arasında buradan geçersin. "Daha Fazla" altında ilan '
          'portföyü, takip ve ayarlar gibi ekranlar yer alır.',
    ),
    CoachMarkStep(
      tabIndex: 7,
      targetId: TourTargetId.settingsHeader,
      icon: Icons.settings_rounded,
      title: 'Ayarlar',
      body: 'Tema, dil ve plan ayarları burada. Bu turu istediğin zaman '
          '"Turu tekrar göster" ile yeniden başlatabilirsin.',
    ),
  ];
}
