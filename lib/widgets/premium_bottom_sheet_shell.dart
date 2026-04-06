import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Premium modal bottom sheet — tutarlı köşe, yüzey rengi ve tutamaç.
/// İçerik [DraggableScrollableSheet] veya düz [Column] olabilir; üstte [PremiumBottomSheetHandle] kullanın.
Future<T?> showPremiumModalBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  bool isScrollControlled = true,
  bool useSafeArea = false,
}) {
  final ext = AppThemeExtension.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.52),
    builder: (ctx) {
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
          child: builder(ctx),
        ),
      );
    },
  );
}

/// Standart üst tutamaç (bottom sheet / draggable sheet üstünde).
class PremiumBottomSheetHandle extends StatelessWidget {
  const PremiumBottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(
          top: DesignTokens.space3, bottom: DesignTokens.space2),
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
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTypography.pageHeading(context)
              .copyWith(fontSize: DesignTokens.fontSizeXl),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.titleSubtitleGap),
          Text(
            subtitle!,
            style: AppTypography.body(context).copyWith(
              color: ext.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
