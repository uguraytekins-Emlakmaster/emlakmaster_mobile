import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:flutter/material.dart';

/// Tek kaynak — rol-farkındalıklı, GERÇEK ulaşılabilir hedefler. Her hedef ya bir
/// kabuk sekmesi kısayolu (shell-aware) ya da gerçek bir tam sayfa rotasıdır.
/// Uydurma hedef, ölü kısayol veya role uygun olmayan rota YOK; yetkisiz alanlar
/// dürüstçe listeden çıkarılır (sessiz omission). Bu katalog hem komut paletini
/// hem de gelecekteki quick-jump yüzeylerini besler (mantık tek yerde).
enum AppDestinationNav { shortcut, route }

@immutable
class AppDestination {
  const AppDestination._({
    required this.id,
    required this.label,
    required this.icon,
    required this.nav,
    this.shortcut,
    this.route,
  });

  const AppDestination.shortcut({
    required String id,
    required String label,
    required IconData icon,
    required MainShellShortcut shortcut,
  }) : this._(
          id: id,
          label: label,
          icon: icon,
          nav: AppDestinationNav.shortcut,
          shortcut: shortcut,
        );

  const AppDestination.route({
    required String id,
    required String label,
    required IconData icon,
    required String route,
  }) : this._(
          id: id,
          label: label,
          icon: icon,
          nav: AppDestinationNav.route,
          route: route,
        );

  final String id;
  final String label;
  final IconData icon;
  final AppDestinationNav nav;

  /// Kabuk sekmesi kısayolu (nav == shortcut).
  final MainShellShortcut? shortcut;

  /// Tam sayfa rota (nav == route).
  final String? route;
}

/// [role] için ulaşılabilir hedefler — yalnızca gerçek + yetki dahilindekiler.
List<AppDestination> appDestinationsFor(AppRole role, AppLocalizations l10n) {
  final isAdmin = FeaturePermission.seesAdminPanel(role);

  final out = <AppDestination>[
    AppDestination.shortcut(
      id: 'home',
      label: _homeLabel(role, l10n),
      icon: Icons.dashboard_rounded,
      shortcut: MainShellShortcut.openHomeTab,
    ),
  ];

  if (isAdmin) {
    out.addAll([
      AppDestination.route(
        id: 'office_admin',
        label: l10n.t('office_desk'),
        icon: Icons.groups_rounded,
        route: AppRouter.routeOfficeAdmin,
      ),
      AppDestination.route(
        id: 'office_invite',
        label: l10n.t('office_invite'),
        icon: Icons.vpn_key_outlined,
        route: AppRouter.routeOfficeInviteCreate,
      ),
    ]);
    // Komuta Merkezi / Komuta Odası admin kabuğunda gerçek sekmedir → shell-aware
    // kısayol (standalone push yarı-mount riski yok). Yalnızca yetki varsa.
    if (FeaturePermission.canViewAllCalls(role)) {
      out.add(AppDestination.shortcut(
        id: 'command_center',
        label: l10n.t('nav_call_center'),
        icon: Icons.call_rounded,
        shortcut: MainShellShortcut.openCallsTab,
      ));
    }
    if (FeaturePermission.canViewWarRoom(role)) {
      out.add(AppDestination.shortcut(
        id: 'war_room',
        label: l10n.t('nav_war_room'),
        icon: Icons.military_tech_rounded,
        shortcut: MainShellShortcut.openListingsTab,
      ));
    }
    out.add(AppDestination.route(
      id: 'operations_deck',
      label: l10n.t('ops_deck'),
      icon: Icons.business_center_rounded,
      route: AppRouter.routeBrokerCommand,
    ));
  } else {
    // Danışman kabuğu sekmeleri.
    out.addAll([
      AppDestination.shortcut(
        id: 'my_calls',
        label: l10n.t('nav_calls'),
        icon: Icons.call_rounded,
        shortcut: MainShellShortcut.openCallsTab,
      ),
      AppDestination.shortcut(
        id: 'my_customers',
        label: l10n.t('nav_customers'),
        icon: Icons.people_rounded,
        shortcut: MainShellShortcut.openCustomersTab,
      ),
      AppDestination.shortcut(
        id: 'listings',
        label: l10n.t('nav_listings'),
        icon: Icons.home_work_rounded,
        shortcut: MainShellShortcut.openListingsTab,
      ),
      AppDestination.shortcut(
        id: 'follow_up',
        label: l10n.t('nav_followup'),
        icon: Icons.replay_rounded,
        shortcut: MainShellShortcut.openFollowUpTab,
      ),
      AppDestination.shortcut(
        id: 'my_tasks',
        label: l10n.t('nav_tasks'),
        icon: Icons.task_alt_rounded,
        shortcut: MainShellShortcut.openTasksTab,
      ),
    ]);
  }

  out.add(AppDestination.shortcut(
    id: 'message_center',
    label: l10n.t('nav_messages'),
    icon: Icons.forum_rounded,
    shortcut: MainShellShortcut.openMessageCenterTab,
  ));

  out.add(AppDestination.shortcut(
    id: 'settings',
    label: l10n.t('nav_settings'),
    icon: Icons.settings_rounded,
    shortcut: MainShellShortcut.openAccountTab,
  ));

  return out;
}

/// Etiket/arama eşleşmesi (önceden hesaplanmış lowercase sorgu ile).
List<AppDestination> filterDestinations(
  List<AppDestination> destinations,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return destinations;
  return destinations
      .where((d) => d.label.toLowerCase().contains(q))
      .toList(growable: false);
}

String _homeLabel(AppRole role, AppLocalizations l10n) {
  if (FeaturePermission.seesAdminPanel(role)) return l10n.t('nav_home_manager');
  return l10n.t('nav_home_consultant');
}
