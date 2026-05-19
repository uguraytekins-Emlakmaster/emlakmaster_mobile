import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_feed_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Cmd+K (veya Ctrl+K) ile açılan Smart Command Palette.
/// Yazarken sayfa komutları ve müşteri araması yapar.
class CommandPalette {
  static void show(BuildContext context) {
    showPremiumDraggableBottomSheet<void>(
      context: context,
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      builder: (ctx, scrollController) => _CommandPaletteContent(
        scrollController: scrollController,
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }
}

class _CommandPaletteContent extends ConsumerStatefulWidget {
  const _CommandPaletteContent({
    required this.scrollController,
    required this.onClose,
  });
  final ScrollController scrollController;
  final VoidCallback onClose;

  @override
  ConsumerState<_CommandPaletteContent> createState() =>
      _CommandPaletteContentState();
}

class _CommandPaletteContentState
    extends ConsumerState<_CommandPaletteContent> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(
        () => setState(() => _query = _controller.text.trim().toLowerCase()));
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
    final filteredActions = _filteredActionsFor(role, _query);

    void goHomeWithShortcut(MainShellShortcut shortcut) {
      ref.read(mainShellShortcutProvider.notifier).enqueue(shortcut);
      context.go(AppRouter.routeHome);
      widget.onClose();
    }

    void onActionTap(_PaletteAction action) {
      switch (action.kind) {
        case _PaletteActionKind.route:
          final route = action.route;
          if (route != null) context.push(route);
          widget.onClose();
        case _PaletteActionKind.homeShortcut:
          final shortcut = action.shortcut;
          if (shortcut != null) {
            goHomeWithShortcut(shortcut);
          }
      }
    }

    return SafeArea(
      child: Column(
        children: [
          const PremiumBottomSheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space5,
              DesignTokens.space2,
              DesignTokens.space5,
              DesignTokens.space3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.bolt_outlined,
                  size: DesignTokens.iconLg,
                  color: ext.accent.withValues(alpha: 0.5),
                ),
                const SizedBox(width: DesignTokens.space3),
                const Expanded(
                  child: PremiumSheetHeader(
                    compact: true,
                    title: 'Hızlı Erişim',
                    subtitle: 'Alan, sayfa ya da müşteri arayın',
                  ),
                ),
                IconButton(
                  tooltip: 'Kapat',
                  style: IconButton.styleFrom(
                    foregroundColor: ext.textTertiary,
                  ),
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: DesignTokens.space5),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Alan, sayfa ya da müşteri ara...',
                hintStyle: AppTypography.body(context)
                    .copyWith(color: ext.foregroundMuted),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: ext.textSecondary,
                  size: DesignTokens.iconMd,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                filled: true,
                fillColor: ext.inputBackground,
              ),
              style: AppTypography.bodyStrong(context)
                  .copyWith(color: ext.inputForeground),
            ),
          ),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: DesignTokens.space5),
              children: [
                if (filteredActions.isNotEmpty) ...[
                  Text('Alanlar',
                      style: AppTypography.sectionLabel(context)
                          .copyWith(color: ext.foregroundMuted)),
                  const SizedBox(height: DesignTokens.space2),
                  ...filteredActions.map((action) => _ActionTile(
                        icon: action.icon,
                        label: action.label,
                        onTap: () => onActionTap(action),
                      )),
                  const SizedBox(height: DesignTokens.space4),
                ],
                if (_query.length >= 2 &&
                    !FeaturePermission.seesClientPanel(role)) ...[
                  Text('Müşteriler',
                      style: AppTypography.sectionLabel(context)
                          .copyWith(color: ext.foregroundMuted)),
                  const SizedBox(height: DesignTokens.space2),
                  Builder(
                    builder: (context) {
                      final customersAsync =
                          ref.watch(officeCustomersSnapshotProvider);
                      if (!customersAsync.hasValue) {
                        return Padding(
                          padding: const EdgeInsets.all(DesignTokens.space4),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(color: ext.accent),
                            ),
                          ),
                        );
                      }
                      final docs = customersAsync.requireValue.docs;
                      final q = _query.replaceAll(RegExp(r'\s'), '');
                      final filtered = docs
                          .where((d) {
                            final data = d.data();
                            final name = (data['fullName'] as String? ??
                                    data['customerIntent'] as String? ??
                                    '')
                                .toLowerCase();
                            final phone = (data['primaryPhone'] as String? ??
                                    data['phone'] as String? ??
                                    '')
                                .replaceAll(RegExp(r'\s'), '');
                            final email =
                                (data['email'] as String? ?? '').toLowerCase();
                            return name.contains(_query) ||
                                email.contains(_query) ||
                                (q.isNotEmpty &&
                                    phone
                                        .replaceAll(RegExp(r'\D'), '')
                                        .contains(
                                            q.replaceAll(RegExp(r'\D'), '')));
                          })
                          .take(8)
                          .toList();
                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(DesignTokens.space4),
                          child: Text(
                            'Eşleşen müşteri yok',
                            style: AppTypography.body(context)
                                .copyWith(color: ext.textTertiary),
                          ),
                        );
                      }
                      return Column(
                        children: filtered.map((d) {
                          final id = d.id;
                          final data = d.data();
                          final name = data['fullName'] as String? ??
                              data['customerIntent'] as String? ??
                              'İsimsiz';
                          return _ActionTile(
                            icon: Icons.person_rounded,
                            label: name,
                            onTap: () {
                              context.push(AppRouter.routeCustomerDetail
                                  .replaceFirst(':id', id));
                              widget.onClose();
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _PaletteActionKind { route, homeShortcut }

String _paletteHomeShortcutLabel(AppRole role) {
  if (FeaturePermission.seesClientPanel(role)) return 'Keşfet';
  if (FeaturePermission.seesAdminPanel(role)) {
    return ProductLabels.managerHome;
  }
  return ProductLabels.consultantHome;
}

class _PaletteAction {
  const _PaletteAction.route({
    required this.label,
    required this.icon,
    required this.route,
  })  : kind = _PaletteActionKind.route,
        shortcut = null;

  const _PaletteAction.shortcut({
    required this.label,
    required this.icon,
    required this.shortcut,
  })  : kind = _PaletteActionKind.homeShortcut,
        route = null;

  final String label;
  final IconData icon;
  final _PaletteActionKind kind;
  final String? route;
  final MainShellShortcut? shortcut;
}

List<_PaletteAction> _filteredActionsFor(AppRole role, String query) {
  final all = <_PaletteAction>[
    _PaletteAction.shortcut(
      label: _paletteHomeShortcutLabel(role),
      icon: Icons.dashboard_rounded,
      shortcut: MainShellShortcut.openHomeTab,
    ),
    if (FeaturePermission.seesClientPanel(role)) ...[
      const _PaletteAction.shortcut(
        label: 'Favoriler',
        icon: Icons.favorite_rounded,
        shortcut: MainShellShortcut.openFavoritesTab,
      ),
      const _PaletteAction.shortcut(
        label: 'Mesajlar',
        icon: Icons.chat_rounded,
        shortcut: MainShellShortcut.openMessagesTab,
      ),
      const _PaletteAction.shortcut(
        label: 'Sanal Tur',
        icon: Icons.video_camera_back_rounded,
        shortcut: MainShellShortcut.openVirtualTourTab,
      ),
    ] else ...[
      if (!FeaturePermission.seesAdminPanel(role)) ...[
        const _PaletteAction.shortcut(
          label: ProductLabels.myCalls,
          icon: Icons.call_rounded,
          shortcut: MainShellShortcut.openCallsTab,
        ),
        const _PaletteAction.shortcut(
          label: ProductLabels.myCustomers,
          icon: Icons.people_rounded,
          shortcut: MainShellShortcut.openCustomersTab,
        ),
        const _PaletteAction.shortcut(
          label: ProductLabels.listings,
          icon: Icons.home_work_rounded,
          shortcut: MainShellShortcut.openListingsTab,
        ),
        const _PaletteAction.shortcut(
          label: ProductLabels.followUp,
          icon: Icons.replay_rounded,
          shortcut: MainShellShortcut.openFollowUpTab,
        ),
        const _PaletteAction.shortcut(
          label: ProductLabels.myTasks,
          icon: Icons.task_alt_rounded,
          shortcut: MainShellShortcut.openTasksTab,
        ),
      ],
      if (FeaturePermission.seesAdminPanel(role)) ...[
        const _PaletteAction.route(
          label: ProductLabels.officeDesk,
          icon: Icons.groups_rounded,
          route: AppRouter.routeOfficeAdmin,
        ),
        const _PaletteAction.route(
          label: ProductLabels.officeInvite,
          icon: Icons.vpn_key_outlined,
          route: AppRouter.routeOfficeInviteCreate,
        ),
        if (FeaturePermission.canViewAllCalls(role))
          const _PaletteAction.route(
            label: ProductLabels.callCenter,
            icon: Icons.call_rounded,
            route: AppRouter.routeCommandCenter,
          ),
        const _PaletteAction.route(
          label: ProductLabels.warRoom,
          icon: Icons.military_tech_rounded,
          route: AppRouter.routeWarRoom,
        ),
        const _PaletteAction.route(
          label: ProductLabels.operationsDeck,
          icon: Icons.business_center_rounded,
          route: AppRouter.routeBrokerCommand,
        ),
      ],
    ],
    if (!FeaturePermission.seesClientPanel(role))
      const _PaletteAction.shortcut(
        label: ProductLabels.messageCenter,
        icon: Icons.forum_rounded,
        shortcut: MainShellShortcut.openMessageCenterTab,
      ),
    const _PaletteAction.shortcut(
      label: ProductLabels.settings,
      icon: Icons.settings_rounded,
      shortcut: MainShellShortcut.openAccountTab,
    ),
  ];
  if (query.isEmpty) return all;
  return all.where((a) => a.label.toLowerCase().contains(query)).toList();
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space2,
        vertical: DesignTokens.space1,
      ),
      minLeadingWidth: 40,
      leading: Icon(
        icon,
        color: ext.textSecondary,
        size: DesignTokens.iconMd,
      ),
      title: Text(
        label,
        style:
            AppTypography.bodyStrong(context).copyWith(color: ext.textPrimary),
      ),
      onTap: onTap,
    );
  }
}
