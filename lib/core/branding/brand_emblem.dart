import 'package:emlakmaster_mobile/core/branding/brand_assets.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Emlak Master marka amblemi — yalnızca marka anlarında; fonksiyon ikonu değildir.
///
/// [BrandEmblemVariant.full]: açılış / kimlik yüzeyleri
/// [BrandEmblemVariant.mini]: ayarlar, kompakt kahraman
/// [BrandEmblemVariant.monoGold] / [monoLight]: boş durum, ince imza
enum BrandEmblemVariant {
  full,
  mini,
  monoGold,
  monoLight,
}

class BrandEmblem extends StatelessWidget {
  const BrandEmblem({
    super.key,
    required this.variant,
    this.size,
    this.opacity = 1,
  });

  final BrandEmblemVariant variant;
  final double? size;

  /// 0–1; boş durumlarda ince imza için düşürülebilir.
  final double opacity;

  double get _defaultSize {
    switch (variant) {
      case BrandEmblemVariant.full:
        return 104;
      case BrandEmblemVariant.mini:
        return 48;
      case BrandEmblemVariant.monoGold:
      case BrandEmblemVariant.monoLight:
        return 40;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sz = size ?? _defaultSize;
    final raw = Image.asset(
      BrandAssets.emblemMasterPng,
      width: sz,
      height: sz,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => _EmblemFallback(size: sz),
    );

    Widget styled;
    switch (variant) {
      case BrandEmblemVariant.full:
      case BrandEmblemVariant.mini:
        styled = raw;
        break;
      case BrandEmblemVariant.monoGold:
        styled = ColorFiltered(
          colorFilter: ColorFilter.mode(
            AppThemeExtension.of(context).accent,
            BlendMode.srcIn,
          ),
          child: raw,
        );
        break;
      case BrandEmblemVariant.monoLight:
        styled = ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.92),
            BlendMode.srcIn,
          ),
          child: raw,
        );
        break;
    }

    return Opacity(
      opacity: opacity.clamp(0, 1),
      child: Semantics(
        label: '${AppConstants.appName} amblem',
        image: true,
        child: styled,
      ),
    );
  }
}

class _EmblemFallback extends StatelessWidget {
  const _EmblemFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ext.accent.withValues(alpha: 0.35)),
      ),
      child: Icon(Icons.apartment_rounded, size: size * 0.45, color: ext.accent),
    );
  }
}

/// Ayarlar / Hakkında: ürün kimliği — amblem + isim + sürüm.
class EmlakMasterProductIdentityCard extends StatelessWidget {
  const EmlakMasterProductIdentityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    final version = AppConstants.appVersion.split('+').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space4,
        DesignTokens.space4,
        DesignTokens.space5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: ext.shadowColor.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              child: const BrandEmblem(
                variant: BrandEmblemVariant.mini,
                size: 56,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.appShortName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: ext.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sürüm $version',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ext.textTertiary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
