import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';

/// Ekipler komuta yüzeyi — Kadro / Komuta density ile hizalı.
abstract final class AdminEkiplerTokens {
  AdminEkiplerTokens._();

  static const double horizontal = AdminCommandTokens.horizontal;
  static const double chromeGap = AdminCommandTokens.chromeGap;
  static const double sectionGap = AdminCommandTokens.sectionGap;
  static const double moduleGap = AdminCommandTokens.moduleGap;

  static const double searchHeight = 38;
  static const double filterChipHeight = 32;
  static const double rowMinHeight = 72;
  static const double rowAvatarSize = 38;
  static const double bottomReserve = 108;

  static const double rowTitleSize = 13.5;
  static const double rowMetaSize = 10.5;
  static const double rowChipSize = 9.5;
}
