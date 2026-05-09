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
                    fontSize: DesignTokens.fontSizeMd,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (phoneSubtitle != null &&
                    phoneSubtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    phoneSubtitle!,
                    style: AppTypography.bodyStrong(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: DesignTokens.space2),
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
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space2),
                Text(
                  contextLine,
                  style: AppTypography.meta(context)
                      .copyWith(color: ext.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (notePreview != null && notePreview!.trim().isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    notePreview!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(context),
                  ),
                ],
                if (technicalFootnote != null &&
                    technicalFootnote!.trim().isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.space1),
                  Text(
                    technicalFootnote!,
                    style: AppTypography.meta(context).copyWith(
                      color: ext.textTertiary,
                      fontSize: 11,
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
  });

  final String label;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final borderAlpha = emphasized ? 0.28 : 0.18;
    final fillAlpha = emphasized ? 0.14 : 0.08;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: fillAlpha),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: borderAlpha)),
      ),
      child: Text(
        label,
        style: AppTypography.meta(context).copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }
}
