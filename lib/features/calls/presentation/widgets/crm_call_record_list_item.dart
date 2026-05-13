import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Çağrı kaydı satırı — insan odaklı hiyerarşi (sol ikon, orta içerik, sağ aksiyon).
class CrmCallRecordListItem extends StatelessWidget {
  const CrmCallRecordListItem({
    super.key,
    required this.title,
    this.phoneSubtitle,
    required this.outcomeLabel,
    required this.captureLabel,
    required this.contextLine,
    this.notePreview,
    this.technicalFootnote,
    required this.leading,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.all(DesignTokens.space4),
  });

  final String title;
  final String? phoneSubtitle;
  final String outcomeLabel;
  final String captureLabel;
  final String contextLine;
  final String? notePreview;
  final String? technicalFootnote;
  final Widget leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final child = Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.cardHeading(context).copyWith(
                    fontSize: DesignTokens.fontSizeXl,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                    letterSpacing: -0.42,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (phoneSubtitle != null &&
                    phoneSubtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.space1 + 1),
                  Text(
                    phoneSubtitle!,
                    style: AppTypography.bodyStrong(context).copyWith(
                      fontSize: DesignTokens.fontSizeMd,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: DesignTokens.space3),
                Wrap(
                  spacing: DesignTokens.space2,
                  runSpacing: DesignTokens.space2,
                  children: [
                    _CrmCallRecordChip(
                      label: outcomeLabel,
                      color: ext.accent,
                      emphasized: true,
                    ),
                    _CrmCallRecordChip(
                      label: captureLabel,
                      color: ext.textSecondary,
                      emphasized: false,
                      surface: ext.surfaceElevated,
                      borderColor: ext.border,
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space3),
                Text(
                  contextLine,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ext.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.44,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (notePreview != null && notePreview!.trim().isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.space2 + 2),
                  Text(
                    notePreview!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(context).copyWith(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
                if (technicalFootnote != null &&
                    technicalFootnote!.trim().isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    technicalFootnote!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ext.textTertiary,
                          fontSize: DesignTokens.fontSizeSm,
                          fontWeight: FontWeight.w500,
                          height: 1.38,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: DesignTokens.space2),
            trailing!,
          ],
        ],
      ),
    );
    if (onTap == null) return child;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardSecondary),
        child: child,
      ),
    );
  }
}

class _CrmCallRecordChip extends StatelessWidget {
  const _CrmCallRecordChip({
    required this.label,
    required this.color,
    required this.emphasized,
    this.surface,
    this.borderColor,
  });

  final String label;
  final Color color;
  final bool emphasized;
  final Color? surface;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final fill = emphasized
        ? color.withValues(alpha: 0.15)
        : (surface ?? ext.surfaceElevated).withValues(alpha: 0.98);
    final borderSide = emphasized
        ? BorderSide(color: color.withValues(alpha: 0.38))
        : BorderSide(
            color: (borderColor ?? ext.border).withValues(alpha: 0.78),
          );
    final textColor = emphasized ? color : ext.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space3 + 2,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: borderSide.color),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
              fontSize: DesignTokens.fontSizeSm,
              letterSpacing: emphasized ? 0.12 : 0.08,
              height: 1.2,
            ),
      ),
    );
  }
}
