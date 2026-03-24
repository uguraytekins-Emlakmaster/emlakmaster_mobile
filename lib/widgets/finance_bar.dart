import 'dart:math' as math;

import 'package:emlakmaster_mobile/core/services/app_lifecycle_power_service.dart';
import 'package:emlakmaster_mobile/core/services/finance_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ekonomi (B): Yahoo / TCMB — [AppThemeExtension] ile light/dark uyumlu kartlar.
class FinanceBar extends StatelessWidget {
  const FinanceBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const FinanceBarLive();
  }
}

class FinanceBarLive extends StatelessWidget {
  const FinanceBarLive({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space6),
      child: StreamBuilder<FinanceRates>(
        stream: FinanceService.ratesStream,
        initialData: FinanceService.getCached(),
        builder: (context, snapshot) {
          final rates = snapshot.data;
          bool hasValidRates(FinanceRates? r) {
            if (r == null) return false;
            return r.usdTry > 0 || r.eurTry > 0 || r.gramGoldTry > 0;
          }

          final awaitingFirst =
              rates == null && snapshot.connectionState == ConnectionState.waiting;
          final awaitingValidRates = rates != null &&
              !hasValidRates(rates) &&
              snapshot.connectionState == ConnectionState.waiting;
          if (awaitingFirst || awaitingValidRates) {
            return _FinanceBarShimmer(ext: ext);
          }

          String fmtUsd() => (rates != null && rates.usdTry > 0)
              ? rates.usdTry.toStringAsFixed(2)
              : '—';
          String fmtEur() => (rates != null && rates.eurTry > 0)
              ? rates.eurTry.toStringAsFixed(2)
              : '—';
          final goldStr = rates != null && rates.gramGoldTry > 0
              ? rates.gramGoldTry.toStringAsFixed(2)
              : '—';

          final usdSeries =
              FinanceService.sparklineUsdTry(rates?.usdTry ?? 34.0);
          final eurSeries =
              FinanceService.sparklineEurTry(rates?.eurTry ?? 36.0);
          final goldSeries =
              FinanceService.sparklineGramGoldTry(rates?.gramGoldTry ?? 2800);

          final usdDense = FinanceService.densifySeries(usdSeries);
          final eurDense = FinanceService.densifySeries(eurSeries);
          final goldDense = FinanceService.densifySeries(goldSeries);

          final liveColor = ext.success;

          final items = <_EconomyCardData>[
            _EconomyCardData(
              label: 'USD/TRY',
              prefixSymbol: r'$',
              mainValue: fmtUsd(),
              suffixSymbol: '₺',
              sparkline: usdDense,
            ),
            _EconomyCardData(
              label: 'EUR/TRY',
              prefixSymbol: '€',
              mainValue: fmtEur(),
              suffixSymbol: '₺',
              sparkline: eurDense,
            ),
            _EconomyCardData(
              label: 'XAU/TRY',
              labelHint: 'gram',
              prefixSymbol: '',
              mainValue: goldStr,
              suffixSymbol: '₺',
              sparkline: goldDense,
            ),
          ];

          final outerBg = Color.alphaBlend(
            ext.foreground.withValues(alpha: 0.04),
            ext.chartBackground,
          );

          return ClipRRect(
            borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardL),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ColoredBox(color: outerBg),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _NoiseTexturePainter(
                        seed: 42,
                        opacity: 0.05,
                        dotColor: ext.foreground,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (snapshot.hasError)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Veriler güncelleniyor…',
                            style: GoogleFonts.inter(
                              color: ext.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      _EconomyLiveHeader(
                        dataSource: rates?.dataSource,
                        liveColor: liveColor,
                        ext: ext,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < items.length; i++)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: i < items.length - 1 ? 10 : 0,
                                ),
                                child: _EconomyFintechCard(
                                  data: items[i],
                                  ext: ext,
                                  liveColor: liveColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EconomyCardData {
  const _EconomyCardData({
    required this.label,
    this.labelHint,
    required this.prefixSymbol,
    required this.mainValue,
    required this.suffixSymbol,
    required this.sparkline,
  });

  final String label;
  final String? labelHint;
  final String prefixSymbol;
  final String mainValue;
  final String suffixSymbol;
  final List<double> sparkline;
}

class _NoiseTexturePainter extends CustomPainter {
  _NoiseTexturePainter({
    required this.seed,
    required this.opacity,
    required this.dotColor,
  });

  final int seed;
  final double opacity;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rnd = math.Random(seed);
    final count = (size.width * size.height * 0.018).round().clamp(120, 2800);
    final paint = Paint()..color = dotColor.withValues(alpha: opacity);
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = 0.35 + rnd.nextDouble() * 0.85;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NoiseTexturePainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.opacity != opacity ||
        oldDelegate.dotColor != dotColor;
  }
}

class _EconomyLiveHeader extends StatefulWidget {
  const _EconomyLiveHeader({
    this.dataSource,
    required this.liveColor,
    required this.ext,
  });

  final String? dataSource;
  final Color liveColor;
  final AppThemeExtension ext;

  @override
  State<_EconomyLiveHeader> createState() => _EconomyLiveHeaderState();
}

class _EconomyLiveHeaderState extends State<_EconomyLiveHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    final reduce = AppLifecyclePowerService.shouldReduceMotion;
    _pulse = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: reduce ? 0 : 1600),
    );
    if (!reduce) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppLifecyclePowerService.shouldReduceMotion;
    final ext = widget.ext;
    final src = widget.dataSource;
    final srcLabel = src == 'TCMB'
        ? 'TCMB · resmi XML'
        : src == 'exchangerate.host'
            ? 'ExchangeRate (ücretsiz katman)'
            : src == 'yahoo-node'
                ? 'Yahoo Finance (Node · ücretsiz)'
                : null;

    final dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.liveColor,
        boxShadow: [
          BoxShadow(
            color: widget.liveColor.withValues(alpha: 0.75),
            blurRadius: 10,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );

    final canliStyle = _sfProDisplayLabel(
      context,
      fontSize: 11,
      letterSpacing: 1.4,
      fontWeight: FontWeight.w600,
      color: widget.liveColor,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ekonomi',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  color: ext.textSecondary,
                ),
              ),
              if (srcLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    srcLabel,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      height: 1.2,
                      color: ext.textTertiary.withValues(alpha: 0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reduce)
                  dot
                else
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      final o = 0.5 + _pulse.value * 0.5;
                      return Opacity(opacity: o, child: dot);
                    },
                  ),
                const SizedBox(width: 8),
                Text('CANLI', style: canliStyle),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

TextStyle _sfProDisplayLabel(
  BuildContext context, {
  required double fontSize,
  required double letterSpacing,
  required FontWeight fontWeight,
  required Color color,
}) {
  final useSf = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
  if (useSf) {
    return TextStyle(
      fontFamily: '.SF Pro Display',
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
      height: 1.0,
    );
  }
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    color: color,
    height: 1.0,
  );
}

TextStyle _sfProDisplayNumber(
  BuildContext context, {
  required double fontSize,
  required Color color,
}) {
  final useSf = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
  if (useSf) {
    return TextStyle(
      fontFamily: '.SF Pro Display',
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.65,
      color: color,
      height: 1.0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: color,
    height: 1.0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

class _EconomyFintechCard extends StatelessWidget {
  const _EconomyFintechCard({
    required this.data,
    required this.ext,
    required this.liveColor,
  });

  final _EconomyCardData data;
  final AppThemeExtension ext;
  final Color liveColor;

  @override
  Widget build(BuildContext context) {
    final numStyle = _sfProDisplayNumber(context, fontSize: 17, color: ext.textPrimary);
    final symStyle = GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: ext.textTertiary.withValues(alpha: 0.85),
      height: 1,
    );

    return Container(
      decoration: BoxDecoration(
        color: ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
        boxShadow: [
          BoxShadow(
            color: ext.shadowColor.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: ext.shadowColor.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.label,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.35,
                      color: ext.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (data.labelHint != null)
                  Text(
                    data.labelHint!,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: ext.textTertiary.withValues(alpha: 0.65),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (data.prefixSymbol.isNotEmpty) ...[
                    Text(data.prefixSymbol, style: symStyle),
                    const SizedBox(width: 2),
                  ],
                  Text(data.mainValue, style: numStyle),
                  Text(' ${data.suffixSymbol}', style: symStyle),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 28,
              width: double.infinity,
              child: CustomPaint(
                painter: _NeonAreaSparklinePainter(
                  values: data.sparkline,
                  neonColor: liveColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeonAreaSparklinePainter extends CustomPainter {
  _NeonAreaSparklinePainter({
    required this.values,
    required this.neonColor,
  });

  final List<double> values;
  final Color neonColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final span = (maxV - minV).abs() < 1e-9 ? 1e-9 : (maxV - minV);

    final linePath = Path();
    for (var i = 0; i < values.length; i++) {
      final t = i / (values.length - 1);
      final x = t * size.width;
      final norm = (values[i] - minV) / span;
      final y = size.height * (1 - 0.1 - norm * 0.8);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          neonColor.withValues(alpha: 0.38),
          neonColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final glowPaint = Paint()
      ..color = neonColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final linePaint = Paint()
      ..color = neonColor.withValues(alpha: 0.98)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, glowPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _NeonAreaSparklinePainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    if (oldDelegate.neonColor != neonColor) return true;
    for (var i = 0; i < values.length; i++) {
      if (values[i] != oldDelegate.values[i]) return true;
    }
    return false;
  }
}

class _FinanceBarShimmer extends StatelessWidget {
  const _FinanceBarShimmer({required this.ext});

  final AppThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardL),
      child: Container(
        color: Color.alphaBlend(
          ext.foreground.withValues(alpha: 0.04),
          ext.chartBackground,
        ),
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerPlaceholder(
                  width: 56,
                  height: 10,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                ),
                const Spacer(),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ext.foreground.withValues(alpha: 0.12),
                  ),
                ),
                const SizedBox(width: 8),
                ShimmerPlaceholder(
                  width: 36,
                  height: 10,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                        decoration: BoxDecoration(
                          color: ext.surfaceElevated,
                          borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardM),
                          boxShadow: [
                            BoxShadow(
                              color: ext.shadowColor.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerPlaceholder(
                              width: 44,
                              height: 10,
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                            ),
                            SizedBox(height: 10),
                            ShimmerPlaceholder(
                              width: 64,
                              height: 18,
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                            ),
                            SizedBox(height: 10),
                            ShimmerPlaceholder(
                              width: 72,
                              height: 28,
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
