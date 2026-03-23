import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/theme/app_surfaces.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_synced_listing_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class FilterChipIntegration extends StatelessWidget {
  const FilterChipIntegration({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? scheme.primary.withValues(alpha: 0.2) : ext.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? scheme.primary.withValues(alpha: 0.55) : ext.border.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? scheme.primary : ext.foregroundSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class SyncedListingCard extends StatelessWidget {
  const SyncedListingCard({super.key, required this.entity});

  final IntegrationSyncedListingEntity entity;

  Future<void> _open(BuildContext context) async {
    HapticFeedback.lightImpact();
    final uri = Uri.tryParse(entity.sourceUrl);
    if (uri == null || !uri.hasScheme) {
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
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    final brand = ext.brandPrimary;
    final img = entity.images.isNotEmpty ? entity.images.first : null;
    final loc = [
      if (entity.district != null && entity.district!.isNotEmpty) entity.district,
      if (entity.city != null && entity.city!.isNotEmpty) entity.city,
    ].whereType<String>().join(', ');

    String priceText = '—';
    if (entity.price != null) {
      final cur = entity.currency ?? '₺';
      priceText = '${entity.price!.toStringAsFixed(0)} $cur';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(AppSurfaces.radiusCardLg),
        child: Container(
          decoration: AppSurfaces.cardLevel1(context, radius: AppSurfaces.radiusCardLg),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: img != null && img.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: img,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => LayoutBuilder(
                          builder: (context, c) => ShimmerPlaceholder(
                            width: c.maxWidth,
                            height: c.maxHeight,
                          ),
                        ),
                        errorWidget: (_, __, ___) => _placeholder(context),
                      )
                    : _placeholder(context),
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
                            entity.title.isNotEmpty ? entity.title : l10n.t('listing'),
                            style: TextStyle(
                              color: ext.foreground,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: brand.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                          ),
                          child: Text(
                            entity.platform.displayName,
                            style: TextStyle(
                              color: brand,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (loc.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: ext.foregroundSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              loc,
                              style: TextStyle(color: ext.foregroundSecondary, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ext.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                            border: Border.all(color: ext.success.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sync_rounded, size: 12, color: ext.success),
                              const SizedBox(width: 4),
                              Text(
                                _syncLabel(entity),
                                style: TextStyle(color: ext.success, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        if (entity.status != null && entity.status!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: ext.border.withValues(alpha: 0.55)),
                              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                            ),
                            child: Text(
                              entity.status!,
                              style: TextStyle(color: ext.foregroundSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space3),
                    Row(
                      children: [
                        Text(
                          priceText,
                          style: TextStyle(
                            color: brand,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.open_in_new_rounded, size: 18, color: ext.foregroundMuted),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _syncLabel(IntegrationSyncedListingEntity e) {
    final t = e.syncedAt ?? e.platformUpdatedAt ?? e.importedAt;
    final d = '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';
    final hm = '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
    return 'Güncellendi $d $hm';
  }

  Widget _placeholder(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return ColoredBox(
      color: ext.surfaceElevated,
      child: Center(
        child: Icon(Icons.photo_outlined, size: 40, color: ext.foregroundMuted.withValues(alpha: 0.4)),
      ),
    );
  }
}
