import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';

/// Savaş odası — executive intervention density (Screen 9 ile hizalı).
abstract final class WarRoomTokens {
  WarRoomTokens._();

  static const double horizontal = AdminCommandTokens.horizontal;
  static const double moduleGap = AdminCommandTokens.moduleGap;
  static const double sectionGap = AdminCommandTokens.sectionGap;
  static const double chromeGap = AdminCommandTokens.chromeGap;

  static const double crisisStripHeight = AdminCommandTokens.summaryStripHeight;
  static const double laneHeight = 64;
  static const double interventionRowHeight = 58;
  static const double routeTileHeight = AdminCommandTokens.routeTileHeight;

  static const double sectionLabelSize = AdminCommandTokens.sectionLabelSize;
  static const double laneTitleSize = 12;
  static const double laneMetaSize = 10;
  static const double interventionTitleSize = 12;
  static const double interventionMetaSize = 10;

  /// Alt dock + geri kazanım şeridi için scroll payı.
  static const double bottomReserve = 120;
}
