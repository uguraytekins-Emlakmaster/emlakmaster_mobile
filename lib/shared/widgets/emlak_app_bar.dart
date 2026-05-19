import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_navigation.dart';
import 'package:flutter/material.dart';

/// Premium AppBar — geri + ana sayfa, obsidyen yüzey, altın krom.
PreferredSizeWidget emlakAppBar(
  BuildContext context, {
  required Widget title,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
  Color? backgroundColor,
  Color? foregroundColor,
  bool centerTitle = false,
  double? elevation,
  bool showHomeWhenCanPop = true,
}) {
  final ext = AppThemeExtension.of(context);
  final bg = backgroundColor ?? ext.background;
  final fg = foregroundColor ?? ext.textPrimary;
  final maxTitleWidth = MediaQuery.sizeOf(context).width - 128;
  return AppBar(
    leading: PremiumNavLeading(showHomeWhenCanPop: showHomeWhenCanPop),
    leadingWidth: PremiumNavLeading.leadingWidth(context),
    automaticallyImplyLeading: false,
    title: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxTitleWidth.clamp(160, 560)),
      child: DefaultTextStyle.merge(
        style: AppTypography.pageHeading(context).copyWith(
          color: fg,
          fontSize: DesignTokens.fontSizeLg,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: centerTitle ? TextAlign.center : TextAlign.start,
        child: title,
      ),
    ),
    actions: actions,
    bottom: bottom,
    backgroundColor: bg,
    foregroundColor: fg,
    elevation: elevation ?? 0,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    centerTitle: centerTitle,
    iconTheme: IconThemeData(color: ext.accent),
    actionsIconTheme: IconThemeData(color: ext.accent),
  );
}
