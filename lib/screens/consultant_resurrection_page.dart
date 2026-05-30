import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/models/follow_up_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/utils/follow_up_list_actions.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/utils/follow_up_list_filter.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/consultant_follow_up_chrome.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/follow_up_lead_card.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/widgets/follow_up_list_skeleton.dart';
import 'package:emlakmaster_mobile/screens/consultant_shell_nav.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Danışman — Takip Merkezi: geri kazanım / sessiz lead komuta ekranı.
class ConsultantResurrectionPage extends ConsumerStatefulWidget {
  const ConsultantResurrectionPage({super.key});

  @override
  ConsumerState<ConsultantResurrectionPage> createState() =>
      _ConsultantResurrectionPageState();
}

class _ConsultantResurrectionPageState
    extends ConsumerState<ConsultantResurrectionPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  FollowUpListFilter _filter = FollowUpListFilter.all;
  String _searchQuery = '';
  late final DebouncedSearchController _debouncedSearch;

  @override
  void initState() {
    super.initState();
    _debouncedSearch = DebouncedSearchController(
      onQueryChanged: (q) {
        if (_searchQuery != q) setState(() => _searchQuery = q);
      },
    );
  }

  @override
  void dispose() {
    _debouncedSearch.dispose();
    super.dispose();
  }

  double _dockBottomReserve(BuildContext context) {
    final ts = MediaQuery.textScalerOf(context);
    final ratio =
        ts.scale(DesignTokens.fontSizeBase) / DesignTokens.fontSizeBase;
    return 112 * ratio.clamp(1.0, 1.38);
  }

  List<Widget> _headerSlivers(FollowUpListSummary summary) {
    return [
      const SliverToBoxAdapter(
        child: PremiumFollowUpPageHeader(
          title: 'Takip Merkezi',
          subtitle: 'müşteri takibi · fırsat geri kazanımı',
        ),
      ),
      SliverToBoxAdapter(child: PremiumFollowUpSummaryStrip(summary: summary)),
      SliverToBoxAdapter(
        child: PremiumFollowUpSearchRow(
          controller: _debouncedSearch.controller,
          hintText: 'İsim, telefon veya not ara',
        ),
      ),
      SliverToBoxAdapter(
        child: PremiumFollowUpFilterStrip(
          selected: _filter,
          onSelected: (f) {
            AppFeedback.selectionClick();
            setState(() => _filter = f);
          },
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dockReserve = _dockBottomReserve(context);
    final resurrectionAsync = ref.watch(resurrectionQueueProvider);

    return ShellScreenReadyListener(
      screenName: 'follow_up',
      provider: resurrectionQueueProvider,
      itemCount: (v) => (v as List).length,
      child: PremiumShellBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: resurrectionAsync.when(
              loading: () => CustomScrollView(
                cacheExtent: 320,
                slivers: [
                  ..._headerSlivers(FollowUpListSummary.empty),
                  const FollowUpListSkeleton(),
                ],
              ),
              error: (_, __) => CustomScrollView(
                slivers: [
                  ..._headerSlivers(FollowUpListSummary.empty),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: dockReserve),
                      child: Center(
                        child: EmptyState(
                          compact: true,
                          grouped: true,
                          icon: Icons.cloud_off_outlined,
                          title: 'Takip listesi yüklenemedi',
                          subtitle:
                              'Bağlantınızı kontrol edip tekrar deneyin.',
                          actionLabel: 'Tekrar dene',
                          onAction: () =>
                              ref.invalidate(resurrectionQueueProvider),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              data: (items) {
                final summary = computeFollowUpListSummary(items);
                final filtered = items
                    .where(
                      (e) => matchesFollowUpListFilter(
                        e,
                        _filter,
                        _searchQuery,
                      ),
                    )
                    .toList(growable: false);

                if (items.isEmpty) {
                  return CustomScrollView(
                    slivers: [
                      ..._headerSlivers(summary),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: dockReserve),
                          child: EmptyState(
                            premiumVisual: true,
                            grouped: true,
                            icon: Icons.track_changes_rounded,
                            title: 'Takip bekleyen müşteri yok',
                            subtitle:
                                '7+ gün sessiz müşteri yok. Yeni temaslar burada görünür.',
                            actionLabel: ProductLabels.myCustomers,
                            onAction: () =>
                                ConsultantShellNav.goToCustomersTab(context),
                            outlinedActionLabel: ProductLabels.myTasks,
                            onOutlinedAction: () =>
                                ConsultantShellNav.goToTasksTab(context),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                if (filtered.isEmpty) {
                  return CustomScrollView(
                    slivers: [
                      ..._headerSlivers(summary),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: dockReserve),
                          child: EmptyState(
                            compact: true,
                            grouped: true,
                            icon: Icons.filter_alt_off_outlined,
                            title: 'Bu filtrede kayıt yok',
                            subtitle: 'Aramayı veya filtreyi değiştirin.',
                            actionLabel: 'Tümünü göster',
                            onAction: () => setState(() {
                              _filter = FollowUpListFilter.all;
                              _debouncedSearch.controller.clear();
                              _searchQuery = '';
                            }),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return CustomScrollView(
                  cacheExtent: 320,
                  slivers: [
                    ..._headerSlivers(summary),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        0,
                        0,
                        0,
                        dockReserve + DesignTokens.space2,
                      ),
                      sliver: SliverList.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final snapshot = FollowUpRowSnapshot.fromItem(item);
                          return RepaintBoundary(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                6,
                              ),
                              child: FollowUpLeadCard(
                                item: item,
                                snapshot: snapshot,
                                onTap: () => FollowUpListActions.openDetail(
                                  context,
                                  item: item,
                                ),
                                onCall: () => FollowUpListActions.launchCall(
                                  context,
                                  item,
                                ),
                                onWhatsApp: () =>
                                    FollowUpListActions.launchWhatsApp(
                                  context,
                                  item,
                                ),
                                onOpenCustomer: () =>
                                    FollowUpListActions.openCustomer(
                                  context,
                                  item,
                                ),
                                onCreateTask: () =>
                                    FollowUpListActions.createTask(
                                  context,
                                  ref,
                                  item,
                                ),
                                onSnooze: () => FollowUpListActions.snooze(
                                  context,
                                  ref,
                                  item,
                                ),
                                onDetail: () => FollowUpListActions.openDetail(
                                  context,
                                  item: item,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
