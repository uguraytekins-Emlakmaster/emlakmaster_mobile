import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Tüm tam sayfa rotalarında tutarlı geri butonu + AppBar.
PreferredSizeWidget emlakAppBar(
  BuildContext context, {
  required Widget title,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
  Color? backgroundColor,
  Color? foregroundColor,
  bool centerTitle = true,
  double? elevation,
}) {
  final theme = Theme.of(context);
  final bg = backgroundColor ??
      theme.appBarTheme.backgroundColor ??
      theme.scaffoldBackgroundColor;
  final fg = foregroundColor ??
      theme.appBarTheme.foregroundColor ??
      theme.colorScheme.onSurface;
  final canPop = context.canPop();
  final titleStyle =
      theme.appBarTheme.titleTextStyle ?? AppTypography.pageHeading(context);
  final maxTitleWidth = MediaQuery.sizeOf(context).width - 112;
  return AppBar(
    leading: canPop ? const AppBackButton() : null,
    automaticallyImplyLeading: false,
    title: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxTitleWidth.clamp(160, 560)),
      child: DefaultTextStyle.merge(
        style: titleStyle,
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
    elevation: elevation ?? theme.appBarTheme.elevation ?? 0,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    centerTitle: centerTitle,
    iconTheme: theme.appBarTheme.iconTheme?.copyWith(color: fg) ??
        IconThemeData(color: fg),
  );
}
