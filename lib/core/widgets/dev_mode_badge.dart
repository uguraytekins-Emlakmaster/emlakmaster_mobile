import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/config/dev_mode_config.dart';
import 'package:emlakmaster_mobile/core/widgets/dev_debug_panel.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
/// Kompakt **DEV** rozeti — yalnızca `!kReleaseMode && isDevMode`.
///
/// [Stack] içinde kullanın; düzen yüksekliği tüketmez, içerik üzerine bindirilir.
/// `Positioned` + `MediaQuery.padding` ile çentik/status bar ile çakışma azaltılır.
class DevModeBadge extends ConsumerWidget {
  const DevModeBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    const show = !kReleaseMode && isDevMode;
    if (!show) return const SizedBox.shrink();

    final pad = MediaQuery.paddingOf(context);
    final textDir = Directionality.of(context);

    return Positioned.directional(
      textDirection: textDir,
      top: pad.top + 6,
      end: 10,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => DevDebugPanel.show(context),
          borderRadius: BorderRadius.circular(14),
          // [Tooltip] needs an [Overlay] ancestor (inside [Navigator]). This badge
          // is painted in [MaterialApp.builder]'s [Stack] *beside* the navigator, so
          // use [Semantics] instead — same a11y label, no RawTooltip / Overlay.
          child: Semantics(
            label: 'Geliştirme modu · debug paneli',
            button: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppThemeExtension.of(context).border.withValues(alpha: 0.65),
                ),
                color: AppThemeExtension.of(context).surface.withValues(alpha: 0.82),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.developer_mode_rounded,
                      size: 11,
                      color: AppThemeExtension.of(context).textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'DEV',
                      style: TextStyle(
                        color: AppThemeExtension.of(context).textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
