import 'package:emlakmaster_mobile/core/navigation/back_navigation_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('clears selection before custom back', (tester) async {
    var selectionCleared = false;
    var customHandled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: BackNavigationScope(
          onClearSelection: () {
            selectionCleared = true;
            return true;
          },
          onCustomBack: () {
            customHandled = true;
            return true;
          },
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    BackNavigationScope.maybeHandle(context);
                  },
                  child: const Text('back'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('back'));
    await tester.pump();

    expect(selectionCleared, isTrue);
    expect(customHandled, isFalse);
  });
}
