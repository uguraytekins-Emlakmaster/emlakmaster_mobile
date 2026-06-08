import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/navigation/app_destinations.dart';
import 'package:emlakmaster_mobile/core/navigation/shell_navigator.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
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
    final premium = PremiumThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
    final filteredActions =
        filterDestinations(appDestinationsFor(role, l10n), _query);

    void onActionTap(AppDestination destination) {
      ShellNavigator.openDestination(context, destination);
      widget.onClose();
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
                  color: premium.champagneGold,
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: PremiumSheetHeader(
                    compact: true,
                    title: l10n.t('cmd_quick_access_title'),
                    subtitle: l10n.t('cmd_quick_access_subtitle'),
                  ),
                ),
                IconButton(
                  tooltip: l10n.t('action_close'),
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
                hintText: l10n.t('cmd_search_hint'),
                hintStyle: AppTypography.body(context)
                    .copyWith(color: ext.foregroundMuted),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: premium.champagneGoldMuted,
                  size: DesignTokens.iconMd,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  borderSide: BorderSide(
                    color: premium.glassBorder.withValues(alpha: 0.35),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  borderSide: BorderSide(
                    color: premium.glassBorder.withValues(alpha: 0.28),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  borderSide: BorderSide(
                    color: premium.champagneGold.withValues(alpha: 0.55),
                  ),
                ),
                filled: true,
                fillColor: premium.glassSurface.withValues(alpha: 0.65),
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
                  Text(l10n.t('cmd_section_areas'),
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
                    FeaturePermission.canViewAllCustomers(role)) ...[
                  Text(l10n.t('cmd_section_customers'),
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
                                  CircularProgressIndicator(color: premium.champagneGold),
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
                            l10n.t('cmd_no_customer_match'),
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
                              l10n.t('customer_unnamed');
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

class _ActionTile extends StatelessWidget {
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space2,
            vertical: DesignTokens.space1,
          ),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: premium.champagneGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    icon,
                    color: premium.champagneGoldMuted,
                    size: DesignTokens.iconMd,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyStrong(context)
                      .copyWith(color: ext.textPrimary),
                ),
              ),
              Icon(
                Icons.north_west_rounded,
                size: 16,
                color: ext.textTertiary.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
