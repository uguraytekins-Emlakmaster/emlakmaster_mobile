import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_surface_quick_filter.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/crm_call_record_display.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_callback_work_mode_cue.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/crm_call_operating_card.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/crm_call_record_list_item.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/manager_calls_team_rhythm_strip.dart';
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
    return [
      const SliverToBoxAdapter(child: PostCallCaptureBanner()),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.screenEdgePadding,
          ),
          child: PremiumInfoBanner(
            message:
                'Bu ekranda çağrıların CRM özeti görünür: sonuç, saat ve kısa not.',
          ),
        ),
      ),
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
              CommandCenterViewScope.pending,
            ],
            selected: chrome.scope,
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
        child: PremiumCallQuickFilterStrip(
          labels: _quickFilterLabels,
          selectedIndex: _quickFilterIndex(chrome.quickFilter),
          onSelected: (i) =>
              chrome.onQuickFilterChanged(_quickFilterOrder[i]),
        ),
      ),
      SliverToBoxAdapter(
        child: PremiumCallRecordsKpiCard(
          stats: CallRecordKpiStats.fromFirestoreDocs(docs),
          expanded: chrome.kpiExpanded,
          onToggleExpanded: chrome.onToggleKpiExpanded,
        ),
      ),
      SliverToBoxAdapter(
        child: ManagerCallsTeamRhythmStrip(
          line: ManagerCallsTeamRhythmLogic.computeLine(docs, agentNames),
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
                (context, index) => CommandCenterCrmRecordTile(
                  doc: config.filtered[index],
                  agentNames: config.agentNames,
                  locals: config.locals,
                  currentUid: config.currentUid,
                  customerFullNameById: config.customerFullNameById,
                  nowMs: nowMs,
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
    final accent = AppThemeExtension.of(context).accent;
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
              final completed = list
                  .where((d) => CrmCallRecordHelpers.hasCaptureCompleted(d.data()))
                  .length;
              final handoffs = list
                  .where((d) => CrmCallRecordHelpers.isSystemHandoff(d.data()))
                  .length;
              final last = list.first;
              final lastData = last.data();
              final dt = CrmCallRecordHelpers.createdAtOf(lastData);
              final timeStr = dt != null
                  ? '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'
                  : '—';
              final outcomeLast =
                  CrmCallRecordHelpers.outcomeDisplayTrDefault(lastData);
              final noteLast =
                  CrmCallRecordDisplay.notePreviewFromFirestoreData(lastData);
              final duration = lastData['durationSec'] as num?;
              final durationStr =
                  duration != null ? '${duration.toInt()} sn' : null;
              final contextLine = 'Son görüşme: $timeStr'
                  '${durationStr != null ? ' · $durationStr' : ''} · '
                  '${list.length} kayıt · $pending bekleyen · '
                  '$completed tamam · $handoffs handoff';
              final captureLabel =
                  pending > 0 ? '$pending takip' : '${list.length} kayıt';
              return CrmCallOperatingCard(
                dense: true,
                child: CrmCallRecordListItem(
                  dense: true,
                  title: name,
                  outcomeLabel: outcomeLast,
                  captureLabel: captureLabel,
                  contextLine: contextLine,
                  notePreview: noteLast,
                  technicalFootnote:
                      'Danışman ${CrmCallRecordDisplay.ellipsedMiddle(e.key)}',
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.078),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusSm + 2),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.20),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
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
    final accent = AppThemeExtension.of(context).accent;
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
              final agent = CrmCallRecordHelpers.agentIdOf(data);
              final outcome = CrmCallRecordHelpers.outcomeDisplayTrDefault(data);
              final cap = CrmCallRecordHelpers.captureStatusTr(data);
              final dt = CrmCallRecordHelpers.createdAtOf(data);
              final timeStr = dt != null
                  ? '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'
                  : '—';
              final pending = list
                  .where((d) => CrmCallRecordHelpers.isHandoffPending(d.data()))
                  .length;
              final rawPhone =
                  (data['phoneNumber'] ?? data['phone'] ?? '').toString();
              final hasDigits = rawPhone.replaceAll(RegExp(r'\D'), '').isNotEmpty;
              final formattedPhone =
                  hasDigits ? CrmCallRecordDisplay.formatPhone(rawPhone) : '—';
              final contactName =
                  CrmCallRecordDisplay.contactNameFromCallData(data);
              final title = CrmCallRecordDisplay.primaryTitle(
                customerFullName: config.customerFullNameById[e.key],
                contactDisplayName: contactName,
                rawPhone: hasDigits ? rawPhone : null,
              );
              final phoneUnder = CrmCallRecordDisplay.shouldShowPhoneUnderTitle(
                title: title,
                formattedPhone: formattedPhone,
              )
                  ? formattedPhone
                  : null;
              final advisorPart = CrmCallRecordDisplay.advisorContext(
                advisorAgentId: agent,
                currentUid: null,
                agentNames: config.agentNames,
              );
              final contextLine = CrmCallRecordDisplay.contextLine(
                advisorPart: advisorPart,
                dateTime: timeStr,
              );
              final captureLabel =
                  pending > 0 ? '$pending takip' : '${list.length} kayıt';
              return CrmCallOperatingCard(
                dense: true,
                child: CrmCallRecordListItem(
                  dense: true,
                  title: title,
                  phoneSubtitle: phoneUnder,
                  outcomeLabel: outcome,
                  captureLabel: captureLabel,
                  contextLine: contextLine,
                  technicalFootnote:
                      'Müşteri ${CrmCallRecordDisplay.ellipsedMiddle(e.key, head: 6)}',
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.078),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusSm + 2),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.20),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      title.isNotEmpty ? title.substring(0, 1).toUpperCase() : '?',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
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
