import 'package:emlakmaster_mobile/core/performance/startup_perf_markers.dart';
import 'package:emlakmaster_mobile/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Otomatik soğuk-açılış baseline — `CAPTURE_STARTUP_PERF=true` ile çalıştırın.
///
/// macOS profile imzası yoksa CI/agent bu testi kullanır (debug binding; karşılaştırma
/// için aynı makinede profile ölçümü tercih edilir).
@pragma('vm:entry-point')
void main() {
  if (!const bool.fromEnvironment('CAPTURE_STARTUP_PERF')) {
    return;
  }

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test-key',
          appId: '1:test:test',
          messagingSenderId: 'test',
          projectId: 'test-project',
          storageBucket: 'test-project.appspot.com',
        ),
      );
    } catch (_) {}
  });

  testWidgets('capture startup milestones and first frame', (tester) async {
    StartupPerfMarkers.resetForTest();
    StartupPerfMarkers.once('main_entered');

    StartupPerfMarkers.once('bootstrap_parallel_done');

    StartupPerfMarkers.once('run_app');
    await tester.pumpWidget(
      const ProviderScope(child: EmlakMasterApp()),
    );
    await tester.pump();
    StartupPerfMarkers.once('first_frame');

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  });
}
