import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Danışman / yönetici / müşteri kartlarında aynı “komut yüzeyi” kart dili — [CrmCallRecordListItem] kabuğu.
class CrmCallOperatingCard extends StatelessWidget {
  const CrmCallOperatingCard({
    super.key,
    required this.child,
    this.margin,
    this.selected = false,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final bool selected;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardFill =
        selected ? Color.lerp(ext.card, ext.accent, 0.065)! : ext.card;
    final borderColor = selected
        ? ext.accent.withValues(alpha: 0.44)
        : ext.border.withValues(alpha: isDark ? 0.64 : 1.0);

    return Card(
      margin: margin ??
          const EdgeInsets.fromLTRB(0, 0, 0, DesignTokens.space3),
      clipBehavior: clipBehavior,
      elevation: isDark ? 0 : 1,
      shadowColor: ext.shadowColor.withValues(alpha: isDark ? 0.42 : 0.14),
      color: cardFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardSecondary),
        side: BorderSide(color: borderColor, width: selected ? 1.25 : 1),
      ),
      child: child,
    );
  }
}
