import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/customer_detail_workspace_actions.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/customer_detail_workspace_flows.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/customer_detail_workspace_types.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/providers/customer_detail_workspace_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/widgets/customer_detail_section_card.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/widgets/customer_detail_workspace_chrome.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/widgets/customer_detail_workspace_skeleton.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

double _bottomReserve(BuildContext context) {
  final ts = MediaQuery.textScalerOf(context);
  final ratio =
      ts.scale(DesignTokens.fontSizeBase) / DesignTokens.fontSizeBase;
  return 96 * ratio.clamp(1.0, 1.38);
}

/// Müşteri detay komuta yüzeyi (Screen 30) — premium, dürüst, hızlı CRM workspace.
class CustomerDetailWorkspaceSurface extends ConsumerStatefulWidget {
  const CustomerDetailWorkspaceSurface({super.key, required this.customerId});

  final String customerId;

  @override
  ConsumerState<CustomerDetailWorkspaceSurface> createState() =>
      _CustomerDetailWorkspaceSurfaceState();
}

class _CustomerDetailWorkspaceSurfaceState
    extends ConsumerState<CustomerDetailWorkspaceSurface> {
  final _readyTracker = ShellScreenReadyTracker('customer_detail_workspace');

  @override
  Widget build(BuildContext context) {
    final snapshotAsync =
        ref.watch(customerDetailWorkspaceSnapshotProvider(widget.customerId));

    ref.listen(
      customerDetailWorkspaceSnapshotProvider(widget.customerId),
      (_, next) {
        final snap = next.valueOrNull;
        if (snap != null && !snap.isNotFound) {
          _readyTracker.onContentReady(itemCount: snap.sections.length);
        }
      },
    );

    return snapshotAsync.when(
      loading: () => const CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: CustomerDetailWorkspaceSkeleton()),
        ],
      ),
      error: (_, __) => CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: CustomerDetailWorkspaceHeader(
              title: 'Müşteri',
              subtitle: 'müşteri durumu ve sonraki adımlar',
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
                title: 'Müşteri yüklenemedi',
                subtitle: 'Bağlantınızı kontrol edip tekrar deneyin.',
                actionLabel: 'Yeniden dene',
                onAction: () => CustomerDetailWorkspaceActions.refresh(
                  ref,
                  widget.customerId,
                ),
              ),
            ),
          ),
        ],
      ),
      data: (snapshot) => _buildScroll(context, snapshot),
    );
  }

  Widget _buildScroll(
    BuildContext context,
    CustomerDetailWorkspaceSnapshot snapshot,
  ) {
    final reserve = _bottomReserve(context);
    final premium = PremiumThemeExtension.of(context);
    final ext = AppThemeExtension.of(context);

    if (snapshot.isNotFound) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CustomerDetailWorkspaceHeader(
              title: snapshot.displayName,
              subtitle: 'müşteri durumu ve sonraki adımlar',
              coverageNote: snapshot.coverageNote,
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: EmptyState(
                premiumVisual: true,
                grouped: true,
                icon: Icons.person_off_outlined,
                title: 'Müşteri bulunamadı',
                subtitle: 'Kayıt silinmiş veya erişim yok.',
                actionLabel: 'Geri dön',
                onAction: () => context.pop(),
              ),
            ),
          ),
        ],
      );
    }

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: CustomerDetailWorkspaceHeader(
          title: snapshot.displayName,
          subtitle: snapshot.identityLine.isNotEmpty
              ? snapshot.identityLine
              : 'müşteri durumu ve sonraki adımlar',
          dateChipLabel: snapshot.dateChipLabel,
          coverageNote: snapshot.coverageNote,
          actions: [
            IconButton(
              tooltip: 'Yenile',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () => CustomerDetailWorkspaceActions.refresh(
                ref,
                widget.customerId,
              ),
              icon: Icon(Icons.refresh_rounded, color: ext.accent, size: 22),
            ),
            IconButton(
              tooltip: 'Düzenle',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () =>
                  CustomerDetailWorkspaceActions.edit(context, ref, snapshot),
              icon: Icon(Icons.edit_outlined, color: ext.accent, size: 22),
            ),
            IconButton(
              tooltip: 'Detay',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () => CustomerDetailWorkspaceActions.showActionSheet(
                context,
                ref,
                snapshot,
              ),
              icon: Icon(Icons.more_horiz_rounded, color: ext.accent, size: 22),
            ),
          ],
        ),
      ),
      SliverToBoxAdapter(
        child: CustomerDetailWorkspaceSummaryStrip(summary: snapshot.summary),
      ),
      if (snapshot.nextActionLabel.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              snapshot.nextActionLabel,
              style: TextStyle(
                color: ext.accent.withValues(alpha: 0.95),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: CustomerDetailQuickActionsRow(
          actions: snapshot.quickActions,
          onAction: (a) => CustomerDetailWorkspaceActions.handleQuickAction(
            context,
            ref,
            snapshot,
            a,
          ),
        ),
      ),
    ];

    for (final section in snapshot.sections) {
      slivers.add(
        SliverToBoxAdapter(
          child: CustomerDetailSectionHeader(
            label: section.title,
            secondary: section.secondary,
          ),
        ),
      );
      slivers.add(
        SliverToBoxAdapter(
          child: CustomerDetailSectionCard(
            section: section,
            onListingTap: (id) =>
                CustomerDetailWorkspaceActions.openListing(context, id),
            onLinkedRowTap: () =>
                CustomerDetailWorkspaceActions.goToTasks(context),
          ),
        ),
      );
    }

    slivers.add(SliverPadding(padding: EdgeInsets.only(bottom: reserve)));

    return Stack(
      children: [
        CustomScrollView(cacheExtent: 360, slivers: slivers),
        Positioned(
          right: 16,
          bottom: reserve + 8,
          child: FloatingActionButton.extended(
            onPressed: () => CustomerDetailWorkspaceFlows.showAddNoteSheet(
              context,
              ref,
              widget.customerId,
            ),
            backgroundColor: premium.champagneGold,
            foregroundColor: ext.onBrand,
            icon: const Icon(Icons.note_add_rounded),
            label: const Text('Not ekle'),
          ),
        ),
      ],
    );
  }
}
