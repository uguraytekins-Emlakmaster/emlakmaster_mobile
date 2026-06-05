import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/consultant_calls_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/calls_workspace_types.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/widgets/calls_workspace_chrome.dart';
import 'package:flutter/material.dart';

enum CallRowMenu { open, call, message, whatsapp, customer, followUp, tasks, detail }

/// Premium çağrı satırı — yüksek yoğunluk, per-row blur yok.
class CallsWorkspaceRow extends StatelessWidget {
  const CallsWorkspaceRow({
    super.key,
    required this.row,
    required this.onTap,
    required this.onCall,
    required this.onMenu,
  });

  final CallRowView row;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final void Function(CallRowMenu) onMenu;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final tone = callToneColor(ext, row.tone);
    final compact = MediaQuery.sizeOf(context).width < 360;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              ConsultantCallsTokens.horizontal,
              0,
              ConsultantCallsTokens.horizontal,
              ConsultantCallsTokens.chromeGap + 2,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: ConsultantCallsTokens.rowPaddingH,
              vertical: ConsultantCallsTokens.rowPaddingV,
            ),
            decoration: BoxDecoration(
              color: ext.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: row.needsCallback
                    ? ext.warning.withValues(alpha: 0.35)
                    : ext.border.withValues(alpha: 0.32),
              ),
            ),
            child: Row(
              children: [
                _DirectionAvatar(
                  isIncoming: row.isIncoming,
                  color: tone,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (compact) ...[
                        Text(
                          row.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textPrimary,
                            fontSize: ConsultantCallsTokens.rowTitleSize,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _OutcomeChip(label: row.outcomeLabel, color: tone),
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                row.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ext.textPrimary,
                                  fontSize: ConsultantCallsTokens.rowTitleSize,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: _OutcomeChip(
                                label: row.outcomeLabel,
                                color: tone,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.phoneLine.isNotEmpty
                                  ? row.phoneLine
                                  : row.directionDuration,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    ext.textSecondary.withValues(alpha: 0.92),
                                fontSize: ConsultantCallsTokens.rowMetaSize,
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _Timestamp(
                            label: row.timestampLabel,
                            colorType: row.timestampColorType,
                          ),
                        ],
                      ),
                      if (row.phoneLine.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          row.directionDuration,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          if (row.isMatched)
                            _MicroTag(
                              icon: Icons.link_rounded,
                              label: 'Müşteri',
                              color: ext.success,
                            ),
                          if (row.needsCallback)
                            _MicroTag(
                              icon: Icons.replay_rounded,
                              label: 'Geri dön',
                              color: ext.warning,
                            ),
                          if (row.isPartial && row.partialNote.isNotEmpty)
                            _MicroTag(
                              icon: Icons.info_outline_rounded,
                              label: row.partialNote,
                              color: ext.textTertiary,
                            ),
                        ],
                      ),
                      if (row.contextLine.isNotEmpty ||
                          row.nextActionLabel.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          row.nextActionLabel.isNotEmpty
                              ? row.nextActionLabel
                              : row.contextLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ext.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                if (!compact && onCall != null)
                  IconButton(
                    tooltip: 'Ara',
                    constraints: const BoxConstraints(
                      minWidth: ConsultantCallsTokens.trailingRailWidth,
                      minHeight: ConsultantCallsTokens.trailingRailWidth,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: onCall,
                    icon: Icon(
                      Icons.call_rounded,
                      size: ConsultantCallsTokens.trailingIconSize,
                      color: ext.accent,
                    ),
                  ),
                PopupMenuButton<CallRowMenu>(
                  tooltip: 'Aksiyonlar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: ConsultantCallsTokens.trailingRailWidth,
                    minHeight: ConsultantCallsTokens.trailingRailWidth,
                  ),
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: ConsultantCallsTokens.trailingIconSize,
                    color: ext.textTertiary,
                  ),
                  onSelected: onMenu,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: CallRowMenu.open,
                      child: Text('Aç'),
                    ),
                    if (onCall != null)
                      const PopupMenuItem(
                        value: CallRowMenu.call,
                        child: Text('Ara'),
                      ),
                    const PopupMenuItem(
                      value: CallRowMenu.message,
                      child: Text('Mesaj'),
                    ),
                    const PopupMenuItem(
                      value: CallRowMenu.whatsapp,
                      child: Text('WhatsApp'),
                    ),
                    if (row.customerId != null && row.customerId!.isNotEmpty)
                      const PopupMenuItem(
                        value: CallRowMenu.customer,
                        child: Text('Müşteriye git'),
                      ),
                    const PopupMenuItem(
                      value: CallRowMenu.followUp,
                      child: Text('Takibe ekle'),
                    ),
                    const PopupMenuItem(
                      value: CallRowMenu.tasks,
                      child: Text('Görevlere git'),
                    ),
                    const PopupMenuItem(
                      value: CallRowMenu.detail,
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

class _DirectionAvatar extends StatelessWidget {
  const _DirectionAvatar({required this.isIncoming, required this.color});

  final bool isIncoming;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      width: ConsultantCallsTokens.rowAvatarSize,
      height: ConsultantCallsTokens.rowAvatarSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Icon(
        isIncoming ? Icons.call_received_rounded : Icons.call_made_rounded,
        size: 16,
        color: color == ext.textTertiary ? ext.textSecondary : color,
      ),
    );
  }
}

class _OutcomeChip extends StatelessWidget {
  const _OutcomeChip({required this.label, required this.color});

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
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Timestamp extends StatelessWidget {
  const _Timestamp({required this.label, required this.colorType});

  final String label;
  final int colorType;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final color = switch (colorType) {
      1 => ext.success,
      2 => ext.warning,
      _ => ext.textTertiary,
    };
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _MicroTag extends StatelessWidget {
  const _MicroTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.55,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
