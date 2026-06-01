import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/shell_tab_back_binding.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_actions.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_filter.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_types.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/providers/follow_up_workspace_provider.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/widgets/follow_up_workspace_chrome.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/widgets/follow_up_workspace_row.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/widgets/follow_up_workspace_skeleton.dart';
import 'package:emlakmaster_mobile/screens/consultant_shell_nav.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

double _dockBottomReserve(BuildContext context) {
  final ts = MediaQuery.textScalerOf(context);
  final ratio = ts.scale(DesignTokens.fontSizeBase) / DesignTokens.fontSizeBase;
  return 120 * ratio.clamp(1.0, 1.38);
}

/// Takiplerim komuta yüzeyi (Screen 28) — premium, dürüst, hızlı takip workspace.
class FollowUpWorkspaceSurface extends ConsumerStatefulWidget {
  const FollowUpWorkspaceSurface({super.key});

  @override
  ConsumerState<FollowUpWorkspaceSurface> createState() =>
      _FollowUpWorkspaceSurfaceState();
}

class _FollowUpWorkspaceSurfaceState
    extends ConsumerState<FollowUpWorkspaceSurface> {
  final _readyTracker = ShellScreenReadyTracker('follow_up_workspace');
  late final DebouncedSearchController _search;
  late final FocusNode _searchFocus;
  String _query = '';
  FollowUpWorkspaceFilter _filter = FollowUpWorkspaceFilter.all;

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

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(followUpWorkspaceSnapshotProvider);
    ref.listen(followUpWorkspaceSnapshotProvider, (_, next) {
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
            SliverToBoxAdapter(child: FollowUpWorkspaceSkeleton()),
          ],
        ),
        error: (_, __) => CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: FollowUpWorkspaceHeader(
                title: 'Takiplerim',
                subtitle: 'müşteri takibi ve sonraki adımlar',
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
                  title: 'Takip listesi yüklenemedi',
                  subtitle: 'Bağlantınızı kontrol edip tekrar deneyin.',
                  actionLabel: 'Yeniden dene',
                  onAction: () => FollowUpWorkspaceActions.refresh(ref),
                ),
              ),
            ),
          ],
        ),
        data: (snapshot) => _buildScroll(context, snapshot),
      ),
    );
  }

  Widget _buildScroll(BuildContext context, FollowUpWorkspaceSnapshot snapshot) {
    final reserve = _dockBottomReserve(context);

    final header = SliverToBoxAdapter(
      child: FollowUpWorkspaceHeader(
        title: 'Takiplerim',
        subtitle: 'müşteri takibi ve sonraki adımlar',
        dateChipLabel: snapshot.dateChipLabel,
        coverageNote: snapshot.coverageNote,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () => FollowUpWorkspaceActions.refresh(ref),
            icon: Icon(
              Icons.refresh_rounded,
              color: AppThemeExtension.of(context).accent,
              size: 22,
            ),
          ),
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
                    icon: Icons.track_changes_rounded,
                    title: 'Takip bekleyen müşteri yok',
                    subtitle:
                        '7+ gün sessiz müşteri yok. Yeni temaslar burada görünür.',
                    actionLabel: ProductLabels.myCustomers,
                    onAction: () =>
                        ConsultantShellNav.goToCustomersTab(context),
                    outlinedActionLabel: ProductLabels.myTasks,
                    onOutlinedAction: () =>
                        ConsultantShellNav.goToTasksTab(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final filtered = filterFollowUpWorkspaceRows(
      snapshot.rows,
      query: _query,
      filter: _filter,
    );

    final showOverdueLane = _filter == FollowUpWorkspaceFilter.all &&
        _query.isEmpty &&
        snapshot.overdueRows.isNotEmpty;

    final showQuickLane = _filter == FollowUpWorkspaceFilter.all &&
        _query.isEmpty &&
        snapshot.quickCloseRows.isNotEmpty;

    final slivers = <Widget>[
      header,
      SliverToBoxAdapter(
        child: FollowUpWorkspaceSummaryStrip(summary: snapshot.summary),
      ),
      SliverToBoxAdapter(
        child: FollowUpWorkspaceSearchRow(
          controller: _search.controller,
          focusNode: _searchFocus,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 6)),
      SliverToBoxAdapter(
        child: FollowUpWorkspaceFilterStrip(
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
          child: FollowUpWorkspaceInlineNote(
            icon: Icons.filter_alt_off_rounded,
            message: _query.isNotEmpty
                ? 'Aramaya uyan takip bulunamadı.'
                : 'Bu görünümde takip yok.',
          ),
        ),
      );
      if (_query.isEmpty && _filter != FollowUpWorkspaceFilter.all) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _filter = FollowUpWorkspaceFilter.all;
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

      if (showOverdueLane) {
        final lane = filterFollowUpWorkspaceRows(
          snapshot.overdueRows,
          query: _query,
        ).take(3).toList();
        laneKeys.addAll(lane.map((r) => r.customerId));
        if (lane.isNotEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: FollowUpWorkspaceSectionHeader(
                label: 'Gecikenler',
                secondary: '${lane.length}',
              ),
            ),
          );
          slivers.add(
            SliverList.builder(
              itemCount: lane.length,
              itemBuilder: (_, i) => _buildRow(lane[i]),
            ),
          );
        }
      }

      if (showQuickLane) {
        final lane = filterFollowUpWorkspaceRows(
          snapshot.quickCloseRows,
          query: _query,
        )
            .where((r) => !laneKeys.contains(r.customerId))
            .take(3)
            .toList();
        laneKeys.addAll(lane.map((r) => r.customerId));
        if (lane.isNotEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: FollowUpWorkspaceSectionHeader(
                label: 'Hızlı çözülebilir',
                secondary: '${lane.length}',
              ),
            ),
          );
          slivers.add(
            SliverList.builder(
              itemCount: lane.length,
              itemBuilder: (_, i) => _buildRow(lane[i]),
            ),
          );
        }
      }

      final mainRows =
          filtered.where((r) => !laneKeys.contains(r.customerId)).toList();

      slivers.add(
        SliverToBoxAdapter(
          child: FollowUpWorkspaceSectionHeader(
            label: 'Takip listesi',
            secondary: '${mainRows.length}',
          ),
        ),
      );
      slivers.add(
        SliverList.builder(
          itemCount: mainRows.length,
          itemBuilder: (_, i) => _buildRow(mainRows[i]),
        ),
      );
    }

    slivers.add(SliverPadding(padding: EdgeInsets.only(bottom: reserve)));

    return CustomScrollView(cacheExtent: 360, slivers: slivers);
  }

  Widget _buildRow(FollowUpRowView row) {
    return FollowUpWorkspaceRow(
      row: row,
      onTap: () => FollowUpWorkspaceActions.openDetail(context, row),
      onCall: row.callablePhone
          ? () => FollowUpWorkspaceActions.call(context, row)
          : null,
      onMenu: (menu) => _onMenu(menu, row),
    );
  }

  void _onMenu(FollowUpRowMenu menu, FollowUpRowView row) {
    switch (menu) {
      case FollowUpRowMenu.open:
        FollowUpWorkspaceActions.openDetail(context, row);
      case FollowUpRowMenu.complete:
        FollowUpWorkspaceActions.complete(context, ref, row);
      case FollowUpRowMenu.customer:
        FollowUpWorkspaceActions.openCustomer(context, row);
      case FollowUpRowMenu.call:
        FollowUpWorkspaceActions.call(context, row);
      case FollowUpRowMenu.message:
        FollowUpWorkspaceActions.message(context, row);
      case FollowUpRowMenu.whatsapp:
        FollowUpWorkspaceActions.whatsapp(context, row);
      case FollowUpRowMenu.tasks:
        FollowUpWorkspaceActions.goToTasks(context);
      case FollowUpRowMenu.snooze:
        FollowUpWorkspaceActions.snooze(context, ref, row);
      case FollowUpRowMenu.detail:
        FollowUpWorkspaceActions.showActionSheet(context, ref, row);
    }
  }
}
