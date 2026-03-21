import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Premium tam ekran analiz yükleyici.
class AnalyzingIntelOverlay extends StatelessWidget {
  const AnalyzingIntelOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: DesignTokens.antiqueGold,
                backgroundColor: DesignTokens.antiqueGold.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: DesignTokens.space6),
            const Text(
              'Piyasa verileri analiz ediliyor…',
              style: TextStyle(
                color: Colors.white,
                fontSize: DesignTokens.fontSizeMd,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Rainbow Investment Intelligence',
              style: TextStyle(
                color: DesignTokens.antiqueGold.withValues(alpha: 0.9),
                fontSize: DesignTokens.fontSizeSm,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
