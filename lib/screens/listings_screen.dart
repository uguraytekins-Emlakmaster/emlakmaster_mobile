import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/consultant_listings_tokens.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/providers/owned_listing_rows_display_provider.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/providers/owned_listing_rows_provider.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/utils/listing_list_filter.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_types.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/providers/listings_workspace_provider.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/widgets/listings_market_segment.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/widgets/listings_workspace_surface.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Portföyüm — danışman ilan workspace (Screen 29). Consultant shell index 4
/// ('listings'). Premium, dürüst, hızlı operasyonel portföy; uydurma skor yok.
class ListingsPage extends ConsumerStatefulWidget {
  const ListingsPage({super.key});

  @override
  ConsumerState<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends ConsumerState<ListingsPage> {
  int _segment = 0;
  int _retryKey = 0;
  ListingListFilter _marketFilter = ListingListFilter.all;
  String _marketSearchQuery = '';
  late final DebouncedSearchController _marketSearch;

  @override
  void initState() {
    super.initState();
    _marketSearch = DebouncedSearchController(
      onQueryChanged: (q) {
        if (_marketSearchQuery != q) setState(() => _marketSearchQuery = q);
      },
    );
  }

  @override
  void dispose() {
    _marketSearch.dispose();
    super.dispose();
  }

  double _dockBottomReserve(BuildContext context) {
    final ts = MediaQuery.textScalerOf(context);
    final ratio =
        ts.scale(DesignTokens.fontSizeBase) / DesignTokens.fontSizeBase;
    return 120 * ratio.clamp(1.0, 1.38);
  }

  void _retryOwned() {
    ref.invalidate(ownedListingRowsProvider);
    ref.invalidate(ownedListingRowsStaleCacheProvider);
    setState(() => _retryKey++);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showMarket = ref.watch(
      featureFlagsProvider.select(
        (a) => a.valueOrNull?[AppConstants.keyFeatureOfficialMarketFeed] ?? false,
      ),
    );
    final dockReserve = _dockBottomReserve(context);
    final isMarket = showMarket && _segment == 1;

    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ShellScreenReadyListener(
          screenName: 'listings',
          provider: listingsWorkspaceSnapshotProvider,
          itemCount: (v) => (v as ListingsWorkspaceSnapshot).rows.length,
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
                          ? 'Portföyüm'
                          : l10n.t('listings_tab_market'),
                    ),
                  ),
                Expanded(
                  child: Builder(
                    key: ValueKey('listings_$_retryKey'),
                    builder: (context) {
                      if (isMarket) {
                        return ListingsMarketSegment(
                          dockReserve: dockReserve,
                          searchController: _marketSearch.controller,
                          searchQuery: _marketSearchQuery,
                          listFilter: _marketFilter,
                          onFilterChanged: (f) {
                            AppFeedback.selectionClick();
                            setState(() => _marketFilter = f);
                          },
                          onRetry: _retryOwned,
                        );
                      }
                      return const ListingsWorkspaceSurface();
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
}
