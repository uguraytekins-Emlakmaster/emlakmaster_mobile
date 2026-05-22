import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Rol/user doc beklerken tam panel yerine hafif iskelet — “Panel hazırlanıyor” hissi azalır.
class ShellBootstrapSkeleton extends StatelessWidget {
  const ShellBootstrapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final line = ext.borderSubtle.withValues(alpha: 0.55);
    final fill = ext.surfaceElevated.withValues(alpha: 0.65);

    Widget bar({double height = 14, double width = double.infinity}) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          border: Border.all(color: line),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DashboardLayoutTokens.horizontalPadding,
            DashboardLayoutTokens.pageTopInset,
            DashboardLayoutTokens.horizontalPadding,
            DesignTokens.space6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              bar(height: 22, width: 220),
              const SizedBox(height: DesignTokens.space3),
              bar(width: 160),
              const SizedBox(height: DesignTokens.space5),
              bar(height: 48),
              const SizedBox(height: DesignTokens.space6),
              Row(
                children: [
                  Expanded(child: bar(height: 56)),
                  const SizedBox(width: DesignTokens.space2),
                  Expanded(child: bar(height: 56)),
                  const SizedBox(width: DesignTokens.space2),
                  Expanded(child: bar(height: 56)),
                ],
              ),
              const Spacer(),
              Align(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ext.accent.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
