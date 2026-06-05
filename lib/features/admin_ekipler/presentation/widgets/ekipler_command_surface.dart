import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/features/admin_consultants/presentation/providers/admin_consultants_providers.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/admin_ekipler_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/ekipler_actions.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/providers/ekipler_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/utils/ekipler_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/utils/ekipler_team_filter.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/widgets/ekipler_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/widgets/ekipler_skeleton.dart';
import 'package:emlakmaster_mobile/features/admin_ekipler/presentation/widgets/ekipler_team_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EkiplerCommandSurface extends ConsumerStatefulWidget {
  const EkiplerCommandSurface({
    super.key,
    this.headerActions = const [],
    this.onCreateTeam,
  });

  final List<Widget> headerActions;
  final VoidCallback? onCreateTeam;

  @override
  ConsumerState<EkiplerCommandSurface> createState() =>
      _EkiplerCommandSurfaceState();
}

class _EkiplerCommandSurfaceState extends ConsumerState<EkiplerCommandSurface> {
  String _search = '';
  EkiplerTeamFilter _filter = EkiplerTeamFilter.all;

  void _invalidate() {
    ref.invalidate(adminConsultantsTeamsProvider);
    ref.invalidate(adminConsultantsListProvider);
    ref.invalidate(ekiplerPageSnapshotProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snapshotAsync = ref.watch(ekiplerPageSnapshotProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final detailed = _filter == EkiplerTeamFilter.detailed;

    return snapshotAsync.when(
      loading: () => const CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: EkiplerLoadingSkeleton()),
        ],
      ),
      error: (_, __) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PremiumEkiplerHeader(actions: widget.headerActions),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: EkiplerEmptyState(
              title: 'Ekipler yüklenemedi',
              message: 'Bağlantınızı kontrol edip tekrar deneyin.',
              onRetry: _invalidate,
            ),
          ),
        ],
      ),
      data: (snapshot) {
        final showUnassigned = _filter == EkiplerTeamFilter.unassigned;
        final filteredTeams = filterEkiplerTeams(
          source: snapshot.teams,
          searchQuery: _search,
          filter: _filter,
        );
        final unassigned = filterUnassignedConsultants(
          source: snapshot.unassignedConsultants,
          searchQuery: _search,
        );

        return CustomScrollView(
          cacheExtent: 480,
          slivers: [
            SliverToBoxAdapter(
              child: PremiumEkiplerHeader(actions: widget.headerActions),
            ),
            SliverToBoxAdapter(
              child: PremiumEkiplerHealthStrip(strip: snapshot.strip),
            ),
            SliverToBoxAdapter(
              child: EkiplerQuickRouteRow(
                onKadro: () => EkiplerActions.openKadro(context),
                onReports: () => EkiplerActions.openReportsTab(context),
                onCommandCenter: EkiplerActions.canOpenCommandCenter(ref)
                    ? () => EkiplerActions.openCommandCenter(context)
                    : null,
                onWarRoom: EkiplerActions.canOpenWarRoom(ref)
                    ? () => EkiplerActions.openWarRoom(context)
                    : null,
              ),
            ),
            SliverToBoxAdapter(
              child: EkiplerCompactSearch(
                hintText: 'Ekip ara (isim, yönetici)',
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            SliverToBoxAdapter(
              child: EkiplerFilterChips(
                selected: _filter,
                onSelected: (f) => setState(() => _filter = f),
              ),
            ),
            if (showUnassigned) ...[
              if (unassigned.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EkiplerEmptyState(
                    title: 'Atanmamış danışman yok',
                    message: _search.isNotEmpty
                        ? 'Arama kriterlerinize uygun atanmamış danışman bulunamadı.'
                        : 'Tüm danışmanlar bir ekibe atanmış görünüyor.',
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: EkiplerSectionHeader(
                    title: 'Atanmamış danışmanlar',
                    count: unassigned.length,
                  ),
                ),
                SliverList.builder(
                  itemCount: unassigned.length,
                  itemBuilder: (context, index) => EkiplerUnassignedRow(
                    user: unassigned[index],
                    onKadro: () => EkiplerActions.openKadro(context),
                  ),
                ),
              ],
            ] else if (filteredTeams.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EkiplerEmptyState(
                  title: l10n.t('empty_teams_title'),
                  message: _search.isNotEmpty
                      ? 'Arama kriterlerinize uygun ekip bulunamadı.'
                      : l10n.t('empty_teams_subtitle'),
                  actionLabel: widget.onCreateTeam != null
                      ? l10n.t('action_add_team')
                      : null,
                  onAction: widget.onCreateTeam,
                ),
              )
            else ...[
              if (_filter == EkiplerTeamFilter.intervention)
                const SliverToBoxAdapter(
                  child: EkiplerSectionHeader(title: 'Müdahale gereken'),
                ),
              SliverList.builder(
                itemCount: filteredTeams.length,
                itemBuilder: (context, index) =>
                    _buildTeamRow(context, filteredTeams[index], detailed),
              ),
            ],
            SliverPadding(
              padding: EdgeInsets.only(
                bottom: AdminEkiplerTokens.bottomReserve + bottom,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTeamRow(
    BuildContext context,
    EkiplerTeamViewModel vm,
    bool detailed,
  ) {
    final teamId = vm.team.id;
    return EkiplerTeamRow(
      viewModel: vm,
      detailed: detailed,
      onTap: () => EkiplerActions.openTeamDetail(context, teamId),
      onKadro: () => EkiplerActions.openKadro(context),
      onReports: () => EkiplerActions.openReportsTab(context),
      onAssign: () => EkiplerActions.openTeamDetail(context, teamId),
      onCommandCenter: EkiplerActions.canOpenCommandCenter(ref)
          ? () => EkiplerActions.openCommandCenter(context)
          : null,
      onWarRoom: EkiplerActions.canOpenWarRoom(ref)
          ? () => EkiplerActions.openWarRoom(context)
          : null,
    );
  }
}
