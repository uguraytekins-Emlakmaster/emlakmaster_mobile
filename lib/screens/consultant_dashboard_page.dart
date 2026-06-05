import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/providers/consultant_daily_provider.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_types.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/widgets/consultant_daily_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Danışman paneli — Benim Günüm günlük operasyon yüzeyi (Screen 21).
/// Tab kimliği korunur (consultant shell index 0 · 'summary' · "Günüm").
/// Yalnızca gerçek, danışmana scoped sinyaller: görev (vade türetilir), atanmış
/// müşteri (lifecycle + deterministik heat) ve bugünkü temas. Uydurma performans
/// skoru / AI koçluk / verimlilik trendi yok.
class ConsultantDashboardPage extends ConsumerWidget {
  const ConsultantDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      return PremiumShellBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: RepaintBoundary(
              child: ShellScreenReadyListener(
                screenName: 'consultant_dashboard',
                provider: consultantDailySnapshotProvider,
                itemCount: (value) => value is ConsultantDailySnapshot
                    ? value.entries.length
                    : null,
                child: const ConsultantDailySurface(),
              ),
            ),
          ),
        ),
      );
    } catch (e, st) {
      AppLogger.e('ConsultantDashboardPage build', e, st);
      final ext = AppThemeExtension.of(context);
      return Material(
        color: ext.background,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: ext.accent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Danışman paneli hazırlanamadı',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ext.textPrimary,
                      fontSize: DesignTokens.fontSizeLg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ekran yüklenirken bir sorun oluştu. Uygulama kabuğu aktif; '
                    'ana sekmeler kullanılmaya devam edebilir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ext.textSecondary,
                      fontSize: DesignTokens.fontSizeSm,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
