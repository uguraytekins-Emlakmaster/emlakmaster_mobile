import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_surfaces.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:emlakmaster_mobile/features/listings/data/listing_row_factory.dart';
import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/providers/market_feed_rows_provider.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/providers/owned_listing_rows_provider.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class ListingsPage extends ConsumerStatefulWidget {
  const ListingsPage({super.key});

  @override
  ConsumerState<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends ConsumerState<ListingsPage> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final showMarket = ref.watch(
      featureFlagsProvider.select(
        (a) => a.valueOrNull?[AppConstants.keyFeatureOfficialMarketFeed] ?? false,
      ),
    );

    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space6,
                DesignTokens.space3,
                DesignTokens.space6,
                DesignTokens.space2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.t('title_listings'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: DesignTokens.space1),
                  Text(
                    _segment == 0 || !showMarket
                        ? l10n.t('listings_subtitle_owned')
                        : l10n.t('listings_subtitle_market'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ext.textSecondary,
                        ),
                  ),
                  if (showMarket) ...[
                    const SizedBox(height: DesignTokens.space4),
                    SegmentedButton<int>(
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        side: WidgetStatePropertyAll(
                          BorderSide(color: ext.border.withValues(alpha: 0.55)),
                        ),
                      ),
                      segments: [
                        ButtonSegment<int>(
                          value: 0,
                          label: Text(l10n.t('listings_tab_owned')),
                          icon: const Icon(Icons.verified_outlined, size: 18),
                        ),
                        ButtonSegment<int>(
                          value: 1,
                          label: Text(l10n.t('listings_tab_market')),
                          icon: const Icon(Icons.public_rounded, size: 18),
                        ),
                      ],
                      selected: {_segment},
                      onSelectionChanged: (Set<int> next) {
                        setState(() => _segment = next.first);
                      },
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: showMarket && _segment == 1
                  ? _MarketFeedPane(scheme: scheme)
                  : _OwnedPane(scheme: scheme),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnedPane extends ConsumerWidget {
  const _OwnedPane({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(ownedListingRowsProvider);
    final canManagePlatformIntegrations = ref.watch(canManagePlatformIntegrationsProvider);

    return async.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: scheme.primary, strokeWidth: 2),
      ),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.t('listings_load_error'),
            textAlign: TextAlign.center,
            style: TextStyle(color: ext.foreground, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return EmptyState(
            premiumVisual: true,
            icon: Icons.home_work_outlined,
            title: l10n.t('empty_listings'),
            subtitle: canManagePlatformIntegrations
                ? l10n.t('empty_listings_sub')
                : '${l10n.t('empty_listings_sub')}\n\n${l10n.t('integration_connections_read_only_notice')}',
            actionLabel: canManagePlatformIntegrations ? l10n.t('empty_listings_cta_import') : null,
            onAction: canManagePlatformIntegrations
                ? () => context.push(AppRouter.routeImportHub)
                : null,
            outlinedActionLabel: canManagePlatformIntegrations ? l10n.t('empty_listings_cta_accounts') : null,
            onOutlinedAction: canManagePlatformIntegrations
                ? () => context.push(AppRouter.routeConnectedAccounts)
                : null,
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space6,
            0,
            DesignTokens.space6,
            DesignTokens.space8,
          ),
          children: _buildOwnedSection(context, rows),
        );
      },
    );
  }

  static List<Widget> _buildOwnedSection(BuildContext context, List<ListingRowView> rows) {
    final l10n = AppLocalizations.of(context);
    final ext = AppThemeExtension.of(context);
    final out = <Widget>[];
    ListingRowKind? prev;
    for (final r in rows) {
      if (prev != r.rowKind &&
          (r.rowKind == ListingRowKind.officePortfolio ||
              r.rowKind == ListingRowKind.connectedPlatform)) {
        final title = r.rowKind == ListingRowKind.officePortfolio
            ? l10n.t('listings_section_office')
            : l10n.t('listings_section_connected');
        out.add(
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.space2, bottom: DesignTokens.space2),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: ext.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
            ),
          ),
        );
      }
      out.add(_ListingRowCard(row: r));
      prev = r.rowKind;
    }
    return out;
  }
}

