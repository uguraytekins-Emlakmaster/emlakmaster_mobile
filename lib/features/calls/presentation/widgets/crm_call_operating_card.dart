import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_surface_card_rhythm.dart';
import 'package:flutter/material.dart';

/// Danışman / yönetici / müşteri kartlarında aynı “komut yüzeyi” kart dili — [CrmCallRecordListItem] kabuğu.
class CrmCallOperatingCard extends StatelessWidget {
  const CrmCallOperatingCard({
    super.key,
    required this.child,
    this.margin,
    this.selected = false,
    this.clipBehavior = Clip.antiAlias,
    this.rhythm = CallSurfaceCardRhythm.standard,
    this.showPriorityRail = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final bool selected;
  final Clip clipBehavior;
  final CallSurfaceCardRhythm rhythm;
  final bool showPriorityRail;

  Color _rhythmBase(AppThemeExtension ext, CallSurfaceCardRhythm r) {
    switch (r) {
      case CallSurfaceCardRhythm.standard:
        return ext.card;
      case CallSurfaceCardRhythm.linkedCustomer:
        return Color.lerp(ext.card, ext.success, 0.020)!;
      case CallSurfaceCardRhythm.unknownIdentity:
        return Color.lerp(ext.card, ext.textSecondary, 0.024)!;
      case CallSurfaceCardRhythm.callbackQueue:
        return Color.lerp(ext.card, ext.accent, 0.026)!;
      case CallSurfaceCardRhythm.attention:
        return Color.lerp(ext.card, ext.info, 0.022)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = _rhythmBase(ext, rhythm);
    final cardFill =
        selected ? Color.lerp(base, ext.accent, 0.034)! : base;
    final borderColor = selected
        ? ext.accent.withValues(alpha: 0.30)
        : ext.border.withValues(alpha: isDark ? 0.52 : 0.82);
    final railColor = rhythm == CallSurfaceCardRhythm.callbackQueue
        ? ext.accent
        : rhythm == CallSurfaceCardRhythm.attention
            ? ext.info
            : ext.accent.withValues(alpha: 0.55);

    final inner = Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (showPriorityRail)
          Positioned(
            left: 0,
            top: 14,
            bottom: 14,
            child: IgnorePointer(
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: railColor.withValues(alpha: 0.42),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(2),
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    return Card(
      margin: margin ??
          const EdgeInsets.fromLTRB(0, 0, 0, DesignTokens.space2 + 2),
      clipBehavior: clipBehavior,
      elevation: isDark ? 0 : (selected ? 0 : 1),
      shadowColor: ext.shadowColor.withValues(alpha: isDark ? 0.36 : 0.10),
      color: cardFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardSecondary),
        side: BorderSide(color: borderColor),
      ),
      child: inner,
    );
  }
}
