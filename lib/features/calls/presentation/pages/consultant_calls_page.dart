import 'dart:async';

import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/platform/io_platform_stub.dart'
    if (dart.library.io) 'dart:io' as io;
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_kpi_period.dart';
import 'package:emlakmaster_mobile/features/calls/application/call_record_detail_navigation.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_list_sort.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_list_source.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_record_row_summary.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_record_grid_tile.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/consultant_calls_search_filter.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/android_call_log_sync_cta.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_kpi_detail_sheet.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_sync_pending_strip.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/utils/csv_export.dart';
import 'package:emlakmaster_mobile/core/utils/sms_launcher.dart';
import 'package:emlakmaster_mobile/core/utils/whatsapp_launcher.dart';
import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/device_call_log_sync_service.dart';
import 'package:emlakmaster_mobile/features/calls/domain/quick_call_outcome.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/domain/local_call_sync_ui_state.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_name_lookup_provider.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_display_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/firestore_agent_display_names_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/local_call_records_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/crm_call_record_display.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_sync_status_icon.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/crm_call_operating_card.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_record_premium_tile.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_identity_quick_actions_sheet.dart';
import 'package:emlakmaster_mobile/screens/consultant_shell_nav.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_list_date_sections.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_surface_quick_filter.dart';
import 'package:emlakmaster_mobile/features/contact_save/presentation/widgets/save_contact_sheet.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/calls_surface_ack.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_capture_banner.dart';
import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/features/calls/application/start_crm_outbound_call.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
/// Danışmanın tüm çağrıları (gelen/giden), numaralar, toplu veri export ve toplu SMS.
class ConsultantCallsPage extends ConsumerStatefulWidget {
  const ConsultantCallsPage({super.key});

  @override
  ConsumerState<ConsultantCallsPage> createState() =>
      _ConsultantCallsPageState();
}

class _ConsultantCallsPageState extends ConsumerState<ConsultantCallsPage> {
  final _readyTracker = ShellScreenReadyTracker('consultant_calls');
  final Set<String> _selectedIds = {};
  bool _isSyncingDeviceCalls = false;
  CallSurfaceQuickFilter _quickFilter = CallSurfaceQuickFilter.all;
  bool _kpiExpanded = false;
  CallListSortMode _sortMode = CallListSortMode.lastCall;
  CallListViewMode _viewMode = CallListViewMode.list;
  CallKpiPeriod _kpiPeriod = CallKpiPeriod.thisMonth;
  bool _selectionMode = false;
  CallListSource _listSource = CallListSource.all;
  String _searchQuery = '';
  late final DebouncedSearchController _debouncedSearch;
  final FocusNode _searchFocusNode = FocusNode();

  static const List<CallSurfaceQuickFilter> _quickFilterOrder = [
    CallSurfaceQuickFilter.all,
    CallSurfaceQuickFilter.today,
    CallSurfaceQuickFilter.unanswered,
    CallSurfaceQuickFilter.callback,
    CallSurfaceQuickFilter.hot,
  ];

  static const List<String> _quickFilterLabels = [
    'Tümü',
    'Bugün',
    'Cevapsız',
    'Geri aranacak',
    'Operasyon',
  ];

  int _quickFilterIndex() {
    final i = _quickFilterOrder.indexOf(_quickFilter);
    return i < 0 ? 0 : i;
  }

