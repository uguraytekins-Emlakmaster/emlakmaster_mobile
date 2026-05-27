import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/models/integration_center_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/platform_setup_wizard_args.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/providers/connected_platforms_providers.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/utils/integration_center_filter.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/consultant_integrations_chrome.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/integration_center_list_skeleton.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/integration_center_platform_card.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ConnectedPlatformsPage extends ConsumerStatefulWidget {
  const ConnectedPlatformsPage({super.key});

  @override
  ConsumerState<ConnectedPlatformsPage> createState() =>
      _ConnectedPlatformsPageState();
}

class _ConnectedPlatformsPageState extends ConsumerState<ConnectedPlatformsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  IntegrationCenterFilter _filter = IntegrationCenterFilter.all;
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

  String _resolvedOfficeId() {
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
    final officeFromMem =
        ref.watch(primaryMembershipProvider).valueOrNull?.officeId;
    final officeFromDoc =
        uid.isEmpty ? null : ref.watch(userDocStreamProvider(uid)).valueOrNull?.officeId;
    return (officeFromMem != null && officeFromMem.isNotEmpty)
        ? officeFromMem
        : (officeFromDoc ?? '');
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _guardedAdminAction(BuildContext context, bool canManage, VoidCallback action) {
    if (!canManage) {
      _snack(context, 'Bu işlem için admin yetkisi gerekiyor.');
      return;
    }
    action();
  }

  List<Widget> _headerSlivers({
    required IntegrationCenterSummary summary,
    required bool canManage,
  }) {
    return [
      SliverToBoxAdapter(
        child: PremiumIntegrationsPageHeader(
          title: 'Entegrasyon Merkezi',
          subtitle: 'harici bağlantılar ve veri akışı',
          actions: [
            IconButton(
              tooltip: 'Kurulum',
              onPressed: () {
                _guardedAdminAction(context, canManage, () {
                  AppFeedback.selectionClick();
                  context.push(
                    AppRouter.routePlatformSetupWizard,
                    extra: const PlatformSetupWizardArgs(),
                  );
                });
              },
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
      ),
      SliverToBoxAdapter(
        child: PremiumIntegrationsSummaryStrip(summary: summary),
      ),
      SliverToBoxAdapter(
        child: PremiumIntegrationsSearchRow(
          controller: _debouncedSearch.controller,
          hintText: 'Platform, durum veya sağlayıcı ara',
        ),
      ),
      SliverToBoxAdapter(
        child: PremiumIntegrationsFilterStrip(
          selected: _filter,
          onSelected: (f) {
            AppFeedback.selectionClick();
            setState(() => _filter = f);
          },
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _snack(context, 'Bağlı hesaplar görünümü aktif.'),
                icon: const Icon(Icons.hub_rounded, size: 16),
                label: const Text('Bağlı hesaplar'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _guardedAdminAction(context, canManage, () {
                    context.push(AppRouter.routeImportHub);
                  });
                },
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: const Text('Import Hub'),
              ),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 2, 16, 6),
          child: Text(
            'Platform Durumları',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    ];
  }

  void _openPlatform(
    BuildContext context,
    IntegrationPlatform row,
    bool canManage,
  ) {
    if (row.capabilities.canImportListings) {
      AppFeedback.lightImpact();
      context.push(AppRouter.routeMyExternalListings);
      return;
    }
    _guardedAdminAction(context, canManage, () {
      context.push(
        AppRouter.routePlatformSetupWizard,
        extra: PlatformSetupWizardArgs(initialPlatform: row.id),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final canManage = ref.watch(canManagePlatformIntegrationsProvider);
    final rows = ref.watch(platformListProvider);
    final officeId = _resolvedOfficeId();
    final setupMapAsync = ref.watch(platformSetupMapProvider(officeId));
    final dockReserve = _dockBottomReserve(context);
    final summary = computeIntegrationCenterSummary(rows, canManage: canManage);
    final filtered = rows
        .where(
          (e) => matchesIntegrationCenterFilter(
            e,
            _filter,
            _searchQuery,
            canManage: canManage,
          ),
        )
        .toList(growable: false);

    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Builder(
            builder: (context) {
              if (setupMapAsync.isLoading && officeId.isNotEmpty) {
                return CustomScrollView(
                  cacheExtent: 320,
                  slivers: [
                    ..._headerSlivers(summary: summary, canManage: canManage),
                    const IntegrationCenterListSkeleton(),
                  ],
                );
              }

              if (setupMapAsync.hasError && officeId.isNotEmpty) {
                return CustomScrollView(
                  slivers: [
                    ..._headerSlivers(summary: summary, canManage: canManage),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: dockReserve),
                        child: Center(
                          child: EmptyState(
                            compact: true,
                            grouped: true,
                            icon: Icons.cloud_off_outlined,
                            title: 'Entegrasyon verisi yüklenemedi',
                            subtitle:
                                'Bağlantıyı kontrol edip tekrar deneyin.',
                            actionLabel: 'Tekrar dene',
                            onAction: () =>
                                ref.invalidate(platformSetupMapProvider(officeId)),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (rows.isEmpty) {
                return CustomScrollView(
                  slivers: [
                    ..._headerSlivers(summary: summary, canManage: canManage),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: dockReserve),
                        child: const EmptyState(
                          premiumVisual: true,
                          grouped: true,
                          icon: Icons.hub_outlined,
                          title: 'Platform kaydı bulunamadı',
                          subtitle: 'Entegrasyon listesi hazır olduğunda burada görünecek.',
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (filtered.isEmpty) {
                return CustomScrollView(
                  slivers: [
                    ..._headerSlivers(summary: summary, canManage: canManage),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: dockReserve),
                        child: EmptyState(
                          compact: true,
                          grouped: true,
                          icon: Icons.filter_alt_off_outlined,
                          title: 'Bu filtrede platform yok',
                          subtitle: 'Arama veya filtreyi güncelleyin.',
                          actionLabel: 'Tümünü göster',
                          onAction: () => setState(() {
                            _filter = IntegrationCenterFilter.all;
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
                  ..._headerSlivers(summary: summary, canManage: canManage),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      0,
                      0,
                      dockReserve + 8,
                    ),
                    sliver: SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final row = filtered[index];
                        final snapshot = IntegrationCenterRowSnapshot.fromPlatform(
                          row,
                          canManage: canManage,
                        );
                        return RepaintBoundary(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                            child: IntegrationCenterPlatformCard(
                              platform: row,
                              snapshot: snapshot,
                              onTap: () => _openPlatform(context, row, canManage),
                              onConnect: () => _guardedAdminAction(
                                context,
                                canManage,
                                () {
                                  context.push(
                                    AppRouter.routePlatformSetupWizard,
                                    extra: PlatformSetupWizardArgs(
                                      initialPlatform: row.id,
                                    ),
                                  );
                                },
                              ),
                              onConfigure: () => _guardedAdminAction(
                                context,
                                canManage,
                                () {
                                  context.push(
                                    AppRouter.routePlatformSetupWizard,
                                    extra: PlatformSetupWizardArgs(
                                      initialPlatform: row.id,
                                      editMode: true,
                                    ),
                                  );
                                },
                              ),
                              onOpen: () => _openPlatform(context, row, canManage),
                              onRetry: () => _guardedAdminAction(
                                context,
                                canManage,
                                () {
                                  ref.invalidate(platformSetupMapProvider(officeId));
                                  _snack(context, '${row.name} için yenileme istendi.');
                                },
                              ),
                              onLearnMore: () =>
                                  _snack(context, snapshot.previewMessage),
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
    );
  }
}
