import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/utils/admin_office_health_summary.dart';
import 'package:emlakmaster_mobile/screens/admin_shell_nav.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PremiumAdminUrgentSection extends StatelessWidget {
  const PremiumAdminUrgentSection({
    super.key,
    required this.items,
  });

  final List<AdminCommandUrgentItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AdminCommandTokens.horizontal,
          0,
          AdminCommandTokens.horizontal,
          AdminCommandTokens.moduleGap,
        ),
        child: _UrgentQuietCard(),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminCommandTokens.horizontal,
        0,
        AdminCommandTokens.horizontal,
        AdminCommandTokens.moduleGap,
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: AdminCommandTokens.moduleGap),
            _UrgentBlock(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _UrgentQuietCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      height: AdminCommandTokens.urgentBlockHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ext.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 18, color: ext.success.withValues(alpha: 0.9)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Acil müdahale kuyruğu sakin. Ofis akışı izleniyor.',
              style: AppTypography.meta(context).copyWith(
                color: ext.textSecondary,
                fontSize: 10.5,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentBlock extends StatelessWidget {
  const _UrgentBlock({required this.item});

  final AdminCommandUrgentItem item;

  Color _tone(AppThemeExtension ext) => switch (item.kind) {
        AdminUrgentKind.escalation => ext.danger,
        AdminUrgentKind.alert => ext.warning,
        AdminUrgentKind.sync => ext.danger,
        AdminUrgentKind.integration => ext.info,
        AdminUrgentKind.missedCalls => ext.warning,
        AdminUrgentKind.followUp => ext.accent,
      };

  IconData _icon() => switch (item.iconName) {
        'escalation' => Icons.priority_high_rounded,
        'alert' => Icons.notifications_active_outlined,
        'sync' => Icons.sync_problem_rounded,
        'integration' => Icons.hub_outlined,
        'missed' => Icons.phone_missed_rounded,
        _ => Icons.flag_outlined,
      };

  void _onTap(BuildContext context) {
    AppFeedback.selectionClick();
    switch (item.kind) {
      case AdminUrgentKind.escalation:
      case AdminUrgentKind.alert:
      case AdminUrgentKind.missedCalls:
        context.push(AppRouter.routeCommandCenter);
      case AdminUrgentKind.sync:
        context.push(AppRouter.routeConnectedAccounts);
      case AdminUrgentKind.integration:
        context.push(AppRouter.routeConnectedAccounts);
      case AdminUrgentKind.followUp:
        final nav = AdminShellNav.maybeOf(context);
        if (nav != null && (nav.tabIndexFor?.call('warRoom') ?? -1) >= 0) {
          AdminShellNav.goToWarRoomTab(context);
        } else {
          AdminShellNav.goToReportsTab(context);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final tone = _tone(ext);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTap(context),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: AdminCommandTokens.urgentBlockHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tone.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(_icon(), size: 18, color: tone),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontSize: AdminCommandTokens.urgentTitleSize,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontSize: AdminCommandTokens.urgentMetaSize,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.count > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${item.count}',
                    style: TextStyle(
                      color: tone,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: ext.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
