import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/onboarding/tour_target.dart';
import 'package:emlakmaster_mobile/features/onboarding/presentation/tour/coach_mark_tour.dart';
import 'package:flutter/material.dart';

/// Danışman kabuğunun tüm ana ekranlarını gezen kapsamlı tur adımları.
/// [tabIndex] değerleri `ConsultantShellPage` `pages` indeksleridir:
/// 0=Günüm, 1=Çağrılar, 2=Müşteriler, 5=Görevler, 6=Ayarlar.
/// Hedefi o an ekranda olmayan adımlar tur tarafından zarifçe atlanır.
List<CoachMarkStep> buildConsultantTourSteps(AppLocalizations l10n) {
  return [
    CoachMarkStep(
      tabIndex: 0,
      targetId: TourTargetId.gunumCommandDeck,
      icon: Icons.dashboard_rounded,
      title: l10n.t('tour_csl_gunum_title'),
      body: l10n.t('tour_csl_gunum_body'),
    ),
    CoachMarkStep(
      tabIndex: 0,
      targetId: TourTargetId.gunumQuickAccess,
      icon: Icons.grid_view_rounded,
      title: l10n.t('tour_csl_quick_title'),
      body: l10n.t('tour_csl_quick_body'),
    ),
    CoachMarkStep(
      tabIndex: 2,
      targetId: TourTargetId.customersHeader,
      icon: Icons.people_rounded,
      title: l10n.t('tour_csl_customers_title'),
      body: l10n.t('tour_csl_customers_body'),
    ),
    CoachMarkStep(
      tabIndex: 1,
      targetId: TourTargetId.callsHeader,
      icon: Icons.call_rounded,
      title: l10n.t('tour_csl_calls_title'),
      body: l10n.t('tour_csl_calls_body'),
    ),
    CoachMarkStep(
      tabIndex: 5,
      targetId: TourTargetId.tasksHeader,
      icon: Icons.task_alt_rounded,
      title: l10n.t('tour_csl_tasks_title'),
      body: l10n.t('tour_csl_tasks_body'),
    ),
    CoachMarkStep(
      targetId: TourTargetId.shellBottomNav,
      icon: Icons.dashboard_customize_rounded,
      title: l10n.t('tour_csl_nav_title'),
      body: l10n.t('tour_csl_nav_body'),
    ),
    CoachMarkStep(
      tabIndex: 6,
      targetId: TourTargetId.settingsHeader,
      icon: Icons.settings_rounded,
      title: l10n.t('title_settings'),
      body: l10n.t('tour_csl_settings_body'),
    ),
  ];
}
