import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/consultant_tasks_tokens.dart';
import 'package:flutter/material.dart';

/// Görev satırı hızlı aksiyonlar — tamamla, ertele, müşteri, düzenle.
class TaskListRowQuickActions extends StatelessWidget {
  const TaskListRowQuickActions({
    super.key,
    this.onComplete,
    this.onPostpone,
    this.onOpenCustomer,
    this.onEdit,
    this.hasCustomer = false,
    this.isDone = false,
  });

  final VoidCallback? onComplete;
  final VoidCallback? onPostpone;
  final VoidCallback? onOpenCustomer;
  final VoidCallback? onEdit;
  final bool hasCustomer;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
  final premium = PremiumThemeExtension.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(
          icon: isDone ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
          color: isDone ? ext.warning : ext.success,
          tooltip: isDone ? 'Yeniden aç' : 'Tamamla',
          onPressed: onComplete,
        ),
        _ActionIcon(
          icon: Icons.snooze_rounded,
          color: ext.info,
          tooltip: 'Ertele',
          onPressed: isDone ? null : onPostpone,
        ),
        _ActionIcon(
          icon: Icons.person_outline_rounded,
          color: premium.champagneGold.withValues(alpha: 0.85),
          tooltip: 'Müşteri',
          onPressed: hasCustomer ? onOpenCustomer : null,
        ),
        _ActionIcon(
          icon: Icons.edit_outlined,
          color: ext.textSecondary,
          tooltip: 'Düzenle',
          onPressed: onEdit,
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
        minWidth: ConsultantTasksTokens.actionTapSize,
        minHeight: ConsultantTasksTokens.actionTapSize,
      ),
      icon: Icon(
        icon,
        size: ConsultantTasksTokens.actionIconSize,
        color: enabled
            ? color
            : AppThemeExtension.of(context)
                .textTertiary
                .withValues(alpha: 0.35),
      ),
    );
  }
}
