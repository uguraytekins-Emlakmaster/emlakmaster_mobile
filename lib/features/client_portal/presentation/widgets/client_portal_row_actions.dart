import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';

class ClientPortalRowActions extends StatelessWidget {
  const ClientPortalRowActions({
    super.key,
    this.onInspect,
    this.onFavorite,
    this.onMessage,
    this.onAppointment,
    this.onShare,
    this.canInspect = true,
    this.canFavorite = false,
    this.canMessage = true,
    this.canAppointment = false,
    this.canShare = true,
  });

  final VoidCallback? onInspect;
  final VoidCallback? onFavorite;
  final VoidCallback? onMessage;
  final VoidCallback? onAppointment;
  final VoidCallback? onShare;
  final bool canInspect;
  final bool canFavorite;
  final bool canMessage;
  final bool canAppointment;
  final bool canShare;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _Pill(
          icon: Icons.visibility_outlined,
          label: 'İncele',
          onPressed: canInspect ? onInspect : null,
          color: ext.accent,
          filled: true,
        ),
        _Pill(
          icon: Icons.favorite_border_rounded,
          label: 'Favori',
          onPressed: canFavorite ? onFavorite : onFavorite,
          color: ext.warning,
          enabled: canFavorite,
          previewLabel: canFavorite ? null : 'Yakında',
        ),
        _Pill(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Mesaj',
          onPressed: canMessage ? onMessage : null,
          color: ext.info,
        ),
        _Pill(
          icon: Icons.event_outlined,
          label: 'Randevu',
          onPressed: canAppointment ? onAppointment : onAppointment,
          color: ext.textSecondary,
          enabled: canAppointment,
          previewLabel: canAppointment ? null : 'Yakında',
        ),
        _Pill(
          icon: Icons.ios_share_rounded,
          label: 'Paylaş',
          onPressed: canShare ? onShare : null,
          color: ext.success,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
    this.filled = false,
    this.enabled = true,
    this.previewLabel,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool filled;
  final bool enabled;
  final String? previewLabel;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final active = enabled && onPressed != null;
    final display = previewLabel != null ? '$label · $previewLabel' : label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: filled && active
                ? color.withValues(alpha: 0.16)
                : ext.surface.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? color.withValues(alpha: 0.42)
                  : ext.border.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: active ? color : ext.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                display,
                style: TextStyle(
                  color: active ? color : ext.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
