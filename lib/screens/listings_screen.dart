import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/listings_portfolio_stream.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class ListingsPage extends StatefulWidget {
  const ListingsPage({super.key});

  @override
  State<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  late final Stream<List<PortfolioListingItem>> _stream =
      ListingsPortfolioStream.combined();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.scaffoldDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Text(
                AppLocalizations.of(context).t('title_listings'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<PortfolioListingItem>>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: DesignTokens.primary,
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
                            const Icon(Icons.error_outline_rounded,
                                size: 48, color: Colors.white54),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context).t('listings_load_error'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    final l10n = AppLocalizations.of(context);
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_work_outlined,
                            size: 56,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.t('empty_listings'),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              l10n.t('empty_listings_sub'),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTap(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
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
                    errorWidget: (_, __, ___) => _placeholderImage(),
                  )
                : _placeholderImage(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isExternal) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: DesignTokens.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.open_in_new_rounded,
                              size: 14,
                              color: DesignTokens.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.t('listing_external_badge'),
                              style: const TextStyle(
                                color: DesignTokens.primary,
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  price,
                  style: const TextStyle(
                    color: DesignTokens.primary,
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

  Widget _placeholderImage() {
    return Container(
      color: DesignTokens.surfaceDarkCard,
      child: Center(
        child: Icon(
          Icons.home_rounded,
          size: 48,
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
