import 'package:cached_network_image/cached_network_image.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/consultant_listings_tokens.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/models/listing_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/widgets/listing_list_row_quick_actions.dart';
import 'package:flutter/material.dart';

/// Yüksek yoğunluklu ilan satırı.
class ListingListPremiumTile extends StatelessWidget {
  const ListingListPremiumTile({
    super.key,
    required this.row,
    required this.snapshot,
    this.onTap,
    this.onDetail,
    this.onEdit,
    this.onShare,
    this.onSync,
  });

  final ListingRowView row;
  final ListingListRowSnapshot snapshot;
  final VoidCallback? onTap;
  final VoidCallback? onDetail;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onSync;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final title = row.title.isNotEmpty ? row.title : 'İlan';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ConsultantListingsTokens.rowPaddingH,
          ConsultantListingsTokens.rowPaddingV,
          ConsultantListingsTokens.rowPaddingH,
          ConsultantListingsTokens.rowPaddingV,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(imageUrl: row.imageUrl),
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
                          title,
                          style: TextStyle(
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: ConsultantListingsTokens.rowTitleSize,
                            letterSpacing: -0.2,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _StatusChip(
                        label: snapshot.statusLabel,
                        tone: snapshot.statusTone,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    snapshot.priceDisplay,
                    style: TextStyle(
                      color: premium.champagneGold,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: ext.textTertiary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          row.locationLabel,
                          style: TextStyle(
                            color: ext.textSecondary,
                            fontSize: ConsultantListingsTokens.rowMetaSize,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _MiniChip(
                        label: snapshot.sourceLabel,
                        fg: premium.champagneGold,
                      ),
                      if (row.surface == ListingSurface.marketFeed)
                        _MiniChip(label: 'Pazar', fg: ext.warning),
                    ],
                  ),
                  if (snapshot.metaLine.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      snapshot.metaLine,
                      style: TextStyle(
                        color: ext.textTertiary,
                        fontSize: 9.5,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  ListingListRowQuickActions(
                    onDetail: onDetail,
                    onEdit: onEdit,
                    onShare: onShare,
                    onSync: onSync,
                    canDetail: snapshot.canOpenDetail || snapshot.canOpenExternal,
                    canShare: snapshot.canShare,
                    canSync: snapshot.canSyncHint,
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

class _Thumb extends StatelessWidget {
  const _Thumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    const size = ConsultantListingsTokens.rowThumbSize;
    final url = imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: 160,
                placeholder: (_, __) => const ShimmerPlaceholder(width: size, height: size),
                errorWidget: (_, __, ___) => _placeholder(ext),
              )
            : _placeholder(ext),
      ),
    );
  }

  Widget _placeholder(AppThemeExtension ext) {
    return ColoredBox(
      color: ext.surfaceElevated,
      child: Icon(
        Icons.home_rounded,
        size: 22,
        color: ext.foregroundMuted.withValues(alpha: 0.35),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.tone});

  final String label;
  final ListingRowStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final color = switch (tone) {
      ListingRowStatusTone.success => ext.success,
      ListingRowStatusTone.warning => ext.warning,
      ListingRowStatusTone.danger => ext.danger,
      ListingRowStatusTone.info => ext.info,
      ListingRowStatusTone.neutral => ext.textTertiary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: ConsultantListingsTokens.statusChipFontSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.fg});

  final String label;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
