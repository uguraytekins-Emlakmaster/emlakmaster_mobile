import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
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
  AppLocalizations l10n,
  int Function(String tabKey) tabIndexForKey,
) {
  final dashboardIndex = tabIndexForKey('dashboard');
  final warRoomIndex = tabIndexForKey('warRoom');
  final commandCenterIndex = tabIndexForKey('commandCenter');
  final reportsIndex = tabIndexForKey('reports');
  final settingsIndex = tabIndexForKey('settings');

  return <CoachMarkStep>[
    CoachMarkStep(
      tabIndex: dashboardIndex >= 0 ? dashboardIndex : null,
      targetId: TourTargetId.managerCommandDeck,
      icon: Icons.dashboard_rounded,
      title: l10n.t('tour_mgr_deck_title'),
      body: l10n.t('tour_mgr_deck_body'),
    ),
    CoachMarkStep(
      tabIndex: dashboardIndex >= 0 ? dashboardIndex : null,
      targetId: TourTargetId.managerOfficeMomentum,
      icon: Icons.speed_rounded,
      title: l10n.t('tour_mgr_momentum_title'),
      body: l10n.t('tour_mgr_momentum_body'),
    ),
    CoachMarkStep(
      tabIndex: dashboardIndex >= 0 ? dashboardIndex : null,
      targetId: TourTargetId.managerOperations,
      icon: Icons.bolt_rounded,
      title: l10n.t('tour_mgr_operations_title'),
      body: l10n.t('tour_mgr_operations_body'),
    ),
    if (warRoomIndex >= 0)
      CoachMarkStep(
        tabIndex: warRoomIndex,
        targetId: TourTargetId.managerWarRoom,
        icon: Icons.military_tech_rounded,
        title: l10n.t('tour_mgr_warroom_title'),
        body: l10n.t('tour_mgr_warroom_body'),
      ),
    if (commandCenterIndex >= 0)
      CoachMarkStep(
        tabIndex: commandCenterIndex,
        targetId: TourTargetId.managerCommandCenter,
        icon: Icons.call_rounded,
        title: l10n.t('tour_mgr_callcenter_title'),
        body: l10n.t('tour_mgr_callcenter_body'),
      ),
    if (reportsIndex >= 0)
      CoachMarkStep(
        tabIndex: reportsIndex,
        targetId: TourTargetId.managerReports,
        icon: Icons.analytics_rounded,
        title: l10n.t('tour_mgr_reports_title'),
        body: l10n.t('tour_mgr_reports_body'),
      ),
    CoachMarkStep(
      targetId: TourTargetId.shellBottomNav,
      icon: Icons.dashboard_customize_rounded,
      title: l10n.t('tour_mgr_nav_title'),
      body: l10n.t('tour_mgr_nav_body'),
    ),
    CoachMarkStep(
      tabIndex: settingsIndex >= 0 ? settingsIndex : null,
      targetId: TourTargetId.settingsHeader,
      icon: Icons.settings_rounded,
      title: l10n.t('title_settings'),
      body: l10n.t('tour_mgr_settings_body'),
    ),
  ];
}
