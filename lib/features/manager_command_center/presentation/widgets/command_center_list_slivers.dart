import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_surface_quick_filter.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/crm_call_record_display.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_callback_work_mode_cue.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_kpi_period.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_group_summary_tile.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_kpi_detail_sheet.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_capture_banner.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/models/command_center_chrome_config.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/models/command_center_scope_config.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/models/command_center_view_scope.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/widgets/command_center_crm_record_tile.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/widgets/command_center_filters_bar.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Komuta merkezi chrome + gruplu liste sliver fabrikası.
abstract final class CommandCenterListSlivers {
  CommandCenterListSlivers._();

  static const List<CallSurfaceQuickFilter> _quickFilterOrder = [
    CallSurfaceQuickFilter.all,
    CallSurfaceQuickFilter.today,
    CallSurfaceQuickFilter.unanswered,
    CallSurfaceQuickFilter.hot,
    CallSurfaceQuickFilter.reached,
    CallSurfaceQuickFilter.fresh,
  ];

  static const List<String> _quickFilterLabels = [
    'Tümü',
    'Bugün',
    'Cevapsız',
    'Operasyon',
    'Ulaşılan',
    'Yeni',
  ];

  static int _quickFilterIndex(CallSurfaceQuickFilter f) {
    final i = _quickFilterOrder.indexOf(f);
    return i < 0 ? 0 : i;
  }


