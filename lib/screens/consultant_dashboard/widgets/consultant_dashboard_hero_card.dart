import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_glass_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_shadow_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_kpi_providers.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/consultant_dashboard_tokens.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:emlakmaster_mobile/widgets/session_avatar_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Executive hero cockpit — glass depth, compact hierarchy, embedded search slot.
class ConsultantDashboardHeroCard extends ConsumerWidget {
  const ConsultantDashboardHeroCard({
    super.key,
    required this.greeting,
    this.searchTrailing,
    this.onSearchSubmitted,
  });

  final String greeting;
  final Widget? searchTrailing;
  final ValueChanged<String>? onSearchSubmitted;

  static const int _weeklyGoal = 15;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final uid =
        ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''));
    final weeklyCalls = uid.isEmpty
        ? 0
        : ref.watch(
            agentWeeklyCallCountProvider(uid)
                .select((a) => a.valueOrNull ?? 0),
          );
    final now = DateTime.now();
    final dateLabel =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    final weekProgress =
        _weeklyGoal > 0 ? (weeklyCalls / _weeklyGoal).clamp(0.0, 1.0) : 0.0;

    return ConsultantDashboardExecutiveSurface(
      goldBorder: true,
      goldRail: true,
      radius: DesignTokens.radiusCardPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: ConsultantDashboardTokens.heroPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: PremiumShadowTokens.goldGlow(),
                          ),
                          child: const SessionAvatarButton(
                            size: ConsultantDashboardTokens.heroAvatarSize,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: ext.success,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: premium.glassSurface,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: AppTypography.pageEyebrow(context).copyWith(
                              fontSize: 11,
                              letterSpacing: 0.6,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppLocalizations.of(context).t('nav_home_consultant'),
                            style: AppTypography.pageHeading(context).copyWith(
                              fontSize: DesignTokens.fontSizeXl,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Executive cockpit · bugünkü operasyon',
                            style: AppTypography.meta(context).copyWith(
                              color: ext.textTertiary,
                              fontSize: 10,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          context.push(AppRouter.routeNotifications),
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: premium.champagneGold,
                        size: 22,
                      ),
                      tooltip: AppLocalizations.of(context).t('notifications'),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ExecutiveChip(
                      label: 'Bugün · $dateLabel',
                      emphasized: true,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _ExecutiveChip(
                        label: '$weeklyCalls / $_weeklyGoal haftalık çağrı',
                        trailing: weekProgress >= 1
                            ? Icons.check_circle_rounded
                            : Icons.trending_up_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  child: Stack(
                    children: [
                      LinearProgressIndicator(
                        value: weekProgress,
                        minHeight: 4,
                        backgroundColor: ext.borderSubtle,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          premium.champagneGold.withValues(alpha: 0.35),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: weekProgress,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: PremiumGlassTokens.goldAccentGradient(),
                            boxShadow: PremiumShadowTokens.goldGlow(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onSearchSubmitted != null) ...[
                  const SizedBox(height: 10),
                  PremiumSearchBar(
                    hintText: 'Müşteri, ilan veya görev ara…',
                    showMic: true,
                    onSubmitted: onSearchSubmitted,
                    trailing: searchTrailing,
                  ),
                ],
                const SizedBox(height: 8),
                const ConsultantDashboardTeamLine(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExecutiveChip extends StatelessWidget {
  const _ExecutiveChip({
    required this.label,
    this.emphasized = false,
    this.trailing,
  });

  final String label;
  final bool emphasized;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final premium = PremiumThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: emphasized
            ? premium.champagneGold.withValues(alpha: 0.14)
            : premium.glassSurface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(
          color: premium.champagneGold.withValues(
            alpha: emphasized ? 0.45 : 0.22,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: emphasized
                    ? premium.champagneGold
                    : premium.champagneGoldMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            Icon(trailing, size: 12, color: premium.champagneGold),
          ],
        ],
      ),
    );
  }
}

/// Danışmanın ekip ve yönetici bilgisi (teamId/managerId varsa).
class ConsultantDashboardTeamLine extends ConsumerWidget {
  const ConsultantDashboardTeamLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final uid = ref.watch(
      currentUserProvider.select((v) => v.valueOrNull?.uid),
    );
    if (uid == null) return const SizedBox.shrink();
    final userDocAsync = ref.watch(userDocStreamProvider(uid));
    return userDocAsync.when(
      data: (doc) {
        if (doc == null) return const SizedBox.shrink();
        final teamId = doc.teamId;
        if (teamId == null || teamId.isEmpty) return const SizedBox.shrink();
        final teamAsync = ref.watch(teamDocSnapshotProvider(teamId));
        return teamAsync.when(
          data: (team) {
            return FutureBuilder<UserDoc?>(
              future: doc.managerId != null && doc.managerId!.isNotEmpty
                  ? UserRepository.getUserDoc(doc.managerId!)
                  : Future.value(),
              builder: (context, managerSnap) {
                final teamName = team?.name ?? '—';
                final managerName =
                    managerSnap.data?.name ?? managerSnap.data?.email ?? '—';
                return Text(
                  '${AppLocalizations.of(context).t('label_team')}: $teamName · ${AppLocalizations.of(context).t('label_manager')}: $managerName',
                  style: TextStyle(
                    color: ext.textTertiary,
                    fontSize: 10,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
