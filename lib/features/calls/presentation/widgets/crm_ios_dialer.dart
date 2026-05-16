import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

/// Dialer ekranı — [ThemeData.brightness] ile açık / koyu (iPhone Phone’a yakın).
@immutable
class DialerThemeTokens {
  const DialerThemeTokens({
    required this.pageBg,
    required this.keyFill,
    required this.keyFillPressed,
    required this.labelPrimary,
    required this.labelSecondary,
    required this.callGreen,
    required this.capsuleFill,
    required this.capsuleBorder,
    required this.keyShadow,
    required this.capsuleShadow,
    required this.inkSplash,
    required this.inkHighlight,
    required this.callButtonShadow,
  });

  final Color pageBg;
  final Color keyFill;
  final Color keyFillPressed;
  final Color labelPrimary;
  final Color labelSecondary;
  final Color callGreen;
  final Color capsuleFill;
  final Color capsuleBorder;
  final Color keyShadow;
  final Color capsuleShadow;
  final Color inkSplash;
  final Color inkHighlight;
  final Color callButtonShadow;

  factory DialerThemeTokens.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const DialerThemeTokens(
        pageBg: Color(0xFF000000),
        keyFill: Color(0xFF3A3A3C),
        keyFillPressed: Color(0xFF48484A),
        labelPrimary: Color(0xFFFFFFFF),
        labelSecondary: Color(0xFF8E8E93),
        callGreen: Color(0xFF30D158),
        capsuleFill: Color(0xFF1C1C1E),
        capsuleBorder: Color(0x38FFFFFF),
        keyShadow: Color(0xB3000000),
        capsuleShadow: Color(0x99000000),
        inkSplash: Color(0x33FFFFFF),
        inkHighlight: Color(0x18FFFFFF),
        callButtonShadow: Color(0x6630D158),
      );
    }
    return const DialerThemeTokens(
      pageBg: Color(0xFFF2F2F7),
      keyFill: Color(0xFFE4E4EA),
      keyFillPressed: Color(0xFFD1D1D6),
      labelPrimary: Color(0xFF000000),
      labelSecondary: Color(0xFF8E8E93),
      callGreen: Color(0xFF34C759),
      capsuleFill: Color(0xFFFFFFFF),
      capsuleBorder: Color(0x14000000),
      keyShadow: Color(0x0D000000),
      capsuleShadow: Color(0x0A000000),
      inkSplash: Color(0x1F000000),
      inkHighlight: Color(0x0A000000),
      callButtonShadow: Color(0x22000000),
    );
  }
}

/// CRM “Yeni arama” — tuş takımı öncelikli, hafif iOS hissi.
class CrmIosDialerShell extends ConsumerWidget {
  const CrmIosDialerShell({
    super.key,
    required this.dialNotifier,
    required this.inAppCrmSession,
    required this.bottomInset,
    required this.onDismiss,
    required this.onStartCall,
  });

  final ValueNotifier<String> dialNotifier;
  final bool inAppCrmSession;
  final double bottomInset;
  final VoidCallback onDismiss;
  final VoidCallback onStartCall;

  static const Map<String, String> _ituLetters = {
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
    '0': '+',
  };

