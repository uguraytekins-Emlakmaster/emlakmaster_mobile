import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/shell_tab_back_binding.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/core/platform/io_platform_stub.dart'
    if (dart.library.io) 'dart:io' as io;
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/consultant_calls_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/android_call_log_sync_cta.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_sync_pending_strip.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/calls_workspace_actions.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/calls_workspace_filter.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/calls_workspace_types.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/providers/calls_workspace_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/widgets/calls_workspace_chrome.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/widgets/calls_workspace_row.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/widgets/calls_workspace_skeleton.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_call_center_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

double _dockBottomReserve(BuildContext context) {
  final ts = MediaQuery.textScalerOf(context);
  final ratio = ts.scale(DesignTokens.fontSizeBase) / DesignTokens.fontSizeBase;
  return 120 * ratio.clamp(1.0, 1.38);
}

/// Çağrılarım komuta yüzeyi (Screen 26) — premium, dürüst, hızlı çağrı workspace.
class CallsWorkspaceSurface extends ConsumerStatefulWidget {
  const CallsWorkspaceSurface({super.key});

  @override
  ConsumerState<CallsWorkspaceSurface> createState() =>
      _CallsWorkspaceSurfaceState();
}

class _CallsWorkspaceSurfaceState extends ConsumerState<CallsWorkspaceSurface> {
  final _readyTracker = ShellScreenReadyTracker('calls_workspace');
  late final DebouncedSearchController _search;
  late final FocusNode _searchFocus;
  String _query = '';
  CallsWorkspaceFilter _filter = CallsWorkspaceFilter.all;
  bool _isSyncingDevice = false;

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

