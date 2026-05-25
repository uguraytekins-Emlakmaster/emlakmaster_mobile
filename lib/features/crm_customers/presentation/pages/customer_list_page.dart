import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/firebase/user_facing_firebase_message.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/navigation/shell_tab_back_binding.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/utils/sms_launcher.dart';
import 'package:emlakmaster_mobile/core/utils/whatsapp_launcher.dart';
import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/features/calls/application/start_crm_outbound_call.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:emlakmaster_mobile/features/contact_save/presentation/widgets/save_contact_sheet.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/consultant_customers_layout.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/utils/customer_list_heat_filter.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/consultant_customers_chrome.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/consultant_customers_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_filtered_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_row_snapshots_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/utils/customer_crm_refresh.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_extra_page_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/models/customer_list_page_data.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/screens/consultant_shell_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/foundation.dart';
import '../widgets/customer_card.dart';

/// Liste altı — dock bar + büyük metin ölçeği için güvenli boşluk (SE / erişilebilirlik).
double _customerListDockBottomReserve(BuildContext context) {
  final ts = MediaQuery.textScalerOf(context);
  final ratio = ts.scale(DesignTokens.fontSizeBase) / DesignTokens.fontSizeBase;
  final clamped = ratio.clamp(1.0, 1.38);
  return 120 * clamped;
}

/// CRM müşteri listesi: Firestore customers stream + arama + kartlar + toplu işlem.
class CustomerListPage extends ConsumerStatefulWidget {
  const CustomerListPage({super.key});