  static List<Widget> buildChrome(
    BuildContext context, {
    required CommandCenterChromeConfig chrome,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered,
    required Map<String, String> agentNames,
  }) {
    final kpiSnapshot =
        CallKpiPeriodLogic.snapshotFromDocs(docs, chrome.kpiPeriod);

    return [
      const SliverToBoxAdapter(child: PostCallCaptureBanner()),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.screenEdgePadding,
            DesignTokens.space1,
            DesignTokens.screenEdgePadding,
            DesignTokens.space1,
          ),
          child: PremiumSegmentedControl<CommandCenterViewScope>(
            segments: const [
              CommandCenterViewScope.all,
              CommandCenterViewScope.consultant,
              CommandCenterViewScope.customer,
            ],
            selected: chrome.scope == CommandCenterViewScope.pending
                ? CommandCenterViewScope.all
                : chrome.scope,
            onSelected: chrome.onScopeChanged,
            labelBuilder: (s) => s.labelTr,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: CommandCenterFiltersBar(
          filterTeamId: chrome.filterTeamId,
          filterAgentId: chrome.filterAgentId,
          filterOutcome: chrome.filterOutcome,
          teamMemberIds: chrome.teamMemberIds,
          onTeamChanged: chrome.onTeamChanged,
          onAgentChanged: chrome.onAgentChanged,
          onOutcomeChanged: chrome.onOutcomeChanged,
        ),
      ),
      SliverToBoxAdapter(
        child: PremiumCallSearchRow(
          controller: chrome.searchController,
          focusNode: chrome.searchFocusNode,
          onSearchTap: () {
            if (chrome.searchQuery.isEmpty) {
              chrome.searchFocusNode.requestFocus();
            }
          },
        ),
      ),
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumCallQuickFilterStrip(
              labels: _quickFilterLabels,
              selectedIndex: chrome.eksikKayitChipSelected
                  ? -1
                  : _quickFilterIndex(chrome.quickFilter),
              onSelected: (i) {
                chrome.onQuickFilterChanged(_quickFilterOrder[i]);
              },
            ),
            if (chrome.onEksikKayitChipTap != null)
              Padding(
                padding: const EdgeInsets.only(
                  left: DesignTokens.screenEdgePadding,
                  top: 6,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PremiumFilterChip(
                    label: 'Eksik kayıt',
                    selected: chrome.eksikKayitChipSelected,
                    onTap: chrome.onEksikKayitChipTap!,
                  ),
                ),
              ),
          ],
        ),
      ),
      SliverToBoxAdapter(
        child: PremiumCallRecordsKpiCard(
          snapshot: kpiSnapshot,
          expanded: chrome.kpiExpanded,
          onToggleExpanded: chrome.onToggleKpiExpanded,
          onPeriodTap: chrome.onKpiPeriodTap,
          onDetailTap: () => showCallKpiDetailSheet(
            context,
            snapshot: kpiSnapshot,
          ),
        ),
      ),
      if (chrome.eksikKayitChipSelected && filtered.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.screenEdgePadding,
              DesignTokens.space1,
              DesignTokens.screenEdgePadding,
              0,
            ),
            child: Text(
              'Sonuç bekleyen ${filtered.length} kayıt',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppThemeExtension.of(context).warning,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: PremiumCallListToolbar(
          sortMode: chrome.sortMode,
          onSortChanged: chrome.onSortChanged,
        ),
      ),
      if (chrome.quickFilter == CallSurfaceQuickFilter.callback &&
          filtered.isNotEmpty)
        SliverToBoxAdapter(
          child: CallCallbackWorkModeCue(count: filtered.length),
        ),
    ];
  }

  static List<Widget> buildScope(
    BuildContext context, {
    required CommandCenterScopeConfig config,
  }) {
    switch (config.scope) {
      case CommandCenterViewScope.consultant:
        return _consultantGroupedSlivers(context, config);
      case CommandCenterViewScope.customer:
        return _customerGroupedSlivers(context, config);
      case CommandCenterViewScope.all:
      case CommandCenterViewScope.pending:
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        return [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.space4,
              DesignTokens.space1,
              DesignTokens.space4,
              config.listBottomInset,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => RepaintBoundary(
                  child: CommandCenterCrmRecordTile(
                    doc: config.filtered[index],
                    agentNames: config.agentNames,
                    locals: config.locals,
                    currentUid: config.currentUid,
                    customerFullNameById: config.customerFullNameById,
                    nowMs: nowMs,
                  ),
                ),
                childCount: config.filtered.length,
              ),
            ),
          ),
        ];
    }
  }

  static List<Widget> _consultantGroupedSlivers(
    BuildContext context,
    CommandCenterScopeConfig config,
  ) {
    final grouped =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final d in config.filtered) {
      final aid = CrmCallRecordHelpers.agentIdOf(d.data());
      if (aid.isEmpty) continue;
      grouped.putIfAbsent(aid, () => []).add(d);
    }
    for (final list in grouped.values) {
      list.sort((a, b) {
        final ta = CrmCallRecordHelpers.createdAtOf(a.data());
        final tb = CrmCallRecordHelpers.createdAtOf(b.data());
        return (tb ?? DateTime(1970)).compareTo(ta ?? DateTime(1970));
      });
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) {
        final ta = CrmCallRecordHelpers.createdAtOf(a.value.first.data());
        final tb = CrmCallRecordHelpers.createdAtOf(b.value.first.data());
        return (tb ?? DateTime(1970)).compareTo(ta ?? DateTime(1970));
      });
    if (entries.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            compact: true,
            anchorAboveCenter: true,
            anchorAlignmentY: -0.52,
            grouped: true,
            icon: Icons.groups_rounded,
            title: 'Danışman özeti yok',
            subtitle:
                'Filtrelere uyan veya müşteri/danışman bağlantılı kayıt bulunamadı.',
            outlinedActionLabel: 'Filtreleri temizle',
            onOutlinedAction: config.onClearFilters,
            actionLabel: 'Yeni arama başlat',
            onAction: () => context.push(
              AppRouter.routeCall,
              extra: const {
                'startedFromScreen': 'command_center_scope_consultant_empty',
              },
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          DesignTokens.space4,
          DesignTokens.space1,
          DesignTokens.space4,
          config.listBottomInset,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final e = entries[index];
              final list = e.value;
              final name = config.agentNames[e.key] ?? e.key;
              final pending = list
                  .where((d) => CrmCallRecordHelpers.isHandoffPending(d.data()))
                  .length;
              final last = list.first;
              final lastData = last.data();
              final dt = CrmCallRecordHelpers.createdAtOf(lastData);
              final timeStr = dt != null
                  ? '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'
                  : '—';
              final outcomeLast =
                  CrmCallRecordHelpers.outcomeDisplayTrDefault(lastData);
              final duration = lastData['durationSec'] as num?;
              final durationStr =
                  duration != null ? '${duration.toInt()} sn' : null;
              final subtitle = 'Son görüşme: $timeStr'
                  '${durationStr != null ? ' · $durationStr' : ''} · '
                  '${list.length} kayıt'
                  '${pending > 0 ? ' · $pending bekleyen' : ''}';
              final badgeLabel =
                  pending > 0 ? '$pending takip' : null;
              return RepaintBoundary(
                child: CallGroupSummaryTile(
                  title: name,
                  subtitle: subtitle,
                  outcomeLabel: outcomeLast,
                  badgeLabel: badgeLabel,
                  leadingLetter: name,
                  onTap: config.onDrillAgent != null
                      ? () => config.onDrillAgent!(e.key)
                      : null,
                ),
              );
            },
            childCount: entries.length,
          ),
        ),
      ),
    ];
  }

  static List<Widget> _customerGroupedSlivers(
    BuildContext context,
    CommandCenterScopeConfig config,
  ) {
    final grouped =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final d in config.filtered) {
      final cid = CrmCallRecordHelpers.customerIdOf(d.data());
      if (cid == null) continue;
      grouped.putIfAbsent(cid, () => []).add(d);
    }
    for (final list in grouped.values) {
      list.sort((a, b) {
        final ta = CrmCallRecordHelpers.createdAtOf(a.data());
        final tb = CrmCallRecordHelpers.createdAtOf(b.data());
        return (tb ?? DateTime(1970)).compareTo(ta ?? DateTime(1970));
      });
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) {
        final ta = CrmCallRecordHelpers.createdAtOf(a.value.first.data());
        final tb = CrmCallRecordHelpers.createdAtOf(b.value.first.data());
        return (tb ?? DateTime(1970)).compareTo(ta ?? DateTime(1970));
      });
    if (entries.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            compact: true,
            anchorAboveCenter: true,
            anchorAlignmentY: -0.52,
            grouped: true,
            icon: Icons.person_off_rounded,
            title: 'Müşteri bağlantılı kayıt yok',
            subtitle:
                'Filtrelere uyan, müşteri kartına bağlı çağrı kaydı bulunamadı.',
            outlinedActionLabel: 'Filtreleri temizle',
            onOutlinedAction: config.onClearFilters,
            actionLabel: 'Yeni arama başlat',
            onAction: () => context.push(
              AppRouter.routeCall,
              extra: const {
                'startedFromScreen': 'command_center_scope_customer_empty',
              },
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          DesignTokens.space4,
          DesignTokens.space1,
          DesignTokens.space4,
          config.listBottomInset,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final e = entries[index];
              final list = e.value;
              final last = list.first;
              final data = last.data();
              final outcome = CrmCallRecordHelpers.outcomeDisplayTrDefault(data);
              final dt = CrmCallRecordHelpers.createdAtOf(data);
              final timeStr = dt != null
                  ? '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'
                  : '—';
              final pending = list
                  .where((d) => CrmCallRecordHelpers.isHandoffPending(d.data()))
                  .length;
              final contactName =
                  CrmCallRecordDisplay.contactNameFromCallData(data);
              final title = CrmCallRecordDisplay.primaryTitle(
                customerFullName: config.customerFullNameById[e.key],
                contactDisplayName: contactName,
                rawPhone: null,
              );
              final subtitle =
                  'Son görüşme: $timeStr · ${list.length} kayıt'
                  '${pending > 0 ? ' · $pending bekleyen' : ''}';
              return RepaintBoundary(
                child: CallGroupSummaryTile(
                  title: title,
                  subtitle: subtitle,
                  outcomeLabel: outcome,
                  badgeLabel: pending > 0 ? '$pending takip' : null,
                  leadingLetter: title,
                  onTap: config.onDrillCustomer != null
                      ? () => config.onDrillCustomer!(e.key)
                      : null,
                ),
              );
            },
            childCount: entries.length,
          ),
        ),
      ),
    ];
  }
}
