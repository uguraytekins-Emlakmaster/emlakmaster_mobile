import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:emlakmaster_mobile/core/services/app_lifecycle_power_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
/// Veri yokken "laboratuvar çalışıyor" hissi: radar animasyonu + dönen durum metinleri.
/// Arka planda animasyon duraklatılır (pil / performans).
class OpportunityRadarLaboratoryEmpty extends StatefulWidget {
  const OpportunityRadarLaboratoryEmpty({super.key});

  @override
  State<OpportunityRadarLaboratoryEmpty> createState() =>
      _OpportunityRadarLaboratoryEmptyState();
}

class _OpportunityRadarLaboratoryEmptyState extends State<OpportunityRadarLaboratoryEmpty>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _radarController;
  Timer? _messageTimer;
  int _messageIndex = 0;

  static const _messages = <String>[
    'Algoritma 3 yeni ilan tarıyor…',
    'Lead kuyruğu ve sessiz müşteriler eşleniyor…',
    'War Room için sinyal biriktiriliyor…',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final reduce = AppLifecyclePowerService.shouldReduceMotion;
    _radarController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: reduce ? 5000 : 2800),
    );
    _startAnimations();
  }

  void _startAnimations() {
    if (!mounted) return;
    final reduce = AppLifecyclePowerService.shouldReduceMotion;
    if (!reduce && !_radarController.isAnimating) {
      _radarController.repeat();
    }
    _messageTimer?.cancel();
    final interval = Duration(seconds: reduce ? 5 : 3);
    _messageTimer = Timer.periodic(interval, (_) {
      if (!mounted) return;
      setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
    });
  }

  void _stopAnimations() {
    _messageTimer?.cancel();
    _messageTimer = null;
    _radarController.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _startAnimations();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _stopAnimations();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAnimations();
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final reduce = AppLifecyclePowerService.shouldReduceMotion;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: reduce
                ? Icon(
                    Icons.radar_rounded,
                    color: ext.success,
                    size: 36,
                  )
                : AnimatedBuilder(
                    animation: _radarController,
                    builder: (ctx, _) {
                      final t = _radarController.value * 2 * math.pi;
                      final pulseExt = AppThemeExtension.of(ctx);
                      return CustomPaint(
                        painter: _RadarPulsePainter(phase: t, successColor: pulseExt.success),
                        child: Center(
                          child: Icon(
                            Icons.radar_rounded,
                            color: pulseExt.success,
                            size: 26,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: DesignTokens.durationNormal,
                  child: Text(
                    _messages[_messageIndex],
                    key: ValueKey<int>(_messageIndex),
                    style: TextStyle(
                      color: ext.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Öne çıkan fırsat geldiğinde burada göreceksiniz.',
                  style: TextStyle(
                    color: ext.textTertiary.withValues(alpha: 0.9),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPulsePainter extends CustomPainter {
  _RadarPulsePainter({required this.phase, required this.successColor});

  final double phase;
  final Color successColor;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide / 2;

    for (var i = 0; i < 3; i++) {
      final wave = (phase / (2 * math.pi) + i * 0.33) % 1.0;
      final r = maxR * (0.35 + 0.65 * wave);
      final opacity = (1 - wave) * 0.45;
      final paint = Paint()
        ..color = successColor.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(c, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPulsePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.successColor != successColor;
  }
}
