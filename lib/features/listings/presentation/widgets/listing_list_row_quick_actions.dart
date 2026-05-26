import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/consultant_listings_tokens.dart';
import 'package:flutter/material.dart';

/// İlan satırı hızlı aksiyonlar.
class ListingListRowQuickActions extends StatelessWidget {
  const ListingListRowQuickActions({
    super.key,
    this.onDetail,
    this.onEdit,
    this.onShare,
    this.onSync,
    this.canDetail = false,
    this.canShare = false,
    this.canSync = false,
  });

  final VoidCallback? onDetail;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onSync;
  final bool canDetail;
  final bool canShare;
  final bool canSync;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(
          icon: Icons.open_in_new_rounded,
          color: premium.champagneGold.withValues(alpha: 0.9),
          tooltip: 'Detay',
          onPressed: canDetail ? onDetail : null,
        ),
        _ActionIcon(
          icon: Icons.edit_outlined,
          color: ext.textSecondary,
          tooltip: 'Düzenle',
          onPressed: onEdit,
        ),
        _ActionIcon(
          icon: Icons.ios_share_rounded,
          color: ext.info,
          tooltip: 'Paylaş',
          onPressed: canShare ? onShare : null,
        ),
        _ActionIcon(
          icon: Icons.sync_rounded,
          color: ext.success,
          tooltip: 'Senkron',
          onPressed: canSync ? onSync : null,
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: ConsultantListingsTokens.actionTapSize,
        minHeight: ConsultantListingsTokens.actionTapSize,
      ),
      icon: Icon(
        icon,
        size: ConsultantListingsTokens.actionIconSize,
        color: enabled
            ? color
            : AppThemeExtension.of(context)
                .textTertiary
                .withValues(alpha: 0.35),
      ),
    );
  }
}
