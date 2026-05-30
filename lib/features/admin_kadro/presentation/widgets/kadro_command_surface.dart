import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/features/admin_consultants/presentation/providers/admin_consultants_providers.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/admin_kadro_tokens.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/kadro_actions.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/providers/kadro_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/utils/kadro_consultant_filter.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/utils/kadro_snapshot.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/widgets/kadro_chrome.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/widgets/kadro_consultant_row.dart';
import 'package:emlakmaster_mobile/features/admin_kadro/presentation/widgets/kadro_skeleton.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef KadroEditHandler = void Function(BuildContext context, UserDoc user);

class KadroCommandSurface extends ConsumerStatefulWidget {
  const KadroCommandSurface({
    super.key,
    required this.canEditTeamRole,
    required this.onEditConsultant,
    this.headerActions = const [],
  });

  final bool canEditTeamRole;
  final KadroEditHandler onEditConsultant;
  final List<Widget> headerActions;

  @override
  ConsumerState<KadroCommandSurface> createState() =>
      _KadroCommandSurfaceState();
}

class _KadroCommandSurfaceState extends ConsumerState<KadroCommandSurface> {
  String _search = '';
  KadroRosterFilter _filter = KadroRosterFilter.all;
  String? _teamFilterId;
  bool _groupByTeam = false;

  void _invalidate() {
    ref.invalidate(adminConsultantsListProvider);
    ref.invalidate(adminConsultantsTeamsProvider);
    ref.invalidate(kadroPageSnapshotProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snapshotAsync = ref.watch(kadroPageSnapshotProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return snapshotAsync.when(
      loading: () => const CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: KadroLoadingSkeleton()),
        ],
      ),
      error: (e, _) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PremiumKadroHeader(actions: widget.headerActions),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: KadroEmptyState(
              title: 'Kadro yüklenemedi',
              message: 'Bağlantınızı kontrol edip tekrar deneyin.',
              onRetry: _invalidate,
            ),
          ),
        ],
      ),
      data: (snapshot) {
        final filtered = filterKadroConsultants(
          source: snapshot.consultants,
          searchQuery: _search,
          filter: _filter,
          teamId: _teamFilterId,
        );
        final teamsForChips = snapshot.teams
            .map((t) => (id: t.id, name: t.name))
            .toList(growable: false);

        return CustomScrollView(
          cacheExtent: 480,
          slivers: [
            SliverToBoxAdapter(
              child: PremiumKadroHeader(actions: widget.headerActions),
            ),
            SliverToBoxAdapter(
              child: PremiumKadroHealthStrip(strip: snapshot.strip),
            ),
            SliverToBoxAdapter(
              child: KadroQuickRouteRow(
                onTeams: () => KadroActions.openTeams(context),
                onReports: () => KadroActions.openReportsTab(context),
                onCommandCenter: KadroActions.canOpenCommandCenter(ref)
                    ? () => KadroActions.openCommandCenter(context)
                    : null,
                onWarRoom: KadroActions.canOpenWarRoom(ref)
                    ? () => KadroActions.openWarRoom(context)
                    : null,
              ),
            ),
            SliverToBoxAdapter(
              child: KadroCompactSearch(
                hintText: l10n.t('search_consultants'),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            SliverToBoxAdapter(
              child: KadroFilterChips(
                selected: _filter,
                onSelected: (f) => setState(() {
                  _filter = f;
                  _groupByTeam = f == KadroRosterFilter.byTeam;
                  if (f != KadroRosterFilter.byTeam) _teamFilterId = null;
                }),
                teamFilterId: _teamFilterId,
                teams: teamsForChips,
                onTeamSelected: (id) => setState(() => _teamFilterId = id),
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: KadroEmptyState(
                  title: l10n.t('empty_consultants'),
                  message: _search.isNotEmpty
                      ? 'Arama kriterlerinize uygun danışman bulunamadı.'
                      : 'Henüz danışman kaydı yok veya filtre sonucu boş.',
                ),
              )
            else if (_groupByTeam)
              ..._teamGroupedSlivers(
                context,
                filtered: filtered,
                snapshot: snapshot,
                l10n: l10n,
              )
            else
              SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) => _buildRow(
                  context,
                  user: filtered[index],
                  snapshot: snapshot,
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.only(
                bottom: AdminKadroTokens.bottomReserve + bottom,
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _teamGroupedSlivers(
    BuildContext context, {
    required List<UserDoc> filtered,
    required KadroPageSnapshot snapshot,
    required AppLocalizations l10n,
  }) {
    final sections = groupKadroByTeam(
      consultants: filtered,
      teams: snapshot.teams,
    );
    final slivers = <Widget>[];
    for (final section in sections) {
      slivers.add(
        SliverToBoxAdapter(
          child: KadroSectionHeader(
            title: section.teamName,
            count: section.consultants.length,
          ),
        ),
      );
      slivers.add(
        SliverList.builder(
          itemCount: section.consultants.length,
          itemBuilder: (context, index) => _buildRow(
            context,
            user: section.consultants[index],
            snapshot: snapshot,
          ),
        ),
      );
    }
    return slivers;
  }

  Widget _buildRow(
    BuildContext context, {
    required UserDoc user,
    required KadroPageSnapshot snapshot,
  }) {
    final teamName = user.teamId != null
        ? snapshot.teamNames[user.teamId!]
        : null;
    final teamId = user.teamId;

    return KadroConsultantRow(
      user: user,
      teamName: teamName,
      canEdit: widget.canEditTeamRole,
      onTap: () {
        if (widget.canEditTeamRole) {
          widget.onEditConsultant(context, user);
        }
      },
      onEdit: () => widget.onEditConsultant(context, user),
      onTeamDetail: teamId != null && teamId.isNotEmpty
          ? () => KadroActions.openTeamDetail(context, teamId)
          : null,
      onReports: () => KadroActions.openReportsTab(context),
      onCommandCenter: KadroActions.canOpenCommandCenter(ref)
          ? () => KadroActions.openCommandCenter(context)
          : null,
    );
  }
}
