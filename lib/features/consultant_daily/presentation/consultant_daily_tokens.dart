import 'package:emlakmaster_mobile/features/dashboard/presentation/admin_command/admin_command_tokens.dart';

/// Benim Günüm — danışman günlük operasyon yüzeyi yoğunluğu (raporlar/engagement
/// ile hizalı). Header/strip metrikleri AdminCommandTokens'tan paylaşılır.
abstract final class ConsultantDailyTokens {
  ConsultantDailyTokens._();

  static const double horizontal = AdminCommandTokens.horizontal;
  static const double chromeGap = AdminCommandTokens.chromeGap;
  static const double sectionGap = AdminCommandTokens.sectionGap;
  static const double moduleGap = AdminCommandTokens.moduleGap;

  static const double surfaceRadius = 16;
  static const double commandPanelPadding = 15;
  static const double commandEyebrowSize = 9;
  static const double commandDeckDividerGap = 10;
  static const double heroAvatarSize = 44;
  static const double bentoCellHeight = 96;

  static const double bentoValueSize = 22;
  static const double bentoValueSizeCompact = 17;
  static const double summaryCellLabelSize = 9;

  static const double searchHeight = 40;
  static const double filterChipHeight = 34;
  static const double rowMinHeight = 78;
  static const double rowIconSize = 38;
  static const double bottomReserve = 112;

  static const double rowTitleSize = 13.5;
  static const double rowMetaSize = 10.5;
  static const double rowChipSize = 9.5;

  static const double sectionAccentWidth = 2;
  static const double sectionAccentHeight = 14;
}
