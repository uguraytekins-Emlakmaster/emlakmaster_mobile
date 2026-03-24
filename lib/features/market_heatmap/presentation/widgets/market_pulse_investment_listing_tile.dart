import 'dart:ui' show FontFeature, ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:emlakmaster_mobile/features/external_listings/domain/entities/external_listing_entity.dart';
import 'package:emlakmaster_mobile/core/theme/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Terminal tarzı Market Pulse satırı — cam rozetler, altın fiyat, trend %.
///
/// 16px grid: iç boşluklar 8 / 16 katları.
class MarketPulseInvestmentListingTile extends StatelessWidget {
  const MarketPulseInvestmentListingTile({super.key, required this.listing});

  final ExternalListingEntity listing;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final textPrimary = ext.foreground;
    final textTertiary = ext.foregroundMuted;
    final brand = ext.brandPrimary;

    final priceDisplay = _priceDisplay(listing);

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final uri = Uri.tryParse(listing.link);
            if (uri != null) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          borderRadius: BorderRadius.circular(AppSurfaces.radiusCard),
          child: Ink(
            decoration: AppSurfaces.cardLevel1(context),
            child: Padding(
              padding: AppSurfaces.paddingCard,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumb(listing: listing, textTertiary: textTertiary),
                  const SizedBox(width: 16),
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
                                  fontSize: 14,
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
                              const SizedBox(width: 8),
                              _GlassPropertyTypeBadge(
                                label: listing.propertyType!.trim(),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (listing.district != null &&
                            listing.district!.isNotEmpty)
                          Text(
                            listing.district!,
                            style: TextStyle(
                              color: textTertiary,
                              fontSize: 12,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        if (listing.district != null &&
                            listing.district!.isNotEmpty)
                          const SizedBox(height: 8),
                        if (priceDisplay.isNotEmpty)
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  priceDisplay,
                                  style: TextStyle(
                                    color: brand,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    letterSpacing: -0.4,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (listing.trendPct != null) ...[
                                const SizedBox(width: 8),
                                _TrendIndicator(pct: listing.trendPct!),
                              ],
                            ],
                          ),
                        const SizedBox(height: 8),
                        _PlatformOriginStrip(source: listing.source),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _priceDisplay(ExternalListingEntity l) {
    if (l.priceText != null && l.priceText!.trim().isNotEmpty) {
      return l.priceText!.trim();
    }
    if (l.priceValue != null) {
      return '${l.priceValue!.toStringAsFixed(0)} ₺';
    }
    return '';
  }
}

/// Yükleme iskeleti — [MarketPulseInvestmentListingTile] ile aynı ölçüler (16px grid).
class MarketPulseListingTileSkeleton extends StatelessWidget {
  const MarketPulseListingTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space4),
      child: Container(
        padding: AppSurfaces.paddingCard,
        decoration: AppSurfaces.cardLevel1(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerPlaceholder(
              width: 64,
              height: 64,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ShimmerPlaceholder(
                          height: 14,
                          width: double.infinity,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ShimmerPlaceholder(
                        height: 24,
                        width: 56,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ShimmerPlaceholder(
                    height: 12,
                    width: 120,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ShimmerPlaceholder(
                        height: 18,
                        width: 100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(width: 8),
                      ShimmerPlaceholder(
                        height: 18,
                        width: 48,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ShimmerPlaceholder(
                    height: 16,
                    width: 88,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPropertyTypeBadge extends StatelessWidget {
  const _GlassPropertyTypeBadge({required this.label});

  final String label;

  ({IconData icon, Color tint}) _visuals(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final t = label.toLowerCase();
    if (t.contains('villa')) {
      return (icon: Icons.holiday_village_rounded, tint: ext.brandPrimary);
    }
    if (t.contains('arsa')) {
      return (icon: Icons.park_rounded, tint: ext.success);
    }
    if (t.contains('iş') || t.contains('isyeri') || t.contains('ticari')) {
      return (icon: Icons.storefront_rounded, tint: ext.foregroundSecondary);
    }
    if (t.contains('konut') || t.contains('daire')) {
      return (icon: Icons.apartment_rounded, tint: ext.brandPrimary);
    }
    return (icon: Icons.home_work_rounded, tint: ext.foregroundMuted);
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final v = _visuals(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: v.tint.withValues(alpha: 0.18),
            border: Border.all(color: ext.border.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: ext.shadowColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(v.icon, size: 13, color: ext.foreground),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: ext.foreground,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendIndicator extends StatelessWidget {
  const _TrendIndicator({required this.pct});

  final double pct;

  @override
  Widget build(BuildContext context) {
    final up = pct >= 0;
    final c = up ? const Color(0xFF4ADE80) : const Color(0xFFFF6B6B);
    final sign = pct >= 0 ? '+' : '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 14,
          color: c,
        ),
        const SizedBox(width: 2),
        Text(
          '$sign${pct.toStringAsFixed(1)}%',
          style: TextStyle(
            color: c,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1,
          ),
        ),
      ],
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
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: listing.imageUrl!,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            placeholder: (_, __) => ShimmerPlaceholder(
              width: 64,
              height: 64,
              borderRadius: BorderRadius.circular(12),
            ),
            errorWidget: (_, __, ___) => _PlaceholderIcon(
                textTertiary: textTertiary, type: listing.propertyType),
          ),
        ),
      );
    }
    return _PlaceholderIcon(
        textTertiary: textTertiary, type: listing.propertyType);
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon({required this.textTertiary, this.type});

  final Color textTertiary;
  final String? type;

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.domain_rounded;
    final t = type?.toLowerCase() ?? '';
    if (t.contains('villa')) {
      icon = Icons.holiday_village_rounded;
    } else if (t.contains('arsa')) {
      icon = Icons.park_rounded;
    } else if (t.contains('iş') || t.contains('isyeri')) {
      icon = Icons.storefront_rounded;
    } else if (t.contains('konut') || t.contains('daire')) {
      icon = Icons.apartment_rounded;
    }

    final ext = AppThemeExtension.of(context);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: ext.surfaceElevated,
      ),
      child: Icon(icon, color: textTertiary, size: 28),
    );
  }
}

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
    final ext = AppThemeExtension.of(context);
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
              color: ext.shadowColor.withValues(alpha: 0.35),
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
