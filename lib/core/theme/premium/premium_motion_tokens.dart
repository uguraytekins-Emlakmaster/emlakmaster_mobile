import 'package:flutter/animation.dart';

/// iOS-grade motion curves and durations for premium interactions.
abstract final class PremiumMotionTokens {
  PremiumMotionTokens._();

  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration sheet = Duration(milliseconds: 340);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.easeOutBack;
  static const Curve decelerate = Curves.decelerate;

  static const double pressScale = 0.97;
  static const double dockLift = 4.0;
}
