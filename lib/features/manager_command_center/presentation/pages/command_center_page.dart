
import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/utils/csv_export.dart';
import 'package:flutter/services.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_kpi_period.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_list_sort.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_surface_quick_filter.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/calls_surface_ack.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/models/command_center_chrome_config.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/models/command_center_feed_filters.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/models/command_center_scope_config.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/models/command_center_view_scope.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/widgets/command_center_calls_feed.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/widgets/command_center_list_slivers.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_call_center_chrome.dart';
import 'package:emlakmaster_mobile/core/navigation/shell_tab_back_binding.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import '../../../../shared/widgets/unauthorized_screen.dart';
/// Yönetici çağrı merkezi: tüm çağrılar. Sadece canViewAllCalls rolleri erişebilir.
class CommandCenterPage extends ConsumerStatefulWidget {
  const CommandCenterPage({super.key});

  @override
  ConsumerState<CommandCenterPage> createState() => _CommandCenterPageState();
}

class _CommandCenterPageState extends ConsumerState<CommandCenterPage> {
  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(displayRoleProvider);
    final premium = PremiumThemeExtension.of(context);
    return roleAsync.when(
      loading: () => PremiumShellBackdrop(
        child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
              color: premium.champagneGold),
        ),
      ),
      ),
      error: (_, __) => const UnauthorizedScreen(
        message: 'Yetki bilgisi alınamadı. Oturumu yenileyip yeniden deneyin.',
      ),
      data: (role) {
        if (!FeaturePermission.canViewAllCalls(role)) {
          return const UnauthorizedScreen(
            message:
                'Bu alan yalnızca yönetim ve operasyon ekiplerine açıktır.',
          );
        }
        return const _CommandCenterBody();
      },
    );
  }
}

class _CommandCenterBody extends ConsumerStatefulWidget {
  const _CommandCenterBody();

  @override
  ConsumerState<_CommandCenterBody> createState() => _CommandCenterBodyState();
}

class _CommandCenterBodyState extends ConsumerState<_CommandCenterBody> {
  CommandCenterViewScope _commandScope = CommandCenterViewScope.all;
  String? _filterTeamId;
  String? _filterAgentId;
  String? _filterCustomerId;
  String? _filterOutcome;
  String _searchQuery = '';
  late final DebouncedSearchController _debouncedSearch;
  final FocusNode _searchFocusNode = FocusNode();

  TextEditingController get _searchController => _debouncedSearch.controller;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _lastFilteredDocs;
  List<String> _teamMemberIds = [];
  CallSurfaceQuickFilter _managerQuickFilter = CallSurfaceQuickFilter.all;
  bool _kpiExpanded = false;
  CallListSortMode _sortMode = CallListSortMode.lastCall;
  CallListViewMode _viewMode = CallListViewMode.list;
  CallKpiPeriod _kpiPeriod = CallKpiPeriod.thisMonth;

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

  void _clearFilters() {
    setState(() {
      _filterTeamId = null;
      _filterAgentId = null;
      _filterCustomerId = null;
      _filterOutcome = null;
      _teamMemberIds = [];
      _searchController.clear();
      if (_commandScope == CommandCenterViewScope.pending) {
        _commandScope = CommandCenterViewScope.all;
      }
    });
  }

  void _cycleKpiPeriod() {
    setState(() {
      _kpiPeriod = _kpiPeriod == CallKpiPeriod.thisMonth
          ? CallKpiPeriod.allTime
          : CallKpiPeriod.thisMonth;
    });
  }

  void _toggleEksikKayitScope() {
    setState(() {
      if (_commandScope == CommandCenterViewScope.pending) {
        _commandScope = CommandCenterViewScope.all;
      } else {
        _commandScope = CommandCenterViewScope.pending;
        _managerQuickFilter = CallSurfaceQuickFilter.all;
      }
    });
  }

