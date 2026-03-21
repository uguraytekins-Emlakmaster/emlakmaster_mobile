import 'package:cached_network_image/cached_network_image.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:emlakmaster_mobile/features/external_listings/domain/entities/external_listing_entity.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Yatırım terminali görünümü — fiyat trendi oku, platform rozetleri, emlak tipi etiketi.
class MarketPulseInvestmentListingTile extends StatelessWidget {
  const MarketPulseInvestmentListingTile({super.key, required this.listing});

  final ExternalListingEntity listing;

  /// Koyu mavi rozet (beyaz metin) — emlak tipi.
  static const Color _typeBadgeBg = Color(0xFF0D47A1);
  static const Color _typeBadgeFg = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    final textTertiary = isDark ? DesignTokens.textTertiaryDark : DesignTokens.textTertiaryLight;
    final border = isDark ? DesignTokens.borderDark : DesignTokens.borderLight;
    final price = listing.priceText ??
        (listing.priceValue != null ? '${listing.priceValue!.toStringAsFixed(0)} ₺' : '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final uri = Uri.tryParse(listing.link);
            if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
          },
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              border: Border.all(color: border.withValues(alpha: 0.45)),
              color: isDark
                  ? DesignTokens.surfaceDarkCard.withValues(alpha: 0.65)
                  : DesignTokens.surfaceLightElevated,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        DesignTokens.primary.withValues(alpha: 0.95),
                        DesignTokens.primary.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _Thumb(listing: listing, textTertiary: textTertiary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              listing.title,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (listing.propertyType != null &&
                              listing.propertyType!.trim().isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: _typeBadgeBg,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                listing.propertyType!.trim(),
                                style: const TextStyle(
                                  color: _typeBadgeFg,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (listing.district != null && listing.district!.isNotEmpty)
                            Text(
                              listing.district!,
                              style: TextStyle(
                                color: textTertiary,
                                fontSize: 11,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          if (listing.district != null &&
                              listing.district!.isNotEmpty &&
                              price.isNotEmpty)
                            Text(' · ', style: TextStyle(color: textTertiary, fontSize: 11)),
                          if (price.isNotEmpty) _PriceWithTrend(priceText: price),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _PlatformOriginStrip(source: listing.source),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.listing, required this.textTertiary});

  final ExternalListingEntity listing;
  final Color textTertiary;

  @override
  Widget build(BuildContext context) {
    if (listing.imageUrl != null && listing.imageUrl!.isNotEmpty) {
      return Hero(
        tag: 'listing_${listing.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CachedNetworkImage(
            imageUrl: listing.imageUrl!,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            placeholder: (_, __) => ShimmerPlaceholder(
              width: 52,
              height: 52,
              borderRadius: BorderRadius.circular(6),
            ),
            errorWidget: (_, __, ___) => _PlaceholderIcon(textTertiary: textTertiary),
          ),
        ),
      );
    }
    return _PlaceholderIcon(textTertiary: textTertiary);
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon({required this.textTertiary});

  final Color textTertiary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: DesignTokens.surfaceDarkElevated.withValues(alpha: 0.5),
      ),
      child: Icon(Icons.domain_rounded, color: textTertiary, size: 26),
    );
  }
}

/// Yeşil yukarı ok, hemen ₺ sembolünün solunda.
class _PriceWithTrend extends StatelessWidget {
  const _PriceWithTrend({required this.priceText});

  final String priceText;

  @override
  Widget build(BuildContext context) {
    final idx = priceText.indexOf('₺');
    final hasLira = idx >= 0;
    final before = hasLira ? priceText.substring(0, idx).trimRight() : priceText;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          before,
          style: const TextStyle(
            color: DesignTokens.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        if (hasLira) ...[
          const SizedBox(width: 2),
          const Padding(
            padding: EdgeInsets.only(bottom: 1),
            child: Icon(
              Icons.arrow_upward_rounded,
              size: 12,
              color: Color(0xFF43A047),
            ),
          ),
          const Text(
            '₺',
            style: TextStyle(
              color: DesignTokens.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

/// «örnek» metni yerine mikro marka rozetleri; tek kaynak veya demo için üçlü şerit.
class _PlatformOriginStrip extends StatelessWidget {
  const _PlatformOriginStrip({required this.source});

  final ExternalListingSource source;

  static const double _h = 16;

  @override
  Widget build(BuildContext context) {
    if (source == ExternalListingSource.demo) {
      return Row(
        children: [
          _MicroBrandBadge.sahibinden(compact: true),
          const SizedBox(width: 4),
          _MicroBrandBadge.emlakjet(compact: true),
          const SizedBox(width: 4),
          _MicroBrandBadge.hepsiEmlak(compact: true),
        ],
      );
    }
    switch (source) {
      case ExternalListingSource.sahibinden:
        return _MicroBrandBadge.sahibinden(compact: false);
      case ExternalListingSource.emlakjet:
        return _MicroBrandBadge.emlakjet(compact: false);
      case ExternalListingSource.hepsiEmlak:
        return _MicroBrandBadge.hepsiEmlak(compact: false);
      case ExternalListingSource.demo:
        return const SizedBox.shrink();
    }
  }
}

/// Sahibinden / Emlakjet / Hepsi Emlak — renkli, mikro boyutlu (logo yerine stilize harf).
class _MicroBrandBadge extends StatelessWidget {
  const _MicroBrandBadge._({
    required this.bg,
    required this.fg,
    required this.label,
    required this.compact,
  });

  final Color bg;
  final Color fg;
  final String label;
  final bool compact;

  factory _MicroBrandBadge.sahibinden({required bool compact}) {
    return _MicroBrandBadge._(
      bg: const Color(0xFFFFC107),
      fg: const Color(0xFF1A1A1A),
      label: 'S',
      compact: compact,
    );
  }

  factory _MicroBrandBadge.emlakjet({required bool compact}) {
    return _MicroBrandBadge._(
      bg: const Color(0xFF00A651),
      fg: Colors.white,
      label: 'E',
      compact: compact,
    );
  }

  factory _MicroBrandBadge.hepsiEmlak({required bool compact}) {
    return _MicroBrandBadge._(
      bg: const Color(0xFFE53935),
      fg: Colors.white,
      label: 'H',
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = compact ? 22.0 : 28.0;
    return Tooltip(
      message: _tooltip,
      child: Container(
        width: w,
        height: _PlatformOriginStrip._h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: compact ? 9 : 10,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }

  String get _tooltip {
    switch (label) {
      case 'S':
        return 'Sahibinden';
      case 'E':
        return 'Emlakjet';
      case 'H':
        return 'Hepsi Emlak';
      default:
        return '';
    }
  }
}
