import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/dialer_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Tuş takımı görsel modu.
enum DialKeyVisualMode {
  /// Yeni arama — standart iOS gri tuşlar.
  dialPad,

  /// Görüşme DTMF — altın basma efekti.
  inCallDtmf,
}

/// Paylaşılan iOS tarzı tuş takımı (silme tuşu dahil).
class IosDialKeypad extends StatelessWidget {
  const IosDialKeypad({
    super.key,
    required this.keyDiameter,
    required this.gapH,
    required this.gapV,
    required this.ituLetters,
    required this.keyOrder,
    required this.tokens,
    required this.onDigit,
    required this.onBackspace,
    this.onLongPressZero,
    this.visualMode = DialKeyVisualMode.dialPad,
  });

  final double keyDiameter;
  final double gapH;
  final double gapV;
  final Map<String, String> ituLetters;
  final List<String> keyOrder;
  final DialerThemeTokens tokens;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onLongPressZero;
  final DialKeyVisualMode visualMode;

  @override
  Widget build(BuildContext context) {
    Widget row3(int a, int b, int c) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IosDialKey(
            label: keyOrder[a],
            letters: ituLetters[keyOrder[a]],
            diameter: keyDiameter,
            tokens: tokens,
            visualMode: visualMode,
            onTap: () => onDigit(keyOrder[a]),
            onLongPress: keyOrder[a] == '0' ? onLongPressZero : null,
          ),
          SizedBox(width: gapH),
          IosDialKey(
            label: keyOrder[b],
            letters: ituLetters[keyOrder[b]],
            diameter: keyDiameter,
            tokens: tokens,
            visualMode: visualMode,
            onTap: () => onDigit(keyOrder[b]),
            onLongPress: keyOrder[b] == '0' ? onLongPressZero : null,
          ),
          SizedBox(width: gapH),
          IosDialKey(
            label: keyOrder[c],
            letters: ituLetters[keyOrder[c]],
            diameter: keyDiameter,
            tokens: tokens,
            visualMode: visualMode,
            onTap: () => onDigit(keyOrder[c]),
            onLongPress: keyOrder[c] == '0' ? onLongPressZero : null,
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row3(0, 1, 2),
        SizedBox(height: gapV),
        row3(3, 4, 5),
        SizedBox(height: gapV),
        row3(6, 7, 8),
        SizedBox(height: gapV + 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: keyDiameter),
            SizedBox(width: gapH),
            IosDialKey(
              label: keyOrder[10],
              letters: ituLetters[keyOrder[10]],
              diameter: keyDiameter,
              tokens: tokens,
              visualMode: visualMode,
              onTap: () => onDigit(keyOrder[10]),
              onLongPress: onLongPressZero,
            ),
            SizedBox(width: gapH),
            IosDialBackspaceKey(
              diameter: keyDiameter,
              tokens: tokens,
              visualMode: visualMode,
              onTap: onBackspace,
              onLongPress: onBackspace,
            ),
          ],
        ),
      ],
    );
  }
}

class IosDialKey extends StatefulWidget {
  const IosDialKey({
    super.key,
    required this.label,
    required this.letters,
    required this.diameter,
    required this.tokens,
    required this.onTap,
    this.onLongPress,
    this.visualMode = DialKeyVisualMode.dialPad,
  });

  final String label;
  final String? letters;
  final double diameter;
  final DialerThemeTokens tokens;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final DialKeyVisualMode visualMode;

  @override
  State<IosDialKey> createState() => _IosDialKeyState();
}

class _IosDialKeyState extends State<IosDialKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final letterSize = (widget.diameter * 0.11).clamp(8.0, 11.0);
    final digitSize = (widget.diameter * 0.36).clamp(26.0, 32.0);
    final inCall = widget.visualMode == DialKeyVisualMode.inCallDtmf;
    final pressedFill = inCall
        ? Color.lerp(
            widget.tokens.keyFillPressed,
            widget.tokens.accentGlow,
            0.22,
          )!
        : widget.tokens.keyFillPressed;

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            AppFeedback.selectionClick();
            widget.onTap();
          },
          onLongPress: widget.onLongPress,
          splashColor: widget.tokens.inkSplash,
          highlightColor: widget.tokens.inkHighlight,
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: widget.diameter,
              height: widget.diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pressed ? pressedFill : widget.tokens.keyFill,
                boxShadow: [
                  if (inCall && _pressed)
                    BoxShadow(
                      color: widget.tokens.accentGlow.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 0.5,
                    ),
                  BoxShadow(
                    color: widget.tokens.keyShadow,
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: widget.letters != null && widget.letters!.isNotEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: digitSize,
                              fontWeight: FontWeight.w400,
                              height: 1.0,
                              color: widget.tokens.labelPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          SizedBox(height: widget.diameter * 0.02),
                          Text(
                            widget.letters!,
                            style: TextStyle(
                              fontSize: letterSize,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              height: 1.0,
                              color: widget.tokens.labelSecondary,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: digitSize,
                          fontWeight: FontWeight.w400,
                          height: 1.0,
                          color: widget.tokens.labelPrimary,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IosDialBackspaceKey extends StatefulWidget {
  const IosDialBackspaceKey({
    super.key,
    required this.diameter,
    required this.tokens,
    required this.onTap,
    this.onLongPress,
    this.visualMode = DialKeyVisualMode.dialPad,
  });

  final double diameter;
  final DialerThemeTokens tokens;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final DialKeyVisualMode visualMode;

  @override
  State<IosDialBackspaceKey> createState() => _IosDialBackspaceKeyState();
}

class _IosDialBackspaceKeyState extends State<IosDialBackspaceKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        AppFeedback.lightImpact();
        widget.onTap();
      },
      onLongPress: widget.onLongPress,
      child: SizedBox(
        width: widget.diameter,
        height: widget.diameter,
        child: Center(
          child: AnimatedScale(
            scale: _pressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 70),
            child: Icon(
              Icons.backspace_outlined,
              size: widget.diameter * 0.32,
              color: widget.visualMode == DialKeyVisualMode.inCallDtmf
                  ? widget.tokens.accentGlow.withValues(
                      alpha: _pressed ? 1.0 : 0.85,
                    )
                  : widget.tokens.labelPrimary.withValues(
                      alpha: _pressed ? 0.55 : 0.42,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