  bool _handleExitSearch() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
      return true;
    }
    if (_searchQuery.isEmpty && _searchController.text.trim().isEmpty) {
      return false;
    }
    setState(() => _searchController.clear());
    return true;
  }

  bool _handleCloseFilters() {
    final hasFilters = _filterTeamId != null ||
        _filterAgentId != null ||
        _filterCustomerId != null ||
        _filterOutcome != null ||
        _managerQuickFilter != CallSurfaceQuickFilter.all;
    if (!hasFilters) return false;
    _clearFilters();
    return true;
  }

  CommandCenterFeedFilters get _feedFilters => CommandCenterFeedFilters(
        viewScope: _commandScope,
        searchQueryLower: _searchQuery.toLowerCase(),
        filterTeamId: _filterTeamId,
        filterAgentId: _filterAgentId,
        filterCustomerId: _filterCustomerId,
        filterOutcome: _filterOutcome,
        teamMemberIds: _teamMemberIds,
        quickFilter: _managerQuickFilter,
        sortMode: _sortMode,
        kpiPeriod: _kpiPeriod,
      );

  void _drillToAgent(String agentId) {
    setState(() {
      _commandScope = CommandCenterViewScope.all;
      _filterAgentId = agentId;
      _filterCustomerId = null;
    });
  }

  void _drillToCustomer(String customerId) {
    setState(() {
      _commandScope = CommandCenterViewScope.all;
      _filterCustomerId = customerId;
      _filterAgentId = null;
    });
  }

  CommandCenterChromeConfig get _chromeConfig => CommandCenterChromeConfig(
        scope: _commandScope,
        searchController: _searchController,
        searchFocusNode: _searchFocusNode,
        searchQuery: _searchQuery,
        filterTeamId: _filterTeamId,
        filterAgentId: _filterAgentId,
        filterOutcome: _filterOutcome,
        teamMemberIds: _teamMemberIds,
        quickFilter: _managerQuickFilter,
        kpiExpanded: _kpiExpanded,
        onScopeChanged: (s) => setState(() => _commandScope = s),
        onTeamChanged: (id, memberIds) => setState(() {
          _filterTeamId = id;
          _teamMemberIds = memberIds;
          if (id != null) _filterAgentId = null;
        }),
        onAgentChanged: (id) => setState(() => _filterAgentId = id),
        onOutcomeChanged: (outcome) => setState(() => _filterOutcome = outcome),
        onQuickFilterChanged: (f) => setState(() {
          _managerQuickFilter = f;
          if (_commandScope == CommandCenterViewScope.pending) {
            _commandScope = CommandCenterViewScope.all;
          }
        }),
        onToggleKpiExpanded: () => setState(() => _kpiExpanded = !_kpiExpanded),
        onSearchTap: () {
          if (_searchQuery.isEmpty) _searchFocusNode.requestFocus();
        },
        sortMode: _sortMode,
        onSortChanged: (m) => setState(() => _sortMode = m),
        viewMode: _viewMode,
        onViewModeChanged: (m) => setState(() {
          _viewMode = m;
          if (m == CallListViewMode.chart) _kpiExpanded = true;
        }),
        kpiPeriod: _kpiPeriod,
        onKpiPeriodTap: _cycleKpiPeriod,
        onEksikKayitChipTap: _toggleEksikKayitScope,
        eksikKayitChipSelected:
            _commandScope == CommandCenterViewScope.pending,
      );

  List<Widget> _managerChromeSlivers(
    BuildContext context, {
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered,
    required Map<String, String> agentNames,
  }) =>
      CommandCenterListSlivers.buildChrome(
        context,
        chrome: _chromeConfig,
        docs: docs,
        filtered: filtered,
        agentNames: agentNames,
      );

  List<Widget> _buildScopeSlivers(
    BuildContext context, {
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered,
    required Map<String, String> agentNames,
    required List<LocalCallRecord> locals,
    required String? currentUid,
    required Map<String, String> customerFullNameById,
    required double listBottomInset,
  }) =>
      CommandCenterListSlivers.buildScope(
        context,
        config: CommandCenterScopeConfig(
          scope: _commandScope,
          filtered: filtered,
          agentNames: agentNames,
          locals: locals,
          currentUid: currentUid,
          customerFullNameById: customerFullNameById,
          listBottomInset: listBottomInset,
          viewMode: _viewMode,
          onClearFilters: _clearFilters,
          onDrillAgent: _drillToAgent,
          onDrillCustomer: _drillToCustomer,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final fg = ext.textPrimary;
    return ShellTabBackBinding(
      onExitSearch: _handleExitSearch,
      onCloseFilters: _handleCloseFilters,
      child: PremiumShellBackdrop(
        child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              PremiumCallCenterPageHeader(
                compact: true,
                title: ProductLabels.callRecords,
                subtitle: 'CRM çağrı merkezi',
                actions: [
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz_rounded, color: premium.champagneGold),
                    onSelected: (value) {
                      if (value == 'csv') {
                        final docs = _lastFilteredDocs;
                        if (docs == null || docs.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Dışa aktarılacak veri yok.')),
                          );
                          return;
                        }
                        final csv = callsToCsv(docs);
                        Clipboard.setData(ClipboardData(text: csv));
                        showCallsSurfaceAck(
                          context,
                          'CSV panoya hazır · ${docs.length} satır',
                        );
                      } else if (value == 'search') {
                        _searchFocusNode.requestFocus();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'csv',
                        child: ListTile(
                          leading: Icon(Icons.download_rounded),
                          title: Text('CSV dışa aktar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'search',
                        child: ListTile(
                          leading: Icon(Icons.tune_rounded),
                          title: Text('Arama ve filtre'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: CommandCenterCallsFeed(
                  filters: _feedFilters,
                  fg: fg,
                  onFilteredDocsChanged: (filtered) =>
                      _lastFilteredDocs = filtered,
                  onClearFilters: _clearFilters,
                  chromeSliversBuilder: (context, data, listBottomInset) =>
                      _managerChromeSlivers(
                    context,
                    docs: data.docs,
                    filtered: data.filtered,
                    agentNames: data.agentNames,
                  ),
                  scopeSliversBuilder: (context, data, listBottomInset) =>
                      _buildScopeSlivers(
                    context,
                    filtered: data.filtered,
                    agentNames: data.agentNames,
                    locals: data.locals,
                    currentUid: data.currentUid,
                    customerFullNameById: data.customerFullNameById,
                    listBottomInset: listBottomInset,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
