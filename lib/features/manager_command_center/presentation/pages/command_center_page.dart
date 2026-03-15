import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/utils/csv_export.dart';
import 'package:flutter/services.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
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
    return roleAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00FF41)),
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

class _CommandCenterBodyState extends State<_CommandCenterBody> {
  late int _viewIndex;
  String? _filterAgentId;
  String? _filterOutcome;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _lastFilteredDocs;

  @override
  void initState() {
    super.initState();
    _viewIndex = widget._viewIndex;
  }

  static const Map<String, String> _outcomeLabels = {
    'connected': 'Bağlandı',
    'missed': 'Cevapsız',
    'no_answer': 'Cevap yok',
    'busy': 'Meşgul',
    'failed': 'Başarısız',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        title: const Text('Çağrı Merkezi'),
        backgroundColor: DesignTokens.backgroundDark,
        foregroundColor: DesignTokens.textPrimaryDark,
        leading: ModalRoute.of(context)?.canPop == true
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              )
            : null,
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
                const SnackBar(
                  content: Text('CSV panoya kopyalandı. Excel\'e yapıştırabilirsiniz.'),
                  backgroundColor: Color(0xFF00FF41),
                ),
              );
            },
            tooltip: 'CSV dışa aktar',
          ),
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
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _CommandCenterFilters(
              filterAgentId: _filterAgentId,
              filterOutcome: _filterOutcome,
              onAgentChanged: (id) => setState(() => _filterAgentId = id),
              onOutcomeChanged: (outcome) => setState(() => _filterOutcome = outcome),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirestoreService.callsStream(),
                builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00FF41)),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.white54, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Çağrılar yüklenemedi.',
                        style: TextStyle(
                          color: DesignTokens.textPrimaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Lütfen tekrar deneyin.',
                        style: TextStyle(
                          color: DesignTokens.textSecondaryDark,
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
                          foregroundColor: DesignTokens.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            final filtered = docs.where((d) {
              final data = d.data();
              if (_filterAgentId != null &&
                  (data['agentId'] as String? ?? '') != _filterAgentId) {
                return false;
              }
              if (_filterOutcome != null &&
                  (data['outcome'] as String? ?? data['callOutcome'] as String?) != _filterOutcome) {
                return false;
              }
              return true;
            }).toList();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _lastFilteredDocs = filtered);
            });
            if (filtered.isEmpty) {
              return const EmptyState(
                icon: Icons.call_rounded,
                title: 'Çağrı listesi',
                subtitle: 'Henüz kayıtlı çağrı yok veya filtreye uygun sonuç yok.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(DesignTokens.space4),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final doc = filtered[index];
                final data = doc.data();
                final id = doc.id;
                final agentId = data['agentId'] as String? ?? '—';
                final duration = data['durationSec'] as num?;
                final durationStr =
                    duration != null ? '${duration.toInt()} sn' : '—';
                final outcomeRaw = data['outcome'] as String? ?? data['callOutcome'] as String?;
                final outcomeStr = outcomeRaw != null
                    ? _outcomeLabels[outcomeRaw] ?? outcomeRaw
                    : '—';
                final createdAt = data['createdAt'];
                String timeStr = '—';
                if (createdAt is Timestamp) {
                  final dt = createdAt.toDate();
                  timeStr = '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                } else if (createdAt != null) {
                  timeStr = createdAt.toString();
                }
                return Card(
                  margin: const EdgeInsets.only(bottom: DesignTokens.space2),
                  color: DesignTokens.surfaceDark,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF00FF41),
                      child: Icon(Icons.call_rounded, color: Colors.black, size: 20),
                    ),
                    title: Text(
                      'Çağrı ${id.length > 8 ? id.substring(0, 8) : id}',
                      style: const TextStyle(
                        color: DesignTokens.textPrimaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Danışman: $agentId · $durationStr · $outcomeStr · $timeStr',
                      style: const TextStyle(
                        color: DesignTokens.textSecondaryDark,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
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
    required this.filterAgentId,
    required this.filterOutcome,
    required this.onAgentChanged,
    required this.onOutcomeChanged,
  });
  final String? filterAgentId;
  final String? filterOutcome;
  final void Function(String?) onAgentChanged;
  final void Function(String?) onOutcomeChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.agentsStream(),
      builder: (context, agentSnap) {
        final agents = agentSnap.data?.docs ?? [];
        final agentIds = agents.map((d) => d.id).toList();
        final agentNames = {
          for (final d in agents) d.id: d.data()['displayName'] as String? ?? d.id,
        };
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space2),
          decoration: const BoxDecoration(
            color: DesignTokens.surfaceDark,
            border: Border(bottom: BorderSide(color: DesignTokens.borderDark)),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: filterAgentId,
                    isExpanded: true,
                    hint: const Text('Danışman', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    dropdownColor: const Color(0xFF161B22),
                    items: [
                      const DropdownMenuItem(child: Text('Tümü', style: TextStyle(color: Colors.white))),
                      ...agentIds.map((id) => DropdownMenuItem(
                            value: id,
                            child: Text(agentNames[id] ?? id, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                    hint: const Text('Sonuç', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    dropdownColor: const Color(0xFF161B22),
                    items: const [
                      DropdownMenuItem(child: Text('Tümü', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'connected', child: Text('Bağlandı', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'missed', child: Text('Cevapsız', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'no_answer', child: Text('Cevap yok', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'busy', child: Text('Meşgul', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'failed', child: Text('Başarısız', style: TextStyle(color: Colors.white))),
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
  }
}