  @override
  ConsumerState<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends ConsumerState<CustomerListPage> {
  final _readyTracker = ShellScreenReadyTracker('customer_list');
  late final DebouncedSearchController _debouncedSearch;
  String _searchQuery = '';
  CustomerListHeatFilter _heatFilter = CustomerListHeatFilter.all;
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  TextEditingController get _searchController => _debouncedSearch.controller;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint(
        'ConsultantCustomers layout=${ConsultantCustomersLayout.layoutVersion} '
        '${ConsultantCustomersLayout.fingerprint}',
      );
    }
    _debouncedSearch = DebouncedSearchController(
      onQueryChanged: (q) {
        if (!mounted) return;
        setState(() => _searchQuery = q.toLowerCase());
      },
    );
  }

  @override
  void dispose() {
    _debouncedSearch.dispose();
    super.dispose();
  }

  Future<void> _addSelectedToFollowUp(
      BuildContext context, WidgetRef ref) async {
    final ext = AppThemeExtension.of(context);
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    AppFeedback.mediumImpact();
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
              content: Text(
                  userFacingErrorMessage(e, context: 'customer_list_task')),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } on StateError catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  userFacingErrorMessage(e, context: 'customer_list_task')),
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
          content: Text(
              '$count müşteri takip listesine eklendi (Görevler\'de görünür).'),
          backgroundColor: ext.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _handleExitSearch() {
    if (_searchQuery.isEmpty && _searchController.text.trim().isEmpty) {
      return false;
    }
    setState(() => _searchController.clear());
    return true;
  }

  bool _handleClearSelection() {
    if (!_selectionMode) return false;
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
    return true;
  }

  bool _isDemoCustomer(String id) => id.startsWith('__dev_demo_');

  String? _callablePhone(CustomerEntity entity) {
    if (_isDemoCustomer(entity.id)) return null;
    final phone = entity.primaryPhone?.trim() ?? '';
    if (phone.isEmpty || !OutboundPhoneDial.isLikelyCallablePhone(phone)) {
      return null;
    }
    return phone;
  }

  void _openCustomerDetail(
    BuildContext context,
    WidgetRef ref,
    String customerId,
  ) {
    if (_isDemoCustomer(customerId)) {
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
    context
        .push(
          AppRouter.routeCustomerDetail.replaceFirst(':id', customerId),
        )
        .then((_) {
      if (context.mounted) {
        invalidateCustomerCrmCascade(ref, customerId);
      }
    });
  }

  void _startRowCall(BuildContext context, CustomerEntity entity) {
    final phone = _callablePhone(entity);
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aranabilir telefon numarası yok.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    AppFeedback.mediumImpact();
    startCrmOutboundCall(
      context,
      phone: phone,
      customerId: entity.id,
      startedFromScreen: 'consultant_customers_list',
    );
  }

  Future<void> _startRowMessage(BuildContext context, CustomerEntity entity) async {
    final phone = _callablePhone(entity);
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesaj için telefon numarası yok.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    AppFeedback.lightImpact();
    final ok = await SmsLauncher.openBulkSms([phone]);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesaj uygulaması açılamadı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _startRowWhatsApp(BuildContext context, CustomerEntity entity) async {
    final phone = _callablePhone(entity);
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp için telefon numarası yok.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    AppFeedback.lightImpact();
    final ok = await WhatsAppLauncher.openChat(phone);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp açılamadı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final uid =
        ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
    final asyncCustomers = ref.watch(customerListForAgentProvider);
    final extraPage = uid.isEmpty
        ? null
        : ref.watch(customerListExtraPageProvider(uid));
    ref.listen(customerListForAgentProvider, (previous, next) {
      if (next.hasValue) {
        _readyTracker.onContentReady(
          itemCount: next.value!.entities.length,
        );
      }
    });
    final showAddDock = uid.isNotEmpty &&
        asyncCustomers.maybeWhen(
          data: (page) => page.entities.isNotEmpty,
          orElse: () => false,
        );

    return ShellTabBackBinding(
      onExitSearch: _handleExitSearch,
      onClearSelection: _handleClearSelection,
      child: PremiumShellBackdrop(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                cacheExtent: 320,
                slivers: [
                  if (!_selectionMode)
                    SliverToBoxAdapter(
                      child: PremiumCustomersPageHeader(
                        title: AppLocalizations.of(context)
                            .t('title_customers'),
                        subtitle:
                            'İlişki portföyü — arama, sıcaklık ve hızlı aksiyon.',
                      ),
                    ),
                  if (_selectionMode)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          ConsultantCustomersTokens.horizontal,
                          DesignTokens.space3,
                          ConsultantCustomersTokens.horizontal,
                          DesignTokens.space3,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context).tArgs(
                                  'n_selected',
                                  ['${_selectedIds.length}'],
                                ),
                                style: AppTypography.pageHeading(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        ConsultantCustomersTokens.horizontal,
                        0,
                        ConsultantCustomersTokens.horizontal,
                        DesignTokens.space3,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                onPressed: _selectedIds.isEmpty
                                    ? null
                                    : () =>
                                        _addSelectedToFollowUp(context, ref),
                                icon: const Icon(Icons.playlist_add_rounded,
                                    size: 18),
                                label: Text(
                                  AppLocalizations.of(context).tArgs(
                                      'add_to_follow_up_count',
                                      ['${_selectedIds.length}']),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: ext.brandPrimary,
                                  foregroundColor: ext.onBrand,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: DesignTokens.space3),
                                ),
                              ),
                            ),
                          ] else ...[
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: AppLocalizations.of(context)
                                      .t('bulk_action'),
                                  constraints: const BoxConstraints(
                                      minWidth: 44, minHeight: 44),
                                  padding: const EdgeInsets.all(10),
                                  onPressed: () =>
                                      setState(() => _selectionMode = true),
                                  icon: Icon(Icons.checklist_rtl_rounded,
                                      color: ext.accent),
                                  visualDensity: VisualDensity.standard,
                                ),
                                const SizedBox(width: DesignTokens.space2),
                                Flexible(
                                  child: FilledButton.icon(
                                    onPressed: () => context
                                        .push(AppRouter.routeBulkCampaign),
                                    icon: const Icon(Icons.campaign_rounded,
                                        size: 18),
                                    label: Text(
                                      AppLocalizations.of(context)
                                          .t('bulk_campaign'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          AppTypography.secondaryButton(context)
                                              .copyWith(color: ext.onBrand),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: ext.brandPrimary,
                                      foregroundColor: ext.onBrand,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: DesignTokens.space4,
                                        vertical: 14,
                                      ),
                                      visualDensity: VisualDensity.standard,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: PremiumCustomerSearchRow(
                      controller: _searchController,
                      hintText:
                          AppLocalizations.of(context).t('search_customers'),
                    ),
                  ),
                  if (!_selectionMode)
                    SliverToBoxAdapter(
                      child: PremiumCustomerHeatFilterStrip(
                        selected: _heatFilter,
                        onSelected: (f) => setState(() => _heatFilter = f),
                      ),
                    ),
                  const SliverPadding(
                      padding: EdgeInsets.only(top: DesignTokens.space2)),
                  ..._customerListBodySlivers(
                    context: context,
                    ref: ref,
                    ext: ext,
                    asyncCustomers: asyncCustomers,
                    uid: uid,
                    extraPage: extraPage,
                    showAddDock: showAddDock,
                  ),
                ],
              ),
            ),
            if (showAddDock)
              _CustomerAddDockBar(
                onPressed: () {
                  AppFeedback.lightImpact();
                  showSaveContactSheet(context, source: 'crm_list');
                },
              ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  List<Widget> _customerListBodySlivers({
    required BuildContext context,
    required WidgetRef ref,
    required AppThemeExtension ext,
    required AsyncValue<CustomerListPageData> asyncCustomers,
    required String uid,
    required CustomerListExtraPageState? extraPage,
    required bool showAddDock,
  }) {
    return asyncCustomers.when(
      loading: () => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CircularProgressIndicator(color: ext.accent),
            ),
          ),
        ),
      ],
      error: (_, __) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: EmptyState(
                premiumVisual: true,
                grouped: true,
                icon: Icons.cloud_off_rounded,
                title: AppLocalizations.of(context)
                    .t('customer_list_load_error'),
                subtitle:
                    'Bağlantıyı kontrol edin; bir süre sonra yenileyin.',
              ),
            ),
          ),
        ),
      ],
      data: (page) {
        final searchFiltered =
            ref.watch(customerListFilteredProvider(_searchQuery));
        final rowSnapshots =
            ref.watch(customerListRowSnapshotsProvider(_searchQuery));
        final filtered = applyCustomerHeatFilter(
          entities: searchFiltered,
          snapshots: rowSnapshots,
          filter: _heatFilter,
        );
        final listBottom = showAddDock
            ? _customerListDockBottomReserve(context)
            : DesignTokens.space4;
        final canLoadMore =
            uid.isNotEmpty && (page.hasMore || (extraPage?.hasMore ?? false));

        if (filtered.isEmpty) {
          final l10n = AppLocalizations.of(context);
          final noCustomers = page.entities.isEmpty &&
              (extraPage?.extraEntities.isEmpty ?? true);
          final noSearchHits = !noCustomers && _searchQuery.isNotEmpty;
          final noHeatHits = !noCustomers &&
              !noSearchHits &&
              searchFiltered.isNotEmpty &&
              filtered.isEmpty;
          if (noCustomers) {
            return [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.space5,
                    DesignTokens.space4,
                    DesignTokens.space5,
                    DesignTokens.space6,
                  ),
                  child: Center(
                    child: _ConsultantCustomersEmptyLaunchpad(
                      onPrimaryAdd: () {
                        AppFeedback.lightImpact();
                        showSaveContactSheet(
                          context,
                          source: 'crm_empty_launchpad',
                        );
                      },
                      onVoiceQuickAdd: () {
                        AppFeedback.lightImpact();
                        showSaveContactSheet(
                          context,
                          source: 'crm_empty_voice',
                        );
                      },
                      onOpenCalls: () {
                        AppFeedback.lightImpact();
                        final shell = ConsultantShellNav.maybeOf(context);
                        if (shell != null) {
                          ConsultantShellNav.goToCallsTab(context);
                        } else {
                          ref
                              .read(mainShellShortcutProvider.notifier)
                              .enqueue(MainShellShortcut.openCallsTab);
                          context.go(AppRouter.routeHome);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ];
          }
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.only(
                  top: noSearchHits ? DesignTokens.space2 : 0,
                ),
                child: EmptyState(
                  premiumVisual: true,
                  grouped: true,
                  anchorAboveCenter: true,
                  icon: Icons.people_rounded,
                  title: noSearchHits
                      ? l10n.t('empty_search_title')
                      : noHeatHits
                          ? 'Bu sıcaklıkta müşteri yok'
                          : l10n.t('empty_customers_title'),
                  subtitle: noSearchHits
                      ? l10n.tArgs(
                          'empty_search_subtitle',
                          [_searchController.text.trim()],
                        )
                      : noHeatHits
                          ? '${_heatFilter.labelTr} filtresine uyan kayıt bulunamadı.'
                          : l10n.t('empty_customers_subtitle'),
                ),
              ),
            ),
          ];
        }

        return [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              ConsultantCustomersTokens.horizontal,
              0,
              ConsultantCustomersTokens.horizontal,
              listBottom,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entity = filtered[index];
                  final row = rowSnapshots[entity.id];
                  if (row == null) return const SizedBox.shrink();
                  final isSelected = _selectedIds.contains(entity.id);
                  return RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: ConsultantCustomersTokens.chromeGap + 2,
                      ),
                      child: CustomerCard(
                        customer: entity,
                        row: row,
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
                            _openCustomerDetail(context, ref, entity.id);
                          }
                        },
                        onCall: _selectionMode
                            ? null
                            : () => _startRowCall(context, entity),
                        onMessage: _selectionMode
                            ? null
                            : () => _startRowMessage(context, entity),
                        onWhatsApp: _selectionMode
                            ? null
                            : () => _startRowWhatsApp(context, entity),
                        onOpenDetail: _selectionMode
                            ? null
                            : () => _openCustomerDetail(context, ref, entity.id),
                        selectionMode: _selectionMode,
                        isSelected: isSelected,
                      ),
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
          if (canLoadMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  ConsultantCustomersTokens.horizontal,
                  DesignTokens.space2,
                  ConsultantCustomersTokens.horizontal,
                  listBottom,
                ),
                child: Center(
                  child: extraPage?.loading == true
                      ? Padding(
                          padding: const EdgeInsets.all(DesignTokens.space4),
                          child: CircularProgressIndicator(
                            color: ext.accent,
                            strokeWidth: 2,
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => ref
                              .read(customerListExtraPageProvider(uid).notifier)
                              .loadMore(uid),
                          icon: const Icon(Icons.expand_more_rounded),
                          label: const Text('Daha fazla müşteri yükle'),
                        ),
                ),
              ),
            ),
        ];
      },
    );
  }
}

