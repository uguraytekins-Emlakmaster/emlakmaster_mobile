import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter/material.dart';
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

class _CommandPaletteContent extends StatefulWidget {
  const _CommandPaletteContent({
    required this.scrollController,
    required this.onClose,
  });
  final ScrollController scrollController;
  final VoidCallback onClose;

  @override
  State<_CommandPaletteContent> createState() => _CommandPaletteContentState();
}

class _CommandPaletteContentState extends State<_CommandPaletteContent> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  static const List<({String label, IconData icon})> _actions = [
    (label: 'Dashboard', icon: Icons.dashboard_rounded),
    (label: 'Ofis yönetimi', icon: Icons.groups_rounded),
    (label: 'Ofis daveti oluştur', icon: Icons.vpn_key_outlined),
    (label: 'Çağrı Merkezi', icon: Icons.call_rounded),
    (label: 'War Room', icon: Icons.military_tech_rounded),
    (label: 'Broker Command', icon: Icons.business_center_rounded),
    (label: 'Müşteriler', icon: Icons.people_rounded),
    (label: 'İlanlar', icon: Icons.home_work_rounded),
    (label: 'Ayarlar', icon: Icons.settings_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _query = _controller.text.trim().toLowerCase()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
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
    final filteredActions = _query.isEmpty
        ? _actions
        : _actions.where((a) => a.label.toLowerCase().contains(_query)).toList();

    void onActionTap(int index) {
      final a = filteredActions[index];
      if (a.label == 'Ofis yönetimi') {
        context.push(AppRouter.routeOfficeAdmin);
      } else if (a.label == 'Ofis daveti oluştur') {
        context.push(AppRouter.routeOfficeInviteCreate);
      } else if (a.label == 'Çağrı Merkezi') {
        context.push(AppRouter.routeCommandCenter);
      } else if (a.label == 'War Room') {
        context.push(AppRouter.routeWarRoom);
      } else if (a.label == 'Broker Command') {
        context.push(AppRouter.routeBrokerCommand);
      } else {
        context.go(AppRouter.routeHome);
      }
      widget.onClose();
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
                prefixIcon: Icon(Icons.search_rounded, color: ext.foregroundSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  Text('Sayfalar', style: TextStyle(color: ext.foregroundMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  ...filteredActions.asMap().entries.map((e) => _ActionTile(
                        icon: e.value.icon,
                        label: e.value.label,
                        onTap: () => onActionTap(e.key),
                      )),
                  const SizedBox(height: 16),
                ],
                if (_query.length >= 2) ...[
                  Text('Müşteriler', style: TextStyle(color: ext.foregroundMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirestoreService.customersStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: DesignTokens.primary))),
                        );
                      }
                      final docs = snapshot.data!.docs;
                      final q = _query.replaceAll(RegExp(r'\s'), '');
                      final filtered = docs.where((d) {
                        final data = d.data();
                        final name = (data['fullName'] as String? ?? data['customerIntent'] as String? ?? '').toLowerCase();
                        final phone = (data['primaryPhone'] as String? ?? data['phone'] as String? ?? '').replaceAll(RegExp(r'\s'), '');
                        final email = (data['email'] as String? ?? '').toLowerCase();
                        return name.contains(_query) || email.contains(_query) ||
                            (q.isNotEmpty && phone.replaceAll(RegExp(r'\D'), '').contains(q.replaceAll(RegExp(r'\D'), '')));
                      }).take(8).toList();
                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Müşteri bulunamadı', style: TextStyle(color: ext.foregroundMuted, fontSize: 13)),
                        );
                      }
                      return Column(
                        children: filtered.map((d) {
                          final id = d.id;
                          final data = d.data();
                          final name = data['fullName'] as String? ?? data['customerIntent'] as String? ?? 'İsimsiz';
                          return _ActionTile(
                            icon: Icons.person_rounded,
                            label: name,
                            onTap: () {
                              context.push(AppRouter.routeCustomerDetail.replaceFirst(':id', id));
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return ListTile(
      leading: Icon(icon, color: DesignTokens.primary),
      title: Text(label, style: TextStyle(color: ext.popoverForeground)),
      onTap: onTap,
    );
  }
}
