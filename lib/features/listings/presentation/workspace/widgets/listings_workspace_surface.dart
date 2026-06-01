import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/navigation/shell_tab_back_binding.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_actions.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_filter.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_types.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/providers/listings_workspace_provider.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/widgets/listings_workspace_chrome.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/widgets/listings_workspace_row.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/widgets/listings_workspace_skeleton.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

double _dockBottomReserve(BuildContext context) {
  final ts = MediaQuery.textScalerOf(context);
  final ratio = ts.scale(DesignTokens.fontSizeBase) / DesignTokens.fontSizeBase;
  return 120 * ratio.clamp(1.0, 1.38);
}

/// Portföyüm komuta yüzeyi (Screen 29) — premium, dürüst, hızlı ilan workspace.
class ListingsWorkspaceSurface extends ConsumerStatefulWidget {
  const ListingsWorkspaceSurface({super.key});

  @override
  ConsumerState<ListingsWorkspaceSurface> createState() =>
      _ListingsWorkspaceSurfaceState();
}

class _ListingsWorkspaceSurfaceState
    extends ConsumerState<ListingsWorkspaceSurface> {
  final _readyTracker = ShellScreenReadyTracker('listings_workspace');
  late final DebouncedSearchController _search;
  late final FocusNode _searchFocus;
  String _query = '';
  ListingsWorkspaceFilter _filter = ListingsWorkspaceFilter.all;

  @override
  void initState() {
    super.initState();
    _searchFocus = FocusNode();
    _search = DebouncedSearchController(
      onQueryChanged: (q) {
        if (!mounted) return;
        setState(() => _query = q.toLowerCase());
      },
    );
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool _handleExitSearch() {
    if (_query.isEmpty && _search.controller.text.trim().isEmpty) return false;
    setState(() => _search.controller.clear());
    return true;
  }

  List<Widget> _headerActions(bool canManage) {
    if (!canManage) return const [];
    final ext = AppThemeExtension.of(context);
    return [
      IconButton(
        tooltip: 'İlan ekle',
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        onPressed: () => ListingsWorkspaceActions.openImportHub(context),
        icon: Icon(Icons.add_rounded, color: ext.accent, size: 22),
      ),
      IconButton(
        tooltip: 'Bağlı hesaplar',
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        onPressed: () =>
            ListingsWorkspaceActions.openConnectedAccounts(context),
        icon: Icon(Icons.hub_outlined, color: ext.accent, size: 22),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snapshotAsync = ref.watch(listingsWorkspaceSnapshotProvider);
    ref.listen(listingsWorkspaceSnapshotProvider, (_, next) {
      final snap = next.valueOrNull;
      if (snap != null) {
        _readyTracker.onContentReady(itemCount: snap.rows.length);
      }
    });

    return ShellTabBackBinding(
      onExitSearch: _handleExitSearch,
      child: snapshotAsync.when(
        loading: () => const CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: ListingsWorkspaceSkeleton()),
          ],
        ),
        error: (_, __) => CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: ListingsWorkspaceHeader(
                title: 'Portföyüm',
                subtitle: 'ilan durumu ve sonraki adımlar',
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: EmptyState(
                  compact: true,
                  grouped: true,
                  premiumVisual: true,
                  icon: Icons.cloud_off_rounded,
                  title: 'İlanlar yüklenemedi',
                  subtitle: 'Bağlantınızı kontrol edip tekrar deneyin.',
                  actionLabel: 'Yeniden dene',
                  onAction: () => ListingsWorkspaceActions.refresh(ref),
                ),
              ),
            ),
          ],
        ),
        data: (snapshot) => _buildScroll(context, snapshot, l10n),
      ),
    );
  }

  Widget _buildScroll(
    BuildContext context,
    ListingsWorkspaceSnapshot snapshot,
    AppLocalizations l10n,
  ) {
    final reserve = _dockBottomReserve(context);
    final actions = _headerActions(snapshot.canManage);

    final header = SliverToBoxAdapter(
      child: ListingsWorkspaceHeader(
        title: 'Portföyüm',
        subtitle: 'ilan durumu ve sonraki adımlar',
        dateChipLabel: snapshot.dateChipLabel,
        coverageNote: snapshot.coverageNote,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () => ListingsWorkspaceActions.refresh(ref),
            icon: Icon(
              Icons.refresh_rounded,
              color: AppThemeExtension.of(context).accent,
              size: 22,
            ),
          ),
          ...actions,
        ],
      ),
    );

    if (snapshot.isEmpty) {
      return CustomScrollView(
        cacheExtent: 360,
        slivers: [
          header,
          SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, reserve),
                child: Center(
                  child: EmptyState(
                    premiumVisual: true,
                    grouped: true,
                    icon: Icons.home_work_outlined,
                    title: 'Henüz portföy yok',
                    subtitle: snapshot.canManage
                        ? l10n.t('empty_listings_sub')
                        : '${l10n.t('empty_listings_sub')}\n\n${l10n.t('integration_connections_read_only_notice')}',
                    actionLabel: snapshot.canManage ? 'İlan ekle' : null,
                    onAction: snapshot.canManage
                        ? () =>
                            ListingsWorkspaceActions.openImportHub(context)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final filtered = filterListingsWorkspaceRows(
      snapshot.rows,
      query: _query,
      filter: _filter,
    );

    final showIncompleteLane = _filter == ListingsWorkspaceFilter.all &&
        _query.isEmpty &&
        snapshot.incompleteRows.isNotEmpty;

    final showReadyLane = _filter == ListingsWorkspaceFilter.all &&
        _query.isEmpty &&
        snapshot.readyRows.isNotEmpty;

    final slivers = <Widget>[
      header,
      SliverToBoxAdapter(
        child: ListingsWorkspaceSummaryStrip(summary: snapshot.summary),
      ),
      SliverToBoxAdapter(
        child: ListingsWorkspaceSearchRow(
          controller: _search.controller,
          focusNode: _searchFocus,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 6)),
      SliverToBoxAdapter(
        child: ListingsWorkspaceFilterStrip(
          selected: _filter,
          onSelected: (f) {
            AppFeedback.selectionClick();
            setState(() => _filter = f);
          },
        ),
      ),
    ];

    if (filtered.isEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: ListingsWorkspaceInlineNote(
            icon: Icons.filter_alt_off_rounded,
            message: _query.isNotEmpty
                ? 'Aramaya uyan ilan bulunamadı.'
                : 'Bu görünümde ilan yok.',
          ),
        ),
      );
      if (_query.isEmpty && _filter != ListingsWorkspaceFilter.all) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _filter = ListingsWorkspaceFilter.all;
                    _search.controller.clear();
                  });
                },
                child: const Text('Tümünü göster'),
              ),
            ),
          ),
        );
      }
    } else {
      final laneKeys = <String>{};

      if (showIncompleteLane) {
        final lane = filterListingsWorkspaceRows(
          snapshot.incompleteRows,
          query: _query,
        ).take(3).toList();
        laneKeys.addAll(lane.map((r) => r.id));
        if (lane.isNotEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: ListingsWorkspaceSectionHeader(
                label: 'Eksikler',
                secondary: '${lane.length}',
              ),
            ),
          );
          slivers.add(
            SliverList.builder(
              itemCount: lane.length,
              itemBuilder: (_, i) => _buildRow(lane[i], snapshot.canManage),
            ),
          );
        }
      }

      if (showReadyLane) {
        final lane = filterListingsWorkspaceRows(
          snapshot.readyRows,
          query: _query,
        )
            .where((r) => !laneKeys.contains(r.id))
            .take(3)
            .toList();
        laneKeys.addAll(lane.map((r) => r.id));
        if (lane.isNotEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: ListingsWorkspaceSectionHeader(
                label: 'Hazır',
                secondary: '${lane.length}',
              ),
            ),
          );
          slivers.add(
            SliverList.builder(
              itemCount: lane.length,
              itemBuilder: (_, i) => _buildRow(lane[i], snapshot.canManage),
            ),
          );
        }
      }

      final mainRows =
          filtered.where((r) => !laneKeys.contains(r.id)).toList();

      slivers.add(
        SliverToBoxAdapter(
          child: ListingsWorkspaceSectionHeader(
            label: 'İlan listesi',
            secondary: '${mainRows.length}',
          ),
        ),
      );
      slivers.add(
        SliverList.builder(
          itemCount: mainRows.length,
          itemBuilder: (_, i) => _buildRow(mainRows[i], snapshot.canManage),
        ),
      );
    }

    slivers.add(SliverPadding(padding: EdgeInsets.only(bottom: reserve)));

    return CustomScrollView(cacheExtent: 360, slivers: slivers);
  }

  Widget _buildRow(ListingWorkspaceRowView row, bool canManage) {
    return ListingsWorkspaceRow(
      row: row,
      onTap: () => ListingsWorkspaceActions.openListing(context, row),
      onMenu: (menu) => _onMenu(menu, row, canManage),
    );
  }

  void _onMenu(ListingRowMenu menu, ListingWorkspaceRowView row, bool canManage) {
    switch (menu) {
      case ListingRowMenu.open:
        ListingsWorkspaceActions.openListing(context, row);
      case ListingRowMenu.edit:
        ListingsWorkspaceActions.edit(context);
      case ListingRowMenu.share:
        ListingsWorkspaceActions.share(context, row);
      case ListingRowMenu.sync:
        ListingsWorkspaceActions.sync(
          context,
          ref,
          row,
          canManage: canManage,
        );
      case ListingRowMenu.detail:
        ListingsWorkspaceActions.showActionSheet(
          context,
          ref,
          row,
          canManage: canManage,
        );
    }
  }
}