class _CustomerAddDockBar extends StatelessWidget {
  const _CustomerAddDockBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Semantics(
      container: true,
      label: 'Müşteri ekle — portföye yeni kişi',
      child: Material(
        color: ext.surfaceElevated,
        elevation: 10,
        shadowColor: ext.shadowColor.withValues(alpha: 0.28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: ext.border.withValues(alpha: 0.55)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space6,
              DesignTokens.space3,
              DesignTokens.space6,
              DesignTokens.space4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Portföye yeni kişi',
                  textAlign: TextAlign.center,
                  style: AppTypography.meta(context).copyWith(
                    color: ext.textTertiary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: DesignTokens.space2),
                Tooltip(
                  message: 'Rehber ve CRM’e kayıt',
                  child: FilledButton.icon(
                    onPressed: () {
                      AppFeedback.mediumImpact();
                      onPressed();
                    },
                    icon: Icon(Icons.person_add_rounded,
                        color: ext.onBrand, size: 22),
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
                      minimumSize: const Size(double.infinity, 52),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      visualDensity: VisualDensity.standard,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusControl),
                      ),
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

/// Danışman müşteri sekmesi: boş durumda premium başlangıç alanı.
class _ConsultantCustomersEmptyLaunchpad extends StatelessWidget {
  const _ConsultantCustomersEmptyLaunchpad({
    required this.onPrimaryAdd,
    required this.onVoiceQuickAdd,
    required this.onOpenCalls,
  });

  final VoidCallback onPrimaryAdd;
  final VoidCallback onVoiceQuickAdd;
  final VoidCallback onOpenCalls;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final radius = BorderRadius.circular(DesignTokens.radiusLg);
    final outlineSide = BorderSide(color: ext.border.withValues(alpha: 0.72));
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 340;
        final hubSize = narrow ? 76.0 : 88.0;
        final hubIcon = narrow ? 34.0 : 40.0;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: ext.surfaceElevated,
                border: Border.all(color: ext.border.withValues(alpha: 0.55)),
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ext.accent.withValues(alpha: 0.9),
                              ext.accent.withValues(alpha: 0.12),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        narrow ? DesignTokens.space5 : DesignTokens.space6,
                        DesignTokens.space6 + 2,
                        narrow ? DesignTokens.space5 : DesignTokens.space6,
                        DesignTokens.space6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: ExcludeSemantics(
                              child: Container(
                                width: hubSize,
                                height: hubSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ext.accent.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: ext.accent.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Icon(
                                  Icons.hub_outlined,
                                  size: hubIcon,
                                  color: ext.accent,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                              height: narrow
                                  ? DesignTokens.space4
                                  : DesignTokens.space5),
                          Text(
                            'Müşteri portföyünü burada kur',
                            textAlign: TextAlign.center,
                            style: AppTypography.cardHeading(context).copyWith(
                              fontSize: narrow
                                  ? DesignTokens.fontSizeMd
                                  : DesignTokens.fontSizeLg,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.space3),
                          Text(
                            narrow
                                ? 'İlk kişiyle CRM canlanır; arama ve takip burada başlar.'
                                : 'Arama, teklif ve takip akışı ilk kişiyle başlar. '
                                    'CRM burada canlanır; ilk kayıt senin momentumunu açar.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body(context).copyWith(
                              color: ext.textTertiary,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(
                              height: narrow
                                  ? DesignTokens.space5
                                  : DesignTokens.space6),
                          Semantics(
                            button: true,
                            label: 'Müşteri ekle',
                            child: Tooltip(
                              message: 'Rehber ve CRM’e kayıt',
                              child: FilledButton.icon(
                                onPressed: onPrimaryAdd,
                                icon: Icon(Icons.person_add_rounded,
                                    color: ext.onBrand, size: 22),
                                label: Text(
                                  'Müşteri ekle',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: ext.onBrand,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: ext.accent,
                                  foregroundColor: ext.onBrand,
                                  minimumSize: const Size(double.infinity, 52),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  visualDensity: VisualDensity.standard,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        DesignTokens.radiusControl),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: DesignTokens.space3),
                          Semantics(
                            button: true,
                            label: 'Sesli veya hızlı müşteri kaydı',
                            child: Tooltip(
                              message: 'Sesli komut veya hızlı form',
                              child: OutlinedButton.icon(
                                onPressed: onVoiceQuickAdd,
                                icon: Icon(Icons.mic_none_rounded,
                                    size: 22, color: ext.accent),
                                label: Text(
                                  narrow
                                      ? 'Ses / hızlı kayıt'
                                      : 'Sesli veya hızlı kayıt',
                                  style: AppTypography.secondaryButton(context),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ext.textPrimary,
                                  side: outlineSide,
                                  minimumSize: const Size(double.infinity, 48),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  visualDensity: VisualDensity.standard,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        DesignTokens.radiusControl),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: DesignTokens.space2),
                          Semantics(
                            button: true,
                            label: 'Çağrılar sekmesine git',
                            child: Tooltip(
                              message: 'Kayıtlı çağrı geçmişi',
                              child: OutlinedButton.icon(
                                onPressed: onOpenCalls,
                                icon: Icon(Icons.call_rounded,
                                    size: 22, color: ext.textSecondary),
                                label: Text(
                                  narrow
                                      ? 'Çağrılara git'
                                      : 'Çağrılarımdan devam et',
                                  style: AppTypography.secondaryButton(context),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ext.textPrimary,
                                  side: outlineSide,
                                  minimumSize: const Size(double.infinity, 48),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  visualDensity: VisualDensity.standard,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        DesignTokens.radiusControl),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: DesignTokens.space4),
                          Text(
                            narrow
                                ? 'Kayıt ekranında rehber ve müşteri akışı bir arada. Akıllı görüşme sonrası kişiler Çağrılarım sekmesine düşer.'
                                : 'Kayıt ekranında rehbere yazma ve uygulama müşteri akışına ekleme tek yerde buluşur; '
                                    'akıllı görüşme sonrası kişiler de Çağrılarım sekmesinden izlenir.',
                            textAlign: TextAlign.center,
                            style: AppTypography.meta(context).copyWith(
                              color: ext.textTertiary.withValues(alpha: 0.95),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

