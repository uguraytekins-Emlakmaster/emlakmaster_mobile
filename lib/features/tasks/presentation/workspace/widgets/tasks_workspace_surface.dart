import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/navigation/shell_tab_back_binding.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/consultant_tasks_tokens.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/tasks_workspace_actions.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/tasks_workspace_filter.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/tasks_workspace_types.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/providers/tasks_workspace_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/widgets/tasks_workspace_chrome.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/widgets/tasks_workspace_row.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/workspace/widgets/tasks_workspace_skeleton.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

double _dockBottomReserve(BuildContext context) {
  final ts = MediaQuery.textScalerOf(context);
  final ratio = ts.scale(DesignTokens.fontSizeBase) / DesignTokens.fontSizeBase;
  return 120 * ratio.clamp(1.0, 1.38);
}

/// Görevlerim komuta yüzeyi (Screen 27) — premium, dürüst, hızlı görev workspace.
class TasksWorkspaceSurface extends ConsumerStatefulWidget {
  const TasksWorkspaceSurface({super.key});

  @override
  ConsumerState<TasksWorkspaceSurface> createState() =>
      _TasksWorkspaceSurfaceState();
}

class _TasksWorkspaceSurfaceState extends ConsumerState<TasksWorkspaceSurface> {
  final _readyTracker = ShellScreenReadyTracker('tasks_workspace');
  late final DebouncedSearchController _search;
  late final FocusNode _searchFocus;
  String _query = '';
  TasksWorkspaceFilter _filter = TasksWorkspaceFilter.all;
  final Set<String> _deletingIds = {};

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
    final uid =
        ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
    if (uid.isEmpty) {
      return Center(
        child: Text(
          'Oturum açık değil.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final snapshotAsync = ref.watch(tasksWorkspaceSnapshotProvider);
    ref.listen(tasksWorkspaceSnapshotProvider, (_, next) {
      final snap = next.valueOrNull;
      if (snap != null) {
        _readyTracker.onContentReady(itemCount: snap.rows.length);
      }
    });

    return ShellTabBackBinding(
      onExitSearch: _handleExitSearch,
      child: Column(
        children: [
          Expanded(
            child: snapshotAsync.when(
              loading: () => const CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: TasksWorkspaceSkeleton()),
                ],
              ),
              error: (_, __) => CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: TasksWorkspaceHeader(
                      title: 'Görevlerim',
                      subtitle: 'Görev durumu ve sonraki adımlar',
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
                        title: 'Görevler yüklenemedi',
                        subtitle: 'Bağlantınızı kontrol edip tekrar deneyin.',
                        actionLabel: 'Yeniden dene',
                        onAction: () => TasksWorkspaceActions.refresh(ref, uid),
                      ),
                    ),
                  ),
                ],
              ),
              data: (snapshot) => _buildScroll(context, snapshot, uid),
            ),
          ),
          if (snapshotAsync.valueOrNull?.isEmpty == false)
            _AddTaskDock(
              onPressed: () => TasksWorkspaceActions.showAddTask(context, ref, uid),
            ),
        ],
      ),
    );
  }

  Widget _buildScroll(
    BuildContext context,
    TasksWorkspaceSnapshot snapshot,
    String uid,
  ) {
    final reserve = _dockBottomReserve(context);
    final visible = snapshot.rows
        .where((r) => !_deletingIds.contains(r.id))
        .toList(growable: false);

    final header = SliverToBoxAdapter(
      child: TasksWorkspaceHeader(
        title: 'Görevlerim',
        subtitle: 'Görev durumu ve sonraki adımlar',
        dateChipLabel: snapshot.dateChipLabel,
        coverageNote: snapshot.coverageNote,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () => TasksWorkspaceActions.refresh(ref, uid),
            icon: Icon(
              Icons.refresh_rounded,
              color: AppThemeExtension.of(context).accent,
              size: 22,
            ),
          ),
        ],
      ),
    );

    if (visible.isEmpty) {
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
                    icon: Icons.task_alt_rounded,
                    title: AppLocalizations.of(context).t('empty_tasks'),
                    subtitle: AppLocalizations.of(context).t('empty_tasks_sub'),
                    actionLabel: AppLocalizations.of(context).t('empty_tasks_cta'),
                    onAction: () =>
                        TasksWorkspaceActions.showAddTask(context, ref, uid),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final filtered = filterTasksWorkspaceRows(
      visible,
      query: _query,
      filter: _filter,
    );

    final showOverdueLane = _filter == TasksWorkspaceFilter.all &&
        _query.isEmpty &&
        snapshot.overdueRows.isNotEmpty;

    final showQuickLane = _filter == TasksWorkspaceFilter.all &&
        _query.isEmpty &&
        snapshot.quickCloseRows.isNotEmpty;

    final slivers = <Widget>[
      header,
      SliverToBoxAdapter(
        child: TasksWorkspaceSummaryStrip(summary: snapshot.summary),
      ),
      SliverToBoxAdapter(
        child: TasksWorkspaceSearchRow(
          controller: _search.controller,
          focusNode: _searchFocus,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 6)),
      SliverToBoxAdapter(
        child: TasksWorkspaceFilterStrip(
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
          child: TasksWorkspaceInlineNote(
            icon: Icons.filter_alt_off_rounded,
            message: _query.isNotEmpty
                ? 'Aramaya uyan görev bulunamadı.'
                : 'Bu görünümde görev yok.',
          ),
        ),
      );
    } else {
      final laneKeys = <String>{};

      if (showOverdueLane) {
        final overdueFiltered = filterTasksWorkspaceRows(
          snapshot.overdueRows.where((r) => !_deletingIds.contains(r.id)).toList(),
          query: _query,
        );
        final lane = overdueFiltered.take(3).toList();
        laneKeys.addAll(lane.map((r) => r.id));
        if (lane.isNotEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: TasksWorkspaceSectionHeader(
                label: 'Gecikenler',
                secondary: '${lane.length}',
              ),
            ),
          );
          slivers.add(
            SliverList.builder(
              itemCount: lane.length,
              itemBuilder: (_, i) => _buildRow(lane[i], uid),
            ),
          );
        }
      }

      if (showQuickLane) {
        final quickFiltered = filterTasksWorkspaceRows(
          snapshot.quickCloseRows
              .where((r) => !_deletingIds.contains(r.id))
              .toList(),
          query: _query,
        );
        final lane = quickFiltered
            .where((r) => !laneKeys.contains(r.id))
            .take(3)
            .toList();
        laneKeys.addAll(lane.map((r) => r.id));
        if (lane.isNotEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: TasksWorkspaceSectionHeader(
                label: 'Hızlı kapatılabilir',
                secondary: '${lane.length}',
              ),
            ),
          );
          slivers.add(
            SliverList.builder(
              itemCount: lane.length,
              itemBuilder: (_, i) => _buildRow(lane[i], uid),
            ),
          );
        }
      }

      final mainRows =
          filtered.where((r) => !laneKeys.contains(r.id)).toList();

      slivers.add(
        SliverToBoxAdapter(
          child: TasksWorkspaceSectionHeader(
            label: 'Görev listesi',
            secondary: '${mainRows.length}',
          ),
        ),
      );
      slivers.add(
        SliverList.builder(
          itemCount: mainRows.length,
          itemBuilder: (_, i) => _buildRow(mainRows[i], uid),
        ),
      );
    }

    slivers.add(SliverPadding(padding: EdgeInsets.only(bottom: reserve)));

    return CustomScrollView(cacheExtent: 360, slivers: slivers);
  }

  Widget _buildRow(TaskRowView row, String uid) {
    return TasksWorkspaceRow(
      row: row,
      onTap: () => TasksWorkspaceActions.openDetail(context, ref, uid, row),
      onComplete: () => TasksWorkspaceActions.toggleDone(
        context,
        ref,
        row,
        !row.done,
      ),
      onMenu: (menu) => _onMenu(menu, row, uid),
    );
  }

  void _onMenu(TaskRowMenu menu, TaskRowView row, String uid) {
    switch (menu) {
      case TaskRowMenu.open:
        TasksWorkspaceActions.openDetail(context, ref, uid, row);
      case TaskRowMenu.complete:
        TasksWorkspaceActions.toggleDone(context, ref, row, true);
      case TaskRowMenu.customer:
        TasksWorkspaceActions.openCustomer(context, row);
      case TaskRowMenu.call:
        TasksWorkspaceActions.call(context, ref, row);
      case TaskRowMenu.message:
        TasksWorkspaceActions.message(context, ref, row);
      case TaskRowMenu.postpone:
        if (!row.done) TasksWorkspaceActions.postpone(context, row);
      case TaskRowMenu.followUp:
        TasksWorkspaceActions.goToFollowUp(context, ref);
      case TaskRowMenu.detail:
        TasksWorkspaceActions.showActionSheet(context, ref, uid, row);
    }
  }
}

class _AddTaskDock extends StatelessWidget {
  const _AddTaskDock({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: ext.surfaceElevated,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: ext.border.withValues(alpha: 0.55)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ConsultantTasksTokens.horizontal,
            DesignTokens.space2,
            ConsultantTasksTokens.horizontal,
            DesignTokens.space3,
          ),
          child: FilledButton.icon(
            onPressed: () {
              AppFeedback.mediumImpact();
              onPressed();
            },
            icon: Icon(Icons.add_rounded, color: ext.onBrand, size: 20),
            label: Text(
              'Yeni görev',
              style: TextStyle(
                color: ext.onBrand,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: ext.accent,
              minimumSize: const Size(double.infinity, 46),
            ),
          ),
        ),
      ),
    );
  }
}
