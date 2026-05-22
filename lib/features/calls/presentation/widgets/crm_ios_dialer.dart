import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/models/dialer_control_prefs.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/dialer_contact_picker.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/dialer_contact_search_header.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/dialer_theme_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/ios_dial_keypad.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_action_feedback.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';

/// CRM “Yeni arama” — tuş takımı öncelikli, hafif iOS hissi.
class CrmIosDialerShell extends ConsumerStatefulWidget {
  const CrmIosDialerShell({
    super.key,
    required this.dialNotifier,
    required this.inAppCrmSession,
    required this.bottomInset,
    required this.onDismiss,
    required this.onStartCall,
    this.onControlPrefsChanged,
  });

  final ValueNotifier<String> dialNotifier;
  final bool inAppCrmSession;
  final double bottomInset;
  final VoidCallback onDismiss;
  final VoidCallback onStartCall;
  final ValueChanged<DialerControlPrefs>? onControlPrefsChanged;

  @override
  ConsumerState<CrmIosDialerShell> createState() => _CrmIosDialerShellState();
}

class _CrmIosDialerShellState extends ConsumerState<CrmIosDialerShell> {
  DialerControlPrefs _controls = const DialerControlPrefs();
  String? _selectedContactName;

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
    if (n.value.isEmpty) {
      setState(() => _selectedContactName = null);
    }
  }

  void _updateControls(DialerControlPrefs next) {
    setState(() => _controls = next);
    widget.onControlPrefsChanged?.call(next);
  }

  void _showMoreSheet(BuildContext context, DialerThemeTokens t) {
    AppFeedback.lightImpact();
    showPremiumScrollableBottomSheet<void>(
      context: context,
      maxHeightFactor: 0.42,
      builder: (ctx) => PremiumScrollableBottomSheetShell(
        title: 'Arama seçenekleri',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: Icon(Icons.contacts_rounded, color: t.labelPrimary),
              title: Text('Rehber listesi', style: TextStyle(color: t.labelPrimary)),
              subtitle: Text(
                'Tüm kişileri aç',
                style: TextStyle(color: t.labelSecondary, fontSize: 13),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await pickDialerContactPhone(context);
                if (picked != null && picked.isNotEmpty) {
                  widget.dialNotifier.value =
                      OutboundPhoneDial.sanitizeDialEntry(picked);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.flag_rounded, color: t.labelPrimary),
              title: Text('Ülke kodu', style: TextStyle(color: t.labelPrimary)),
              subtitle: Text(
                'Türkiye (+90) — diğer ülkeler yakında',
                style: TextStyle(color: t.labelSecondary, fontSize: 13),
              ),
              onTap: () {
                Navigator.pop(ctx);
                showPremiumActionFeedback(
                  context,
                  title: 'Ülke kodu',
                  message: 'Şu an giden aramalar +90 Türkiye formatında başlar.',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = DialerThemeTokens.of(context);
    final officeName = ref.watch(
      currentOfficeProvider.select((o) => o.valueOrNull?.name),
    );
    final textScaler = MediaQuery.of(context).textScaler;
    final maxScale = textScaler.scale(1.0).clamp(1.0, 1.35);
    final dialNotifier = widget.dialNotifier;

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
                    onPressed: widget.onDismiss,
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
            if (widget.inAppCrmSession)
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
                  child: DialerContactSearchHeader(
                    tokens: t,
                    officeName: officeName,
                    dialNotifier: dialNotifier,
                    onContactSelected: (name) {
                      setState(() => _selectedContactName = name);
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: dialNotifier,
                builder: (context, digits, _) {
                  final display = widget.inAppCrmSession
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
                                  contactName: _selectedContactName,
                                  hasDigits: digits.trim().isNotEmpty,
                                  textScale: maxScale,
                                  tokens: t,
                                  onBackspace: () => _backspace(dialNotifier),
                                ),
                              ),
                            ),
                            IosDialKeypad(
                              keyDiameter: keyD,
                              gapH: gapH,
                              gapV: gapV,
                              ituLetters: _ituLetters,
                              keyOrder: _keyOrder,
                              tokens: t,
                              onDigit: (k) => _append(dialNotifier, k),
                              onBackspace: () => _backspace(dialNotifier),
                              onLongPressZero: () =>
                                  _longPressZero(dialNotifier),
                            ),
                            const SizedBox(height: 8),
                            _DialerBottomControlRow(
                              controls: _controls,
                              onToggleMute: () {
                                AppFeedback.selectionClick();
                                _updateControls(
                                  _controls.copyWith(muted: !_controls.muted),
                                );
                              },
                              onToggleSpeaker: () {
                                AppFeedback.selectionClick();
                                _updateControls(
                                  _controls.copyWith(
                                    speakerOn: !_controls.speakerOn,
                                  ),
                                );
                              },
                              onToggleHold: () {
                                AppFeedback.selectionClick();
                                final next = _controls.copyWith(
                                  onHold: !_controls.onHold,
                                );
                                _updateControls(next);
                                if (next.onHold) {
                                  showPremiumActionFeedback(
                                    context,
                                    title: 'Bekletme',
                                    message:
                                        'Görüşme başladığında bekletme sistem telefonundan yönetilir.',
                                  );
                                }
                              },
                              onMore: () => _showMoreSheet(context, t),
                            ),
                            const SizedBox(height: 10),
                            DialerGreenCallButton(
                              tokens: t,
                              enabled: canStart,
                              onPressed: widget.onStartCall,
                            ),
                            SizedBox(height: widget.bottomInset + 12),
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

class _DialerBottomControlRow extends StatelessWidget {
  const _DialerBottomControlRow({
    required this.controls,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onToggleHold,
    required this.onMore,
  });

  final DialerControlPrefs controls;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleHold;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final t = DialerThemeTokens.of(context);
    Widget item(
      IconData icon,
      String label, {
      bool active = false,
      VoidCallback? onTap,
    }) {
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: active ? const Color(0xFF30D158) : t.labelSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          active ? const Color(0xFF30D158) : t.labelSecondary,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (active)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 20,
                      height: 2,
                      color: const Color(0xFF30D158),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        item(Icons.dialpad_rounded, 'Klavye', active: true),
        item(
          controls.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          'Sessiz',
          active: controls.muted,
          onTap: onToggleMute,
        ),
        item(
          controls.speakerOn
              ? Icons.volume_up_rounded
              : Icons.volume_up_outlined,
          'Hoparlör',
          active: controls.speakerOn,
          onTap: onToggleSpeaker,
        ),
        item(
          Icons.pause_rounded,
          'Beklet',
          active: controls.onHold,
          onTap: onToggleHold,
        ),
        item(Icons.more_horiz_rounded, 'Daha fazla', onTap: onMore),
      ],
    );
  }
}

class _DialNumberDisplay extends StatelessWidget {
  const _DialNumberDisplay({
    required this.display,
    required this.contactName,
    required this.hasDigits,
    required this.textScale,
    required this.tokens,
    required this.onBackspace,
  });

  final String display;
  final String? contactName;
  final bool hasDigits;
  final double textScale;
  final DialerThemeTokens tokens;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final name = contactName?.trim();
    final numberWidget = hasDigits
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (name != null && name.isNotEmpty) ...[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 22 * textScale,
                      fontWeight: FontWeight.w600,
                      color: tokens.labelPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  display,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: name != null && name.isNotEmpty
                        ? 28 * textScale
                        : 36 * textScale,
                    fontWeight: FontWeight.w300,
                    height: 1.12,
                    letterSpacing: 0.5,
                    color: tokens.labelPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          )
        : Text(
            'Numara girin veya üstten rehberde arayın',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20 * textScale,
              fontWeight: FontWeight.w400,
              color: tokens.labelSecondary,
              height: 1.2,
            ),
          );

    return Center(child: numberWidget);
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
