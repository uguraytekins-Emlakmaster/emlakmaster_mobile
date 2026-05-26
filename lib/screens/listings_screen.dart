import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/external_listings/presentation/providers/external_listings_provider.dart';
import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/consultant_listings_tokens.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/models/listing_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/providers/market_feed_rows_display_provider.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/providers/owned_listing_rows_display_provider.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/providers/owned_listing_rows_provider.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/utils/listing_list_filter.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/widgets/consultant_listings_chrome.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/widgets/listing_card.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/widgets/listing_list_skeleton.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ListingsPage extends ConsumerStatefulWidget {
  const ListingsPage({super.key});

  @override
  ConsumerState<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends ConsumerState<ListingsPage> {
  int _segment = 0;
  int _retryKey = 0;
  ListingListFilter _listFilter = ListingListFilter.all;
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
    final clamped = ratio.clamp(1.0, 1.38);
    return 112 * clamped;
  }

  @override
  Widget build(BuildContext context) {
    final premium = PremiumThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    final showMarket = ref.watch(
      featureFlagsProvider.select(
        (a) => a.valueOrNull?[AppConstants.keyFeatureOfficialMarketFeed] ?? false,
      ),
    );
    final canManage = ref.watch(canManagePlatformIntegrationsProvider);
    final dockReserve = _dockBottomReserve(context);
    final isMarket = showMarket && _segment == 1;

    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ShellScreenReadyListener(
          screenName: 'listings',
          provider: ownedListingRowsDisplayProvider,
          itemCount: (v) => (v as List).length,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showMarket)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ConsultantListingsTokens.horizontal,
                      4,
                      ConsultantListingsTokens.horizontal,
                      4,
                    ),
                    child: PremiumSegmentedControl<int>(
                      segments: const [0, 1],
                      selected: _segment,
                      onSelected: (v) => setState(() => _segment = v),
                      labelBuilder: (v) => v == 0
                          ? l10n.t('listings_tab_owned')
                          : l10n.t('listings_tab_market'),
                    ),
                  ),
                Expanded(
                  child: Builder(
                    key: ValueKey('listings_$_retryKey'),
                    builder: (context) {
                      if (isMarket) {
                        return _MarketPortfolioBody(
                          dockReserve: dockReserve,
                          premium: premium,
                          searchController: _debouncedSearch.controller,
                          searchQuery: _searchQuery,
                          listFilter: _listFilter,
                          onFilterChanged: (f) => setState(() => _listFilter = f),
                          onRetry: _retryOwned,
                        );
                      }
                      return _OwnedPortfolioBody(
                        dockReserve: dockReserve,
                        premium: premium,
                        canManage: canManage,
                        searchController: _debouncedSearch.controller,
                        searchQuery: _searchQuery,
                        listFilter: _listFilter,
                        onFilterChanged: (f) => setState(() => _listFilter = f),
                        onResetFilters: _resetFilters,
                        onRetry: _retryOwned,
                        headerActions: _headerActions(
                          context,
                          premium,
                          canManage,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _retryOwned() {
    ref.invalidate(ownedListingRowsProvider);
    ref.invalidate(ownedListingRowsStaleCacheProvider);
    setState(() => _retryKey++);
  }

  void _resetFilters() {
    _debouncedSearch.controller.clear();
    setState(() {
      _listFilter = ListingListFilter.all;
      _searchQuery = '';
    });
  }

  List<Widget> _headerActions(
    BuildContext context,
    PremiumThemeExtension premium,
    bool canManage,
  ) {
    if (!canManage) return const [];
    return [
      IconButton(
        tooltip: 'İlan ekle',
        onPressed: () {
          AppFeedback.lightImpact();
          context.push(AppRouter.routeImportHub);
        },
        icon: Icon(Icons.add_rounded, color: premium.champagneGold, size: 22),
      ),
      IconButton(
        tooltip: 'Bağlı hesaplar',
        onPressed: () {
          AppFeedback.lightImpact();
          context.push(AppRouter.routeConnectedAccounts);
        },
        icon: Icon(Icons.hub_outlined, color: premium.champagneGold, size: 22),
      ),
    ];
  }
}

class _OwnedPortfolioBody extends ConsumerWidget {
  const _OwnedPortfolioBody({
    required this.dockReserve,
    required this.premium,
    required this.canManage,
    required this.searchController,
    required this.searchQuery,
    required this.listFilter,
    required this.onFilterChanged,
    required this.onResetFilters,
    required this.onRetry,
    required this.headerActions,
  });

  final double dockReserve;
  final PremiumThemeExtension premium;
  final bool canManage;
  final TextEditingController searchController;
  final String searchQuery;
  final ListingListFilter listFilter;
  final ValueChanged<ListingListFilter> onFilterChanged;
  final VoidCallback onResetFilters;
  final VoidCallback onRetry;
  final List<Widget> headerActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(ownedListingRowsDisplayProvider);

    if (async.isLoading && !async.hasValue) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PremiumListingsPageHeader(
              title: 'İlanlarım',
              subtitle: 'Portföy yönetimi · aktif ilan akışı',
              actions: headerActions,
            ),
          ),
          const SliverToBoxAdapter(child: ListingListSkeleton()),
        ],
      );
    }

    if (async.hasError && !async.hasValue) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PremiumListingsPageHeader(
              title: 'İlanlarım',
              subtitle: 'Portföy yönetimi · aktif ilan akışı',
              actions: headerActions,
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _ListingsErrorState(onRetry: onRetry),
          ),
        ],
      );
    }

    final allRows = async.valueOrNull ?? [];
    final ownedRows =
        allRows.where((r) => r.surface == ListingSurface.owned).toList();
    final summary = computeListingListSummary(ownedRows);
    final filtered = ownedRows
        .where((r) => matchesListingListFilter(r, listFilter, searchQuery))
        .toList();

    if (ownedRows.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PremiumListingsPageHeader(
              title: 'İlanlarım',
              subtitle: 'Portföy yönetimi · aktif ilan akışı',
              actions: headerActions,
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                ConsultantListingsTokens.horizontal,
                0,
                ConsultantListingsTokens.horizontal,
                dockReserve,
              ),
              child: EmptyState(
                premiumVisual: true,
                grouped: true,
                icon: Icons.home_work_outlined,
                title: 'Henüz portföy yok',
                subtitle: canManage
                    ? l10n.t('empty_listings_sub')
                    : '${l10n.t('empty_listings_sub')}\n\n${l10n.t('integration_connections_read_only_notice')}',
                actionLabel: canManage ? 'İlan ekle' : null,
                onAction: canManage
                    ? () => context.push(AppRouter.routeImportHub)
                    : null,
                outlinedActionLabel:
                    canManage ? l10n.t('empty_listings_cta_import') : null,
                onOutlinedAction: canManage
                    ? () => context.push(AppRouter.routeImportHub)
                    : null,
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      cacheExtent: 320,
      slivers: [
        SliverToBoxAdapter(
          child: PremiumListingsPageHeader(
            title: 'İlanlarım',
            subtitle: 'Portföy yönetimi · aktif ilan akışı',
            actions: headerActions,
          ),
        ),
        SliverToBoxAdapter(child: PremiumListingsSummaryStrip(summary: summary)),
        SliverToBoxAdapter(
          child: PremiumListingSearchRow(
            controller: searchController,
            hintText: 'İlan, konum veya fiyat ara',
          ),
        ),
        SliverToBoxAdapter(
          child: PremiumListingFilterStrip(
            selected: listFilter,
            onSelected: onFilterChanged,
          ),
        ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                ConsultantListingsTokens.horizontal,
                24,
                ConsultantListingsTokens.horizontal,
                dockReserve,
              ),
              child: PremiumEmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: 'Sonuç yok',
                subtitle: 'Arama veya filtreyi değiştirin.',
                actionLabel: 'Filtreyi sıfırla',
                onAction: onResetFilters,
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              ConsultantListingsTokens.horizontal,
              0,
              ConsultantListingsTokens.horizontal,
              dockReserve,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final row = filtered[index];
                  final snapshot = ListingListRowSnapshot.fromRow(row);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: RepaintBoundary(
                      child: ListingCard(
                        row: row,
                        snapshot: snapshot,
                        onTap: () => _ListingActions.openRow(context, row),
                        onDetail: () => _ListingActions.openRow(context, row),
                        onEdit: () => _ListingActions.edit(context),
                        onShare: () => _ListingActions.share(context, row),
                        onSync: () => _ListingActions.sync(
                          context,
                          ref,
                          row,
                          canManage,
                        ),
                      ),
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _MarketPortfolioBody extends ConsumerWidget {
  const _MarketPortfolioBody({
    required this.dockReserve,
    required this.premium,
    required this.searchController,
    required this.searchQuery,
    required this.listFilter,
    required this.onFilterChanged,
    required this.onRetry,
  });

  final double dockReserve;
  final PremiumThemeExtension premium;
  final TextEditingController searchController;
  final String searchQuery;
  final ListingListFilter listFilter;
  final ValueChanged<ListingListFilter> onFilterChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final enabled = ref.watch(
      featureFlagsProvider.select(
        (a) => a.valueOrNull?[AppConstants.keyFeatureOfficialMarketFeed] ?? false,
      ),
    );

    if (!enabled) {
      return const CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PremiumListingsPageHeader(
              title: 'İlanlarım',
              subtitle: 'Pazar akışı · resmi veri',
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.space6),
                child: EmptyState(
                  premiumVisual: true,
                  grouped: true,
                  icon: Icons.lock_outline_rounded,
                  title: 'Pazar akışı kapalı',
                  subtitle:
                      'Resmi pazar verisi etkinleştirilince burada görünecek.',
                ),
              ),
            ),
          ),
        ],
      );
    }

    final async = ref.watch(marketFeedRowsDisplayProvider);

    if (async.isLoading && !async.hasValue) {
      return const CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PremiumListingsPageHeader(
              title: 'İlanlarım',
              subtitle: 'Pazar akışı · resmi veri',
            ),
          ),
          SliverToBoxAdapter(child: ListingListSkeleton()),
        ],
      );
    }

    if (async.hasError && !async.hasValue) {
      return CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: PremiumListingsPageHeader(
              title: 'İlanlarım',
              subtitle: 'Pazar akışı · resmi veri',
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _ListingsErrorState(
              onRetry: () {
                ref.invalidate(externalListingsStreamProvider);
                ref.invalidate(marketFeedRowsStaleCacheProvider);
                onRetry();
              },
            ),
          ),
        ],
      );
    }

    final rows = async.valueOrNull ?? [];
    final filtered = rows
        .where((r) => matchesListingListFilter(r, listFilter, searchQuery))
        .toList();

    return CustomScrollView(
      cacheExtent: 320,
      slivers: [
        const SliverToBoxAdapter(
          child: PremiumListingsPageHeader(
            title: 'İlanlarım',
            subtitle: 'Pazar akışı · resmi veri',
          ),
        ),
        SliverToBoxAdapter(
          child: PremiumListingSearchRow(
            controller: searchController,
            hintText: 'Pazar ilanı ara',
          ),
        ),
        SliverToBoxAdapter(
          child: PremiumListingFilterStrip(
            selected: listFilter,
            onSelected: onFilterChanged,
          ),
        ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                ConsultantListingsTokens.horizontal,
                24,
                ConsultantListingsTokens.horizontal,
                dockReserve,
              ),
              child: EmptyState(
                premiumVisual: true,
                grouped: true,
                icon: Icons.rss_feed_rounded,
                title: l10n.t('listings_empty_market'),
                subtitle: l10n.t('listings_empty_market_sub'),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              ConsultantListingsTokens.horizontal,
              0,
              ConsultantListingsTokens.horizontal,
              dockReserve,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final row = filtered[index];
                  final snapshot = ListingListRowSnapshot.fromRow(row);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: RepaintBoundary(
                      child: ListingCard(
                        row: row,
                        snapshot: snapshot,
                        onTap: () => _ListingActions.openRow(context, row),
                        onDetail: () => _ListingActions.openRow(context, row),
                        onEdit: () => _ListingActions.edit(context),
                        onShare: () => _ListingActions.share(context, row),
                      ),
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _ListingsErrorState extends StatelessWidget {
  const _ListingsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space6),
        child: EmptyState(
          compact: true,
          grouped: true,
          icon: Icons.cloud_off_outlined,
          title: 'İlanlar yüklenemedi',
          subtitle: 'Bağlantınızı kontrol edip tekrar deneyin.',
          actionLabel: 'Tekrar dene',
          onAction: onRetry,
        ),
      ),
    );
  }
}

