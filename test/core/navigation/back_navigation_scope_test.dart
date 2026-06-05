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

  // Regresyon: rotanın FocusScope'u (metin alanı olmadan) odaktayken geri
  // basışı sessizce yutulmamalı; sonraki adım (onCustomBack) çalışmalı.
  // Geri tetikleyici sistem/donanım butonu gibi davranır; bu yüzden odağı
  // çalmamak için handler'ı yakalanan context üzerinden doğrudan çağırırız.
  testWidgets(
      'keyboard dismiss step does not swallow back without an editable focus',
      (tester) async {
    var customHandled = false;
    final focusNode = FocusNode();
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: ShellTabBackRegistrar(
          onCustomBack: () {
            customHandled = true;
            return true;
          },
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return Scaffold(
                body: Focus(
                  focusNode: focusNode,
                  child: const Text('content'),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Metin alanı olmayan bir öğeye odaklan: primaryFocus.hasFocus true olur
    // ama EditableText değildir.
    focusNode.requestFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);

    expect(BackNavigationScope.maybeHandle(capturedContext), isTrue);
    expect(customHandled, isTrue);

    focusNode.dispose();
  });
}
