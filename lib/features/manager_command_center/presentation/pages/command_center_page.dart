import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/utils/csv_export.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
import 'package:flutter/services.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/emlak_app_bar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/unauthorized_screen.dart';
/// Yönetici çağrı merkezi: tüm çağrılar. Sadece canViewAllCalls rolleri erişebilir.
class CommandCenterPage extends ConsumerStatefulWidget {
  const CommandCenterPage({super.key});

  @override
  ConsumerState<CommandCenterPage> createState() => _CommandCenterPageState();
}

class _CommandCenterPageState extends ConsumerState<CommandCenterPage> {
  final int _viewIndex = 0;

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(displayRoleProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loadingBg = isDark ? AppThemeExtension.of(context).background : AppThemeExtension.of(context).background;
    return roleAsync.when(
      loading: () => Scaffold(
        backgroundColor: loadingBg,
        body: Center(
          child: CircularProgressIndicator(color: AppThemeExtension.of(context).accent),
        ),
      ),
      error: (_, __) => const UnauthorizedScreen(
        message: 'Rol bilgisi yüklenemedi. Lütfen tekrar giriş yapın.',
      ),
      data: (role) {
        if (!FeaturePermission.canViewAllCalls(role)) {
          return const UnauthorizedScreen(
            message: 'Çağrı Merkezi ekranına sadece yönetici ve operasyon rolleri erişebilir.',
          );
        }
        return _CommandCenterBody(viewIndex: _viewIndex);
      },
    );
  }
}

class _CommandCenterBody extends StatefulWidget {
  const _CommandCenterBody({required int viewIndex}) : _viewIndex = viewIndex;
  final int _viewIndex;

  @override
  State<_CommandCenterBody> createState() => _CommandCenterBodyState();
}

enum _CommandScope {
  /// Tüm CRM çağrı kayıtları (son N)
  all,
  /// Danışman bazlı özet
  consultant,
  /// Müşteri bazlı özet
  customer,
  /// Sonuç bekleyen handoff oturumları
  pending,
}

class _CommandCenterBodyState extends State<_CommandCenterBody> {
  late int _viewIndex;
  _CommandScope _commandScope = _CommandScope.all;
  String? _filterTeamId;
  String? _filterAgentId;
  String? _filterOutcome;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _lastFilteredDocs;
  List<String> _teamMemberIds = [];

