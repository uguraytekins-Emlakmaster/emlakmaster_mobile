import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/consultant_integrations_tokens.dart';
import 'package:flutter/material.dart';

class IntegrationCenterRowActions extends StatelessWidget {
  const IntegrationCenterRowActions({
    super.key,
    this.onConnect,
    this.onConfigure,
    this.onOpen,
    this.onRetry,
    this.onLearnMore,
    this.canConnect = false,
    this.canConfigure = false,
    this.canOpen = false,
    this.canRetry = false,
    this.canLearnMore = true,
  });

  final VoidCallback? onConnect;
  final VoidCallback? onConfigure;
  final VoidCallback? onOpen;
  final VoidCallback? onRetry;
  final VoidCallback? onLearnMore;
  final bool canConnect;
  final bool canConfigure;
  final bool canOpen;
  final bool canRetry;
  final bool canLearnMore;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _ActionPill(
          icon: Icons.link_rounded,
          label: 'Bağlan',
          onPressed: canConnect ? onConnect : null,
          color: ext.success,
          filled: true,
        ),
        _ActionPill(
          icon: Icons.tune_rounded,
          label: 'Yapılandır',
          onPressed: canConfigure ? onConfigure : null,
          color: ext.info,
        ),
        _ActionPill(
          icon: Icons.open_in_new_rounded,
          label: 'Aç',
          onPressed: canOpen ? onOpen : null,
          color: ext.accent,
        ),
        _ActionPill(
          icon: Icons.refresh_rounded,
          label: 'Yeniden dene',
          onPressed: canRetry ? onRetry : null,
          color: ext.warning,
        ),
        _ActionPill(
          icon: Icons.info_outline_rounded,
          label: 'Daha fazla',
          onPressed: canLearnMore ? onLearnMore : null,
          color: ext.textSecondary,
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final enabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: !enabled
              ? ext.surface
              : (filled ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !enabled
                ? ext.border.withValues(alpha: 0.35)
                : color.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
        children: [
            Icon(
              icon,
              size: ConsultantIntegrationsTokens.actionIconSize - 2,
              color: enabled ? color : ext.textTertiary.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: enabled ? color : ext.textTertiary.withValues(alpha: 0.45),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
