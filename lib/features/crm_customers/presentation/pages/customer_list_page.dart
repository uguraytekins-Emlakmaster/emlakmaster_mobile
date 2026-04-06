import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/firebase/user_facing_firebase_message.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/contact_save/presentation/widgets/save_contact_sheet.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/sync_delayed_risk_customer_ids_provider.dart';
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
      } on FirebaseException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userFacingErrorMessage(e, context: 'customer_list_task')),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } on StateError catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userFacingErrorMessage(e, context: 'customer_list_task')),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
    final uid = ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
    final asyncCustomers = ref.watch(customerListForAgentProvider);
    final showAddDock = uid.isNotEmpty &&
        asyncCustomers.maybeWhen(
          data: (_) => true,
          orElse: () => false,
        );

    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                cacheExtent: 320,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.space6,
                        DesignTokens.space5,
                        DesignTokens.space6,
                        DesignTokens.space3,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _selectionMode
                                  ? AppLocalizations.of(context).tArgs('n_selected', ['${_selectedIds.length}'])
                                  : AppLocalizations.of(context).t('title_customers'),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: ext.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                                style: TextStyle(color: ext.textSecondary),
                              ),
                            ),
                            const SizedBox(width: DesignTokens.space2),
                            Flexible(
                              child: FilledButton.icon(
                                onPressed: _selectedIds.isEmpty ? null : () => _addSelectedToFollowUp(context, ref),
                                icon: const Icon(Icons.playlist_add_rounded, size: 18),
                                label: Text(
                                  AppLocalizations.of(context).tArgs('add_to_follow_up_count', ['${_selectedIds.length}']),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: ext.brandPrimary,
                                  foregroundColor: ext.onBrand,
                                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space3),
                                ),
                              ),
                            ),
                          ] else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: AppLocalizations.of(context).t('bulk_action'),
                                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                  padding: const EdgeInsets.all(10),
                                  onPressed: () => setState(() => _selectionMode = true),
                                  icon: Icon(Icons.checklist_rtl_rounded, color: ext.accent),
                                  visualDensity: VisualDensity.standard,
                                ),
                                const SizedBox(width: DesignTokens.space2),
                                Flexible(
                                  child: FilledButton.icon(
                                    onPressed: () => context.push(AppRouter.routeBulkCampaign),
                                    icon: const Icon(Icons.campaign_rounded, size: 18),
                                    label: Text(
                                      AppLocalizations.of(context).t('bulk_campaign'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: ext.brandPrimary,
                                      foregroundColor: ext.onBrand,
                                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: 12),
                                      visualDensity: VisualDensity.standard,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                  const SliverPadding(padding: EdgeInsets.only(top: DesignTokens.space3)),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: asyncCustomers.when(
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
                            ? List<CustomerEntity>.from(entities)
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
                        final riskIds = ref.watch(syncDelayedRiskCustomerIdsProvider);
                        if (filtered.length > 1) {
                          filtered.sort((a, b) {
                            final ar = riskIds.contains(a.id);
                            final br = riskIds.contains(b.id);
                            if (ar != br) return ar ? -1 : 1;
                            return b.updatedAt.compareTo(a.updatedAt);
                          });
                        }
                        if (filtered.isEmpty) {
                          final l10n = AppLocalizations.of(context);
                          final noCustomers = entities.isEmpty;
                          final noSearchHits = !noCustomers && _searchQuery.isNotEmpty;
                          return Padding(
                            padding: EdgeInsets.only(
                              top: noCustomers ? DesignTokens.space2 : 0,
                            ),
                            child: EmptyState(
                              premiumVisual: true,
                              grouped: noCustomers,
                              anchorAboveCenter: true,
                              anchorAlignmentY: noCustomers ? -0.48 : -0.4,
                              icon: Icons.people_rounded,
                              title: noSearchHits
                                  ? l10n.t('empty_search_title')
                                  : l10n.t('empty_customers_title'),
                              subtitle: noSearchHits
                                  ? l10n.tArgs('empty_search_subtitle', [_searchController.text.trim()])
                                  : l10n.t('empty_customers_subtitle'),
                              actionLabel: noCustomers ? l10n.t('empty_customers_cta') : null,
                              onAction: noCustomers
                                  ? () {
                                      HapticFeedback.lightImpact();
                                      showSaveContactSheet(context, source: 'crm_empty_state');
                                    }
                                  : null,
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            DesignTokens.space6,
                            0,
                            DesignTokens.space6,
                            showAddDock ? 88 : DesignTokens.space4,
                          ),
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
                    ),
                  ),
                ],
              ),
            ),
            if (showAddDock)
              _CustomerAddDockBar(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  showSaveContactSheet(context, source: 'crm_list');
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomerAddDockBar extends StatelessWidget {
  const _CustomerAddDockBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: ext.surfaceElevated,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: ext.border.withValues(alpha: 0.5)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space6,
            DesignTokens.space3,
            DesignTokens.space6,
            DesignTokens.space3,
          ),
          child: FilledButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              onPressed();
            },
            icon: Icon(Icons.person_add_rounded, color: ext.onBrand, size: 22),
            label: Text(
              'Müşteri ekle',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: ext.onBrand,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: ext.accent,
              foregroundColor: ext.onBrand,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
              ),
            ),
          ),
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
      height: 48,
      decoration: BoxDecoration(
        color: ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
        border: Border.all(color: ext.border.withValues(alpha: 0.55)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).t('search_customers'),
          hintStyle: TextStyle(color: ext.textTertiary, fontSize: DesignTokens.fontSizeBase),
          prefixIcon: Icon(Icons.search_rounded, color: ext.textTertiary, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: 12),
        ),
        style: TextStyle(color: ext.textPrimary),
      ),
    );
  }
}
