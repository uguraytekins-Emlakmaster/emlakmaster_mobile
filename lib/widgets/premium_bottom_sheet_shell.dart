import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Sheet içinde metin ölçeği üst sınırı — yüksek erişilebilirlik ayarında taşmayı azaltır.
const double kPremiumSheetMaxTextScale = 1.25;

/// Modal sheet gövdesinde metin ölçeğini sınırlar.
Widget premiumSheetClampContext(BuildContext context, {required Widget child}) {
  final mq = MediaQuery.of(context);
  return MediaQuery(
    data: mq.copyWith(
      textScaler: mq.textScaler.clamp(
        maxScaleFactor: kPremiumSheetMaxTextScale,
      ),
    ),
    child: child,
  );
}

/// Premium modal bottom sheet — tutarlı köşe, yüzey rengi ve tutamaç.
/// İçerik [DraggableScrollableSheet] veya düz [Column] olabilir; üstte [PremiumBottomSheetHandle] kullanın.
Future<T?> showPremiumModalBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  bool isScrollControlled = true,
  bool useSafeArea = false,
  bool useRootNavigator = false,
  bool keyboardAware = true,
  double? maxHeightFactor,
}) {
  if (keyboardAware || maxHeightFactor != null) {
    return showPremiumScrollableBottomSheet<T>(
      context: context,
      builder: builder,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      maxHeightFactor: maxHeightFactor ?? 0.90,
    );
  }
  final ext = AppThemeExtension.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    barrierColor: ext.shadowColor.withValues(alpha: isDark ? 0.52 : 0.18),
    builder: (ctx) => _premiumSheetDecor(
          ctx,
          child: premiumSheetClampContext(ctx, child: builder(ctx)),
        ),
  );
}

/// Tek [DraggableScrollableSheet] — iç içe sürükleme + sabit yükseklik kısıtı yok.
Future<T?> showPremiumDraggableBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context, ScrollController scrollController)
      builder,
  bool useRootNavigator = false,
  double initialChildSize = 0.6,
  double minChildSize = 0.4,
  double maxChildSize = 0.92,
}) {
  final ext = AppThemeExtension.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    barrierColor: ext.shadowColor.withValues(alpha: isDark ? 0.52 : 0.18),
    builder: (ctx) {
      final media = MediaQuery.of(ctx);
      final sheetHeight = media.size.height * maxChildSize;
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: premiumSheetClampContext(
          ctx,
          child: _premiumSheetDecor(
            ctx,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: sheetHeight,
                child: DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: initialChildSize,
                  minChildSize: minChildSize,
                  maxChildSize: 1.0,
                  builder: (sheetCtx, scrollController) =>
                      builder(sheetCtx, scrollController),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Klavye + küçük ekran güvenli modal — maks. yükseklik ve kaydırılabilir gövde için.
Future<T?> showPremiumScrollableBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  bool useSafeArea = true,
  bool useRootNavigator = false,
  double maxHeightFactor = 0.90,
}) {
  final ext = AppThemeExtension.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    barrierColor: ext.shadowColor.withValues(alpha: isDark ? 0.52 : 0.18),
    builder: (ctx) {
      final media = MediaQuery.of(ctx);
      final maxHeight = media.size.height * maxHeightFactor;
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: _premiumSheetDecor(
          ctx,
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: premiumSheetClampContext(ctx, child: builder(ctx)),
            ),
          ),
        ),
      );
    },
  );
}

Widget _premiumSheetDecor(BuildContext context, {required Widget child}) {
  final ext = AppThemeExtension.of(context);
  const r = BorderRadius.vertical(
    top: Radius.circular(DesignTokens.radiusSheet),
  );
  return ClipRRect(
    borderRadius: r,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: r,
        border: Border(
          top: BorderSide(color: ext.border.withValues(alpha: 0.45)),
        ),
        boxShadow: [
          BoxShadow(
            color: ext.shadowColor.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: child,
    ),
  );
}

/// Sabit üst/alt + kaydırılabilir gövde — Column taşmasını önler.
class PremiumScrollableBottomSheetShell extends StatelessWidget {
  const PremiumScrollableBottomSheetShell({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.header,
    this.onClose,
    this.showHandle = true,
    this.showCloseButton = true,
    this.bottomActions,
    this.padding,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? header;
  final VoidCallback? onClose;
  final bool showHandle;
  final bool showCloseButton;
  final Widget? bottomActions;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final edge = padding ??
        const EdgeInsets.fromLTRB(
          DesignTokens.space5,
          0,
          DesignTokens.space5,
          DesignTokens.space3,
        );
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    void close() {
      if (onClose != null) {
        onClose!();
      } else {
        Navigator.of(context).maybePop();
      }
    }

    return premiumSheetClampContext(
      context,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHandle) const PremiumBottomSheetHandle(),
        if (header != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.space5,
              0,
              DesignTokens.space5,
              DesignTokens.space2,
            ),
            child: header,
          )
        else if (title != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.space5,
              0,
              DesignTokens.space5,
              DesignTokens.space2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PremiumSheetHeader(
                    compact: true,
                    title: title!,
                    subtitle: subtitle,
                  ),
                ),
                if (showCloseButton)
                  IconButton(
                    tooltip: 'Kapat',
                    visualDensity: VisualDensity.compact,
                    onPressed: close,
                    icon: Icon(Icons.close_rounded, color: ext.textSecondary),
                  ),
              ],
            ),
          ),
        Flexible(
          child: SingleChildScrollView(
            padding: edge,
            child: child,
          ),
        ),
        if (bottomActions != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.space5,
              DesignTokens.space2,
              DesignTokens.space5,
              DesignTokens.space3 + bottomSafe,
            ),
            child: bottomActions,
          ),
      ],
    ),
    );
  }
}

/// Standart üst tutamaç (bottom sheet / draggable sheet üstünde).
class PremiumBottomSheetHandle extends StatelessWidget {
  const PremiumBottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: DesignTokens.space3,
        bottom: DesignTokens.space3,
      ),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: ext.textTertiary.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Başlık + isteğe bağlı alt başlık — form sayfalarında hiyerarşi.
class PremiumSheetHeader extends StatelessWidget {
  const PremiumSheetHeader({
    super.key,
    required this.title,
    this.subtitle,

    /// Alt sayfa / önizleme gibi dar yüzeylerde daha sakin tipografi.
    this.compact = false,
  });

  final String title;
  final String? subtitle;

  /// Alt sayfa / önizleme gibi dar yüzeylerde daha sakin tipografi.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final titleStyle = compact
        ? AppTypography.cardHeading(context)
            .copyWith(fontSize: DesignTokens.fontSizeLg, height: 1.2)
        : AppTypography.pageHeading(context)
            .copyWith(fontSize: DesignTokens.fontSizeXl);
    final subtitleStyle = compact
        ? AppTypography.body(context).copyWith(
            color: ext.textSecondary,
            fontSize: DesignTokens.fontSizeSm,
            height: 1.45,
          )
        : AppTypography.body(context).copyWith(
            color: ext.textSecondary,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.titleSubtitleGap),
          Text(
            subtitle!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: subtitleStyle,
          ),
        ],
      ],
    );
  }
}
