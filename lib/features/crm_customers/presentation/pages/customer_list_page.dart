import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/models/customer_models.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../widgets/customer_card.dart';

/// CRM müşteri listesi: Firestore customers stream + arama + kartlar + toplu işlem.
class CustomerListPage extends ConsumerStatefulWidget {
  const CustomerListPage({super.key});

  @override
  ConsumerState<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends ConsumerState<CustomerListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  Future<void> _addSelectedToFollowUp(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    HapticFeedback.mediumImpact();
    final count = _selectedIds.length;
    final due = DateTime.now().add(const Duration(days: 3));
    for (final id in _selectedIds) {
      await FirestoreService.setTask({
        'advisorId': uid,
        'customerId': id,
        'title': 'Takip et',
        'dueAt': Timestamp.fromDate(due),
        'done': false,
      });
    }
    if (context.mounted) {
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count müşteri takip listesine eklendi (Görevler\'de görünür).'),
          backgroundColor: DesignTokens.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static CustomerEntity _docToEntity(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final id = doc.id;
    final updatedAt = _parseDate(data['updatedAt']) ?? DateTime.now();
    final createdAt = _parseDate(data['createdAt']) ?? updatedAt;
    final fullName = data['fullName'] as String? ??
        data['customerIntent'] as String? ??
        'Müşteri';
    final regionRaw = data['regionPreferences'] ?? data['preferredRegions'];
    final regionList = regionRaw is List ? regionRaw.map((e) => e.toString()).toList() : <String>[];
    return CustomerEntity(
      id: id,
      fullName: fullName.isEmpty ? 'İsimsiz' : fullName,
      primaryPhone: data['primaryPhone'] as String? ?? data['phone'] as String?,
      email: data['email'] as String?,
      assignedAdvisorId: data['assignedAgentId'] as String?,
      nextSuggestedAction: data['lastNextStepSuggestion'] as String?,
      lastInteractionAt: _parseDate(data['lastInteractionAt']) ?? updatedAt,
      regionPreferences: List<String>.from(regionList),
      callsCount: data['callsCount'] as int? ?? 0,
      visitsCount: data['visitsCount'] as int? ?? 0,
      offersCount: data['offersCount'] as int? ?? 0,
      budgetMin: (data['budgetMin'] as num?)?.toDouble(),
      budgetMax: (data['budgetMax'] as num?)?.toDouble(),
      leadTemperature: (data['leadTemperature'] as num?)?.toDouble(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeExtension.of(context).background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space6,
                  DesignTokens.space4,
                  DesignTokens.space6,
                  DesignTokens.space2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectionMode
                            ? AppLocalizations.of(context).tArgs('n_selected', ['${_selectedIds.length}'])
                            : AppLocalizations.of(context).t('title_customers'),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppThemeExtension.of(context).foreground,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (_selectionMode) ...[
                      TextButton(
                        onPressed: () => setState(() {
                          _selectionMode = false;
                          _selectedIds.clear();
                        }),
                        child: Text(
                          AppLocalizations.of(context).t('cancel'),
                          style: TextStyle(color: AppThemeExtension.of(context).foregroundSecondary),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _selectedIds.isEmpty ? null : () => _addSelectedToFollowUp(context, ref),
                        icon: const Icon(Icons.playlist_add_rounded, size: 18),
                        label: Text(AppLocalizations.of(context).tArgs('add_to_follow_up_count', ['${_selectedIds.length}'])),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppThemeExtension.of(context).brandPrimary,
                          foregroundColor: AppThemeExtension.of(context).onBrand,
                        ),
                      ),
                    ] else ...[
                      TextButton.icon(
                        onPressed: () => setState(() => _selectionMode = true),
                        icon: Icon(Icons.checklist_rounded, size: 20, color: AppThemeExtension.of(context).brandPrimary),
                        label: Text(
                          AppLocalizations.of(context).t('bulk_action'),
                          style: TextStyle(color: AppThemeExtension.of(context).brandPrimary),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.space2),
                      FilledButton.icon(
                        onPressed: () => context.push(AppRouter.routeBulkCampaign),
                        icon: const Icon(Icons.campaign_rounded, size: 18),
                        label: Text(AppLocalizations.of(context).t('bulk_campaign')),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppThemeExtension.of(context).brandPrimary,
                          foregroundColor: AppThemeExtension.of(context).onBrand,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space6),
                child: _SearchBar(controller: _searchController),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(top: DesignTokens.space4)),
            SliverFillRemaining(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirestoreService.customersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: DesignTokens.primary),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: AppThemeExtension.of(context).danger.withValues(alpha: 0.9),
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppLocalizations.of(context).t('customer_list_load_error'),
                              style: TextStyle(
                                color: AppThemeExtension.of(context).foreground,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];
                  final entities = docs.map(_docToEntity).toList();
                  final filtered = _searchQuery.isEmpty
                      ? entities
                      : entities.where((e) {
                          final q = _searchQuery;
                          final name = (e.fullName ?? '').toLowerCase();
                          final phone = (e.primaryPhone ?? '').replaceAll(RegExp(r'\s'), '');
                          final email = (e.email ?? '').toLowerCase();
                          final queryNoSpaces = q.replaceAll(RegExp(r'\s'), '');
                          return name.contains(q) ||
                              email.contains(q) ||
                              phone.contains(queryNoSpaces) ||
                              (queryNoSpaces.isNotEmpty && phone.contains(queryNoSpaces));
                        }).toList();
                  if (filtered.isEmpty) {
                    final l10n = AppLocalizations.of(context);
                    return EmptyState(
                      premiumVisual: true,
                      icon: Icons.people_rounded,
                      title: docs.isEmpty ? l10n.t('empty_customers_title') : l10n.t('empty_search_title'),
                      subtitle: docs.isEmpty
                          ? '${l10n.t('empty_customers_subtitle')}\n\n${l10n.t('empty_state_empower')}'
                          : l10n.tArgs('empty_search_subtitle', [_searchQuery]),
                      actionLabel: docs.isEmpty ? l10n.t('add_customer') : null,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space6),
                    itemCount: filtered.length,
                    cacheExtent: 200,
                    semanticChildCount: filtered.length,
                    itemBuilder: (context, index) {
                      final entity = filtered[index];
                      final isSelected = _selectedIds.contains(entity.id);
                      return RepaintBoundary(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: DesignTokens.space3),
                          child: CustomerCard(
                          customer: entity,
                          onTap: () {
                            if (_selectionMode) {
                              setState(() {
                                if (isSelected) {
                                  _selectedIds.remove(entity.id);
                                } else {
                                  _selectedIds.add(entity.id);
                                }
                              });
                            } else {
                              context.push(AppRouter.routeCustomerDetail.replaceFirst(':id', entity.id));
                            }
                          },
                          selectionMode: _selectionMode,
                          isSelected: isSelected,
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: ext.border.withValues(alpha: 0.65)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).t('search_customers'),
          hintStyle: TextStyle(color: ext.foregroundMuted, fontSize: DesignTokens.fontSizeBase),
          prefixIcon: Icon(Icons.search_rounded, color: ext.foregroundMuted, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: 12),
        ),
        style: TextStyle(color: ext.foreground),
      ),
    );
  }
}
