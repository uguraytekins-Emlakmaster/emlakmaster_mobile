import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/shell_tab_back_binding.dart';
import 'package:emlakmaster_mobile/core/onboarding/tour_target.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/consultant_customers_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/consultant_customers_chrome.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_actions.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_filter.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_types.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/providers/customer_workspace_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/widgets/customer_workspace_chrome.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/widgets/customer_workspace_row.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/widgets/customer_workspace_skeleton.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Liste altı — dock + büyük metin ölçeği için güvenli boşluk (SE / erişilebilirlik).
double _dockBottomReserve(BuildContext context) {
  final ts = MediaQuery.textScalerOf(context);
  final ratio = ts.scale(DesignTokens.fontSizeBase) / DesignTokens.fontSizeBase;
  return 120 * ratio.clamp(1.0, 1.38);
}

/// Müşterilerim komuta yüzeyi (Screen 25) — premium, dürüst, hızlı CRM workspace.
/// Tek türetilmiş snapshot; arama/filtre bellek içi. Yalnızca gerçek sinyaller.
class CustomerWorkspaceSurface extends ConsumerStatefulWidget {
  const CustomerWorkspaceSurface({super.key});

  @override
  ConsumerState<CustomerWorkspaceSurface> createState() =>
      _CustomerWorkspaceSurfaceState();
}

