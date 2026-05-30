import 'package:flutter/material.dart';

/// Yönetici komuta katmanı — executive mobile-first density.
abstract final class AdminCommandTokens {
  AdminCommandTokens._();

  static const double horizontal = 16;
  static const double topInset = 0;
  static const double headerBottomGap = 6;
  static const double chromeGap = 5;
  static const double sectionGap = 10;
  static const double moduleGap = 6;

  static const double headerEmblemSize = 34;
  static const double headerTitleSize = 19;
  static const double headerSubtitleSize = 12;

  static const double headerDateFontSize = 11;
  static const double headerActionIconSize = 24;
  static const double headerAvatarSize = 40;
  static const double headerActionTap = 44;

  /// Üst sağlık / kriz şeridi metrik yoğunluğu.
  static const double summaryStripHeight = 54;
  static const double metricValueSize = 14;
  static const double metricLabelSize = 9.5;
  static const double adminMetricLabelBoost = 0.5;
  static const double honestyNoteSize = 10.5;
  static const double sectionSecondarySize = 10.5;
  static const double intelLineSize = 11;
  static const double intelLineGap = 6;
  static const double intelLineHeight = 1.28;
  static const double intelCriticalLineHeight = 1.34;
  static const double intelCardPaddingH = 10;
  static const double intelCardPaddingV = 9;

  static const double urgentBlockHeight = 56;
  static const double routeTileHeight = 52;

  static const double sectionLabelSize = 11;
  static const double urgentTitleSize = 12.5;
  static const double urgentMetaSize = 10;

  /// iPhone-first header rhythm; scales slightly on wider phones.
  static AdminCommandHeaderMetrics headerMetrics(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 392;
    final widePhone = width >= 420;

    return AdminCommandHeaderMetrics(
      topInset: 0,
      bottomGap: compact ? 6 : 7,
      horizontal: horizontal,
      emblemSize: compact ? 32 : (widePhone ? 36 : 34),
      emblemPad: compact ? 7 : 8,
      titleGap: compact ? 9 : 10,
      titleSize: compact ? 18.5 : (widePhone ? 20 : 19),
      subtitleSize: compact ? 11.5 : 12,
      titleToSubtitleGap: 3,
      honestyTopGap: 5,
      dateFontSize: compact ? 10.5 : 11,
      actionIconSize: 24,
      avatarSize: 40,
      actionTap: 44,
      controlRailGap: 4,
    );
  }

  /// Approximate chrome height for QA notes (excludes honesty pill).
  static double estimateHeaderRowHeight(AdminCommandHeaderMetrics m) {
    final emblemBlock = m.emblemSize + m.emblemPad * 2;
    final titleBlock =
        m.titleSize * 1.05 + m.titleToSubtitleGap + m.subtitleSize * 1.15;
    final rail = 22 + m.controlRailGap + m.actionTap;
    return [emblemBlock, titleBlock, rail].reduce((a, b) => a > b ? a : b);
  }

  /// Telefon genişliğine göre üst şerit metrik vurgusu.
  static AdminCommandStripTypography stripTypography(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 392;
    final widePhone = width >= 430;

    return AdminCommandStripTypography(
      valueSize: compact ? 13.5 : (widePhone ? 14.5 : metricValueSize),
      labelSize: compact ? 9 : (widePhone ? 10 : metricLabelSize),
      dividerHeight: compact ? 28 : 30,
    );
  }

  /// Admin komuta üst şeridi — etiketler bir adım daha okunaklı.
  static AdminCommandStripTypography adminStripTypography(BuildContext context) {
    final base = stripTypography(context);
    return AdminCommandStripTypography(
      valueSize: base.valueSize,
      labelSize: base.labelSize + adminMetricLabelBoost,
      dividerHeight: base.dividerHeight,
    );
  }
}

@immutable
class AdminCommandHeaderMetrics {
  const AdminCommandHeaderMetrics({
    required this.topInset,
    required this.bottomGap,
    required this.horizontal,
    required this.emblemSize,
    required this.emblemPad,
    required this.titleGap,
    required this.titleSize,
    required this.subtitleSize,
    required this.titleToSubtitleGap,
    required this.honestyTopGap,
    required this.dateFontSize,
    required this.actionIconSize,
    required this.avatarSize,
    required this.actionTap,
    required this.controlRailGap,
  });

  final double topInset;
  final double bottomGap;
  final double horizontal;
  final double emblemSize;
  final double emblemPad;
  final double titleGap;
  final double titleSize;
  final double subtitleSize;
  final double titleToSubtitleGap;
  final double honestyTopGap;
  final double dateFontSize;
  final double actionIconSize;
  final double avatarSize;
  final double actionTap;
  final double controlRailGap;

  double get rowHeight => AdminCommandTokens.estimateHeaderRowHeight(this);
}

@immutable
class AdminCommandStripTypography {
  const AdminCommandStripTypography({
    required this.valueSize,
    required this.labelSize,
    required this.dividerHeight,
  });

  final double valueSize;
  final double labelSize;
  final double dividerHeight;
}
