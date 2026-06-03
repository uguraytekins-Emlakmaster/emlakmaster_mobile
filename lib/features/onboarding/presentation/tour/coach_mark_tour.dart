import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/onboarding/tour_target.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:flutter/material.dart';

/// Tek bir tur adımı — kararlı bir arayüz hedefine [targetId] ile bağlanır.
/// [tabIndex] verilirse, adım gösterilmeden önce ilgili sekmeye geçilir.
class CoachMarkStep {
  const CoachMarkStep({
    required this.targetId,
    required this.icon,
    required this.title,
    required this.body,
    this.tabIndex,
  });

  final TourTargetId targetId;
  final IconData icon;
  final String title;
  final String body;

  /// Danışman kabuğu `pages` indeksi (null = sekme değiştirme).
  final int? tabIndex;
}

/// Kapsamlı, atlanabilir coach-mark turu. Sekmeler arası otomatik gezinir,
/// her hedefi [TourRegistry] üzerinden çözer ve overlay'i Navigator alt
/// ağacındaki [Overlay]'e yerleştirir (kök Overlay'e dokunmaz).
class CoachMarkTour {
  CoachMarkTour._();

  static OverlayEntry? _entry;

  static bool get isShowing => _entry != null;

  /// Turu başlatır. Hedefi o an çözülemeyen adımlar zarifçe atlanır; hiçbir
  /// adım gösterilemezse tur açılmaz ve [onCompleted] yine de çağrılır.
  static void show(
    BuildContext context, {
    required List<CoachMarkStep> steps,
    required void Function(int pageIndex) goToTab,
    required VoidCallback onCompleted,
  }) {
    if (_entry != null) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    if (steps.isEmpty) {
      onCompleted();
      return;
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CoachMarkOverlay(
        steps: steps,
        goToTab: goToTab,
        onClose: () {
          if (identical(_entry, entry)) _entry = null;
          if (entry.mounted) entry.remove();
          onCompleted();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  /// Açık turu temizler (ör. kabuk kapanırken).
  static void dismiss() {
    final entry = _entry;
    _entry = null;
    if (entry != null && entry.mounted) entry.remove();
  }
}

class _CoachMarkOverlay extends StatefulWidget {
  const _CoachMarkOverlay({
    required this.steps,
    required this.goToTab,
    required this.onClose,
  });

  final List<CoachMarkStep> steps;
  final void Function(int pageIndex) goToTab;
  final VoidCallback onClose;

  @override
  State<_CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<_CoachMarkOverlay> {
  int _index = 0;
  int _shownCount = 0; // gösterilen (atlanmayan) adım sayısı — sayaç için
  Rect? _targetRect;
  bool _closed = false;

  static const double _spotlightPad = 8;
  static const double _spotlightRadius = 18;
  static const int _maxResolveAttempts = 16;
  static const Duration _attemptGap = Duration(milliseconds: 70);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareFrom(0));
  }

  /// [start] adımından itibaren çözülebilen ilk adımı hazırlar; çözülemeyenleri
  /// atlar. Çözülebilir adım kalmazsa turu kapatır.
  Future<void> _prepareFrom(int start) async {
    var i = start;
    if (mounted) {
      setState(() => _targetRect = null);
    }
    while (i < widget.steps.length) {
      final step = widget.steps[i];
      if (step.tabIndex != null) {
        widget.goToTab(step.tabIndex!);
      }
      final key = await _resolveTarget(step);
      if (!mounted || _closed) return;
      if (key != null) {
        await Scrollable.ensureVisible(
          key.currentContext!,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
        if (!mounted || _closed) return;
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || _closed) return;
        final rect = _computeRect(key);
        if (rect != null) {
          setState(() {
            _index = i;
            _targetRect = rect;
            _shownCount++;
          });
          return;
        }
      }
      i++; // hedef yok → bu adımı atla
    }
    _finish();
  }

  Future<GlobalKey?> _resolveTarget(CoachMarkStep step) async {
    for (var attempt = 0; attempt < _maxResolveAttempts; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || _closed) return null;
      final key = TourRegistry.instance.keyFor(step.targetId);
      final ro = key?.currentContext?.findRenderObject();
      if (key != null &&
          ro is RenderBox &&
          ro.attached &&
          ro.hasSize &&
          ro.size.shortestSide > 1) {
        return key;
      }
      await Future<void>.delayed(_attemptGap);
      if (!mounted || _closed) return null;
    }
    return null;
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

  bool get _isLastShowable {
    // Geçerli adımdan sonra başka adım yoksa "Bitir".
    return _index >= widget.steps.length - 1;
  }

  void _next() {
    AppFeedback.selectionClick();
    _prepareFrom(_index + 1);
  }

  void _finish() {
    if (_closed) return;
    _closed = true;
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
          // Her durumda erişilebilir "Atla" — geçiş anında bile kapana kıstırmaz.
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: Semantics(
                  button: true,
                  label: 'Turu atla',
                  child: TextButton.icon(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black.withValues(alpha: 0.32),
                      minimumSize: const Size(64, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusPill),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text(
                      'Atla',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (spotlight != null) _buildCard(context, spotlight, size, accent),
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
    final isLast = _isLastShowable;
    final stepNo = _shownCount > 0 ? _shownCount : 1;

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
              'TUR · ADIM $stepNo',
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
                    onPressed: isLast ? _finish : _next,
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

    final glow = Paint()
      ..color = borderColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(rrect, glow);

    final border = Paint()
      ..color = borderColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, border);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.spotlight != spotlight ||
        oldDelegate.scrimColor != scrimColor ||
        oldDelegate.borderColor != borderColor;
  }
}
