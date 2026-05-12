import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
/// Premium tam ekran analiz yükleyici.
class AnalyzingIntelOverlay extends StatelessWidget {
  const AnalyzingIntelOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: ext.background.withValues(alpha: isDark ? 0.94 : 0.78),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space6,
            vertical: DesignTokens.space6,
          ),
          decoration: BoxDecoration(
            color: ext.surface.withValues(alpha: isDark ? 0.9 : 0.96),
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(color: ext.border.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: ext.shadowColor.withValues(alpha: isDark ? 0.34 : 0.14),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: ext.accent,
                  backgroundColor: ext.accent.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: DesignTokens.space6),
              Text(
                'Piyasa verileri analiz ediliyor…',
                style: TextStyle(
                  color: ext.textPrimary,
                  fontSize: DesignTokens.fontSizeMd,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.space2),
              Text(
                'Rainbow Investment Intelligence',
                style: TextStyle(
                  color: ext.accent.withValues(alpha: 0.9),
                  fontSize: DesignTokens.fontSizeSm,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
