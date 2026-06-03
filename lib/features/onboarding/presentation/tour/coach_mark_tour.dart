import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:flutter/material.dart';

/// Tek bir tur adımı — gerçek bir arayüz öğesine [targetKey] ile bağlanır.
class CoachMarkStep {
  const CoachMarkStep({
    required this.targetKey,
    required this.icon,
    required this.title,
    required this.body,
  });

  final GlobalKey targetKey;
  final IconData icon;
  final String title;
  final String body;
}

/// Coach-mark / spotlight turunu Navigator alt ağacındaki [Overlay] üzerinde
/// gösterir (kök Overlay'e dokunmaz; bkz. main.dart uyarısı). Atlanabilir ve
/// tamamlandığında/atlandığında [onCompleted] bir kez çağrılır.
class CoachMarkTour {
  CoachMarkTour._();

  static OverlayEntry? _entry;

  static bool get isShowing => _entry != null;

  /// Turu başlatır. [steps] içinde o an ekranda bulunmayan hedefler atlanır.
  /// Görünür hedef yoksa tur açılmaz ve [onCompleted] hemen çağrılır.
  static void show(
    BuildContext context, {
    required List<CoachMarkStep> steps,
    required VoidCallback onCompleted,
  }) {
    if (_entry != null) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final visible =
        steps.where((s) => s.targetKey.currentContext != null).toList();
    if (visible.isEmpty) {
      onCompleted();
      return;
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CoachMarkOverlay(
        steps: visible,
        onClose: () {
          if (_entry == entry) _entry = null;
          if (entry.mounted) entry.remove();
          onCompleted();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  /// Açık turu temizler (ör. ekran kapanırken).
  static void dismiss() {
    final entry = _entry;
    _entry = null;
    if (entry != null && entry.mounted) entry.remove();
  }
}

class _CoachMarkOverlay extends StatefulWidget {
  const _CoachMarkOverlay({
    required this.steps,
    required this.onClose,
  });

  final List<CoachMarkStep> steps;
  final VoidCallback onClose;

  @override
  State<_CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<_CoachMarkOverlay> {
  int _index = 0;
  Rect? _targetRect;

  static const double _spotlightPad = 8;
  static const double _spotlightRadius = 18;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareCurrent());
  }

  Future<void> _prepareCurrent() async {
    final step = widget.steps[_index];
    final ctx = step.targetKey.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    setState(() => _targetRect = _computeRect(step.targetKey));
  }

  Rect? _computeRect(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.attached) return null;
    final overlayBox = context.findRenderObject();
    final Offset topLeft = overlayBox is RenderBox
        ? box.localToGlobal(Offset.zero, ancestor: overlayBox)
        : box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      _finish();
      return;
    }
    AppFeedback.selectionClick();
    setState(() {
      _index++;
      _targetRect = null;
    });
    _prepareCurrent();
  }

  void _finish() {
    AppFeedback.lightImpact();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final premium = PremiumThemeExtension.of(context);
    final accent = premium.champagneGold;
    final rect = _targetRect;
    final spotlight = rect?.inflate(_spotlightPad);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(
                painter: _SpotlightPainter(
                  spotlight: spotlight,
                  scrimColor: Colors.black.withValues(alpha: 0.72),
                  borderColor: accent,
                  radius: _spotlightRadius,
                ),
              ),
            ),
          ),
          if (spotlight != null)
            _buildCard(context, spotlight, size, accent),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    Rect spotlight,
    Size size,
    Color accent,
  ) {
    final ext = AppThemeExtension.of(context);
    final step = widget.steps[_index];
    final isLast = _index == widget.steps.length - 1;

    final spaceBelow = size.height - spotlight.bottom;
    final placeBelow = spaceBelow > 240;

    final card = Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        decoration: BoxDecoration(
          color: ext.surfaceElevated,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(color: accent.withValues(alpha: 0.42)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADIM ${_index + 1} / ${widget.steps.length}',
              style: TextStyle(
                color: accent.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Icon(step.icon, size: 18, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.title,
                    style: TextStyle(
                      color: ext.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              step.body,
              style: TextStyle(
                color: ext.textSecondary,
                fontSize: 13.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Turu atla',
                  child: TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: ext.textSecondary,
                      minimumSize: const Size(64, 44),
                    ),
                    child: const Text(
                      'Atla',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: isLast ? 'Turu bitir' : 'Sonraki adım',
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: ext.onBrand,
                      minimumSize: const Size(96, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                    ),
                    child: Text(
                      isLast ? 'Bitir' : 'İleri',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
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

    return Positioned(
      left: 20,
      right: 20,
      top: placeBelow ? spotlight.bottom + 18 : null,
      bottom: placeBelow ? null : (size.height - spotlight.top) + 18,
      child: card,
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.spotlight,
    required this.scrimColor,
    required this.borderColor,
    required this.radius,
  });

  final Rect? spotlight;
  final Color scrimColor;
  final Color borderColor;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final scrim = Paint()..color = scrimColor;

    if (spotlight == null) {
      canvas.drawRect(full, scrim);
      return;
    }

    final rrect = RRect.fromRectAndRadius(spotlight!, Radius.circular(radius));
    final scrimPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(full),
      Path()..addRRect(rrect),
    );
    canvas.drawPath(scrimPath, scrim);

    final border = Paint()
      ..color = borderColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, border);

    final glow = Paint()
      ..color = borderColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(rrect, glow);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.spotlight != spotlight ||
        oldDelegate.scrimColor != scrimColor ||
        oldDelegate.borderColor != borderColor;
  }
}
