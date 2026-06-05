import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/auth_logout_coordinator.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_access_state.dart';
import 'package:emlakmaster_mobile/features/office/presentation/utils/office_error_ui.dart';
import 'package:emlakmaster_mobile/features/office/services/office_migration_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
/// Ofis işaretçisi / üyelik tutarsızlığı, askı, davet veya kaldırılmış üyelik — kurtarma.
class OfficeRecoveryPage extends ConsumerWidget {
  const OfficeRecoveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    final access = ref.watch(officeAccessStateProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final doc = user != null ? ref.watch(userDocStreamProvider(user.uid)).valueOrNull : null;
    final oid = doc?.officeId;

    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: access.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _RecoveryBody(
              title: l10n.t('office_recovery_conn_title'),
              message: officeErrorUserMessage(e),
              ext: ext,
              child: _RecoveryActions(
                onRetry: () {
                  if (user != null) {
                    ref.invalidate(userDocStreamProvider(user.uid));
                    ref.invalidate(primaryMembershipProvider);
                  }
                },
                onSignOut: () async {
                  await AuthLogoutCoordinator.signOut(ref);
                },
              ),
            ),
            data: (state) {
              final (title, subtitle, chip) = _copyForState(l10n, state);
              return _RecoveryBody(
                title: title,
                message: subtitle,
                chipLabel: chip,
                ext: ext,
                child: _RecoveryActions(
                  onRetry: () {
                    if (user != null) {
                      ref.invalidate(userDocStreamProvider(user.uid));
                      ref.invalidate(primaryMembershipProvider);
                    }
                  },
                  onSignOut: () async {
                    await AuthLogoutCoordinator.signOut(ref);
                  },
                  extra: state == OfficeAccessState.membershipMissing ||
                          state == OfficeAccessState.inconsistentPointer
                      ? _RepairTile(
                          officeId: oid,
                          onRepair: oid == null || user == null
                              ? null
                              : () async {
                                  try {
                                    await OfficeMigrationService.clearOfficePointerIfMembershipMissing(
                                      uid: user.uid,
                                      officeId: oid,
                                    );
                                    if (context.mounted) {
                                      ref.invalidate(userDocStreamProvider(user.uid));
                                      ref.invalidate(primaryMembershipProvider);
                                      context.go(AppRouter.routeOfficeGate);
                                    }
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(officeErrorUserMessage(e))),
                                    );
                                  }
                                },
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

(String, String, String) _copyForState(
    AppLocalizations l10n, OfficeAccessState state) {
  switch (state) {
    case OfficeAccessState.membershipMissing:
      return (
        l10n.t('office_state_missing_title'),
        l10n.t('office_state_missing_body'),
        l10n.t('office_state_missing_chip'),
      );
    case OfficeAccessState.inconsistentPointer:
      return (
        l10n.t('office_state_inconsistent_title'),
        l10n.t('office_state_inconsistent_body'),
        l10n.t('office_state_inconsistent_chip'),
      );
    case OfficeAccessState.invitedOnly:
      return (
        l10n.t('office_state_invited_title'),
        l10n.t('office_state_invited_body'),
        l10n.t('office_state_invited_chip'),
      );
    case OfficeAccessState.suspended:
      return (
        l10n.t('office_state_suspended_title'),
        l10n.t('office_state_suspended_body'),
        l10n.t('office_state_suspended_chip'),
      );
    case OfficeAccessState.removed:
      return (
        l10n.t('office_state_removed_title'),
        l10n.t('office_state_removed_body'),
        l10n.t('office_state_removed_chip'),
      );
    default:
      return (
        l10n.t('office_state_default_title'),
        l10n.t('office_state_default_body'),
        '—',
      );
  }
}

class _RecoveryBody extends StatelessWidget {
  const _RecoveryBody({
    required this.title,
    required this.message,
    required this.ext,
    required this.child,
    this.chipLabel,
  });

  final String title;
  final String message;
  final AppThemeExtension ext;
  final Widget child;
  final String? chipLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        if (chipLabel != null && chipLabel != '—')
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ext.surfaceElevated,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                border: Border.all(color: ext.accent.withValues(alpha: 0.35)),
              ),
              child: Text(
                chipLabel!,
                style: TextStyle(
                  color: ext.foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        if (chipLabel != null && chipLabel != '—') const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ext.foreground,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: TextStyle(
            color: ext.foregroundSecondary,
            height: 1.45,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 28),
        Expanded(child: SingleChildScrollView(child: child)),
      ],
    );
  }
}

class _RecoveryActions extends StatelessWidget {
  const _RecoveryActions({
    required this.onRetry,
    required this.onSignOut,
    this.extra,
  });

  final VoidCallback onRetry;
  final VoidCallback onSignOut;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (extra != null) extra!,
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: Text(l10n.t('office_revalidate')),
          style: FilledButton.styleFrom(
            backgroundColor: ext.accent,
            foregroundColor: ext.onBrand,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => context.push(AppRouter.routeOfficeJoin),
          icon: const Icon(Icons.vpn_key_rounded, size: 20),
          label: Text(l10n.t('office_join')),
          style: OutlinedButton.styleFrom(
            foregroundColor: ext.foreground,
            side: BorderSide(color: ext.foregroundSecondary.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onSignOut,
          child: Text(
            l10n.t('settings_logout'),
            style: TextStyle(color: ext.foregroundSecondary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _RepairTile extends StatelessWidget {
  const _RepairTile({required this.officeId, required this.onRepair});

  final String? officeId;
  final VoidCallback? onRepair;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    if (officeId == null || onRepair == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('office_repair_title'),
                style: TextStyle(
                  color: ext.foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.t('office_repair_body'),
                style: TextStyle(color: ext.foregroundSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRepair,
                child: Text(l10n.t('office_repair_cta')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
