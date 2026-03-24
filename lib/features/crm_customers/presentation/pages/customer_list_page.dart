import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/design_tokens.dart';
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

  Future<void> _addSelectedToFollowUp(BuildContext context, WidgetRef ref) async {
    final ext = AppThemeExtension.of(context);
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    HapticFeedback.mediumImpact();
    final due = DateTime.now().add(const Duration(days: 3));
    var count = 0;
    for (final id in _selectedIds) {
      if (id.startsWith('__dev_demo_')) continue;
      count++;
      try {
        await FirestoreService.setTask({
          'advisorId': uid,
          'customerId': id,
          'title': 'Takip et',
          'dueAt': Timestamp.fromDate(due),
          'done': false,
        });
      } catch (_) {
        // Yumuşak geçiş: görev yazılamazsa sessizce atla
      }
    }
    if (context.mounted) {
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count müşteri takip listesine eklendi (Görevler\'de görünür).'),
          backgroundColor: ext.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Scaffold(
      backgroundColor: ext.background,
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
                              color: ext.foreground,
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
                          style: TextStyle(color: ext.foregroundSecondary),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _selectedIds.isEmpty ? null : () => _addSelectedToFollowUp(context, ref),
                        icon: const Icon(Icons.playlist_add_rounded, size: 18),
                        label: Text(AppLocalizations.of(context).tArgs('add_to_follow_up_count', ['${_selectedIds.length}'])),
                        style: FilledButton.styleFrom(
                          backgroundColor: ext.brandPrimary,
                          foregroundColor: ext.onBrand,
                        ),
                      ),
                    ] else ...[
                      TextButton.icon(
                        onPressed: () => setState(() => _selectionMode = true),
                        icon: Icon(Icons.checklist_rounded, size: 20, color: ext.brandPrimary),
                        label: Text(
                          AppLocalizations.of(context).t('bulk_action'),
                          style: TextStyle(color: ext.brandPrimary),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.space2),
                      FilledButton.icon(
                        onPressed: () => context.push(AppRouter.routeBulkCampaign),
                        icon: const Icon(Icons.campaign_rounded, size: 18),
                        label: Text(AppLocalizations.of(context).t('bulk_campaign')),
                        style: FilledButton.styleFrom(
                          backgroundColor: ext.brandPrimary,
                          foregroundColor: ext.onBrand,
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
              child: Consumer(
                builder: (context, ref, _) {
                  final async = ref.watch(customerListForAgentProvider);
                  return async.when(
                    loading: () => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: ext.accent),
                      ),
                    ),
                    error: (_, __) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: EmptyState(
                          premiumVisual: true,
                          icon: Icons.cloud_off_rounded,
                          title: AppLocalizations.of(context).t('customer_list_load_error'),
                          subtitle: 'Bağlantıyı kontrol edin veya bir süre sonra yeniden deneyin.',
                        ),
                      ),
                    ),
                    data: (entities) {
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
                    final isEmptyFirestore = entities.isEmpty;
                    return EmptyState(
                      premiumVisual: true,
                      icon: Icons.people_rounded,
                      title: isEmptyFirestore ? l10n.t('empty_customers_title') : l10n.t('empty_search_title'),
                      subtitle: isEmptyFirestore
                          ? l10n.t('empty_customers_subtitle')
                          : l10n.tArgs('empty_search_subtitle', [_searchQuery]),
                      actionLabel: isEmptyFirestore ? l10n.t('empty_customers_cta') : null,
                      onAction: isEmptyFirestore
                          ? () => context.push(AppRouter.routeCall)
                          : null,
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
                              if (entity.id.startsWith('__dev_demo_')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Demo kayıt — gerçek müşteri için arama veya müşteri oluşturun.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
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
