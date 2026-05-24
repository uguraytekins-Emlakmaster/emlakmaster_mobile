import 'package:emlakmaster_mobile/core/theme/app_theme.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_color_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PremiumThemeExtension registered on dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) {
            final premium = PremiumThemeExtension.of(context);
            expect(premium.isDark, isTrue);
            expect(premium.champagneGold, PremiumColorTokens.champagneGold);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  test('Premium color tokens match Figma DNA anchors', () {
    expect(PremiumColorTokens.obsidian, const Color(0xFF050506));
    expect(PremiumColorTokens.champagneGold, const Color(0xFFC9A962));
    expect(PremiumColorTokens.midnightNavy, const Color(0xFF0B0F17));
  });
}
