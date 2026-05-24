import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/broker_dashboard_kpi_providers.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/consultant_dashboard_layout.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:emlakmaster_mobile/widgets/session_avatar_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Figma-style hero card: gold accent rail, avatar, greeting, date chip, notifications.
class ConsultantDashboardHeroCard extends ConsumerWidget {
  const ConsultantDashboardHeroCard({super.key, required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final now = DateTime.now();
    final dateLabel =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

    return PremiumSurfaceCard(
      goldBorder: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (kDebugMode) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space3,
                vertical: DesignTokens.space2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFB91C1C),
                border: Border.all(
                  color: premium.champagneGold,
                  width: 2,
                ),
              ),
              child: const Text(
                'NEW DASHBOARD LAYOUT ACTIVE · ${ConsultantDashboardLayout.layoutVersion}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  height: 1.2,
                ),
              ),
            ),
          ],
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  premium.champagneGold,
                  premium.champagneGold.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DesignTokens.radiusCardPrimary),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space4,
              DesignTokens.space4,
              DesignTokens.space3,
              DesignTokens.space3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: SessionAvatarButton(size: 52),
                    ),
                    Positioned(
                      right: -1,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: ext.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: premium.glassSurface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: AppTypography.pageEyebrow(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: DesignTokens.space1),
                      Text(
                        ProductLabels.consultantHome,
                        style: AppTypography.pageHeading(context).copyWith(
                          fontSize: DesignTokens.fontSize2xl,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: DesignTokens.space2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.space2,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: premium.champagneGold.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusPill),
                          border: Border.all(
                            color: premium.champagneGold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          'Bugün · $dateLabel',
                          style: TextStyle(
                            color: premium.champagneGold,
                            fontSize: DesignTokens.fontSizeXs,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.push(AppRouter.routeNotifications),
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: premium.champagneGold,
                    size: 24,
                  ),
                  tooltip: AppLocalizations.of(context).t('notifications'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.space4,
              DesignTokens.space2,
              DesignTokens.space4,
              DesignTokens.space3,
            ),
            child: ConsultantDashboardTeamLine(),
          ),
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
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${AppLocalizations.of(context).t('label_team')}: $teamName · ${AppLocalizations.of(context).t('label_manager')}: $managerName',
                    style: TextStyle(
                      color: ext.textTertiary,
                      fontSize: DesignTokens.fontSizeXs,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
