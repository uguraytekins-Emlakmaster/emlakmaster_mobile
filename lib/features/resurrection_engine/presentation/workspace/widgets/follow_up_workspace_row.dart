import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/consultant_follow_up_tokens.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_types.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/widgets/follow_up_workspace_chrome.dart';
import 'package:flutter/material.dart';

enum FollowUpRowMenu {
  open,
  complete,
  customer,
  call,
  message,
  whatsapp,
  tasks,
  snooze,
  detail,
}

class FollowUpWorkspaceRow extends StatelessWidget {
  const FollowUpWorkspaceRow({
    super.key,
    required this.row,
    required this.onTap,
    required this.onCall,
    required this.onMenu,
  });

  final FollowUpRowView row;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final void Function(FollowUpRowMenu) onMenu;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final tone = followUpToneColor(ext, row.tone);
    final compact = MediaQuery.sizeOf(context).width < 360;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              ConsultantFollowUpTokens.horizontal,
              0,
              ConsultantFollowUpTokens.horizontal,
              ConsultantFollowUpTokens.chromeGap + 2,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: ConsultantFollowUpTokens.rowPaddingH,
              vertical: ConsultantFollowUpTokens.rowPaddingV,
            ),
            decoration: BoxDecoration(
              color: ext.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: row.isOverdue
                    ? ext.danger.withValues(alpha: 0.35)
                    : ext.border.withValues(alpha: 0.32),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SegmentDot(color: tone, urgent: row.isOverdue || row.isToday),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (compact) ...[
                        Text(
                          row.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textPrimary,
                            fontSize: ConsultantFollowUpTokens.rowTitleSize,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _StatusChip(
                            label: row.statusLabel,
                            color: tone,
                          ),
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                row.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ext.textPrimary,
                                  fontSize:
                                      ConsultantFollowUpTokens.rowTitleSize,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: _StatusChip(
                                label: row.statusLabel,
                                color: tone,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 2),
                      Text(
                        row.lastContactLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ext.textSecondary.withValues(alpha: 0.9),
                          fontSize: ConsultantFollowUpTokens.rowMetaSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (row.contextLine.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          row.contextLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (row.nextActionLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          row.nextActionLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.accent.withValues(alpha: 0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (row.isPartial && row.partialNote.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          row.partialNote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textTertiary,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!compact && row.callablePhone && onCall != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Ara',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: ConsultantFollowUpTokens.actionTapSize,
                      minHeight: ConsultantFollowUpTokens.actionTapSize,
                    ),
                    onPressed: onCall,
                    icon: Icon(
                      Icons.call_rounded,
                      size: ConsultantFollowUpTokens.actionIconSize,
                      color: ext.accent,
                    ),
                  ),
                ],
                PopupMenuButton<FollowUpRowMenu>(
                  tooltip: 'Aksiyonlar',
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: ConsultantFollowUpTokens.actionIconSize + 2,
                    color: ext.textTertiary,
                  ),
                  onSelected: onMenu,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: FollowUpRowMenu.open,
                      child: Text('Aç'),
                    ),
                    const PopupMenuItem(
                      value: FollowUpRowMenu.complete,
                      child: Text('Tamamla'),
                    ),
                    if (row.isMatched)
                      const PopupMenuItem(
                        value: FollowUpRowMenu.customer,
                        child: Text('Müşteriye git'),
                      ),
                    if (row.callablePhone) ...[
                      const PopupMenuItem(
                        value: FollowUpRowMenu.call,
                        child: Text('Ara'),
                      ),
                      const PopupMenuItem(
                        value: FollowUpRowMenu.message,
                        child: Text('Mesaj'),
                      ),
                      const PopupMenuItem(
                        value: FollowUpRowMenu.whatsapp,
                        child: Text('WhatsApp'),
                      ),
                    ],
                    const PopupMenuItem(
                      value: FollowUpRowMenu.tasks,
                      child: Text('Göreve git'),
                    ),
                    const PopupMenuItem(
                      value: FollowUpRowMenu.snooze,
                      child: Text('Ertele'),
                    ),
                    const PopupMenuItem(
                      value: FollowUpRowMenu.detail,
                      child: Text('Detay'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentDot extends StatelessWidget {
  const _SegmentDot({required this.color, required this.urgent});

  final Color color;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: urgent ? 0.95 : 0.65),
        shape: BoxShape.circle,
        boxShadow: urgent
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 4,
                ),
              ]
            : null,
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: ConsultantFollowUpTokens.statusChipFontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
