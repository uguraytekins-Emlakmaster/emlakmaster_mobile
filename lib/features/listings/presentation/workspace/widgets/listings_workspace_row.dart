import 'package:cached_network_image/cached_network_image.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/consultant_listings_tokens.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_types.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/widgets/listings_workspace_chrome.dart';
import 'package:flutter/material.dart';

enum ListingRowMenu {
  open,
  edit,
  share,
  sync,
  detail,
}

class ListingsWorkspaceRow extends StatelessWidget {
  const ListingsWorkspaceRow({
    super.key,
    required this.row,
    required this.onTap,
    required this.onMenu,
  });

  final ListingWorkspaceRowView row;
  final VoidCallback onTap;
  final void Function(ListingRowMenu) onMenu;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final tone = listingToneColor(ext, row.tone);
    final compact = MediaQuery.sizeOf(context).width < 360;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              ConsultantListingsTokens.horizontal,
              0,
              ConsultantListingsTokens.horizontal,
              ConsultantListingsTokens.chromeGap + 2,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: ConsultantListingsTokens.rowPaddingH,
              vertical: ConsultantListingsTokens.rowPaddingV,
            ),
            decoration: BoxDecoration(
              color: ext.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: row.needsAttention
                    ? ext.warning.withValues(alpha: 0.35)
                    : row.isMissing
                        ? ext.danger.withValues(alpha: 0.3)
                        : ext.border.withValues(alpha: 0.32),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumb(url: row.row.imageUrl),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (compact) ...[
                        Text(
                          row.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textPrimary,
                            fontSize: ConsultantListingsTokens.rowTitleSize,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _StatusChip(label: row.statusLabel, color: tone),
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                row.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ext.textPrimary,
                                  fontSize:
                                      ConsultantListingsTokens.rowTitleSize,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: _StatusChip(
                                label: row.statusLabel,
                                color: tone,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 2),
                      Text(
                        row.typeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.textSecondary.withValues(alpha: 0.9),
                          fontSize: ConsultantListingsTokens.rowMetaSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (row.priceDisplay.isNotEmpty &&
                          row.priceDisplay != '—') ...[
                        const SizedBox(height: 2),
                        Text(
                          row.priceDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: premium.champagneGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (row.locationLine.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          row.locationLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (row.nextActionLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          row.nextActionLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.accent.withValues(alpha: 0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (row.isPartial && row.partialNote.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          row.partialNote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textTertiary,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<ListingRowMenu>(
                  tooltip: 'Aksiyonlar',
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: ConsultantListingsTokens.actionIconSize + 2,
                    color: ext.textTertiary,
                  ),
                  onSelected: onMenu,
                  itemBuilder: (context) => [
                    if (row.canOpenDetail || row.canOpenExternal)
                      PopupMenuItem(
                        value: ListingRowMenu.open,
                        child: Text(row.canOpenDetail ? 'İlana git' : 'Aç'),
                      ),
                    const PopupMenuItem(
                      value: ListingRowMenu.edit,
                      child: Text('Düzenle'),
                    ),
                    if (row.canShare)
                      const PopupMenuItem(
                        value: ListingRowMenu.share,
                        child: Text('Mesaj'),
                      ),
                    if (row.canSync)
                      const PopupMenuItem(
                        value: ListingRowMenu.sync,
                        child: Text('Tamamla'),
                      ),
                    const PopupMenuItem(
                      value: ListingRowMenu.detail,
                      child: Text('Detay'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    const size = ConsultantListingsTokens.rowThumbSize;
    final hasUrl = url != null && url!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                memCacheWidth: 120,
                errorWidget: (_, __, ___) => _placeholder(ext),
                placeholder: (_, __) => ColoredBox(
                  color: ext.surface.withValues(alpha: 0.6),
                ),
              )
            : _placeholder(ext),
      ),
    );
  }

  Widget _placeholder(AppThemeExtension ext) {
    return ColoredBox(
      color: ext.surface.withValues(alpha: 0.65),
      child: Icon(
        Icons.home_work_outlined,
        size: 22,
        color: ext.textTertiary,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: ConsultantListingsTokens.statusChipFontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
