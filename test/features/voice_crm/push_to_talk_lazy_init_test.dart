import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/features/voice_crm/presentation/widgets/push_to_talk_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PushToTalkButton builds without initializing speech on mount',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: PushToTalkButton(
            onSpeechResult: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(PushToTalkButton), findsOneWidget);
  });
}
