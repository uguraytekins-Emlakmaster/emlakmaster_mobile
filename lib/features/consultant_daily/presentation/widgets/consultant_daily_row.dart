import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/consultant_daily_tokens.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_types.dart';
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
    final tone = dailyToneColor(ext, entry.tone);

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ConsultantDailyTokens.horizontal,
          0,
          ConsultantDailyTokens.horizontal,
          ConsultantDailyTokens.moduleGap,
        ),
        child: Material(
          color: ext.surfaceElevated.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: ConsultantDailyTokens.rowMinHeight,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ext.border.withValues(alpha: 0.26)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: ConsultantDailyTokens.rowIconSize,
                    height: ConsultantDailyTokens.rowIconSize,
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: tone.withValues(alpha: 0.34)),
                    ),
                    child: Icon(_kindIcon(entry.kind), size: 18, color: tone),
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
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusChip(label: entry.statusLabel, color: tone),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.typeLabel}  ·  ${entry.timeLabel}',
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
                            color: ext.textSecondary,
                            fontSize: ConsultantDailyTokens.rowMetaSize + 0.5,
                            height: 1.28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: ext.accent,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                entry.actionLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ext.accent,
                                  fontSize: ConsultantDailyTokens.rowChipSize + 1,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
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
                  const SizedBox(width: 4),
                  _RowMenu(
                    onDetail: onDetail,
                    onCall: onCall,
                    onMessage: onMessage,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
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
