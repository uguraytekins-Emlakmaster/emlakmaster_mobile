import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/performance/debounced_search_controller.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/client_portal_tokens.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/data/client_portal_preview_catalog.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/models/client_listing_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/utils/client_portal_actions.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/utils/client_portal_filter.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_chrome.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_listing_tile.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:emlakmaster_mobile/widgets/session_avatar_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Müşteri Keşfet — premium client portal discovery surface.
class ClientPortalDiscoveryPage extends ConsumerStatefulWidget {
  const ClientPortalDiscoveryPage({super.key});

  @override
  ConsumerState<ClientPortalDiscoveryPage> createState() =>
      _ClientPortalDiscoveryPageState();
}

class _ClientPortalDiscoveryPageState extends ConsumerState<ClientPortalDiscoveryPage> {
  ClientPortalFilter _filter = ClientPortalFilter.all;
  String _searchQuery = '';
  late final DebouncedSearchController _debouncedSearch;
  List<({ClientPortalPreviewListing listing, ClientListingRowSnapshot snapshot})>?
      _visibleRows;

  @override
  void initState() {
    super.initState();
    _debouncedSearch = DebouncedSearchController(
      onQueryChanged: (q) {
        if (_searchQuery == q) return;
        setState(() {
          _searchQuery = q;
          _visibleRows = null;
        });
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

  List<({ClientPortalPreviewListing listing, ClientListingRowSnapshot snapshot})>
      _resolveVisibleRows() {
    return _visibleRows ??= clientPortalPreviewCatalog
        .where((e) => matchesClientPortalFilter(e, _filter, _searchQuery))
        .map(
          (listing) => (
            listing: listing,
            snapshot: ClientListingRowSnapshot.fromPreview(listing),
          ),
        )
        .toList(growable: false);
  }

  List<Widget> _headerSlivers({
    required ClientPortalSummary summary,
    required bool signedIn,
  }) {
    return [
      SliverToBoxAdapter(
        child: PremiumClientPortalHeader(
          title: 'Hoş geldiniz',
          subtitle: 'Size özel portföy · güvenilir danışman deneyimi',
          actions: signedIn
              ? const [
                  Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: SessionAvatarButton(size: 38),
                  ),
                ]
              : const [],
        ),
      ),
      SliverToBoxAdapter(child: PremiumClientSummaryStrip(summary: summary)),
      SliverToBoxAdapter(
        child: PremiumClientPortalSearchRow(
          controller: _debouncedSearch.controller,
        ),
      ),
      SliverToBoxAdapter(
        child: PremiumClientPortalFilterStrip(
          selected: _filter,
          onSelected: (f) {
            AppFeedback.selectionClick();
            setState(() {
              _filter = f;
              _visibleRows = null;
            });
          },
        ),
      ),
      const SliverToBoxAdapter(
        child: PremiumClientSectionLabel(
          label: 'Portföy',
          secondary: 'Önizleme ilanları',
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final dockReserve = _dockBottomReserve(context);
    final signedIn = ref.watch(currentUserProvider.select((u) => u.valueOrNull != null));
    final summary = computeClientPortalSummary(signedIn: signedIn);
    final visibleRows = _resolveVisibleRows();

    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() => _visibleRows = null);
              await Future<void>.delayed(const Duration(milliseconds: 180));
            },
            child: CustomScrollView(
              cacheExtent: 240,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                ..._headerSlivers(summary: summary, signedIn: signedIn),
                if (_filter == ClientPortalFilter.favorites)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: dockReserve),
                      child: Center(
                        child: EmptyState(
                          compact: true,
                          grouped: true,
                          icon: Icons.favorite_border_rounded,
                          title: 'Henüz favori ilan yok',
                          subtitle:
                              'Favori kaydı yakında aktif olacak. Şimdilik önizleme portföyünü inceleyebilirsiniz.',
                          outlinedActionLabel: 'Portföye dön',
                          onOutlinedAction: () => setState(() {
                            _filter = ClientPortalFilter.all;
                            _visibleRows = null;
                          }),
                        ),
                      ),
                    ),
                  )
                else if (visibleRows.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: dockReserve),
                      child: Center(
                        child: EmptyState(
                          compact: true,
                          grouped: true,
                          icon: Icons.search_off_outlined,
                          title: 'Eşleşen ilan bulunamadı',
                          subtitle: 'Arama veya filtreyi değiştirmeyi deneyin.',
                          actionLabel: 'Filtreyi sıfırla',
                          onAction: () {
                            _debouncedSearch.controller.clear();
                            setState(() {
                              _filter = ClientPortalFilter.all;
                              _searchQuery = '';
                              _visibleRows = null;
                            });
                          },
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == visibleRows.length) {
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              ClientPortalTokens.horizontal,
                              8,
                              ClientPortalTokens.horizontal,
                              dockReserve,
                            ),
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  ClientPortalActions.advisorRequestPreview(context),
                              icon: const Icon(Icons.support_agent_rounded, size: 18),
                              label: const Text('Danışmanıma talep ilet'),
                            ),
                          );
                        }
                        final row = visibleRows[index];
                        return ClientPortalListingTile(
                          listing: row.listing,
                          snapshot: row.snapshot,
                          onInspect: () => ClientPortalActions.inspectPreview(
                            context,
                            row.listing,
                          ),
                          onFavorite: () =>
                              ClientPortalActions.favoritePreview(context),
                          onMessage: () => ClientPortalActions.openMessages(ref),
                          onAppointment: () =>
                              ClientPortalActions.appointmentPreview(context),
                          onShare: () => ClientPortalActions.shareListing(
                            context,
                            row.listing,
                          ),
                        );
                      },
                      childCount: visibleRows.length + 1,
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