  static const List<String> _keyOrder = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '*',
    '0',
    '#',
  ];

  void _append(ValueNotifier<String> n, String key) {
    AppFeedback.selectionClick();
    n.value = OutboundPhoneDial.sanitizeDialEntry(n.value + key);
  }

  void _longPressZero(ValueNotifier<String> n) {
    AppFeedback.mediumImpact();
    final raw = n.value;
    if (raw.endsWith('0')) {
      final base = raw.substring(0, raw.length - 1);
      n.value = OutboundPhoneDial.sanitizeDialEntry(
        '+${OutboundPhoneDial.digitsOnly(base)}',
      );
      return;
    }
    final s = OutboundPhoneDial.sanitizeDialEntry(raw);
    if (!s.startsWith('+')) {
      n.value = OutboundPhoneDial.sanitizeDialEntry(
          '+${s.replaceFirst(RegExp(r'^\+'), '')}');
    }
  }

  void _backspace(ValueNotifier<String> n) {
    AppFeedback.lightImpact();
    final v = n.value;
    n.value = v.isEmpty ? '' : v.substring(0, v.length - 1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = DialerThemeTokens.of(context);
    final officeName = ref.watch(
      currentOfficeProvider.select((o) => o.valueOrNull?.name),
    );
    final textScaler = MediaQuery.of(context).textScaler;
    final maxScale = textScaler.scale(1.0).clamp(1.0, 1.35);

    return ColoredBox(
      color: t.pageBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Kapat',
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: t.labelSecondary,
                      size: 28,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Yeni arama',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.25,
                        color: t.labelPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            if (inAppCrmSession)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                child: Text(
                  'Gerçek GSM araması için müşteri kartından arayın.',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12 * maxScale,
                    height: 1.25,
                    color: t.labelSecondary,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                child: Text(
                  'Sistem telefonu açılır.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12 * maxScale,
                    height: 1.2,
                    color: t.labelSecondary,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: _OutgoingLineCapsule(
                    officeName: officeName,
                    tokens: t,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: dialNotifier,
                builder: (context, digits, _) {
                  final display = inAppCrmSession
                      ? digits
                      : OutboundPhoneDial.formatDialDisplayTurkeyFirst(digits);
                  final canStart =
                      OutboundPhoneDial.hasDialEntryContent(digits);
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final keyD = (w * 0.195).clamp(72.0, 84.0);
                      final gapH = (w * 0.045).clamp(14.0, 22.0);
                      final gapV = gapH * 0.92;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            const SizedBox(height: 6),
                            Expanded(
                              flex: 5,
                              child: Center(
                                child: _DialNumberDisplay(
                                  display: display,
                                  hasDigits: digits.trim().isNotEmpty,
                                  textScale: maxScale,
                                  tokens: t,
                                  onBackspace: () => _backspace(dialNotifier),
                                ),
                              ),
                            ),
                            _IosDialKeypad(
                              keyDiameter: keyD,
                              gapH: gapH,
                              gapV: gapV,
                              ituLetters: _ituLetters,
                              keyOrder: _keyOrder,
                              tokens: t,
                              onDigit: (k) => _append(dialNotifier, k),
                              onLongPressZero: () =>
                                  _longPressZero(dialNotifier),
                            ),
                            const SizedBox(height: 10),
                            DialerGreenCallButton(
                              tokens: t,
                              enabled: canStart,
                              onPressed: onStartCall,
                            ),
                            SizedBox(height: bottomInset + 12),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutgoingLineCapsule extends StatelessWidget {
  const _OutgoingLineCapsule({
    required this.officeName,
    required this.tokens,
  });

  final String? officeName;
  final DialerThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final hasName = officeName != null && officeName!.trim().isNotEmpty;
    final lineTitle = hasName ? officeName!.trim() : 'Kurumsal çıkış hattı';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.capsuleFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.capsuleBorder),
        boxShadow: [
          BoxShadow(
            color: tokens.capsuleShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              size: 18,
              color: tokens.labelSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Giden hat',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: tokens.labelSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    lineTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: tokens.labelPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: tokens.labelSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _DialNumberDisplay extends StatelessWidget {
  const _DialNumberDisplay({
    required this.display,
    required this.hasDigits,
    required this.textScale,
    required this.tokens,
    required this.onBackspace,
  });

  final String display;
  final bool hasDigits;
  final double textScale;
  final DialerThemeTokens tokens;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final numberWidget = hasDigits
        ? FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              display,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 36 * textScale,
                fontWeight: FontWeight.w300,
                height: 1.12,
                letterSpacing: 0.5,
                color: tokens.labelPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          )
        : Text(
            'Numara girin',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26 * textScale,
              fontWeight: FontWeight.w400,
              color: tokens.labelSecondary,
              height: 1.1,
            ),
          );

    return Row(
      children: [
        Expanded(child: Center(child: numberWidget)),
        if (hasDigits)
          IconButton(
            tooltip: 'Sil',
            onPressed: onBackspace,
            icon: Icon(
              Icons.backspace_outlined,
              color: tokens.labelSecondary,
              size: 26,
            ),
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }
}

class _IosDialKeypad extends StatelessWidget {
  const _IosDialKeypad({
    required this.keyDiameter,
    required this.gapH,
    required this.gapV,
    required this.ituLetters,
    required this.keyOrder,
    required this.tokens,
    required this.onDigit,
    required this.onLongPressZero,
  });

  final double keyDiameter;
  final double gapH;
  final double gapV;
  final Map<String, String> ituLetters;
  final List<String> keyOrder;
  final DialerThemeTokens tokens;
  final ValueChanged<String> onDigit;
  final VoidCallback onLongPressZero;

  @override
  Widget build(BuildContext context) {
    Widget row3(int a, int b, int c) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IosDialKey(
            label: keyOrder[a],
            letters: ituLetters[keyOrder[a]],
            diameter: keyDiameter,
            tokens: tokens,
            onTap: () => onDigit(keyOrder[a]),
            onLongPress: keyOrder[a] == '0' ? onLongPressZero : null,
          ),
          SizedBox(width: gapH),
          _IosDialKey(
            label: keyOrder[b],
            letters: ituLetters[keyOrder[b]],
            diameter: keyDiameter,
            tokens: tokens,
            onTap: () => onDigit(keyOrder[b]),
            onLongPress: keyOrder[b] == '0' ? onLongPressZero : null,
          ),
          SizedBox(width: gapH),
          _IosDialKey(
            label: keyOrder[c],
            letters: ituLetters[keyOrder[c]],
            diameter: keyDiameter,
            tokens: tokens,
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
        row3(9, 10, 11),
      ],
    );
  }
}

class _IosDialKey extends StatefulWidget {
  const _IosDialKey({
    required this.label,
    required this.letters,
    required this.diameter,
    required this.tokens,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final String? letters;
  final double diameter;
  final DialerThemeTokens tokens;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<_IosDialKey> createState() => _IosDialKeyState();
}

class _IosDialKeyState extends State<_IosDialKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final letterSize = (widget.diameter * 0.11).clamp(8.0, 11.0);
    final digitSize = (widget.diameter * 0.36).clamp(26.0, 32.0);

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          splashColor: widget.tokens.inkSplash,
          highlightColor: widget.tokens.inkHighlight,
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            child: Ink(
              width: widget.diameter,
              height: widget.diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pressed
                    ? widget.tokens.keyFillPressed
                    : widget.tokens.keyFill,
                boxShadow: [
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

/// Ortada yuvarlak yeşil arama — tam genişlik CTA yok.
class DialerGreenCallButton extends StatelessWidget {
  const DialerGreenCallButton({
    super.key,
    required this.tokens,
    required this.enabled,
    required this.onPressed,
  });

  final DialerThemeTokens tokens;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: 'Aramayı başlat',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled
                ? () {
                    AppFeedback.mediumImpact();
                    onPressed();
                  }
                : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 140),
              opacity: enabled ? 1 : 0.38,
              child: Ink(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.callGreen,
                  boxShadow: [
                    BoxShadow(
                      color: tokens.callButtonShadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.call_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
