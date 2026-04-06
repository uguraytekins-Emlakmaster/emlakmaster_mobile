import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Cmd+K (veya Ctrl+K) ile açılan Smart Command Palette.
/// Yazarken sayfa komutları ve müşteri araması yapar.
class CommandPalette {
  static void show(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ext.popoverBackground,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => _CommandPaletteContent(
          scrollController: scrollController,
          onClose: () => Navigator.pop(ctx),
        ),
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
      ref.read(mainShellShortcutProvider.notifier).state = shortcut;
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Sayfa veya müşteri ara...',
                hintStyle: TextStyle(color: ext.foregroundMuted),
                prefixIcon:
                    Icon(Icons.search_rounded, color: ext.foregroundSecondary),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: ext.inputBackground,
              ),
              style: TextStyle(color: ext.inputForeground),
            ),
          ),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (filteredActions.isNotEmpty) ...[
                  Text('Sayfalar',
                      style:
                          TextStyle(color: ext.foregroundMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  ...filteredActions.map((action) => _ActionTile(
                        icon: action.icon,
                        label: action.label,
                        onTap: () => onActionTap(action),
                      )),
                  const SizedBox(height: 16),
                ],
                if (_query.length >= 2 &&
                    !FeaturePermission.seesClientPanel(role)) ...[
                  Text('Müşteriler',
                      style:
                          TextStyle(color: ext.foregroundMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirestoreService.customersStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
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
                      final docs = snapshot.data!.docs;
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
                          padding: const EdgeInsets.all(16),
                          child: Text('Müşteri bulunamadı',
                              style: TextStyle(
                                  color: ext.foregroundMuted, fontSize: 13)),
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
    const _PaletteAction.shortcut(
      label: 'Dashboard',
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
          label: 'Çağrılar',
          icon: Icons.call_rounded,
          shortcut: MainShellShortcut.openCallsTab,
        ),
        const _PaletteAction.shortcut(
          label: 'Müşteriler',
          icon: Icons.people_rounded,
          shortcut: MainShellShortcut.openCustomersTab,
        ),
        const _PaletteAction.shortcut(
          label: 'İlanlar',
          icon: Icons.home_work_rounded,
          shortcut: MainShellShortcut.openListingsTab,
        ),
        const _PaletteAction.shortcut(
          label: 'Takip',
          icon: Icons.replay_rounded,
          shortcut: MainShellShortcut.openFollowUpTab,
        ),
        const _PaletteAction.shortcut(
          label: 'Görevler',
          icon: Icons.task_alt_rounded,
          shortcut: MainShellShortcut.openTasksTab,
        ),
      ],
      if (FeaturePermission.seesAdminPanel(role)) ...[
        const _PaletteAction.route(
          label: 'Ofis yönetimi',
          icon: Icons.groups_rounded,
          route: AppRouter.routeOfficeAdmin,
        ),
        const _PaletteAction.route(
          label: 'Ofis daveti oluştur',
          icon: Icons.vpn_key_outlined,
          route: AppRouter.routeOfficeInviteCreate,
        ),
        if (FeaturePermission.canViewAllCalls(role))
          const _PaletteAction.route(
            label: 'Çağrı Merkezi',
            icon: Icons.call_rounded,
            route: AppRouter.routeCommandCenter,
          ),
        const _PaletteAction.route(
          label: 'War Room',
          icon: Icons.military_tech_rounded,
          route: AppRouter.routeWarRoom,
        ),
        const _PaletteAction.route(
          label: 'Broker Command',
          icon: Icons.business_center_rounded,
          route: AppRouter.routeBrokerCommand,
        ),
      ],
    ],
    const _PaletteAction.shortcut(
      label: 'Ayarlar',
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
      leading: Icon(icon, color: ext.accent),
      title: Text(label, style: TextStyle(color: ext.popoverForeground)),
      onTap: onTap,
    );
  }
}
