import 'package:cloud_functions/cloud_functions.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// `--dart-define=USE_FUNCTIONS_EMULATOR=true` ile Market Pulse callable’ı yerel emülatöre yönlendirir.
/// Önce: `scripts/run_functions_emulator.sh` veya `firebase emulators:start --only functions`
void configureFirebaseFunctionsForDebug() {
  const useEmu = bool.fromEnvironment('USE_FUNCTIONS_EMULATOR');
  if (!kDebugMode || !useEmu) return;
  if (Firebase.apps.isEmpty) return;
  try {
    FirebaseFunctions.instanceFor(region: 'europe-west1').useFunctionsEmulator(
      '127.0.0.1',
      5001,
    );
    if (kDebugMode) {
      debugPrint(
        'Firebase Functions: emulator europe-west1 → 127.0.0.1:5001 (USE_FUNCTIONS_EMULATOR)',
      );
    }
  } catch (e, st) {
    AppLogger.e('Firebase Functions emulator config', e, st);
  }
}
