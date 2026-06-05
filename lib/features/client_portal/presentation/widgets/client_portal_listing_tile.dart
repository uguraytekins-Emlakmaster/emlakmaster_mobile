import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/client_portal_tokens.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/data/client_portal_preview_catalog.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/models/client_listing_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_row_actions.dart';
import 'package:flutter/material.dart';

class ClientPortalListingTile extends StatelessWidget {
  const ClientPortalListingTile({
    super.key,
    required this.listing,
    required this.snapshot,
    this.onTap,
    this.onInspect,
    this.onFavorite,
    this.onMessage,
    this.onAppointment,
    this.onShare,
  });

  final ClientPortalPreviewListing listing;
  final ClientListingRowSnapshot snapshot;
  final VoidCallback? onTap;
  final VoidCallback? onInspect;
  final VoidCallback? onFavorite;
  final VoidCallback? onMessage;
  final VoidCallback? onAppointment;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final tone = snapshot.toneColor(
      snapshot.statusTone,
      ext.accent,
      ext.info,
      ext.success,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientPortalTokens.horizontal,
        0,
        ClientPortalTokens.horizontal,
        6,
      ),
      child: Material(
        color: ext.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap ?? onInspect,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ext.border.withValues(alpha: 0.32)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                ClientPortalTokens.rowPaddingH,
                ClientPortalTokens.rowPaddingV,
                ClientPortalTokens.rowPaddingH,
                ClientPortalTokens.rowPaddingV,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Thumb(kindLabel: snapshot.kindLabel),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    listing.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: ext.textPrimary,
                                      fontSize: ClientPortalTokens.rowTitleSize,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                _Chip(label: snapshot.statusLabel, color: tone),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              listing.priceLabel,
                              style: TextStyle(
                                color: ext.accent,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              listing.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ext.textSecondary,
                                fontSize: ClientPortalTokens.rowMetaSize,
                              ),
                            ),
                            Text(
                              listing.features,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ext.textTertiary,
                                fontSize: ClientPortalTokens.rowMetaSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClientPortalRowActions(
                    onInspect: onInspect,
                    onFavorite: onFavorite,
                    onMessage: onMessage,
                    onAppointment: onAppointment,
                    onShare: onShare,
                    canFavorite: snapshot.canFavorite,
                    canMessage: snapshot.canMessage,
                    canAppointment: snapshot.canAppointment,
                    canShare: snapshot.canShare,
                    canInspect: snapshot.canInspect,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.kindLabel});

  final String kindLabel;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      width: ClientPortalTokens.thumbSize,
      height: ClientPortalTokens.thumbSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ext.accent.withValues(alpha: 0.22),
            ext.surfaceElevated.withValues(alpha: 0.85),
          ],
        ),
        border: Border.all(color: ext.border.withValues(alpha: 0.28)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work_outlined, color: ext.accent, size: 22),
          Text(
            kindLabel,
            style: TextStyle(
              color: ext.textTertiary,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
