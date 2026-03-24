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
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => DevDebugPanel.show(context),
          borderRadius: BorderRadius.circular(20),
          // [Tooltip] needs an [Overlay] ancestor (inside [Navigator]). This badge
          // is painted in [MaterialApp.builder]'s [Stack] *beside* the navigator, so
          // use [Semantics] instead — same a11y label, no RawTooltip / Overlay.
          child: Semantics(
            label: 'Geliştirme modu · debug paneli',
            button: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppThemeExtension.of(context).accent.withValues(alpha: 0.5),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF252530).withValues(alpha: 0.94),
                    const Color(0xFF141418).withValues(alpha: 0.96),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppThemeExtension.of(context).accent.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.developer_mode_rounded,
                      size: 13,
                      color: AppThemeExtension.of(context).accent.withValues(alpha: 0.95),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'DEV',
                      style: TextStyle(
                        color: AppThemeExtension.of(context).accent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
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