abstract final class _ListingActions {
  static Future<void> openRow(BuildContext context, ListingRowView row) async {
    AppFeedback.lightImpact();
    final detail = row.detailListingId;
    if (detail != null && detail.isNotEmpty) {
      if (!context.mounted) return;
      context.push(AppRouter.routeListingDetail.replaceFirst(':id', detail));
      return;
    }
    final link = row.openInBrowserUrl;
    if (link != null && link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri == null) {
        if (!context.mounted) return;
        _snack(
          context,
          AppLocalizations.of(context).t('listing_external_no_link'),
        );
        return;
      }
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _snack(
          context,
          AppLocalizations.of(context).t('listing_external_open_failed'),
        );
      }
      return;
    }
    if (!context.mounted) return;
    _snack(context, AppLocalizations.of(context).t('listing_external_no_link'));
  }

  static void edit(BuildContext context) {
    AppFeedback.lightImpact();
    _snack(
      context,
      'İlan düzenleme sihirbazı yakında. Şimdilik içe aktarma veya bağlı platformları kullanın.',
    );
  }

  static Future<void> share(BuildContext context, ListingRowView row) async {
    AppFeedback.lightImpact();
    final price = row.priceLabel.contains('₺') || row.priceLabel == '—'
        ? row.priceLabel
        : '${row.priceLabel} ₺';
    final text = [
      row.title.isNotEmpty ? row.title : 'İlan',
      row.locationLabel,
      price,
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    final premium = PremiumThemeExtension.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'İlan metni panoya kopyalandı — WhatsApp veya SMS ile paylaşabilirsiniz.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: premium.champagneGold,
      ),
    );
  }

  static void sync(
    BuildContext context,
    WidgetRef ref,
    ListingRowView row,
    bool canManage,
  ) {
    AppFeedback.lightImpact();
    if (canManage) {
      context.push(AppRouter.routeConnectedAccounts);
      return;
    }
    _snack(
      context,
      'Senkron yönetimi için ofis yöneticisi yetkisi gerekir.',
    );
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