  /// WhatsApp sırayla aç: kuyruk ve şu anki indeks (açılan bir sonraki).
  List<String>? _whatsappQueue;
  int _whatsappIndex = 0;
  String _whatsappMessage = '';
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];

  @override
  void initState() {
    super.initState();
    _debouncedSearch = DebouncedSearchController(
      onQueryChanged: (q) {
        if (!mounted) return;
        setState(() => _searchQuery = q);
      },
    );
  }

  @override
  void dispose() {
    _debouncedSearch.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  TextEditingController get _searchController => _debouncedSearch.controller;

  Future<void> _refreshCalls() async {
    ref.invalidate(consultantCallsStreamProvider);
    ref.invalidate(localCallRecordsStreamProvider);
    if (io.Platform.isAndroid) {
      await _syncDeviceCallLog();
    }
  }

  int _pendingLocalCount(List<LocalCallRecord> locals, int nowMs) {
    var n = 0;
    for (final r in locals) {
      final st = deriveLocalCallSyncUiState(r, nowMs: nowMs);
      if (st != LocalCallSyncUiState.synced || !r.hasQuickCapturePayload) {
        n++;
      }
    }
    return n;
  }

  void _openCustomerDirectoryForLinking() {
    ConsultantShellNav.goToCustomersTab(context);
  }

  Widget _listRowWithDateHeader({
    required int index,
    required List<LocalCallRecord> filteredLocals,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (callListShouldShowDateHeader(
          index: index,
          filteredLocals: filteredLocals,
          filteredDocs: filteredDocs,
        ))
          CallListDateSectionHeader(
            label: callListDateHeaderLabelForIndex(
              index: index,
              filteredLocals: filteredLocals,
              filteredDocs: filteredDocs,
            ),
          ),
        child,
      ],
    );
  }

  Widget _consultantGridCell(
    BuildContext context, {
    required int index,
    required List<LocalCallRecord> filteredLocals,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs,
    required Map<String, String> customerNames,
  }) {
    final CallRecordRowSummary row;
    if (index < filteredLocals.length) {
      row = CallRecordRowSummary.fromLocal(
        filteredLocals[index],
        customerNames,
      );
    } else {
      row = CallRecordRowSummary.fromFirestore(
        filteredDocs[index - filteredLocals.length],
        customerNames,
      );
    }
    return RepaintBoundary(
      child: CallRecordGridTile(
        title: row.title,
        directionDuration: row.directionDuration,
        outcomeLabel: row.outcomeLabel,
        onTap: () => showCallIdentityQuickActionsSheet(
          context,
          rawPhone: row.rawPhone,
          customerId: row.customerId,
          displayLabel: row.title,
          firestoreCallDocId: row.firestoreDocId,
          onCallListMutated: () =>
              ref.invalidate(consultantCallsStreamProvider),
          onOpenCustomerDirectory: _openCustomerDirectoryForLinking,
        ),
      ),
    );
  }

  void _selectAll(
    bool select, [
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>? firestoreVisible,
  ]) {
    setState(() {
      if (select) {
        final target = firestoreVisible ?? _docs;
        for (final d in target) {
          _selectedIds.add(d.id);
        }
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      _selectionMode = true;
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        AppFeedback.selectionClick();
        _selectedIds.add(id);
      }
    });
  }

  void _enterSelectionMode() {
    setState(() => _selectionMode = true);
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _cycleKpiPeriod() {
    setState(() {
      _kpiPeriod = _kpiPeriod == CallKpiPeriod.thisMonth
          ? CallKpiPeriod.allTime
          : CallKpiPeriod.thisMonth;
    });
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _selectedDocs() {
    final idSet = _selectedIds.toSet();
    return _docs.where((d) => idSet.contains(d.id)).toList();
  }

  List<String> _phonesFromDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> list) {
    final phones = <String>[];
    for (final d in list) {
      final data = d.data();
      final p =
          data['phoneNumber'] as String? ?? data['phone'] as String? ?? '';
      if (p.trim().isNotEmpty) phones.add(p.trim());
    }
    return phones;
  }

  void _copyCsvToClipboard() {
    final list = _selectedIds.isEmpty ? _docs : _selectedDocs();
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dışarı alınacak görüşme yok.')),
      );
      return;
    }
    final csv = callsToCsvWithPhones(list);
    Clipboard.setData(ClipboardData(text: csv));
    if (mounted) {
      showCallsSurfaceAck(
        context,
        'CSV panoya hazır · ${list.length} satır',
      );
      AnalyticsService.instance.logEvent(AnalyticsEvents.callsExportCsv, {
        AnalyticsEvents.paramCount: list.length,
      });
    }
  }

  Future<void> _openBulkSms() async {
    final list = _selectedIds.isEmpty ? _docs : _selectedDocs();
    final phones = _phonesFromDocs(list);
    if (phones.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('SMS için en az bir geçerli numara seçin.')),
        );
      }
      return;
    }
    final ok = await SmsLauncher.openBulkSms(phones);
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS uygulaması açılamadı.')),
      );
    } else if (mounted && ok) {
      showCallsSurfaceAck(context, 'SMS akışı başlatıldı');
      AnalyticsService.instance.logEvent(AnalyticsEvents.callsBulkSms, {
        AnalyticsEvents.paramCount: phones.length,
      });
    }
  }

  /// Toplu WhatsApp: seçili numaraları sırayla WhatsApp’ta açar (opsiyonel mesaj ile).
  Future<void> _openWhatsAppBulk() async {
    final list = _selectedIds.isEmpty ? _docs : _selectedDocs();
    final phones = _phonesFromDocs(list);
    if (phones.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('WhatsApp için en az bir geçerli numara seçin.')),
        );
      }
      return;
    }
    final controller = TextEditingController(text: _whatsappMessage);
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final dTheme = Theme.of(ctx);
        final dIsDark = dTheme.brightness == Brightness.dark;
        final dSurface = dIsDark
            ? AppThemeExtension.of(context).surface
            : AppThemeExtension.of(context).surface;
        final dBg = dIsDark
            ? AppThemeExtension.of(context).background
            : AppThemeExtension.of(context).background;
        final dFg = dIsDark
            ? AppThemeExtension.of(context).textPrimary
            : AppThemeExtension.of(context).textPrimary;
        final dSecondary = dIsDark
            ? AppThemeExtension.of(context).textSecondary
            : AppThemeExtension.of(context).textSecondary;
        return AlertDialog(
          backgroundColor: dSurface,
          title: Text('WhatsApp akışını aç', style: TextStyle(color: dFg)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${phones.length} kişi seçildi. Dilerseniz bir mesaj hazırlayın; sohbet açıldığında kutuya yerleşir.',
                  style: AppTypography.body(ctx).copyWith(color: dSecondary),
                ),
                const SizedBox(height: DesignTokens.space3),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Merhaba, size uygun bir ilan paylaşabilirim...',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                    filled: true,
                    fillColor: dBg,
                  ),
                  style: AppTypography.bodyStrong(ctx).copyWith(color: dFg),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(foregroundColor: dSecondary),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              style: FilledButton.styleFrom(
                  backgroundColor: AppThemeExtension.of(context).accent),
              child: const Text('İlk sohbeti aç'),
            ),
          ],
        );
      },
    );
    if (message == null || !mounted) return;
    _whatsappMessage = message;
    setState(() {
      _whatsappQueue = phones;
      _whatsappIndex = 0;
    });
    final opened = await WhatsAppLauncher.openChat(phones.first,
        message: _whatsappMessage.trim().isEmpty ? null : _whatsappMessage);
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'WhatsApp açılamadı. Uygulamanın yüklü olduğundan emin olun.')),
      );
    } else if (mounted) {
      showCallsSurfaceAck(context, 'Mesaj akışı başlatıldı');
    }
    setState(() => _whatsappIndex = 1);
    if (_whatsappIndex >= _whatsappQueue!.length) {
      setState(() {
        _whatsappQueue = null;
        _whatsappIndex = 0;
      });
    }
    AnalyticsService.instance.logEvent(AnalyticsEvents.callsBulkWhatsappStart, {
      AnalyticsEvents.paramCount: phones.length,
    });
  }

  Future<void> _openNextWhatsApp() async {
    final queue = _whatsappQueue;
    if (queue == null || _whatsappIndex >= queue.length) {
      setState(() {
        _whatsappQueue = null;
        _whatsappIndex = 0;
      });
      return;
    }
    final phone = queue[_whatsappIndex];
    final message = _whatsappMessage.trim().isEmpty ? null : _whatsappMessage;
    await WhatsAppLauncher.openChat(phone, message: message);
    if (!mounted) return;
    setState(() => _whatsappIndex = _whatsappIndex + 1);
    if (_whatsappIndex >= queue.length) {
      setState(() {
        _whatsappQueue = null;
        _whatsappIndex = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp akışı tamamlandı.')),
      );
    }
  }

  void _clearWhatsAppQueue() {
    setState(() {
      _whatsappQueue = null;
      _whatsappIndex = 0;
    });
  }

  String _syncSubtitleHint(LocalCallSyncUiState s) {
    return switch (s) {
      LocalCallSyncUiState.pending => 'Aktarım sırası bekleniyor',
      LocalCallSyncUiState.syncing => 'Buluta aktarılıyor',
      LocalCallSyncUiState.synced => 'Bulutta hazır',
      LocalCallSyncUiState.failedRetry => 'Kısa süre sonra yeniden denenecek',
      LocalCallSyncUiState.failedPermanent =>
        'Buluta aktarılamadı · Yeniden dene',
    };
  }

  Widget _buildIosInfoBanner(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space2 + 2,
        DesignTokens.space4,
        DesignTokens.space2 + 2,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ext.infoSurface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(color: ext.border.withValues(alpha: 0.52)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space3,
            DesignTokens.space4,
            DesignTokens.space4,
            DesignTokens.space3,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  margin: const EdgeInsets.only(right: DesignTokens.space3),
                  decoration: BoxDecoration(
                    color: ext.accent.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: ext.info,
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      'Ürün notu',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: ext.accent.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space1),
                    Text(
                      'iOS’ta yalnızca uygulama içi görüşmeler',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.22,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space1 + 2),
                    Text(
                      'Apple kısıtları nedeniyle sistem arama geçmişi bu listede yer almaz; CRM’deki kayıtlar uygulama üzerinden yapılan görüşmelerdir.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ext.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.48,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _consultantSelectionCommandBar(
    BuildContext context,
    AppThemeExtension ext,
    Color fg,
  ) {
    final n = _selectedIds.length;
    return Material(
      color: ext.card,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: ext.border.withValues(alpha: 0.38)),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space1 + 2,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Text(
                '$n seçili',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _openBulkSms,
                icon: const Icon(Icons.sms_rounded),
                tooltip: 'Toplu SMS',
              ),
              const SizedBox(width: DesignTokens.space2),
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _openWhatsAppBulk,
                icon: const Icon(Icons.chat_rounded),
                tooltip: 'WhatsApp akışı',
              ),
              const SizedBox(width: DesignTokens.space2),
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _copyCsvToClipboard,
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'CSV panoya',
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _callsChromeSlivers({
    required BuildContext context,
    required AppThemeExtension ext,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs,
    required int visibleTotal,
    required int totalCount,
    required int pendingLocalCount,
  }) {
    final theme = Theme.of(context);
    final fg = ext.textPrimary;
    final textSecondary = ext.textSecondary;
    final kpiSnapshot =
        CallKpiPeriodLogic.snapshotFromDocs(_docs, _kpiPeriod);

    return [
      const SliverToBoxAdapter(child: PostCallCaptureBanner()),
      if (io.Platform.isIOS)
        const SliverToBoxAdapter(
          child: PremiumCallsPlatformHint(
            message:
                'iOS’ta yalnızca uygulama içi görüşmeler listelenir; sistem arama geçmişi dahil değildir.',
          ),
        ),
      if (io.Platform.isAndroid)
        SliverToBoxAdapter(
          child: AndroidCallLogSyncCta(
            isSyncing: _isSyncingDeviceCalls,
            onSync: _syncDeviceCallLog,
          ),
        ),
      SliverToBoxAdapter(
        child: PremiumCallSearchRow(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onSearchTap: () {
            if (_searchQuery.isEmpty) _searchFocusNode.requestFocus();
          },
        ),
      ),
      SliverToBoxAdapter(
        child: CallSyncPendingStrip(
          pendingCount: pendingLocalCount,
          onTap: () => setState(() => _listSource = CallListSource.deviceDraft),
        ),
      ),
      SliverToBoxAdapter(
        child: PremiumCallRecordsKpiCard(
          snapshot: kpiSnapshot,
          expanded: _kpiExpanded,
          listViewMode: _viewMode,
          onToggleExpanded: () => setState(() => _kpiExpanded = !_kpiExpanded),
          onPeriodTap: _cycleKpiPeriod,
          onDetailTap: () => showCallKpiDetailSheet(
            context,
            snapshot: kpiSnapshot,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: PremiumCallSourceFilterStrip(
          selected: _listSource,
          onSelected: (s) => setState(() => _listSource = s),
        ),
      ),
      SliverToBoxAdapter(
        child: PremiumCallQuickFilterStrip(
          labels: _quickFilterLabels,
          selectedIndex: _quickFilterIndex(),
          onSelected: (i) => setState(() => _quickFilter = _quickFilterOrder[i]),
        ),
      ),
      SliverToBoxAdapter(
        child: PremiumCallListToolbar(
          sortMode: _sortMode,
          onSortChanged: (m) => setState(() => _sortMode = m),
          viewMode: _viewMode,
          onViewModeChanged: (m) => setState(() {
            _viewMode = m;
            if (m == CallListViewMode.chart) _kpiExpanded = true;
          }),
          trailing: _selectionMode || _selectedIds.isNotEmpty
              ? TextButton(
                  onPressed: _exitSelectionMode,
                  child: const Text('Seçimi bitir'),
                )
              : TextButton(
                  onPressed: _enterSelectionMode,
                  child: const Text('Seç'),
                ),
        ),
      ),
      if (_selectedIds.isNotEmpty)
        SliverToBoxAdapter(
          child: _consultantSelectionCommandBar(context, ext, fg),
        ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space4,
            DesignTokens.space1,
            DesignTokens.space4,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _quickFilterLabels[_quickFilterIndex()],
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: _quickFilter == CallSurfaceQuickFilter.all
                            ? ' · $totalCount kayıt'
                            : ' · $visibleTotal kayıt',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_selectionMode || _selectedIds.isNotEmpty) ...[
                TextButton(
                  onPressed: () => _selectAll(true, filteredDocs),
                  style: TextButton.styleFrom(
                    foregroundColor: ext.accent,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Hepsini seç'),
                ),
                TextButton(
                  onPressed: _exitSelectionMode,
                  style: TextButton.styleFrom(
                    foregroundColor: textSecondary,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Seçimi kaldır'),
                ),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  Future<void> _syncDeviceCallLog() async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    if (uid == null || uid.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oturum açık değil.')),
        );
      }
      return;
    }
    if (!io.Platform.isAndroid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Telefon arama geçmişi yalnızca Android\'de desteklenir. iOS\'ta yalnızca uygulama içi görüşmeler listelenir.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    setState(() => _isSyncingDeviceCalls = true);
    final result =
        await DeviceCallLogSyncService.instance.syncCallLogToFirestore(uid);
    if (!mounted) return;
    setState(() => _isSyncingDeviceCalls = false);
    AnalyticsService.instance.logEvent(AnalyticsEvents.callsDeviceSyncResult, {
      AnalyticsEvents.paramResult: result.name,
    });
    switch (result) {
      case DeviceCallLogSyncResult.success:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telefon görüşmeleri içeri alındı.')),
        );
        break;
      case DeviceCallLogSyncResult.permissionDenied:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arama geçmişi izni verilmedi.')),
        );
        break;
      case DeviceCallLogSyncResult.permissionPermanentlyDenied:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Arama geçmişi izni kapalı. İsterseniz ayarlardan açabilirsiniz.'),
            action: SnackBarAction(
              label: 'İzin ayarları',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        break;
      case DeviceCallLogSyncResult.notSupported:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bu cihaz arama geçmişini desteklemiyor.')),
        );
        break;
      case DeviceCallLogSyncResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aktarım sırasında bir sorun oluştu.')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? AppThemeExtension.of(context).background
        : AppThemeExtension.of(context).background;
    final fg = isDark
        ? AppThemeExtension.of(context).textPrimary
        : AppThemeExtension.of(context).textPrimary;
    final surface = isDark
        ? AppThemeExtension.of(context).surface
        : AppThemeExtension.of(context).surface;
    final textSecondary = isDark
        ? AppThemeExtension.of(context).textSecondary
        : AppThemeExtension.of(context).textSecondary;
    final ext = AppThemeExtension.of(context);
    final callsAsync = ref.watch(consultantCallsDisplayProvider);
    ref.listen(consultantCallsDisplayProvider, (previous, next) {
      if (next.hasValue) {
        _readyTracker.onContentReady(itemCount: next.value!.length);
      }
    });
    final currentUid =
        ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''));
    final agentNames =
        ref.watch(firestoreAgentDisplayNamesProvider).valueOrNull ??
            const <String, String>{};
    if (kDebugMode && callsAsync.isLoading) {
      AppLogger.d('[consultant_calls] loading...');
    }
    if (kDebugMode && callsAsync.hasError) {
      AppLogger.w(
        '[consultant_calls] error',
        callsAsync.error,
        callsAsync.stackTrace,
      );
    }

    final queue = _whatsappQueue;
    final hasQueue =
        queue != null && queue.isNotEmpty && _whatsappIndex < queue.length;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PremiumCallCenterPageHeader(
              compact: true,
              title: ProductLabels.myCalls,
              subtitle: 'CRM çağrı merkezi',
              actions: [
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz_rounded, color: ext.accent),
                  onSelected: (value) {
                    switch (value) {
                      case 'csv':
                        _copyCsvToClipboard();
                      case 'sms':
                        _openBulkSms();
                      case 'whatsapp':
                        _openWhatsAppBulk();
                      case 'sync':
                        if (io.Platform.isAndroid && !_isSyncingDeviceCalls) {
                          unawaited(_syncDeviceCallLog());
                        }
                      case 'select':
                        _enterSelectionMode();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'csv',
                      child: ListTile(
                        leading: Icon(Icons.copy_rounded),
                        title: Text('CSV dışa aktar'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'sms',
                      child: ListTile(
                        leading: Icon(Icons.sms_rounded),
                        title: Text('Toplu SMS'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'whatsapp',
                      child: ListTile(
                        leading: Icon(Icons.chat_rounded),
                        title: Text('WhatsApp akışı'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (io.Platform.isAndroid)
                      const PopupMenuItem(
                        value: 'sync',
                        child: ListTile(
                          leading: Icon(Icons.phone_android_rounded),
                          title: Text('Telefon geçmişini içeri al'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'select',
                      child: ListTile(
                        leading: Icon(Icons.checklist_rounded),
                        title: Text('Toplu seçim'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: callsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
              color: AppThemeExtension.of(context).accent),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    color: textSecondary, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Çağrılar yüklenemedi.',
                  style: AppTypography.cardHeading(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(FirestoreService.userFacingErrorMessage(e),
                    style: AppTypography.body(context)
                        .copyWith(color: textSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: DesignTokens.space4),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(consultantCallsStreamProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
        data: (docs) {
          final customerNames = ref.watch(customerNameLookupProvider);
          _docs = docs;
          if (kDebugMode) {
            AppLogger.d('[consultant_calls] loaded docs=${docs.length}');
          }
          final locals =
              ref.watch(localCallRecordsStreamProvider).valueOrNull ?? [];
          final docIds = docs.map((d) => d.id).toSet();
          final byFirestoreId = <String, LocalCallRecord>{};
          for (final r in locals) {
            final fid = r.firestoreDocumentId;
            if (fid != null && fid.isNotEmpty) {
              byFirestoreId[fid] = r;
            }
          }
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final localStandalone = <LocalCallRecord>[];
          for (final r in locals) {
            final fid = r.firestoreDocumentId;
            if (fid != null && docIds.contains(fid)) continue;
            if (deriveLocalCallSyncUiState(r, nowMs: nowMs) ==
                LocalCallSyncUiState.synced) {
              continue;
            }
            localStandalone.add(r);
          }
          localStandalone.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (_docs.isEmpty && localStandalone.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (io.Platform.isIOS) _buildIosInfoBanner(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space6),
                    child: EmptyState(
                      premiumVisual: true,
                      grouped: true,
                      anchorAboveCenter: true,
                      icon: Icons.call_rounded,
                      title:
                          AppLocalizations.of(context).t('empty_calls_title'),
                      subtitle:
                          AppLocalizations.of(context).t('empty_calls_sub'),
                      outlinedActionLabel: 'Portföye kaydet',
                      onOutlinedAction: () => showSaveContactSheet(
                        context,
                        source: 'consultant_calls_empty',
                      ),
                      actionLabel:
                          AppLocalizations.of(context).t('empty_calls_cta'),
                      onAction: () => context.push(
                        AppRouter.routeCall,
                        extra: const {
                          'startedFromScreen': 'consultant_calls',
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          final totalCount = localStandalone.length + _docs.length;
          final pendingLocalCount = _pendingLocalCount(localStandalone, nowMs);
          final searchLower = _searchQuery.toLowerCase();
          final periodDocs = _kpiPeriod == CallKpiPeriod.thisMonth
              ? CallKpiPeriodLogic.filterDocs(_docs, _kpiPeriod).toList()
              : _docs;
          var filteredDocs = periodDocs
              .where(
                (d) => CallSurfaceQuickFilterLogic.matchesFirestoreDoc(
                  d,
                  _quickFilter,
                ),
              )
              .where(
                (d) => ConsultantCallsSearchFilter.matchesFirestoreDoc(
                  d,
                  searchLower,
                  customerNames,
                ),
              )
              .toList();
          if (_listSource == CallListSource.deviceDraft) {
            filteredDocs = [];
          }
          CallListSortLogic.sortFirestoreDocs(filteredDocs, _sortMode);
          var filteredLocals = localStandalone
              .where(
                (r) => CallSurfaceQuickFilterLogic.matchesLocalRecord(
                  r,
                  _quickFilter,
                ),
              )
              .where(
                (r) => ConsultantCallsSearchFilter.matchesLocalRecord(
                  r,
                  searchLower,
                  customerNames,
                ),
              )
              .toList();
          if (_listSource == CallListSource.crmOnly) {
            filteredLocals = [];
          }
          CallListSortLogic.sortLocalRecords(filteredLocals, _sortMode);
          final visibleTotal =
              filteredLocals.length + filteredDocs.length;
          if (visibleTotal == 0 && totalCount > 0) {
            return RefreshIndicator(
              color: ext.accent,
              onRefresh: _refreshCalls,
              child: CustomScrollView(
              slivers: [
                ..._callsChromeSlivers(
                  context: context,
                  ext: ext,
                  filteredDocs: filteredDocs,
                  visibleTotal: visibleTotal,
                  totalCount: totalCount,
                  pendingLocalCount: pendingLocalCount,
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.space6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_alt_off_rounded,
                              size: 44, color: textSecondary),
                          const SizedBox(height: DesignTokens.space3),
                          Text(
                            'Bu filtreye uygun görüşme yok',
                            textAlign: TextAlign.center,
                            style: AppTypography.cardHeading(context),
                          ),
                          const SizedBox(height: DesignTokens.space2),
                          FilledButton.tonal(
                            onPressed: () => setState(() =>
                                _quickFilter = CallSurfaceQuickFilter.all),
                            child: const Text('Filtreyi sıfırla'),
                          ),
                          const SizedBox(height: DesignTokens.space2),
                          OutlinedButton.icon(
                            onPressed: () => context.push(
                              AppRouter.routeCall,
                              extra: const {
                                'startedFromScreen':
                                    'consultant_calls_filter_empty',
                              },
                            ),
                            icon: const Icon(Icons.call_made_rounded, size: 18),
                            label: const Text('Yeni arama başlat'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              ),
            );
          }
          final listBottomInset =
              DashboardLayoutTokens.contentScrollBottomInset(context);
          return RefreshIndicator(
            color: ext.accent,
            onRefresh: _refreshCalls,
            child: CustomScrollView(
            cacheExtent: 480,
            slivers: [
              ..._callsChromeSlivers(
                context: context,
                ext: ext,
                filteredDocs: filteredDocs,
                visibleTotal: visibleTotal,
                totalCount: totalCount,
                pendingLocalCount: pendingLocalCount,
              ),
              if (_viewMode == CallListViewMode.chart)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      DesignTokens.space4,
                      DesignTokens.space2,
                      DesignTokens.space4,
                      listBottomInset,
                    ),
                    child: Text(
                      'Kayıt listesi için liste veya ızgara görünümüne geçin.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ),
                )
              else if (_viewMode == CallListViewMode.grid)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    DesignTokens.space4,
                    DesignTokens.space1,
                    DesignTokens.space4,
                    listBottomInset,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: DesignTokens.space2,
                      crossAxisSpacing: DesignTokens.space2,
                      childAspectRatio: 0.92,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _consultantGridCell(
                        context,
                        index: index,
                        filteredLocals: filteredLocals,
                        filteredDocs: filteredDocs,
                        customerNames: customerNames,
                      ),
                      childCount: visibleTotal,
                    ),
                  ),
                )
              else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  DesignTokens.space4,
                  DesignTokens.space1,
                  DesignTokens.space4,
                  listBottomInset,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                    if (index < filteredLocals.length) {
                      final r = filteredLocals[index];
                      final dt =
                          DateTime.fromMillisecondsSinceEpoch(r.createdAt);
                      final callTime = callListTimeLabel(dt);
                      final outcomeStr = r.outcome ?? '—';
                      final syncHint = _syncSubtitleHint(
                        deriveLocalCallSyncUiState(r, nowMs: nowMs),
                      );
                      final custName =
                          r.customerId != null && r.customerId!.isNotEmpty
                              ? customerNames[r.customerId!]
                              : null;
                      final localTitle = CrmCallRecordDisplay.primaryTitle(
                        customerFullName: custName,
                        rawPhone: r.phoneNumber,
                      );
                      final localDirection =
                          CallRecordPremiumTile.formatDirectionDuration(
                        isIncoming: false,
                      );
                      final localMeta = 'Sen · $callTime';
                      final localStatus = syncHint.trim().isNotEmpty
                          ? syncHint
                          : null;
                      return _listRowWithDateHeader(
                        index: index,
                        filteredLocals: filteredLocals,
                        filteredDocs: filteredDocs,
                        child: RepaintBoundary(
                          child: Slidable(
                        key: ValueKey('sl_local_${r.id}'),
                        startActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.22,
                          children: [
                            SlidableAction(
                              onPressed: (_) {
                                if (OutboundPhoneDial.isLikelyCallablePhone(
                                    r.phoneNumber)) {
                                  AppFeedback.mediumImpact();
                                  startCrmOutboundCall(
                                    context,
                                    phone: r.phoneNumber,
                                    customerId: r.customerId,
                                    startedFromScreen: 'consultant_calls',
                                  );
                                }
                              },
                              backgroundColor:
                                  AppThemeExtension.of(context).success,
                              foregroundColor: Colors.white,
                              icon: Icons.call_rounded,
                              label: 'Ara',
                            ),
                          ],
                        ),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.24,
                          children: [
                            SlidableAction(
                              onPressed: (_) {
                                showCallIdentityQuickActionsSheet(
                                  context,
                                  rawPhone: r.phoneNumber,
                                  customerId: r.customerId,
                                  displayLabel: localTitle,
                                  firestoreCallDocId: r.firestoreDocumentId,
                                  onCallListMutated: () => ref.invalidate(
                                      consultantCallsStreamProvider),
                                  onOpenCustomerDirectory:
                                      _openCustomerDirectoryForLinking,
                                );
                              },
                              backgroundColor:
                                  AppThemeExtension.of(context).accent,
                              foregroundColor: Colors.white,
                              icon: Icons.bolt_rounded,
                              label: 'İşlem',
                            ),
                          ],
                        ),
                        child: _LocalCallRecordCard(
                          title: localTitle,
                          directionDuration: localDirection,
                          outcome: QuickCallOutcome.labelTr(outcomeStr),
                          statusLabel: localStatus,
                          metaLine: localMeta,
                          customerLinkHint:
                              (r.customerId == null ||
                                      r.customerId!.isEmpty)
                                  ? 'Müşteri kartı yok'
                                  : null,
                          rawPhone: r.phoneNumber,
                          customerId: r.customerId,
                          firestoreDocId: r.firestoreDocumentId,
                          onCallListMutated: () => ref.invalidate(
                              consultantCallsStreamProvider),
                          onOpenCustomerDirectory:
                              _openCustomerDirectoryForLinking,
                          syncIcon: CallSyncStatusIcon(
                            record: r,
                            onManualRetry:
                                deriveLocalCallSyncUiState(r, nowMs: nowMs) ==
                                        LocalCallSyncUiState.failedPermanent
                                    ? () => unawaited(
                                        retryLocalCallRecordSync(r))
                                    : null,
                          ),
                        ),
                      ),
                        ),
                      );
                    }
                    final doc =
                        filteredDocs[index - filteredLocals.length];
                    final data = doc.data();
                    final id = doc.id;
                    final direction = data['direction'] as String? ??
                        data['callDirection'] as String? ??
                        '';
                    final isIncoming = direction == 'incoming';
                    final rawPhone = data['phoneNumber'] as String? ??
                        data['phone'] as String? ??
                        '';
                    final duration = data['durationSec'] as num?;
                    final outcomeRaw = data['outcome'] as String? ??
                        data['callOutcome'] as String?;
                    final outcomeStr = outcomeRaw != null
                        ? (CrmCallRecordHelpers
                                .kOutcomeCodeLabelsTr[outcomeRaw] ??
                            outcomeRaw)
                        : '—';
                    final createdDt = CrmCallRecordHelpers.createdAtOf(data);
                    final callTime = createdDt != null
                        ? callListTimeLabel(createdDt)
                        : null;
                    final selected = _selectedIds.contains(id);
                    final hasPhone = rawPhone.trim().isNotEmpty;
                    final contactName =
                        CrmCallRecordDisplay.contactNameFromCallData(data);
                    final match = byFirestoreId[id];
                    final customerId = (data['customerId'] as String?)?.trim();
                    final customerName =
                        customerId != null && customerId.isNotEmpty
                            ? customerNames[customerId]
                            : null;
                    final advisorId = (data['advisorId'] as String?)?.trim() ??
                        (data['agentId'] as String?)?.trim() ??
                        '';
                    final advisorPart = CrmCallRecordDisplay.advisorContext(
                      advisorAgentId: advisorId,
                      currentUid: currentUid,
                      agentNames: agentNames,
                    );
                    final completionLabel =
                        CrmCallRecordHelpers.captureStatusTr(data);
                    final resolvedCustomerName = customerName?.trim();
                    final rowTitle = CrmCallRecordDisplay.primaryTitle(
                      customerFullName: (resolvedCustomerName != null &&
                              resolvedCustomerName.isNotEmpty)
                          ? resolvedCustomerName
                          : null,
                      contactDisplayName: contactName,
                      rawPhone: rawPhone.isEmpty ? null : rawPhone,
                    );
                    final directionDuration =
                        CallRecordPremiumTile.formatDirectionDuration(
                      isIncoming: isIncoming,
                      durationSec: duration?.toInt(),
                    );
                    final metaParts = <String>[
                      if (advisorPart.trim().isNotEmpty) advisorPart,
                      if (callTime != null) callTime,
                    ];
                    final metaLine =
                        metaParts.isEmpty ? null : metaParts.join(' · ');
                    final statusLabel = completionLabel.trim().isNotEmpty &&
                            completionLabel != '—'
                        ? completionLabel
                        : null;
                    final bulkSelect =
                        _selectionMode || _selectedIds.isNotEmpty;
                    final durationSec = duration?.toInt();
                    final playLabel =
                        CrmCallRecordHelpers.formatDurationMmSs(durationSec);
                    final showDetail = playLabel.isNotEmpty;
                    final customerLinkHint =
                        (customerId == null || customerId.isEmpty)
                            ? 'Müşteri kartı yok'
                            : null;

                    return _listRowWithDateHeader(
                      index: index,
                      filteredLocals: filteredLocals,
                      filteredDocs: filteredDocs,
                      child: RepaintBoundary(
                        child: Slidable(
                      key: ValueKey('sl_fs_$id'),
                      startActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.22,
                        children: [
                          SlidableAction(
                            onPressed: (_) {
                              if (OutboundPhoneDial.isLikelyCallablePhone(
                                  rawPhone)) {
                                AppFeedback.mediumImpact();
                                startCrmOutboundCall(
                                  context,
                                  phone: rawPhone,
                                  customerId: customerId,
                                  startedFromScreen: 'consultant_calls',
                                );
                              }
                            },
                            backgroundColor:
                                AppThemeExtension.of(context).success,
                            foregroundColor: Colors.white,
                            icon: Icons.call_rounded,
                            label: 'Ara',
                          ),
                        ],
                      ),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.24,
                        children: [
                          SlidableAction(
                            onPressed: (_) {
                              if (!hasPhone) return;
                              showCallIdentityQuickActionsSheet(
                                context,
                                rawPhone: rawPhone,
                                customerId: customerId,
                                displayLabel: rowTitle,
                                firestoreCallDocId: id,
                                onCallListMutated: () => ref.invalidate(
                                    consultantCallsStreamProvider),
                                onOpenCustomerDirectory:
                                    _openCustomerDirectoryForLinking,
                              );
                            },
                            backgroundColor:
                                AppThemeExtension.of(context).accent,
                            foregroundColor: Colors.white,
                            icon: Icons.bolt_rounded,
                            label: 'İşlem',
                          ),
                        ],
                      ),
                      child: _FirestoreCallRecordCard(
                        selected: selected,
                        enabled: hasPhone,
                        onSelect: hasPhone ? () => _toggleSelection(id) : null,
                        showCheckbox: bulkSelect,
                        title: rowTitle,
                        directionDuration: directionDuration,
                        outcome: outcomeStr,
                        statusLabel: statusLabel,
                        metaLine: metaLine,
                        playDurationLabel: showDetail ? playLabel : null,
                        customerLinkHint: customerLinkHint,
                        rawPhone: rawPhone,
                        customerId: customerId,
                        firestoreDocId: id,
                        onCallListMutated: () => ref.invalidate(
                            consultantCallsStreamProvider),
                        onOpenCustomerDirectory: _openCustomerDirectoryForLinking,
                        leadingIcon: isIncoming
                            ? Icons.call_received_rounded
                            : Icons.call_made_rounded,
                        leadingColor: isIncoming
                            ? AppThemeExtension.of(context).success
                            : AppThemeExtension.of(context).info,
                        trailing: match != null
                            ? CallSyncStatusIcon(
                                record: match,
                                onManualRetry:
                                    deriveLocalCallSyncUiState(match,
                                                nowMs: nowMs) ==
                                            LocalCallSyncUiState
                                                .failedPermanent
                                        ? () => unawaited(
                                            retryLocalCallRecordSync(match))
                                        : null,
                              )
                            : const ServerOnlyCallSourceIcon(),
                      ),
                    ),
                      ),
                    );
                    },
                    childCount: visibleTotal,
                  ),
                ),
              ),
            ],
            ),
          );
        },
      ),
    ),
          ],
        ),
      ),
      bottomNavigationBar: hasQueue
          ? Material(
              color: surface,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space4,
                      vertical: DesignTokens.space2),
                  child: Row(
                    children: [
                      Icon(Icons.chat_rounded,
                          color: AppThemeExtension.of(context).accent,
                          size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sıradaki sohbeti aç (${_whatsappIndex + 1}/${queue.length})',
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _openNextWhatsApp,
                        style: TextButton.styleFrom(
                            foregroundColor:
                                AppThemeExtension.of(context).accent),
                        child: const Text('Sıradakini aç'),
                      ),
                      TextButton(
                        onPressed: _clearWhatsAppQueue,
                        style: TextButton.styleFrom(
                            foregroundColor: textSecondary),
                        child: const Text('Akışı kapat'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _LocalCallRecordCard extends StatelessWidget {
  const _LocalCallRecordCard({
    required this.title,
    required this.directionDuration,
    required this.outcome,
    this.statusLabel,
    this.metaLine,
    this.customerLinkHint,
    required this.rawPhone,
    this.customerId,
    this.firestoreDocId,
    this.onCallListMutated,
    this.onOpenCustomerDirectory,
    required this.syncIcon,
  });

  final String title;
  final String directionDuration;
  final String outcome;
  final String? statusLabel;
  final String? metaLine;
  final String? customerLinkHint;
  final String rawPhone;
  final String? customerId;
  final String? firestoreDocId;
  final VoidCallback? onCallListMutated;
  final VoidCallback? onOpenCustomerDirectory;
  final Widget syncIcon;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    void openActions() {
      showCallIdentityQuickActionsSheet(
        context,
        rawPhone: rawPhone,
        customerId: customerId,
        displayLabel: title,
        firestoreCallDocId: firestoreDocId,
        onCallListMutated: onCallListMutated,
        onOpenCustomerDirectory: onOpenCustomerDirectory,
      );
    }

    return CrmCallOperatingCard(
      dense: true,
      child: CallRecordPremiumTile(
        title: title,
        directionDuration: directionDuration,
        outcomeLabel: outcome,
        statusLabel: statusLabel,
        metaLine: metaLine,
        leadingIcon: Icons.call_made_rounded,
        leadingColor: ext.info,
        leadingBadge: SizedBox(
          width: 18,
          height: 18,
          child: FittedBox(child: syncIcon),
        ),
        customerLinkHint: customerLinkHint,
        onMenu: openActions,
        onTap: openActions,
      ),
    );
  }
}

class _FirestoreCallRecordCard extends StatelessWidget {
  const _FirestoreCallRecordCard({
    required this.selected,
    required this.enabled,
    required this.onSelect,
    required this.title,
    required this.directionDuration,
    required this.outcome,
    this.statusLabel,
    this.metaLine,
    this.playDurationLabel,
    this.customerLinkHint,
    required this.rawPhone,
    this.customerId,
    this.firestoreDocId,
    this.onCallListMutated,
    this.onOpenCustomerDirectory,
    required this.leadingIcon,
    required this.leadingColor,
    required this.trailing,
    this.showCheckbox = false,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback? onSelect;
  final String title;
  final String directionDuration;
  final String outcome;
  final String? statusLabel;
  final String? metaLine;
  final String? playDurationLabel;
  final String? customerLinkHint;
  final String rawPhone;
  final String? customerId;
  final String? firestoreDocId;
  final VoidCallback? onCallListMutated;
  final VoidCallback? onOpenCustomerDirectory;
  final IconData leadingIcon;
  final Color leadingColor;
  final Widget trailing;
  final bool showCheckbox;

  @override
  Widget build(BuildContext context) {
    final callable =
        enabled && OutboundPhoneDial.isLikelyCallablePhone(rawPhone);
    final playLabel = playDurationLabel?.trim();
    final hasDetail = firestoreDocId != null &&
        firestoreDocId!.trim().isNotEmpty &&
        playLabel != null &&
        playLabel.isNotEmpty;

    void openActions() {
      showCallIdentityQuickActionsSheet(
        context,
        rawPhone: rawPhone,
        customerId: customerId,
        displayLabel: title,
        firestoreCallDocId: firestoreDocId,
        onCallListMutated: onCallListMutated,
        onOpenCustomerDirectory: onOpenCustomerDirectory,
      );
    }

    void onDetailTap() {
      CallRecordDetailNavigation.openSummary(
        context,
        firestoreDocId: firestoreDocId,
        onFallback: openActions,
      );
    }

    return CrmCallOperatingCard(
      selected: selected,
      dense: true,
      child: CallRecordPremiumTile(
        title: title,
        directionDuration: directionDuration,
        outcomeLabel: outcome,
        statusLabel: statusLabel,
        metaLine: metaLine,
        leadingIcon: leadingIcon,
        leadingColor: leadingColor,
        showCheckbox: showCheckbox,
        checked: selected,
        onCheckChanged: enabled && onSelect != null
            ? (_) => onSelect!()
            : null,
        customerLinkHint: customerLinkHint,
        onMenu: callable ? openActions : null,
        onDetail: hasDetail ? onDetailTap : null,
        playDurationLabel: hasDetail ? playLabel : null,
        trailing: trailing,
        onTap: showCheckbox && onSelect != null
            ? onSelect
            : (callable ? openActions : null),
      ),
    );
  }
}
