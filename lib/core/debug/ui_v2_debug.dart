import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/premium/premium_color_tokens.dart';

/// Debug-only proof that premium UI (Phase 2+) widgets are mounted.
/// Never shown in release/profile builds.
void logUiV2Active(String screenName, {String? detail}) {
  if (!kDebugMode) return;
  final extra = detail == null || detail.isEmpty ? '' : ' · $detail';
  debugPrint('[UI_V2_ACTIVE] $screenName build$extra');
}

/// Tiny overlay badge — top-left, non-interactive.
class UiV2DebugBadge extends StatelessWidget {
  const UiV2DebugBadge({
    super.key,
    required this.screenName,
    this.detail,
  });

  final String screenName;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final top = MediaQuery.paddingOf(context).top + 4;
    final text = detail == null || detail!.isEmpty
        ? 'UI v2 active · $screenName'
        : 'UI v2 active · $screenName · $detail';
    return Positioned(
      top: top,
      left: 8,
      right: 8,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: PremiumColorTokens.midnightNavy.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: PremiumColorTokens.champagneGold.withValues(alpha: 0.55),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                text,
                style: const TextStyle(
                  color: PremiumColorTokens.champagneGoldLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps [child] with optional debug badge + build log.
class UiV2DebugScope extends StatelessWidget {
  const UiV2DebugScope({
    super.key,
    required this.screenName,
    required this.child,
    this.detail,
    this.logOnBuild = true,
  });

  final String screenName;
  final String? detail;
  final Widget child;
  final bool logOnBuild;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode && logOnBuild) {
      logUiV2Active(screenName, detail: detail);
    }
    if (!kDebugMode) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        UiV2DebugBadge(screenName: screenName, detail: detail),
      ],
    );
  }
}
