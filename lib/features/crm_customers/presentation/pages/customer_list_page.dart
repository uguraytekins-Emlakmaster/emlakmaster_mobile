import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/firebase/user_facing_firebase_message.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/contact_save/presentation/widgets/save_contact_sheet.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/sync_delayed_risk_customer_ids_provider.dart';
import 'package:emlakmaster_mobile/screens/consultant_shell_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/models/customer_models.dart';
import '../../../../shared/widgets/empty_state.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(
          () => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addSelectedToFollowUp(
      BuildContext context, WidgetRef ref) async {
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

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final uid =
        ref.watch(currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''));
    final asyncCustomers = ref.watch(customerListForAgentProvider);
    final showAddDock = uid.isNotEmpty &&
        asyncCustomers.maybeWhen(
          data: (list) => list.isNotEmpty,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectionMode
                                      ? AppLocalizations.of(context).tArgs(
                                          'n_selected',
                                          ['${_selectedIds.length}'])
                                      : AppLocalizations.of(context)
                                          .t('title_customers'),
                                  style: AppTypography.pageHeading(context),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (!_selectionMode) ...[
                                  const SizedBox(height: DesignTokens.space2),
                                  Text(
                                    'İlişki portföyün — arama, sıcaklık ve hızlı aksiyon tek yerde.',
                                    style: AppTypography.meta(context).copyWith(
                                      color: ext.textTertiary,
                                      height: 1.35,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
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
                          ] else
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
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.space5),
                      child: _SearchBar(controller: _searchController),
                    ),
                  ),
                  const SliverPadding(
                      padding: EdgeInsets.only(top: DesignTokens.space3)),
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
                            grouped: true,
                            icon: Icons.cloud_off_rounded,
                            title: AppLocalizations.of(context)
                                .t('customer_list_load_error'),
                            subtitle:
                                'Bağlantıyı kontrol edin; bir süre sonra yenileyin.',
                          ),
                        ),
                      ),
                      data: (entities) {
                        final filtered = _searchQuery.isEmpty
                            ? List<CustomerEntity>.from(entities)
                            : entities.where((e) {
                                final q = _searchQuery;
                                final name = (e.fullName ?? '').toLowerCase();
                                final phone = (e.primaryPhone ?? '')
                                    .replaceAll(RegExp(r'\s'), '');
                                final email = (e.email ?? '').toLowerCase();
                                final queryNoSpaces =
                                    q.replaceAll(RegExp(r'\s'), '');
                                return name.contains(q) ||
                                    email.contains(q) ||
                                    phone.contains(queryNoSpaces) ||
                                    (queryNoSpaces.isNotEmpty &&
                                        phone.contains(queryNoSpaces));
                              }).toList();
                        final riskIds =
                            ref.watch(syncDelayedRiskCustomerIdsProvider);
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
                          final noSearchHits =
                              !noCustomers && _searchQuery.isNotEmpty;
                          if (noCustomers) {
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        DesignTokens.space5,
                                        DesignTokens.space4,
                                        DesignTokens.space5,
                                        DesignTokens.space6,
                                      ),
                                      child: Center(
                                        child:
                                            _ConsultantCustomersEmptyLaunchpad(
                                          onPrimaryAdd: () {
                                            HapticFeedback.lightImpact();
                                            showSaveContactSheet(
                                              context,
                                              source: 'crm_empty_launchpad',
                                            );
                                          },
                                          onVoiceQuickAdd: () {
                                            HapticFeedback.lightImpact();
                                            showSaveContactSheet(
                                              context,
                                              source: 'crm_empty_voice',
                                            );
                                          },
                                          onOpenCalls: () {
                                            HapticFeedback.lightImpact();
                                            final shell =
                                                ConsultantShellNav.maybeOf(
                                                    context);
                                            if (shell != null) {
                                              shell.goToTab(1);
                                            } else {
                                              ref
                                                  .read(
                                                    mainShellShortcutProvider
                                                        .notifier,
                                                  )
                                                  .enqueue(
                                                    MainShellShortcut
                                                        .openCallsTab,
                                                  );
                                              context.go(AppRouter.routeHome);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                          return Padding(
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
                                  : l10n.t('empty_customers_title'),
                              subtitle: noSearchHits
                                  ? l10n.tArgs('empty_search_subtitle',
                                      [_searchController.text.trim()])
                                  : l10n.t('empty_customers_subtitle'),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            DesignTokens.space5,
                            0,
                            DesignTokens.space5,
                            showAddDock
                                ? _customerListDockBottomReserve(context)
                                : DesignTokens.space4,
                          ),
                          itemCount: filtered.length,
                          cacheExtent: 200,
                          semanticChildCount: filtered.length,
                          itemBuilder: (context, index) {
                            final entity = filtered[index];
                            final isSelected = _selectedIds.contains(entity.id);
                            return RepaintBoundary(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    bottom: DesignTokens.space3),
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
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Demo kayıt — gerçek müşteri için arama veya müşteri oluşturun.',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        return;
                                      }
                                      context.push(AppRouter.routeCustomerDetail
                                          .replaceFirst(':id', entity.id));
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
                      HapticFeedback.mediumImpact();
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
        border: Border.all(color: ext.border.withValues(alpha: 0.62)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).t('search_customers'),
          hintStyle: TextStyle(
              color: ext.textPassive, fontSize: DesignTokens.fontSizeBase),
          prefixIcon:
              Icon(Icons.search_rounded, color: ext.textPassive, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space4, vertical: 12),
        ),
        style: TextStyle(color: ext.textPrimary),
      ),
    );
  }
}