class _MarketFeedPane extends ConsumerWidget {
  const _MarketFeedPane({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    final enabled = ref.watch(
      featureFlagsProvider.select(
        (a) => a.valueOrNull?[AppConstants.keyFeatureOfficialMarketFeed] ?? false,
      ),
    );
    if (!enabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space6),
          child: EmptyState(
            premiumVisual: true,
            icon: Icons.lock_outline_rounded,
            title: l10n.t('listings_market_disabled_title'),
            subtitle: l10n.t('listings_market_disabled_sub'),
          ),
        ),
      );
    }

    final async = ref.watch(marketFeedRowsProvider);
    return async.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: scheme.primary, strokeWidth: 2),
      ),
      error: (_, __) => Center(
        child: Text(
          l10n.t('listings_load_error'),
          style: TextStyle(color: ext.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return EmptyState(
            premiumVisual: true,
            icon: Icons.rss_feed_rounded,
            title: l10n.t('listings_empty_market'),
            subtitle: l10n.t('listings_empty_market_sub'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space6,
            0,
            DesignTokens.space6,
            DesignTokens.space8,
          ),
          itemCount: rows.length,
          itemBuilder: (context, i) => _ListingRowCard(row: rows[i]),
        );
      },
    );
  }
}

class _ListingRowCard extends StatelessWidget {
  const _ListingRowCard({required this.row});

  final ListingRowView row;

  Future<void> _onTap(BuildContext context) async {
    HapticFeedback.lightImpact();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).t('listing_external_no_link')),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).t('listing_external_open_failed')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).t('listing_external_no_link')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ext = AppThemeExtension.of(context);
    final brand = ext.brandPrimary;
    final title = row.title.isNotEmpty ? row.title : l10n.t('listing');
    final price = row.priceLabel.contains('₺') || row.priceLabel == '—'
        ? row.priceLabel
        : '${row.priceLabel} ₺';
    final platform = tryPlatformForRow(row);
    final sourceLabel = sourcePlatformDisplayLabel(row.sourcePlatform, platform: platform);
    final syncLabel = listingSyncStatusLabel(row.syncStatus);
    final dateStr = row.lastSyncedAt != null ? _formatDt(row.lastSyncedAt!) : '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTap(context),
          borderRadius: BorderRadius.circular(AppSurfaces.radiusCardLg),
          child: Container(
            decoration: AppSurfaces.cardLevel1(context, radius: AppSurfaces.radiusCardLg),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: row.imageUrl != null && row.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: row.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => LayoutBuilder(
                            builder: (context, c) => ShimmerPlaceholder(
                              width: c.maxWidth,
                              height: c.maxHeight,
                            ),
                          ),
                          errorWidget: (_, __, ___) => _placeholderImage(context),
                        )
                      : _placeholderImage(context),
                ),
                Padding(
                  padding: AppSurfaces.paddingCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Badge(
                            label: sourceLabel,
                            fg: brand,
                            bg: brand.withValues(alpha: 0.12),
                          ),
                          if (row.surface == ListingSurface.marketFeed)
                            _Badge(
                              label: l10n.t('listings_badge_market'),
                              fg: ext.warning,
                              bg: ext.warning.withValues(alpha: 0.12),
                            )
                          else
                            _Badge(
                              label: l10n.t('listings_badge_owned'),
                              fg: ext.success,
                              bg: ext.success.withValues(alpha: 0.12),
                            ),
                        ],
                      ),
                      if (row.surface == ListingSurface.marketFeed) ...[
                        const SizedBox(height: DesignTokens.space2),
                        Text(
                          l10n.t('listings_badge_not_inventory'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ext.textTertiary,
                                fontSize: 11,
                                height: 1.3,
                              ),
                        ),
                      ],
                      const SizedBox(height: DesignTokens.space3),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: DesignTokens.space3),
                      Text(
                        price,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: brand,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: DesignTokens.space2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: ext.textTertiary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              row.locationLabel,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: ext.textSecondary,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (row.surface == ListingSurface.owned) ...[
                        const SizedBox(height: DesignTokens.space2),
                        Text(
                          l10n.tArgs('listings_sync_line', [syncLabel, dateStr]),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: ext.textTertiary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return ColoredBox(
      color: ext.surfaceElevated,
      child: Center(
        child: Icon(
          Icons.home_rounded,
          size: 48,
          color: ext.foregroundMuted.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.fg,
    required this.bg,
  });

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space2, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: fg.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

String _formatDt(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
}
