import 'package:emlakmaster_mobile/core/onboarding/tour_target.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/widgets/raporlar_command_surface.dart';
import 'package:emlakmaster_mobile/screens/providers/admin_reports_perf_provider.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Raporlar — executive reporting hub (Screen 19).
/// Tüm yayınlanmış yönetici yüzeylerini tek navigasyonel komuta yüzeyinde toplar.
class AdminReportsPage extends ConsumerWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: TourTarget(
          id: TourTargetId.managerReports,
          child: ShellScreenReadyListener(
            screenName: 'admin_reports',
            provider: adminReportsPerfProvider,
            child: const SafeArea(
              child: RaporlarCommandSurface(),
            ),
          ),
        ),
      ),
    );
  }
}
