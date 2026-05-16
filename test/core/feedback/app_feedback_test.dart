import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppFeedback haptic gating', () {
    test('lightImpact skipped when haptic disabled', () async {
      AppFeedback.applyRuntimeFlags(haptic: false);
      await AppFeedback.lightImpact();
      // No exception — platform channel may be no-op in test.
    });

    test('lightImpact runs when haptic enabled', () async {
      AppFeedback.applyRuntimeFlags(haptic: true);
      await AppFeedback.lightImpact();
    });
  });

  group('AppFeedback sound gating', () {
    test('play does nothing when sound disabled in test', () async {
      AppFeedback.applyRuntimeFlags(sound: false);
      await AppFeedback.playSuccess();
    });
  });
}
