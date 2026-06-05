import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/external_listings/presentation/providers/external_listings_provider.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/consultant_listings_tokens.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/models/listing_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/providers/market_feed_rows_display_provider.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/utils/listing_list_filter.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/widgets/consultant_listings_chrome.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/widgets/listing_card.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/widgets/listing_list_skeleton.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_actions.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pazar akışı sekmesi — feature flag ile; Portföyüm workspace’ten ayrı tutulur.
class ListingsMarketSegment extends ConsumerWidget {
  const ListingsMarketSegment({
    super.key,
    required this.dockReserve,
    required this.searchController,
    required this.searchQuery,
    required this.listFilter,
    required this.onFilterChanged,
    required this.onRetry,
  });

  final double dockReserve;
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
              title: 'Pazar akışı',
              subtitle: 'resmi veri · ofis envanteri değil',
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
              title: 'Pazar akışı',
              subtitle: 'resmi veri · ofis envanteri değil',
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
              title: 'Pazar akışı',
              subtitle: 'resmi veri · ofis envanteri değil',
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: EmptyState(
                compact: true,
                grouped: true,
                icon: Icons.cloud_off_outlined,
                title: 'Pazar akışı yüklenemedi',
                subtitle: 'Bağlantınızı kontrol edip tekrar deneyin.',
                actionLabel: 'Tekrar dene',
                onAction: () {
                  ref.invalidate(externalListingsStreamProvider);
                  ref.invalidate(marketFeedRowsStaleCacheProvider);
                  onRetry();
                },
              ),
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
      cacheExtent: 360,
      slivers: [
        const SliverToBoxAdapter(
          child: PremiumListingsPageHeader(
            title: 'Pazar akışı',
            subtitle: 'resmi veri · ofis envanteri değil',
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
            padding: EdgeInsets.only(bottom: dockReserve),
            sliver: SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final row = filtered[index];
                final snapshot = ListingListRowSnapshot.fromRow(row);
                return RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ConsultantListingsTokens.horizontal,
                      0,
                      ConsultantListingsTokens.horizontal,
                      6,
                    ),
                    child: ListingCard(
                      row: row,
                      snapshot: snapshot,
                      onTap: () =>
                          ListingsWorkspaceActions.openListingRow(context, row),
                      onDetail: () =>
                          ListingsWorkspaceActions.openListingRow(context, row),
                      onEdit: () => ListingsWorkspaceActions.edit(context),
                      onShare: () =>
                          ListingsWorkspaceActions.shareRow(context, row),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

}
