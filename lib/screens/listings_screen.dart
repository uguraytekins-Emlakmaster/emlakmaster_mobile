import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_surfaces.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/my_external_listings_inner.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/listings_portfolio_stream.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
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

  late final Stream<List<PortfolioListingItem>> _stream =
      ListingsPortfolioStream.combined();

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final flags = ref.watch(featureFlagsProvider).valueOrNull;
    final extInt = flags?[AppConstants.keyFeatureExternalIntegrations] ?? true;

    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.t('title_listings'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: ext.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (extInt) ...[
                    const SizedBox(height: 12),
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment<int>(
                          value: 0,
                          label: Text(l10n.t('listings_tab_portfolio')),
                          icon: const Icon(Icons.home_work_outlined, size: 18),
                        ),
                        ButtonSegment<int>(
                          value: 1,
                          label: Text(l10n.t('listings_tab_my_external')),
                          icon: const Icon(Icons.hub_outlined, size: 18),
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
              child: extInt && _segment == 1
                  ? const MyExternalListingsInner()
                  : StreamBuilder<List<PortfolioListingItem>>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: scheme.primary,
                        strokeWidth: 2,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 48, color: ext.danger.withValues(alpha: 0.9)),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context).t('listings_load_error'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: ext.foreground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    final l10n = AppLocalizations.of(context);
                    return EmptyState(
                      premiumVisual: true,
                      icon: Icons.home_work_outlined,
                      title: l10n.t('empty_listings'),
                      subtitle: l10n.t('empty_listings_sub'),
                      actionLabel: l10n.t('empty_listings_cta_import'),
                      onAction: () => context.push(AppRouter.routeImportHub),
                      outlinedActionLabel: l10n.t('empty_listings_cta_accounts'),
                      onOutlinedAction: () => context.push(AppRouter.routeConnectedAccounts),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    itemCount: items.length,
                    cacheExtent: 400,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final title = item.title.isNotEmpty
                          ? item.title
                          : AppLocalizations.of(context).t('listing');
                      final rawPrice = item.price;
                      final price = rawPrice.contains('₺') || rawPrice == '—'
                          ? rawPrice
                          : '$rawPrice ₺';
                      return RepaintBoundary(
                        child: _ListingCard(
                          listingId: item.id,
                          isExternal: item.isExternal,
                          externalLink: item.externalLink,
                          imageUrl: item.imageUrl,
                          title: title,
                          price: price,
                          location: item.location,
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
    );
  }
}

class _ListingCard extends StatelessWidget {
  final String listingId;
  final bool isExternal;
  final String? externalLink;
  final String? imageUrl;
  final String title;
  final String price;
  final String location;

  const _ListingCard({
    required this.listingId,
    required this.isExternal,
    this.externalLink,
    this.imageUrl,
    required this.title,
    required this.price,
    required this.location,
  });

  Future<void> _onTap(BuildContext context) async {
    HapticFeedback.lightImpact();
    if (isExternal) {
      final link = externalLink;
      if (link == null || link.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).t('listing_external_no_link')),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
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
    context.push(AppRouter.routeListingDetail.replaceFirst(':id', listingId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ext = AppThemeExtension.of(context);
    final brand = ext.brandPrimary;

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
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: ext.foreground,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isExternal) ...[
                            const SizedBox(width: DesignTokens.space2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignTokens.space2,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: brand.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.open_in_new_rounded,
                                    size: 14,
                                    color: brand,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.t('listing_external_badge'),
                                    style: TextStyle(
                                      color: brand,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: DesignTokens.space2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: ext.foregroundSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                color: ext.foregroundSecondary,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.space3),
                      Text(
                        price,
                        style: TextStyle(
                          color: brand,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
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
