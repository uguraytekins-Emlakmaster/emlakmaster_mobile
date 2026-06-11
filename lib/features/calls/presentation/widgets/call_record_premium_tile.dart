import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_shadow_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/consultant_calls_tokens.dart';
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

    final compact = MediaQuery.sizeOf(context).width < 360;
    final avatarSize = compact
        ? ConsultantCallsTokens.rowAvatarSize
        : ConsultantCallsTokens.rowAvatarSize + 2;
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantCallsTokens.rowPaddingH,
        ConsultantCallsTokens.rowPaddingV,
        ConsultantCallsTokens.rowPaddingH,
        ConsultantCallsTokens.rowPaddingV,
      ),
      child: Row(
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
            width: avatarSize,
            height: avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: PremiumShadowTokens.goldGlow(),
                  ),
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      color: leadingColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: leadingColor.withValues(alpha: 0.32),
                      ),
                    ),
                    child: Icon(
                      leadingIcon,
                      color: leadingColor,
                      size: compact ? 17 : 19,
                    ),
                  ),
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
          SizedBox(width: compact ? 8 : DesignTokens.space3),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tightHeight =
                    constraints.maxHeight < 76 && constraints.maxHeight.isFinite;
                final titleStyle = TextStyle(
                  color: ext.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: ConsultantCallsTokens.rowTitleSize,
                  letterSpacing: -0.25,
                  height: 1.1,
                );
                final metaStyle = TextStyle(
                  color: ext.textTertiary,
                  fontWeight: FontWeight.w500,
                  fontSize: 9.5,
                  height: 1.1,
                );

                if (tightHeight) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: titleStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (status != null && status.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: _StatusPill(label: status, ext: ext),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              [
                                directionDuration,
                                if (metaLine != null && metaLine!.trim().isNotEmpty)
                                  metaLine!.trim(),
                              ].join(' · '),
                              style: TextStyle(
                                color: ext.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: ConsultantCallsTokens.rowMetaSize,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _OutcomePill(
                            label: outcomeLabel,
                            fill: outcome.fill,
                            border: outcome.border,
                            textColor: outcome.text,
                            dense: true,
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: titleStyle,
                            // İsim/numara yarım kalmasın — gerekirse 2 satıra sarar.
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (status != null && status.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: _StatusPill(label: status, ext: ext),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      directionDuration,
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: ConsultantCallsTokens.rowMetaSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (linkHint != null && linkHint.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        linkHint,
                        style: metaStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    _OutcomePill(
                      label: outcomeLabel,
                      fill: outcome.fill,
                      border: outcome.border,
                      textColor: outcome.text,
                      dense: compact,
                    ),
                    if (metaLine != null && metaLine!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        metaLine!,
                        style: metaStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          SizedBox(width: compact ? 6 : DesignTokens.space2),
          SizedBox(
            width: ConsultantCallsTokens.trailingRailWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing != null)
                  SizedBox(
                    width: ConsultantCallsTokens.trailingIconSize,
                    height: ConsultantCallsTokens.trailingIconSize,
                    child: Center(child: trailing!),
                  ),
                if (trailing != null && (onMenu != null || showPlay || showDetail))
                  const SizedBox(height: 4),
                if (onMenu != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: onMenu,
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: ext.textTertiary.withValues(alpha: 0.9),
                      size: ConsultantCallsTokens.trailingIconSize,
                    ),
                  ),
                if (showPlay) ...[
                  const SizedBox(height: 2),
                  Material(
                    color: premium.champagneGold.withValues(alpha: 0.1),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onPlay,
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: premium.champagneGold,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  if (playLabel.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        playLabel,
                        style: TextStyle(
                          color: ext.textTertiary,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                          height: 1,
                        ),
                      ),
                    ),
                ],
                if (showDetail)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: onDetail,
                    icon: Icon(
                      Icons.article_outlined,
                      color: ext.textTertiary.withValues(alpha: 0.9),
                      size: 18,
                    ),
                    tooltip: 'Kayıt detayı',
                  ),
              ],
            ),
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
    this.dense = false,
  });

  final String label;
  final Color fill;
  final Color border;
  final Color textColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: dense ? 9.5 : 11,
          height: 1,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: ext.border.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: ext.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 9.5,
          height: 1,
        ),
      ),
    );
  }
}

