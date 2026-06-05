import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/consultant_follow_up_tokens.dart';
import 'package:flutter/material.dart';

class FollowUpListRowQuickActions extends StatelessWidget {
  const FollowUpListRowQuickActions({
    super.key,
    this.onCall,
    this.onWhatsApp,
    this.onOpenCustomer,
    this.onCreateTask,
    this.onSnooze,
    this.onDetail,
    this.canCall = false,
    this.canWhatsApp = false,
    this.canOpenCustomer = true,
    this.canCreateTask = true,
    this.canSnooze = true,
    this.canDetail = true,
  });

  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onOpenCustomer;
  final VoidCallback? onCreateTask;
  final VoidCallback? onSnooze;
  final VoidCallback? onDetail;
  final bool canCall;
  final bool canWhatsApp;
  final bool canOpenCustomer;
  final bool canCreateTask;
  final bool canSnooze;
  final bool canDetail;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(parent: ClampingScrollPhysics()),
      child: Row(
        children: [
          _ActionIcon(
            icon: Icons.call_outlined,
            color: ext.info,
            tooltip: 'Ara',
            onPressed: canCall ? onCall : null,
          ),
          _ActionIcon(
            icon: Icons.chat_rounded,
            color: const Color(0xFF25D366),
            tooltip: 'WhatsApp',
            onPressed: canWhatsApp ? onWhatsApp : null,
          ),
          _ActionIcon(
            icon: Icons.person_outline_rounded,
            color: premium.champagneGold.withValues(alpha: 0.9),
            tooltip: 'Müşteri aç',
            onPressed: canOpenCustomer ? onOpenCustomer : null,
          ),
          _ActionIcon(
            icon: Icons.add_task_outlined,
            color: ext.success,
            tooltip: 'Görev oluştur',
            onPressed: canCreateTask ? onCreateTask : null,
          ),
          _ActionIcon(
            icon: Icons.snooze_rounded,
            color: ext.warning,
            tooltip: 'Ertele',
            onPressed: canSnooze ? onSnooze : null,
          ),
          _ActionIcon(
            icon: Icons.auto_stories_outlined,
            color: ext.textSecondary,
            tooltip: 'Geri kazanım detay',
            onPressed: canDetail ? onDetail : null,
          ),
        ],
      ),
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
        minWidth: ConsultantFollowUpTokens.actionTapSize,
        minHeight: ConsultantFollowUpTokens.actionTapSize,
      ),
      icon: Icon(
        icon,
        size: ConsultantFollowUpTokens.actionIconSize,
        color: enabled
            ? color
            : AppThemeExtension.of(context)
                .textTertiary
                .withValues(alpha: 0.35),
      ),
    );
  }
}
