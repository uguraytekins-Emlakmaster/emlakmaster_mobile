import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/consultant_daily_tokens.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_types.dart';
import 'package:emlakmaster_mobile/screens/consultant_dashboard/widgets/consultant_dashboard_surface.dart';
import 'package:flutter/material.dart';

Color dailyToneColor(AppThemeExtension ext, DailyTone tone) {
  switch (tone) {
    case DailyTone.danger:
      return ext.danger;
    case DailyTone.warning:
      return ext.warning;
    case DailyTone.info:
      return ext.info;
    case DailyTone.success:
      return ext.success;
    case DailyTone.neutral:
      return ext.textTertiary;
  }
}

/// Executive urgency — visible but not alarm-panel red stacking.
Color dailyExecutiveTone(AppThemeExtension ext, DailyTone tone) {
  switch (tone) {
    case DailyTone.danger:
      return Color.lerp(ext.warning, ext.danger, 0.42)!;
    case DailyTone.warning:
      return ext.warning.withValues(alpha: 0.88);
    case DailyTone.info:
      return ext.info.withValues(alpha: 0.9);
    case DailyTone.success:
      return ext.success.withValues(alpha: 0.9);
    case DailyTone.neutral:
      return ext.textSecondary.withValues(alpha: 0.82);
  }
}

IconData _kindIcon(DailyKind kind) {
  switch (kind) {
    case DailyKind.task:
      return Icons.checklist_rounded;
    case DailyKind.followUp:
      return Icons.history_rounded;
    case DailyKind.customer:
      return Icons.person_rounded;
  }
}

class ConsultantDailyRow extends StatelessWidget {
  const ConsultantDailyRow({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDetail,
    this.onCall,
    this.onMessage,
  });

  final ConsultantDailyEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDetail;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final emphasized = entry.needsAttention;
    final tone = emphasized
        ? dailyExecutiveTone(ext, entry.tone)
        : dailyToneColor(ext, entry.tone);
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final showRail = emphasized && !narrow;

    final content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: narrow ? 8 : 12,
          vertical: 11,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showRail)
              Container(
                width: 2,
                height: ConsultantDailyTokens.rowIconSize + 2,
                margin: const EdgeInsets.only(right: 10, top: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  color: tone.withValues(alpha: 0.62),
                ),
              ),
            Container(
              width: ConsultantDailyTokens.rowIconSize,
              height: ConsultantDailyTokens.rowIconSize,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: emphasized ? 0.14 : 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tone.withValues(alpha: emphasized ? 0.32 : 0.24),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_kindIcon(entry.kind), size: 17, color: tone),
                ],
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textPrimary,
                            fontSize: ConsultantDailyTokens.rowTitleSize,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -0.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: _StatusChip(
                          label: entry.statusLabel,
                          color: tone,
                          soft: emphasized,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    entry.typeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tone.withValues(alpha: emphasized ? 0.88 : 0.95),
                      fontSize: ConsultantDailyTokens.rowChipSize + 0.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.timeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ext.textTertiary,
                      fontSize: ConsultantDailyTokens.rowMetaSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ext.textSecondary.withValues(alpha: 0.92),
                      fontSize: ConsultantDailyTokens.rowMetaSize + 0.5,
                      height: 1.28,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Flexible(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: premium.champagneGold.withValues(
                              alpha: emphasized ? 0.08 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: premium.champagneGold.withValues(
                                alpha: emphasized ? 0.22 : 0.28,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 14,
                                color: premium.champagneGold.withValues(
                                  alpha: emphasized ? 0.78 : 0.88,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  entry.actionLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: premium.champagneGold.withValues(
                                      alpha: emphasized ? 0.78 : 0.88,
                                    ),
                                    fontSize:
                                        ConsultantDailyTokens.rowChipSize + 1,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 2,
                        child: Text(
                          entry.context,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: ext.textTertiary,
                            fontSize: ConsultantDailyTokens.rowChipSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            _RowMenu(
              onDetail: onDetail,
              onCall: onCall,
              onMessage: onMessage,
            ),
          ],
        ),
      ),
    );

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ConsultantDailyTokens.horizontal,
          0,
          ConsultantDailyTokens.horizontal,
          ConsultantDailyTokens.moduleGap,
        ),
        child: emphasized
            ? ConsultantDashboardExecutiveSurface(
                ambientStrength: 0.78,
                radius: ConsultantDailyTokens.surfaceRadius,
                child: Material(
                  color: Colors.transparent,
                  child: content,
                ),
              )
            : ConsultantDashboardExecutiveSurface(
                ambientStrength: entry.isPartial ? 0.62 : 0.55,
                radius: ConsultantDailyTokens.surfaceRadius,
                child: Material(
                  color: Colors.transparent,
                  child: content,
                ),
              ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    this.soft = false,
  });

  final String label;
  final Color color;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: soft ? 0.1 : 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: soft ? 0.28 : 0.36),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: ConsultantDailyTokens.rowChipSize,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.onDetail, this.onCall, this.onMessage});

  final VoidCallback onDetail;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Eylemler',
      icon: Icon(Icons.more_vert_rounded, size: 18, color: ext.textTertiary),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        switch (value) {
          case 'detail':
            onDetail();
            break;
          case 'call':
            onCall?.call();
            break;
          case 'message':
            onMessage?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'detail', child: Text('Detay')),
        if (onCall != null)
          const PopupMenuItem(value: 'call', child: Text('Ara')),
        if (onMessage != null)
          const PopupMenuItem(value: 'message', child: Text('Mesaj')),
      ],
    );
  }
}
