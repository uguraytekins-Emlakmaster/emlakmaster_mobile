import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/consultant_customers_tokens.dart';
import 'package:flutter/material.dart';

/// Satır hızlı aksiyonları — Ara, Mesaj, WhatsApp, Detay.
class CustomerListRowQuickActions extends StatelessWidget {
  const CustomerListRowQuickActions({
    super.key,
    this.onCall,
    this.onMessage,
    this.onWhatsApp,
    this.onOpenDetail,
  });

  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(
          icon: Icons.call_rounded,
          color: ext.success,
          tooltip: 'Ara',
          onPressed: onCall,
        ),
        _ActionIcon(
          icon: Icons.sms_rounded,
          color: ext.info,
          tooltip: 'Mesaj',
          onPressed: onMessage,
        ),
        _ActionIcon(
          icon: Icons.chat_rounded,
          color: const Color(0xFF25D366),
          tooltip: 'WhatsApp',
          onPressed: onWhatsApp,
        ),
        _ActionIcon(
          icon: Icons.chevron_right_rounded,
          color: premium.champagneGold.withValues(alpha: 0.85),
          tooltip: 'Müşteri detayı',
          onPressed: onOpenDetail,
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
        minWidth: ConsultantCustomersTokens.actionTapSize,
        minHeight: ConsultantCustomersTokens.actionTapSize,
      ),
      icon: Icon(
        icon,
        size: ConsultantCustomersTokens.actionIconSize,
        color: enabled
            ? color
            : AppThemeExtension.of(context).textTertiary.withValues(alpha: 0.35),
      ),
    );
  }
}
