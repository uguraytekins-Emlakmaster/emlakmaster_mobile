import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';

/// Üyelikler / Davetler komuta yüzeyi — Kadro / İşlem Kayıtları density ile hizalı.
abstract final class AdminUyeliklerTokens {
  AdminUyeliklerTokens._();

  static const double horizontal = AdminCommandTokens.horizontal;
  static const double chromeGap = AdminCommandTokens.chromeGap;
  static const double sectionGap = AdminCommandTokens.sectionGap;
  static const double moduleGap = AdminCommandTokens.moduleGap;

  static const double searchHeight = 38;
  static const double filterChipHeight = 32;
  static const double rowMinHeight = 70;
  static const double rowIconSize = 34;
  static const double bottomReserve = 108;

  static const double rowTitleSize = 13;
  static const double rowMetaSize = 10.5;
  static const double rowChipSize = 9.5;
}
