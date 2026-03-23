import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/utils/csv_export.dart';
import 'package:flutter/services.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final loadingBg = isDark ? DesignTokens.scaffoldDark : DesignTokens.backgroundLight;
    return roleAsync.when(
      loading: () => Scaffold(
        backgroundColor: loadingBg,
        body: const Center(
          child: CircularProgressIndicator(color: DesignTokens.primary),
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
  };

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceCard = isDark ? DesignTokens.surfaceDarkCard : DesignTokens.surfaceLight;
    final textPrimary = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    final textSecondary = isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
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
                hintText: 'Telefon, danışman, sonuç...',
                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: DesignTokens.primary.withValues(alpha: 0.9), size: 22),
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
                  borderSide: const BorderSide(color: DesignTokens.primary, width: 1.2),
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
    final bg = isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight;
    final fg = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    return Scaffold(
      backgroundColor: bg,
      appBar: emlakAppBar(
        context,
        title: const Text('Çağrı Merkezi'),
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
                const SnackBar(
                  content: Text('CSV panoya kopyalandı. Excel\'e yapıştırabilirsiniz.'),
                  backgroundColor: DesignTokens.primary,
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
                stream: FirestoreService.callsStream(),
                builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: DesignTokens.primary),
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
                          color: DesignTokens.textSecondaryDark, size: 48),
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
                          color: isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight,
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
            final q = _searchQuery.toLowerCase();
            final filtered = docs.where((d) {
              final data = d.data();
              final agentId = data['agentId'] as String? ?? '';
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
                final matches = id.contains(q) || agentId.toLowerCase().contains(q) ||
                    phone.contains(q) || outcomeLabel.contains(q);
                if (!matches) return false;
              }
              return true;
            }).toList();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _lastFilteredDocs = filtered);
            });
            if (filtered.isEmpty) {
              final hasAnyDocs = docs.isNotEmpty;
              return EmptyState(
                compact: true,
                icon: Icons.call_rounded,
                title: hasAnyDocs ? 'Uygun çağrı yok' : 'Çağrı kaydı yok',
                subtitle: hasAnyDocs
                    ? 'Arama veya filtrelere uygun kayıt bulunamadı.'
                    : 'Henüz sisteme düşen çağrı yok. Yeni kayıtlar burada listelenir.',
                outlinedActionLabel: hasAnyDocs ? 'Filtreleri temizle' : 'Yeni kayıt (yakında)',
                onOutlinedAction: hasAnyDocs
                    ? _clearFilters
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Çağrı ekleme akışı yakında bağlanacak.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(DesignTokens.space4),
              itemCount: filtered.length,
              cacheExtent: 300,
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
                final cardTheme = Theme.of(context);
                final cardIsDark = cardTheme.brightness == Brightness.dark;
                final surface = cardIsDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
                final tp = cardIsDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
                final ts = cardIsDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;
                return Card(
                  margin: const EdgeInsets.only(bottom: DesignTokens.space2),
                  color: surface,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: DesignTokens.primary,
                      child: Icon(Icons.call_rounded, color: DesignTokens.inputTextOnGold, size: 20),
                    ),
                    title: Text(
                      'Çağrı ${id.length > 8 ? id.substring(0, 8) : id}',
                      style: TextStyle(
                        color: tp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Danışman: $agentId · $durationStr · $outcomeStr · $timeStr',
                      style: TextStyle(
                        color: ts,
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
            final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
            final surfaceCard = isDark ? DesignTokens.surfaceDarkCard : DesignTokens.surfaceLight;
            final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
            final textColor = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
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
    final surfaceCard = isDark ? DesignTokens.surfaceDarkCard : DesignTokens.surfaceLight;
    final borderColor = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
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
            color: _pressed ? DesignTokens.primary.withValues(alpha: 0.5) : borderColor,
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
                color: DesignTokens.primary.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 20, color: DesignTokens.primary),
            if (widget.label != null) ...[
              const SizedBox(width: 6),
              Text(
                widget.label!,
                style: const TextStyle(
                  color: DesignTokens.primary,
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
