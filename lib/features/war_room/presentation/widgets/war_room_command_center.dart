import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/war_room/data/war_room_providers.dart';
import 'package:emlakmaster_mobile/features/war_room/data/war_room_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/war_room_tokens.dart';
import 'package:emlakmaster_mobile/features/war_room/presentation/widgets/war_room_intervention_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Executive intervention center — gerçek operasyon sinyalleri.
class WarRoomCommandCenter extends ConsumerWidget {
  const WarRoomCommandCenter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = PremiumThemeExtension.of(context);
    final snapshotAsync = ref.watch(warRoomInterventionSnapshotProvider);

    return RefreshIndicator(
      onRefresh: () async => invalidateWarRoomData(ref),
      color: premium.champagneGold,
      backgroundColor: premium.glassSurface,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: PremiumNavLeading(),
                ),
                const Spacer(),
                const _WarRoomTeamFilter(),
                IconButton(
                  tooltip: 'Yenile',
                  onPressed: () => invalidateWarRoomData(ref),
                  icon: Icon(Icons.refresh_rounded,
                      color: AppThemeExtension.of(context).accent, size: 22),
                ),
                TextButton.icon(
                  onPressed: () => context.push(AppRouter.routeCommandCenter),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(Icons.phone_in_talk_rounded,
                      size: 18,
                      color: AppThemeExtension.of(context).accent),
                  label: Text(
                    AppLocalizations.of(context).t('nav_call_center'),
                    style: TextStyle(
                      color: AppThemeExtension.of(context).accent,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: PremiumWarRoomHeader()),
          snapshotAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: WarRoomLoadingSkeleton(),
            ),
            error: (_, __) => SliverToBoxAdapter(
              child: WarRoomPartialState(
                onRetry: () => invalidateWarRoomData(ref),
              ),
            ),
            data: (snapshot) => SliverList(
              delegate: SliverChildListDelegate([
                WarRoomCrisisStrip(summary: snapshot.health),
                const WarRoomSectionLabel(
                  label: 'Öncelik hatları',
                  secondary: 'Gerçek kuyruklar',
                ),
                WarRoomPriorityLanes(lanes: snapshot.lanes),
                const WarRoomSectionLabel(
                  label: 'Müdahale listesi',
                  secondary: 'Ne düzeltilmeli?',
                ),
                WarRoomInterventionList(rows: snapshot.interventions),
                const WarRoomSectionLabel(
                  label: 'Operasyon geçişi',
                  secondary: 'Mevcut yüzeyler',
                ),
                const WarRoomSecondaryRoutes(),
                const SizedBox(height: WarRoomTokens.bottomReserve),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarRoomTeamFilter extends ConsumerWidget {
  const _WarRoomTeamFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedId = ref.watch(warRoomSelectedTeamIdProvider);
    final teamsAsync = ref.watch(warRoomTeamsProvider);
    return teamsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (teams) {
        if (teams.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedId,
              isDense: true,
              hint: Text(
                l10n.t('label_team'),
                style: TextStyle(
                  color: AppThemeExtension.of(context).accent,
                  fontSize: 12,
                ),
              ),
              dropdownColor: AppThemeExtension.of(context).surface,
              items: [
                DropdownMenuItem<String?>(
                  child: Text(
                    l10n.t('filter_all_teams'),
                    style: TextStyle(
                      color: AppThemeExtension.of(context).textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
                ...teams.map(
                  (t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(
                      t.name,
                      style: TextStyle(
                        color: AppThemeExtension.of(context).textPrimary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) =>
                  ref.read(warRoomSelectedTeamIdProvider.notifier).state = v,
            ),
          ),
        );
      },
    );
  }
}