  @override
  void initState() {
    super.initState();
    _viewIndex = widget._viewIndex;
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text.trim()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _filterTeamId = null;
      _filterAgentId = null;
      _filterOutcome = null;
      _teamMemberIds = [];
      _searchController.clear();
    });
  }

  static const Map<String, String> _outcomeLabels = {
    'connected': 'Bağlandı',
    'missed': 'Cevapsız',
    'no_answer': 'Cevap yok',
    'busy': 'Meşgul',
    'failed': 'Başarısız',
    'handoff_pending': 'Sonuç bekleniyor',
    'completed': 'Tamamlandı (uygulama içi)',
    'reached': 'Ulaşıldı',
    'callback_scheduled': 'Tekrar aranacak',
    'appointment_set': 'Randevu oluşturuldu',
    'offer_sent': 'Teklif verildi',
  };

  Stream<QuerySnapshot<Map<String, dynamic>>> _callsStreamForScope() {
    switch (_commandScope) {
      case _CommandScope.pending:
        return FirestoreService.callsHandoffPendingStream();
      default:
        return FirestoreService.callsStream();
    }
  }

  Widget _buildScopeContent(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered,
    Map<String, String> agentNames,
    Color fg,
    bool isDark,
  ) {
    final surface =
        isDark ? AppThemeExtension.of(context).surface : AppThemeExtension.of(context).surface;
    switch (_commandScope) {
      case _CommandScope.consultant:
        return _buildConsultantGroupedList(context, filtered, agentNames, surface, fg, isDark);
      case _CommandScope.customer:
        return _buildCustomerGroupedList(context, filtered, agentNames, surface, fg, isDark);
      case _CommandScope.all:
      case _CommandScope.pending:
        return ListView.builder(
          padding: const EdgeInsets.all(DesignTokens.space4),
          itemCount: filtered.length,
          cacheExtent: 300,
          itemBuilder: (context, index) => _buildCrmRecordTile(
            context,
            filtered[index],
            agentNames,
            surface,
            fg,
            isDark,
          ),
        );
    }
  }

  Widget _buildCrmRecordTile(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, String> agentNames,
    Color surface,
    Color fg,
    bool isDark,
  ) {
    final data = doc.data();
    final id = doc.id;
    final agentId = CrmCallRecordHelpers.agentIdOf(data);
    final displayAgent = agentNames[agentId] ?? agentId;
    final duration = data['durationSec'] as num?;
    final durationStr = duration != null ? '${duration.toInt()} sn' : '—';
    final outcomeStr =
        CrmCallRecordHelpers.outcomeDisplayTr(data, _outcomeLabels);
    final phone = (data['phoneNumber'] ?? data['phone'] ?? '').toString();
    final cust = CrmCallRecordHelpers.customerIdOf(data);
    final createdAt = data['createdAt'];
    String timeStr = '—';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      timeStr =
          '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    final ts = isDark
        ? AppThemeExtension.of(context).textSecondary
        : AppThemeExtension.of(context).textSecondary;
    final cap = CrmCallRecordHelpers.captureStatusTr(data);
    final src = CrmCallRecordHelpers.sourceDisplayTr(data);
    final note = (data['quickCaptureNote'] as String? ?? '').trim();
    final noteLine = note.isNotEmpty ? ' · Not: ${note.length > 42 ? '${note.substring(0, 42)}…' : note}' : '';
    return Card(
      margin: const EdgeInsets.only(bottom: DesignTokens.space2),
      color: surface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppThemeExtension.of(context).accent,
          child: Icon(Icons.call_rounded, color: AppThemeExtension.of(context).onBrand, size: 20),
        ),
        title: Text(
          'CRM kayıt ${id.length > 8 ? id.substring(0, 8) : id}',
          style: TextStyle(color: fg, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$displayAgent · $phone · $outcomeStr · $timeStr'
          '${durationStr != '—' ? ' · Kayıtlı süre (CRM): $durationStr' : ''}\n'
          '$src · $cap$noteLine'
          '${cust != null ? ' · Müşteri: $cust' : ''}',
          style: TextStyle(color: ts, fontSize: 12, height: 1.35),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildConsultantGroupedList(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered,
    Map<String, String> agentNames,
    Color surface,
    Color fg,
    bool isDark,
  ) {
    final grouped = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final d in filtered) {
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
      return EmptyState(
        compact: true,
        anchorAboveCenter: true,
        anchorAlignmentY: -0.52,
        grouped: true,
        icon: Icons.groups_rounded,
        title: 'Danışman özeti yok',
        subtitle: 'Filtrelere uyan veya müşteri/danışman bağlantılı kayıt bulunamadı.',
        outlinedActionLabel: 'Filtreleri temizle',
        onOutlinedAction: _clearFilters,
      );
    }
    final ts = isDark
        ? AppThemeExtension.of(context).textSecondary
        : AppThemeExtension.of(context).textSecondary;
    return ListView.builder(
      padding: const EdgeInsets.all(DesignTokens.space4),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        final list = e.value;
        final name = agentNames[e.key] ?? e.key;
        final pending = list.where((d) => CrmCallRecordHelpers.isHandoffPending(d.data())).length;
        final completed = list.where((d) => CrmCallRecordHelpers.hasCaptureCompleted(d.data())).length;
        final handoffs = list.where((d) => CrmCallRecordHelpers.isSystemHandoff(d.data())).length;
        final last = list.first;
        final dt = CrmCallRecordHelpers.createdAtOf(last.data());
        final timeStr = dt != null
            ? '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'
            : '—';
        return Card(
          margin: const EdgeInsets.only(bottom: DesignTokens.space2),
          color: surface,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppThemeExtension.of(context).accent.withValues(alpha: 0.2),
              child: Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                style: TextStyle(
                  color: AppThemeExtension.of(context).accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(name, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
            subtitle: Text(
              'Son kayıt: $timeStr · Toplam: ${list.length} · Handoff: $handoffs · '
              'Tamamlanan: $completed · Bekleyen: $pending',
              style: TextStyle(color: ts, fontSize: 12, height: 1.35),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildCustomerGroupedList(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered,
    Map<String, String> agentNames,
    Color surface,
    Color fg,
    bool isDark,
  ) {
    final grouped = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final d in filtered) {
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
      return EmptyState(
        compact: true,
        anchorAboveCenter: true,
        anchorAlignmentY: -0.52,
        grouped: true,
        icon: Icons.person_off_rounded,
        title: 'Müşteri bağlantılı kayıt yok',
        subtitle: 'Filtrelere uyan ve müşteri ID’si içeren CRM çağrı kaydı yok.',
        outlinedActionLabel: 'Filtreleri temizle',
        onOutlinedAction: _clearFilters,
      );
    }
    final ts = isDark
        ? AppThemeExtension.of(context).textSecondary
        : AppThemeExtension.of(context).textSecondary;
    return ListView.builder(
      padding: const EdgeInsets.all(DesignTokens.space4),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        final list = e.value;
        final last = list.first;
        final data = last.data();
        final agent = CrmCallRecordHelpers.agentIdOf(data);
        final displayAgent = agentNames[agent] ?? agent;
        final outcome = CrmCallRecordHelpers.outcomeDisplayTr(data, _outcomeLabels);
        final dt = CrmCallRecordHelpers.createdAtOf(data);
        final timeStr = dt != null
            ? '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'
            : '—';
        final pending = list.where((d) => CrmCallRecordHelpers.isHandoffPending(d.data())).length;
        return Card(
          margin: const EdgeInsets.only(bottom: DesignTokens.space2),
          color: surface,
          child: ListTile(
            leading: const Icon(Icons.person_rounded, size: 28),
            title: Text(
              'Müşteri ${e.key.length > 12 ? '${e.key.substring(0, 12)}…' : e.key}',
              style: TextStyle(color: fg, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'Son temas: $timeStr · $displayAgent · $outcome · Kayıt: ${list.length} · Bekleyen: $pending',
              style: TextStyle(color: ts, fontSize: 12, height: 1.35),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceCard = isDark ? AppThemeExtension.of(context).card : AppThemeExtension.of(context).surface;
    final textPrimary = isDark ? AppThemeExtension.of(context).textPrimary : AppThemeExtension.of(context).textPrimary;
    final textSecondary = isDark ? AppThemeExtension.of(context).textSecondary : AppThemeExtension.of(context).textSecondary;
    final border = isDark ? AppThemeExtension.of(context).border : AppThemeExtension.of(context).border;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space2),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(color: textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Telefon, müşteri id, danışman, sonuç, not...',
                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: AppThemeExtension.of(context).accent.withValues(alpha: 0.9), size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, size: 20, color: textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                        },
                        tooltip: 'Temizle',
                      )
                    : null,
                filled: true,
                fillColor: surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  borderSide: BorderSide(color: border.withValues(alpha: 0.6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  borderSide: BorderSide(color: AppThemeExtension.of(context).accent, width: 1.2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
          _TapShadowButton(
            onPressed: () {
              if (_searchQuery.isEmpty) {
                _searchFocusNode.requestFocus();
              }
            },
            icon: Icons.search_rounded,
            label: 'Ara',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppThemeExtension.of(context).background : AppThemeExtension.of(context).background;
    final fg = isDark ? AppThemeExtension.of(context).textPrimary : AppThemeExtension.of(context).textPrimary;
    final surface = isDark ? AppThemeExtension.of(context).surface : AppThemeExtension.of(context).surface;
    return Scaffold(
      backgroundColor: bg,
      appBar: emlakAppBar(
        context,
        title: const Text('CRM çağrı kayıtları'),
        backgroundColor: theme.appBarTheme.backgroundColor ?? bg,
        foregroundColor: theme.appBarTheme.foregroundColor ?? fg,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {
              final docs = _lastFilteredDocs;
              if (docs == null || docs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dışa aktarılacak veri yok.')),
                );
                return;
              }
              final csv = callsToCsv(docs);
              Clipboard.setData(ClipboardData(text: csv));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('CSV panoya kopyalandı. Excel\'e yapıştırabilirsiniz.'),
                  backgroundColor: AppThemeExtension.of(context).accent,
                ),
              );
            },
            tooltip: 'CSV dışa aktar',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space4,
                  DesignTokens.space3,
                  DesignTokens.space4,
                  DesignTokens.space2,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppThemeExtension.of(context).accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'CRM çağrı kaydı: handoff oturumu, kayıtlı sonuç ve notlar. '
                        'Operatör doğrulamalı hat süresi veya kesin bağlantı durumu burada yoktur; telekom dinlemesi değildir.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppThemeExtension.of(context).textSecondary
                              : AppThemeExtension.of(context).textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(DesignTokens.space4, 0, DesignTokens.space4, DesignTokens.space2),
              child: SegmentedButton<_CommandScope>(
                segments: const [
                  ButtonSegment(
                    value: _CommandScope.all,
                    label: Text('Tüm kayıtlar'),
                    icon: Icon(Icons.list_alt_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: _CommandScope.consultant,
                    label: Text('Danışman'),
                    icon: Icon(Icons.person_search_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: _CommandScope.customer,
                    label: Text('Müşteri'),
                    icon: Icon(Icons.people_alt_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: _CommandScope.pending,
                    label: Text('Eksik kayıt'),
                    icon: Icon(Icons.pending_actions_rounded, size: 16),
                  ),
                ],
                selected: {_commandScope},
                onSelectionChanged: (s) => setState(() => _commandScope = s.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                ),
              ),
            ),
            Material(
              color: surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space4,
                  DesignTokens.space2,
                  DesignTokens.space4,
                  DesignTokens.space2,
                ),
                child: Row(
                  children: [
                    Text(
                      'Görünüm',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isDark ? AppThemeExtension.of(context).textSecondary : AppThemeExtension.of(context).textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, icon: Icon(Icons.table_rows_rounded, size: 18)),
                        ButtonSegment(value: 1, icon: Icon(Icons.grid_view_rounded, size: 18)),
                        ButtonSegment(value: 2, icon: Icon(Icons.timeline_rounded, size: 18)),
                      ],
                      selected: {_viewIndex},
                      onSelectionChanged: (s) => setState(() => _viewIndex = s.first),
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _CommandCenterFilters(
              filterTeamId: _filterTeamId,
              filterAgentId: _filterAgentId,
              filterOutcome: _filterOutcome,
              teamMemberIds: _teamMemberIds,
              onTeamChanged: (id, memberIds) => setState(() {
                _filterTeamId = id;
                _teamMemberIds = memberIds;
                if (id != null) _filterAgentId = null;
              }),
              onAgentChanged: (id) => setState(() => _filterAgentId = id),
              onOutcomeChanged: (outcome) => setState(() => _filterOutcome = outcome),
            ),
            _buildSearchBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirestoreService.agentsStream(),
                builder: (context, agentSnap) {
                  final agentDocs = agentSnap.data?.docs ?? [];
                  final agentNames = {
                    for (final d in agentDocs)
                      d.id: d.data()['displayName'] as String? ?? d.id,
                  };
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _callsStreamForScope(),
                builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: AppThemeExtension.of(context).accent),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: AppThemeExtension.of(context).textSecondary, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Çağrılar yüklenemedi.',
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lütfen tekrar deneyin.',
                        style: TextStyle(
                          color: isDark ? AppThemeExtension.of(context).textSecondary : AppThemeExtension.of(context).textSecondary,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: () => setState(() {}),
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: const Text('Tekrar dene'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppThemeExtension.of(context).accent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            final q = _searchQuery.toLowerCase();
            final filtered = docs.where((d) {
              final data = d.data();
              final agentId = CrmCallRecordHelpers.agentIdOf(data);
              if (_filterTeamId != null &&
                  _teamMemberIds.isNotEmpty &&
                  !_teamMemberIds.contains(agentId)) {
                return false;
              }
              if (_filterAgentId != null && agentId != _filterAgentId) {
                return false;
              }
              if (_filterOutcome != null &&
                  (data['outcome'] as String? ?? data['callOutcome'] as String?) != _filterOutcome) {
                return false;
              }
              if (q.isNotEmpty) {
                final id = d.id.toLowerCase();
                final phone = ((data['phoneNumber'] ?? data['phone']) ?? '').toString().toLowerCase();
                final outcomeRaw = data['outcome'] as String? ?? data['callOutcome'] as String? ?? '';
                final outcomeLabel = outcomeRaw.isNotEmpty ? (_outcomeLabels[outcomeRaw] ?? outcomeRaw).toLowerCase() : '';
                final cust = (data['customerId'] as String? ?? '').toLowerCase();
                final note = (data['quickCaptureNote'] as String? ?? '').toLowerCase();
                final ql = (data['quickOutcomeLabelTr'] as String? ?? '').toLowerCase();
                final matches = id.contains(q) ||
                    agentId.toLowerCase().contains(q) ||
                    phone.contains(q) ||
                    outcomeLabel.contains(q) ||
                    cust.contains(q) ||
                    note.contains(q) ||
                    ql.contains(q);
                if (!matches) return false;
              }
              return true;
            }).toList();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _lastFilteredDocs = filtered);
            });
            if (filtered.isEmpty) {
              final hasAnyDocs = docs.isNotEmpty;
              final l10n = AppLocalizations.of(context);
              if (hasAnyDocs) {
                return EmptyState(
                  compact: true,
                  anchorAboveCenter: true,
                  anchorAlignmentY: -0.52,
                  grouped: true,
                  icon: Icons.call_rounded,
                  title: 'Uygun çağrı yok',
                  subtitle: 'Arama veya filtrelere uygun kayıt bulunamadı.',
                  outlinedActionLabel: 'Filtreleri temizle',
                  onOutlinedAction: _clearFilters,
                );
              }
              return EmptyState(
                premiumVisual: true,
                grouped: true,
                anchorAboveCenter: true,
                anchorAlignmentY: -0.52,
                icon: Icons.call_rounded,
                title: l10n.t('empty_calls_title'),
                subtitle: l10n.t('empty_calls_sub'),
                actionLabel: l10n.t('empty_calls_cta'),
                onAction: () => context.push(
                AppRouter.routeCall,
                extra: const {
                  'startedFromScreen': 'command_center',
                },
              ),
              );
            }
            return _buildScopeContent(context, filtered, agentNames, fg, isDark);
          },
        );
      },
    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandCenterFilters extends StatelessWidget {
  const _CommandCenterFilters({
    required this.filterTeamId,
    required this.filterAgentId,
    required this.filterOutcome,
    required this.teamMemberIds,
    required this.onTeamChanged,
    required this.onAgentChanged,
    required this.onOutcomeChanged,
  });
  final String? filterTeamId;
  final String? filterAgentId;
  final String? filterOutcome;
  final List<String> teamMemberIds;
  final void Function(String? teamId, List<String> memberIds) onTeamChanged;
  final void Function(String?) onAgentChanged;
  final void Function(String?) onOutcomeChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TeamDoc>>(
      stream: FirestoreService.teamsStream(),
      builder: (context, teamSnap) {
        final teams = teamSnap.data ?? [];
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService.agentsStream(),
          builder: (context, agentSnap) {
            final agents = agentSnap.data?.docs ?? [];
            var agentIds = agents.map((d) => d.id).toList();
            if (filterTeamId != null && teamMemberIds.isNotEmpty) {
              agentIds = agentIds.where((id) => teamMemberIds.contains(id)).toList();
            }
            final agentNames = {
              for (final d in agents) d.id: d.data()['displayName'] as String? ?? d.id,
            };
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final surface = isDark ? AppThemeExtension.of(context).surface : AppThemeExtension.of(context).surface;
            final surfaceCard = isDark ? AppThemeExtension.of(context).card : AppThemeExtension.of(context).surface;
            final border = isDark ? AppThemeExtension.of(context).border : AppThemeExtension.of(context).border;
            final textColor = isDark ? AppThemeExtension.of(context).textPrimary : AppThemeExtension.of(context).textPrimary;
            final hintColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space2),
              decoration: BoxDecoration(
                color: surface,
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  if (teams.isNotEmpty)
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: filterTeamId,
                          isExpanded: true,
                          hint: Text('Ekip', style: TextStyle(color: hintColor, fontSize: 13)),
                          dropdownColor: surfaceCard,
                          items: [
                            DropdownMenuItem(child: Text('Tüm ekipler', style: TextStyle(color: textColor))),
                            ...teams.map((t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text(t.name, style: TextStyle(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                                )),
                          ],
                          onChanged: (v) {
                            if (v == null) {
                              onTeamChanged(null, <String>[]);
                              return;
                            }
                            final t = teams.where((x) => x.id == v).toList();
                            final memberIds = t.isEmpty ? <String>[] : t.first.memberIds;
                            onTeamChanged(v, memberIds);
                          },
                        ),
                      ),
                    ),
                  if (teams.isNotEmpty) const SizedBox(width: DesignTokens.space3),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: filterAgentId,
                        isExpanded: true,
                        hint: Text('Danışman', style: TextStyle(color: hintColor, fontSize: 13)),
                        dropdownColor: surfaceCard,
                        items: [
                          DropdownMenuItem(child: Text('Tümü', style: TextStyle(color: textColor))),
                          ...agentIds.map((id) => DropdownMenuItem(
                                value: id,
                                child: Text(agentNames[id] ?? id, style: TextStyle(color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (v) => onAgentChanged(v),
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space3),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: filterOutcome,
                        isExpanded: true,
                        hint: Text('Sonuç', style: TextStyle(color: hintColor, fontSize: 13)),
                        dropdownColor: surfaceCard,
                        items: [
                          DropdownMenuItem(child: Text('Tümü', style: TextStyle(color: textColor))),
                          DropdownMenuItem(value: 'connected', child: Text('Bağlandı', style: TextStyle(color: textColor))),
                          DropdownMenuItem(value: 'missed', child: Text('Cevapsız', style: TextStyle(color: textColor))),
                          DropdownMenuItem(value: 'no_answer', child: Text('Cevap yok', style: TextStyle(color: textColor))),
                          DropdownMenuItem(value: 'busy', child: Text('Meşgul', style: TextStyle(color: textColor))),
                          DropdownMenuItem(value: 'failed', child: Text('Başarısız', style: TextStyle(color: textColor))),
                          DropdownMenuItem(value: 'handoff_pending', child: Text('Sonuç bekleniyor (handoff)', style: TextStyle(color: textColor))),
                        ],
                        onChanged: (v) => onOutcomeChanged(v),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Tıklamada gölge efekti (iPhone benzeri). Kısa süreli animasyon, kasma yok.
class _TapShadowButton extends StatefulWidget {
  const _TapShadowButton({
    required this.onPressed,
    required this.icon,
    this.label,
  });
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;

  @override
  State<_TapShadowButton> createState() => _TapShadowButtonState();
}

class _TapShadowButtonState extends State<_TapShadowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceCard = isDark ? AppThemeExtension.of(context).card : AppThemeExtension.of(context).surface;
    final borderColor = isDark ? AppThemeExtension.of(context).border : AppThemeExtension.of(context).border;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space3),
        decoration: BoxDecoration(
          color: surfaceCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(
            color: _pressed ? AppThemeExtension.of(context).accent.withValues(alpha: 0.5) : borderColor,
            width: _pressed ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _pressed ? 0.35 : 0.2),
              blurRadius: _pressed ? 4 : 8,
              offset: Offset(0, _pressed ? 1 : 3),
              spreadRadius: _pressed ? 0 : 0.5,
            ),
            if (!_pressed)
              BoxShadow(
                color: AppThemeExtension.of(context).accent.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 20, color: AppThemeExtension.of(context).accent),
            if (widget.label != null) ...[
              const SizedBox(width: 6),
              Text(
                widget.label!,
                style: TextStyle(
                  color: AppThemeExtension.of(context).accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