  Future<void> _syncDevice() async {
    if (_isSyncingDevice) return;
    setState(() => _isSyncingDevice = true);
    try {
      await CallsWorkspaceActions.syncDeviceCallLog(context, ref);
    } finally {
      if (mounted) setState(() => _isSyncingDevice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(callsWorkspaceSnapshotProvider);
    ref.listen(callsWorkspaceSnapshotProvider, (_, next) {
      final snap = next.valueOrNull;
      if (snap != null) {
        _readyTracker.onContentReady(itemCount: snap.rows.length);
      }
    });

    return ShellTabBackBinding(
      onExitSearch: _handleExitSearch,
      child: snapshotAsync.when(
        loading: () => const CustomScrollView(
          slivers: [SliverToBoxAdapter(child: CallsWorkspaceSkeleton())],
        ),
        error: (_, __) => CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: CallsWorkspaceHeader(
                title: 'Çağrılarım',
                subtitle: 'Son aramalar ve geri dönüş aksiyonları',
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
                  title: 'Çağrılar yüklenemedi',
                  subtitle: 'Bağlantınızı kontrol edip tekrar deneyin.',
                  actionLabel: 'Yeniden dene',
                  onAction: () => CallsWorkspaceActions.refresh(ref),
                ),
              ),
            ),
          ],
        ),
        data: (snapshot) => _buildData(context, snapshot),
      ),
    );
  }

  Widget _buildData(BuildContext context, CallsWorkspaceSnapshot snapshot) {
    final reserve = _dockBottomReserve(context);

    final header = SliverToBoxAdapter(
      child: CallsWorkspaceHeader(
        title: 'Çağrılarım',
        subtitle: 'Son aramalar ve geri dönüş aksiyonları',
        dateChipLabel: snapshot.dateChipLabel,
        coverageNote: snapshot.coverageNote,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () => CallsWorkspaceActions.refresh(ref),
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
          if (io.Platform.isAndroid)
            SliverToBoxAdapter(
              child: AndroidCallLogSyncCta(
                isSyncing: _isSyncingDevice,
                onSync: _syncDevice,
              ),
            ),
          SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height * 0.48,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, reserve),
                child: Center(
                  child: EmptyState(
                    premiumVisual: true,
                    grouped: true,
                    icon: Icons.call_outlined,
                    title: 'Henüz çağrı kaydı yok',
                    subtitle:
                        'CRM içi görüşmeler ve tamamlanan kayıtlar burada '
                        'görünür. iOS’ta sistem arama günlüğü okunamaz; '
                        'Android’de isteğe bağlı içe aktarım yapabilirsiniz.',
                    actionLabel: io.Platform.isAndroid
                        ? 'Telefon geçmişini içe aktar'
                        : 'Yenile',
                    onAction: io.Platform.isAndroid
                        ? _syncDevice
                        : () => CallsWorkspaceActions.refresh(ref),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final filtered = filterCallsWorkspaceRows(
      snapshot.rows,
      query: _query,
      filter: _filter,
    );

    final showAttentionLane = _filter == CallsWorkspaceFilter.all &&
        _query.isEmpty &&
        snapshot.attentionRows.isNotEmpty;

    final slivers = <Widget>[
      header,
      SliverToBoxAdapter(
        child: CallsWorkspaceSummaryStrip(summary: snapshot.summary),
      ),
      if (snapshot.pendingLocalCount > 0)
        SliverToBoxAdapter(
          child: CallSyncPendingStrip(
            pendingCount: snapshot.pendingLocalCount,
            onTap: () {
              AppFeedback.selectionClick();
              setState(() => _filter = CallsWorkspaceFilter.callback);
            },
          ),
        ),
      if (io.Platform.isAndroid)
        SliverToBoxAdapter(
          child: AndroidCallLogSyncCta(
            isSyncing: _isSyncingDevice,
            onSync: _syncDevice,
          ),
        ),
      SliverToBoxAdapter(
        child: PremiumCallSearchRow(
          controller: _search.controller,
          focusNode: _searchFocus,
          hintText: 'İsim, telefon veya sonuç ara…',
          showMic: false,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 6)),
      SliverToBoxAdapter(
        child: CallsWorkspaceFilterStrip(
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
          child: CallsWorkspaceInlineNote(
            icon: Icons.filter_alt_off_rounded,
            message: _query.isNotEmpty
                ? 'Aramaya uyan çağrı bulunamadı.'
                : 'Bu görünümde çağrı yok.',
          ),
        ),
      );
    } else {
      if (showAttentionLane) {
        final attentionFiltered = filterCallsWorkspaceRows(
          snapshot.attentionRows,
          query: _query,
          filter: CallsWorkspaceFilter.all,
        );
        final laneRows = attentionFiltered.take(3).toList(growable: false);
        final laneKeys = laneRows.map((r) => r.recordKey).toSet();
        final mainRows =
            filtered.where((r) => !laneKeys.contains(r.recordKey)).toList();

        if (laneRows.isNotEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: CallsWorkspaceSectionHeader(
                label: 'Geri dönülmesi gerekenler',
                secondary: '${laneRows.length}',
              ),
            ),
          );
          slivers.add(
            SliverList.builder(
              itemCount: laneRows.length,
              itemBuilder: (context, index) => _buildRow(laneRows[index]),
            ),
          );
        }
        slivers.add(
          SliverToBoxAdapter(
            child: CallsWorkspaceSectionHeader(
              label: 'Son aramalar',
              secondary: '${mainRows.length}',
            ),
          ),
        );
        slivers.add(
          SliverList.builder(
            itemCount: mainRows.length,
            itemBuilder: (context, index) => _buildRow(mainRows[index]),
          ),
        );
      } else {
        slivers.add(
          SliverToBoxAdapter(
            child: CallsWorkspaceSectionHeader(
              label: 'Son aramalar',
              secondary: '${filtered.length}',
            ),
          ),
        );
      }

      if (!showAttentionLane) {
        slivers.add(
          SliverList.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) => _buildRow(filtered[index]),
          ),
        );
      }

      final canLoadMore = snapshot.hasMore &&
          _query.isEmpty &&
          _filter == CallsWorkspaceFilter.all;
      if (canLoadMore) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                ConsultantCallsTokens.horizontal,
                4,
                ConsultantCallsTokens.horizontal,
                8,
              ),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      CallsWorkspaceActions.loadMore(ref, snapshot.uid),
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  label: const Text('Daha fazla çağrı yükle'),
                ),
              ),
            ),
          ),
        );
      }
    }

    slivers.add(SliverPadding(padding: EdgeInsets.only(bottom: reserve)));

    return CustomScrollView(cacheExtent: 360, slivers: slivers);
  }

  Widget _buildRow(CallRowView row) {
    return CallsWorkspaceRow(
      row: row,
      onTap: () => CallsWorkspaceActions.openDetail(context, row),
      onCall: row.callablePhone
          ? () => CallsWorkspaceActions.call(context, row)
          : null,
      onMenu: (menu) => _onMenu(menu, row),
    );
  }

  void _onMenu(CallRowMenu menu, CallRowView row) {
    switch (menu) {
      case CallRowMenu.open:
        CallsWorkspaceActions.openDetail(context, row);
      case CallRowMenu.call:
        CallsWorkspaceActions.call(context, row);
      case CallRowMenu.message:
        CallsWorkspaceActions.message(context, row);
      case CallRowMenu.whatsapp:
        CallsWorkspaceActions.whatsapp(context, row);
      case CallRowMenu.customer:
        CallsWorkspaceActions.openCustomer(context, row);
      case CallRowMenu.followUp:
        CallsWorkspaceActions.addToFollowUp(context, ref, row);
      case CallRowMenu.tasks:
        CallsWorkspaceActions.goToTasks(context);
      case CallRowMenu.detail:
        CallsWorkspaceActions.showDetailSheet(context, ref, row);
    }
  }
}