class _CustomerWorkspaceSurfaceState
    extends ConsumerState<CustomerWorkspaceSurface> {
  final _readyTracker = ShellScreenReadyTracker('customer_workspace');
  late final DebouncedSearchController _search;
  String _query = '';
  CustomerWorkspaceFilter _filter = CustomerWorkspaceFilter.all;

  @override
  void initState() {
    super.initState();
    _search = DebouncedSearchController(
      onQueryChanged: (q) {
        if (!mounted) return;
        setState(() => _query = q.toLowerCase());
      },
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _handleExitSearch() {
    if (_query.isEmpty && _search.controller.text.trim().isEmpty) return false;
    setState(() => _search.controller.clear());
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(customerWorkspaceSnapshotProvider);
    ref.listen(customerWorkspaceSnapshotProvider, (_, next) {
      final snap = next.valueOrNull;
      if (snap != null) {
        _readyTracker.onContentReady(itemCount: snap.rows.length);
      }
    });

    return ShellTabBackBinding(
      onExitSearch: _handleExitSearch,
      child: snapshotAsync.when(
        loading: () => const CustomScrollView(
          slivers: [SliverToBoxAdapter(child: CustomerWorkspaceSkeleton())],
        ),
        error: (_, __) => CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: CustomerWorkspaceHeader(
                title: 'Müşterilerim',
                subtitle: 'Müşteri durumu ve sonraki adımlar',
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: EmptyState(
                  compact: true,
                  grouped: true,
                  premiumVisual: true,
                  icon: Icons.cloud_off_rounded,
                  title: 'Müşteriler yüklenemedi',
                  subtitle: 'Bağlantınızı kontrol edip tekrar deneyin.',
                  actionLabel: 'Yeniden dene',
                  onAction: () => CustomerWorkspaceActions.refresh(ref),
                ),
              ),
            ),
          ],
        ),
        data: (snapshot) => _buildData(context, snapshot),
      ),
    );
  }

  Widget _buildData(BuildContext context, CustomerWorkspaceSnapshot snapshot) {
    final reserve = _dockBottomReserve(context);

    final header = SliverToBoxAdapter(
      child: TourTarget(
        id: TourTargetId.customersHeader,
        child: CustomerWorkspaceHeader(
          title: 'Müşterilerim',
          subtitle: 'Müşteri durumu ve sonraki adımlar',
          coverageNote: snapshot.coverageNote,
          actions: [
            IconButton(
              tooltip: 'Müşteri ekle',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () => CustomerWorkspaceActions.addCustomer(context,
                  source: 'crm_header'),
              icon: Icon(
                Icons.person_add_alt_1_rounded,
                color: AppThemeExtension.of(context).accent,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );

    if (snapshot.isEmpty) {
      return CustomScrollView(
        cacheExtent: 360,
        slivers: [
          header,
          SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height * 0.48,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, reserve),
                child: Center(
                  child: EmptyState(
                    premiumVisual: true,
                    grouped: true,
                    icon: Icons.hub_outlined,
                    title: 'Müşteri portföyünü burada kur',
                    subtitle:
                        'İlk kişiyle CRM canlanır; arama, teklif ve takip burada '
                        'başlar. Uydurma kayıt gösterilmez.',
                    actionLabel: 'Müşteri ekle',
                    onAction: () => CustomerWorkspaceActions.addCustomer(
                      context,
                      source: 'crm_empty',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final filtered = filterCustomerWorkspaceRows(
      snapshot.rows,
      query: _query,
      filter: _filter,
    );

    final slivers = <Widget>[
      header,
      SliverToBoxAdapter(
        child: CustomerWorkspaceSummaryStrip(summary: snapshot.summary),
      ),
      SliverToBoxAdapter(
        child: PremiumCustomerSearchRow(
          controller: _search.controller,
          hintText: 'İsim, telefon veya e-posta ara…',
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 6)),
      SliverToBoxAdapter(
        child: CustomerWorkspaceFilterStrip(
          selected: _filter,
          onSelected: (f) {
            AppFeedback.selectionClick();
            setState(() => _filter = f);
          },
        ),
      ),
    ];

    if (filtered.isEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: CustomerWorkspaceInlineNote(
            icon: Icons.filter_alt_off_rounded,
            message: _query.isNotEmpty
                ? 'Aramaya uyan müşteri bulunamadı.'
                : 'Bu görünümde müşteri yok.',
          ),
        ),
      );
    } else {
      slivers.add(
        SliverToBoxAdapter(
          child: CustomerWorkspaceSectionHeader(
            label: 'Öncelik sırası',
            secondary: '${filtered.length}',
          ),
        ),
      );
      slivers.add(
        SliverList.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final row = filtered[index];
            return CustomerWorkspaceRow(
              row: row,
              onTap: () =>
                  CustomerWorkspaceActions.openDetail(context, ref, row),
              onCall: row.callablePhone
                  ? () => CustomerWorkspaceActions.call(context, row)
                  : null,
              onMenu: (menu) => _onMenu(menu, row),
            );
          },
        ),
      );

      final canLoadMore = snapshot.hasMore &&
          _query.isEmpty &&
          _filter == CustomerWorkspaceFilter.all;
      if (canLoadMore) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                ConsultantCustomersTokens.horizontal,
                4,
                ConsultantCustomersTokens.horizontal,
                8,
              ),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      CustomerWorkspaceActions.loadMore(ref, snapshot.uid),
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  label: const Text('Daha fazla müşteri yükle'),
                ),
              ),
            ),
          ),
        );
      }
    }

    slivers.add(SliverPadding(padding: EdgeInsets.only(bottom: reserve)));

    return CustomScrollView(cacheExtent: 360, slivers: slivers);
  }

  void _onMenu(CustomerRowMenu menu, CustomerRowView row) {
    switch (menu) {
      case CustomerRowMenu.open:
        CustomerWorkspaceActions.openDetail(context, ref, row);
      case CustomerRowMenu.call:
        CustomerWorkspaceActions.call(context, row);
      case CustomerRowMenu.message:
        CustomerWorkspaceActions.message(context, row);
      case CustomerRowMenu.whatsapp:
        CustomerWorkspaceActions.whatsapp(context, row);
      case CustomerRowMenu.followUp:
        CustomerWorkspaceActions.addToFollowUp(context, ref, row);
      case CustomerRowMenu.tasks:
        CustomerWorkspaceActions.goToTasks(context);
    }
  }
}
