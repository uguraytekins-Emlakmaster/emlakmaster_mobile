import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_outcome_style.dart';
import 'package:flutter/material.dart';

/// Tasarım referansı: Çağrılarım listesi — sade, renkli satır.
class CallRecordPremiumTile extends StatelessWidget {
  const CallRecordPremiumTile({
    super.key,
    required this.title,
    required this.directionDuration,
    required this.outcomeLabel,
    this.statusLabel,
    this.metaLine,
    required this.leadingIcon,
    required this.leadingColor,
    this.onTap,
    this.onMenu,
    this.onPlay,
    this.onDetail,
    this.playDurationLabel,
    this.customerLinkHint,
    this.leadingBadge,
    this.trailing,
    this.showCheckbox = false,
    this.checked = false,
    this.onCheckChanged,
  });

  final String title;
  final String directionDuration;
  final String outcomeLabel;
  final String? statusLabel;
  final String? metaLine;
  final IconData leadingIcon;
  final Color leadingColor;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;
  final VoidCallback? onPlay;
  final VoidCallback? onDetail;
  final String? playDurationLabel;
  final String? customerLinkHint;
  final Widget? leadingBadge;
  final Widget? trailing;
  final bool showCheckbox;
  final bool checked;
  final ValueChanged<bool>? onCheckChanged;

  static String formatDirectionDuration({
    required bool isIncoming,
    int? durationSec,
  }) {
    final dir = isIncoming ? 'Gelen' : 'Giden';
    if (durationSec == null || durationSec <= 0) return dir;
    final m = durationSec ~/ 60;
    final s = durationSec % 60;
    return '$dir · ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final outcome = CallOutcomeStyle.resolve(ext, outcomeLabel);
    final showStatus = !CallOutcomeStyle.shouldHideStatusPill(
      statusLabel: statusLabel,
      outcomeLabel: outcomeLabel,
    );
    final status = showStatus ? statusLabel?.trim() : null;
    final playLabel = playDurationLabel?.trim();
    final showPlay = onPlay != null &&
        playLabel != null &&
        playLabel.isNotEmpty;
    final showDetail = onDetail != null && !showPlay;
    final linkHint = customerLinkHint?.trim();

    final row = Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space3 + 2,
        DesignTokens.space3,
        DesignTokens.space3,
        DesignTokens.space3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCheckbox) ...[
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: checked,
                onChanged: onCheckChanged == null
                    ? null
                    : (v) => onCheckChanged!(v ?? false),
                activeColor: premium.champagneGold,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: DesignTokens.space2),
          ],
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: leadingColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: leadingColor.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(leadingIcon, color: leadingColor, size: 20),
                ),
                if (leadingBadge != null)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: leadingBadge!,
                  ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              height: 1.2,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (status != null && status.isNotEmpty) ...[
                      const SizedBox(width: DesignTokens.space2),
                      _StatusPill(label: status, ext: ext),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  directionDuration,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ext.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (linkHint != null && linkHint.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    linkHint,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ext.textTertiary,
                          fontWeight: FontWeight.w500,
                          fontSize: DesignTokens.fontSizeXs,
                        ),
                  ),
                ],
                const SizedBox(height: DesignTokens.space2),
                _OutcomePill(
                  label: outcomeLabel,
                  fill: outcome.fill,
                  border: outcome.border,
                  textColor: outcome.text,
                ),
                if (metaLine != null && metaLine!.trim().isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    metaLine!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ext.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (onMenu != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onMenu,
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: ext.textTertiary,
                    size: 22,
                  ),
                ),
              if (showPlay) ...[
                const SizedBox(height: 2),
                Material(
                  color: premium.champagneGold.withValues(alpha: 0.12),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onPlay,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: premium.champagneGold,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                if (showPlay && playLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      playLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: ext.textTertiary,
                            fontWeight: FontWeight.w600,
                            fontSize: DesignTokens.fontSizeXs,
                          ),
                    ),
                  ),
              ],
              if (showDetail) ...[
                const SizedBox(height: 2),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onDetail,
                  icon: Icon(
                    Icons.article_outlined,
                    color: ext.textTertiary,
                    size: 22,
                  ),
                  tooltip: 'Kayıt detayı',
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(height: 4),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return row;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: row,
      ),
    );
  }
}

class _OutcomePill extends StatelessWidget {
  const _OutcomePill({
    required this.label,
    required this.fill,
    required this.border,
    required this.textColor,
  });

  final String label;
  final Color fill;
  final Color border;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.ext});

  final String label;
  final AppThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: ext.border.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: ext.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: DesignTokens.fontSizeXs,
            ),
      ),
    );
  }
}

