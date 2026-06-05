import 'package:emlakmaster_mobile/core/navigation/shell_tab_back_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regresyon: rotanın FocusScope'u (metin alanı olmadan) odaktayken
  // handleBack klavye adımı geri'yi sessizce yutmamalı; sonraki adım
  // (onCustomBack) çalışmalı.
  testWidgets('handleBack does not swallow back without an editable focus',
      (tester) async {
    var customHandled = false;
    final focusNode = FocusNode();
    final bindingKey = GlobalKey<ShellTabBackBindingState>();

    await tester.pumpWidget(
      MaterialApp(
        home: ShellTabBackBinding(
          key: bindingKey,
          onCustomBack: () {
            customHandled = true;
            return true;
          },
          child: Scaffold(
            body: Focus(
              focusNode: focusNode,
              child: const Text('content'),
            ),
          ),
        ),
      ),
    );

    // Metin alanı olmayan bir öğeye odaklan: primaryFocus.hasFocus true olur
    // ama EditableText değildir.
    focusNode.requestFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);

    expect(bindingKey.currentState!.handleBack(), isTrue);
    expect(customHandled, isTrue);

    focusNode.dispose();
  });
}
