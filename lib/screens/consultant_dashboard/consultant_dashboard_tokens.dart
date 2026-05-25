import 'package:flutter/material.dart';

/// Günüm — Apple premium density tokens.
abstract final class ConsultantDashboardTokens {
  ConsultantDashboardTokens._();

  static const double horizontal = 16;
  static const double topInset = 10;
  static const double sectionGap = 12;
  static const double blockGap = 10;
  static const double kpiCellGap = 6;
  static const double quickNavHeight = 52;
  static const double heroAvatarSize = 44;
  static const double kpiValueSize = 22;
  static const double goldRailHeight = 3;
  static const double sectionHeaderBottom = 6;

  static const EdgeInsets heroPadding =
      EdgeInsets.fromLTRB(14, 13, 12, 11);
  static const EdgeInsets kpiCellPadding =
      EdgeInsets.symmetric(horizontal: 10, vertical: 11);
  static const EdgeInsets quickNavCellPadding =
      EdgeInsets.symmetric(horizontal: 8, vertical: 11);
}
