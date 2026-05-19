import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/core/resilience/safe_operation.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/services/app_lifecycle_power_service.dart';
import 'package:emlakmaster_mobile/features/ai_sales_assistant/presentation/widgets/ai_sales_assistant_panel.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/agent_doc_provider.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/outbound_system_handoff_page.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/models/dialer_control_prefs.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/crm_ios_dialer.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/dialer_theme_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/ios_dial_keypad.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Arama ekranı state makinesi: connecting → connected → ending → (summary).
enum CallUIState {
  connecting,
  connected,
  ending,
}

class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({
    super.key,
    this.customerId,
    this.phone,
    this.inAppCrmSession = false,
    this.startedFromScreen,
  });

  final String? customerId;
  final String? phone;

  /// true: Magic Call / CRM oturumu (uygulama içi; gerçek GSM hattı değildir).
  final bool inAppCrmSession;

  /// Örn. `customer_detail`, `consultant_dashboard` — handoff oturumu için.
  final String? startedFromScreen;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CallUIState _callState = CallUIState.connecting;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isKeypadOpen = false;

  /// Sürükleme sırasında anlık değer (animasyonsuz); null = panel fraction kullan
  double? _keypadDragValue;
  int _elapsedSeconds = 0;

  /// [CallUIState.connected] anında — arka plan / süre sayacı durunca duvar saati ile senkron.
  DateTime? _connectedWallClock;
  Timer? _ticker;

  /// Numara girişi (Magic / görüşme özeti; çevir modunda [ValueNotifier] tercih edilir)
  String _dialDigits = '';

  /// Çevir modu: tuş takımı — yalnızca bu alt ağaç [ValueListenableBuilder] ile yenilenir.
  ValueNotifier<String>? _dialEntryNotifier;

  /// Arama ekranı: true = sadece numara gir / tuş takımı; false = arama simülasyonu
  bool _isDialMode = false;

  /// Tuş takımından basılan rakamlar (aramada DTMF gösterimi)
  String _keypadDigits = '';

  DialerControlPrefs _dialControlPrefs = const DialerControlPrefs();

  /// Sürükleme başlangıç Y ve fraction (drag callback için)
  double _keypadDragStartY = 0;
  double _keypadDragStartFraction = 0;

  static const Duration _keypadSnapDuration = Duration(milliseconds: 280);
  static const Curve _keypadSnapCurve = Curves.easeOutCubic;

  /// Görüşme içi sürüklenen tuş takımı paneli — [OutboundSystemHandoffPage] rotasında oluşturulmaz.
  AnimationController? _keypadPanelController;
  Animation<double>? _keypadPanelAnimation;

  String? get _signedInUid {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    return uid != null && uid.isNotEmpty ? uid : null;
  }

  /// Gerçek GSM: sistem telefonuna devret; sahte “bağlandı” arayüzünü kullanma.
  bool get _usesOutboundHandoff =>
      !widget.inAppCrmSession &&
      ((widget.phone != null && widget.phone!.trim().isNotEmpty) ||
          (widget.customerId != null && widget.customerId!.trim().isNotEmpty));

  @override
  void initState() {
    super.initState();
    if (_usesOutboundHandoff) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    AppFeedback.lightImpact();
    _isDialMode = widget.phone == null && widget.customerId == null;
    if (_isDialMode) {
      _dialEntryNotifier = ValueNotifier<String>('');
    } else {
      _dialDigits = widget.phone ?? '';
    }

    _keypadPanelController = AnimationController(
      vsync: this,
      duration: _keypadSnapDuration,
    );
    _keypadPanelAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _keypadPanelController!, curve: _keypadSnapCurve),
    );
    _keypadPanelController!.addListener(() => setState(() {}));
    _keypadPanelController!.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && _isKeypadOpen) {
        setState(() => _isKeypadOpen = false);
      }
    });

    if (!_isDialMode) {
      _startElapsedTicker();

      // connecting → connected (kısa gecikme ile arama “açılıyor” hissi)
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _enterConnected();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final agentId = _signedInUid;
        if (agentId == null) return;
        unawaited(runWithResilienceWidget(
          ref: ref,
          () => FirestoreService.setAgentStatus(
              agentId: agentId, status: 'Görüşmede'),
        ));
      });
    }
  }

  void _startElapsedTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _callState != CallUIState.connected) return;
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _startCallWithDialNumber() {
    final rawEntry = _dialEntryNotifier?.value ?? _dialDigits;
    final number = OutboundPhoneDial.sanitizeDialEntry(rawEntry)
        .replaceAll(RegExp(r'\s'), '')
        .trim();
    if (number.isEmpty) return;
    AppFeedback.mediumImpact();

    // Varsayılan: gerçek GSM — sistem telefonuna devret (Magic Call modunda değilsek).
    if (!widget.inAppCrmSession) {
      if (!OutboundPhoneDial.isLikelyCallablePhone(number)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geçerli bir telefon numarası girin.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final started = widget.startedFromScreen ?? 'call_dial_pad';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.pushReplacement(
          AppRouter.routeCall,
          extra: {
            'phone': number,
            'startedFromScreen': started,
          },
        );
      });
      return;
    }

    _dialDigits = OutboundPhoneDial.sanitizeDialEntry(rawEntry);
    setState(() {
      _isDialMode = false;
      _isMuted = _dialControlPrefs.muted;
      _isSpeakerOn = _dialControlPrefs.speakerOn;
    });
    _startElapsedTicker();
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _enterConnected();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final agentId = _signedInUid;
      if (agentId == null) return;
      unawaited(runWithResilienceWidget(
        ref: ref,
        () => FirestoreService.setAgentStatus(
            agentId: agentId, status: 'Görüşmede'),
      ));
    });
  }

  @override
  void dispose() {
    if (!_usesOutboundHandoff) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _ticker?.cancel();
    _dialEntryNotifier?.dispose();
    _keypadPanelController?.dispose();
    super.dispose();
  }

  void _enterConnected({bool anchorWallClock = true}) {
    if (!mounted) return;
    setState(() {
      _callState = CallUIState.connected;
      if (anchorWallClock) {
        _connectedWallClock = DateTime.now();
      }
    });
  }

  void _resyncElapsedFromWallClock() {
    final start = _connectedWallClock;
    if (!mounted || start == null) return;
    final secs = DateTime.now().difference(start).inSeconds.clamp(0, 172800);
    if (_elapsedSeconds != secs) {
      setState(() => _elapsedSeconds = secs);
    } else {
      _elapsedSeconds = secs;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_callState != CallUIState.connected) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _ticker?.cancel();
        _ticker = null;
        _resyncElapsedFromWallClock();
        break;
      case AppLifecycleState.resumed:
        _resyncElapsedFromWallClock();
        _startElapsedTicker();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _openKeypadPanel() {
    setState(() => _isKeypadOpen = true);
    _keypadPanelController?.forward(from: 0);
  }

  void _closeKeypadPanel() {
    _keypadPanelController?.reverse();
  }

  void _onKeypadDragStart(DragStartDetails details) {
    _keypadDragStartY = details.globalPosition.dy;
    _keypadDragStartFraction =
        _keypadDragValue ?? _keypadPanelAnimation?.value ?? 0;
  }

  void _onKeypadDragUpdate(DragUpdateDetails details, double sheetHeight) {
    final delta = details.globalPosition.dy - _keypadDragStartY;
    final newFraction =
        (_keypadDragStartFraction - delta / sheetHeight).clamp(0.0, 1.0);
    setState(() => _keypadDragValue = newFraction);
  }

  void _onKeypadDragEnd(double sheetHeight) {
    final current = _keypadDragValue ?? _keypadPanelAnimation?.value ?? 0;
    setState(() => _keypadDragValue = null);
    final c = _keypadPanelController;
    if (c == null) return;
    if (current < 0.5) {
      c.value = current;
      c.reverse();
    } else {
      c.value = current;
      c.forward();
    }
  }

  /// Görüşme DTMF paneli — tam tuş takımı için yeterli yükseklik.
  static const double _keypadSheetMaxFraction = 0.62;

  Widget _buildDraggableKeypadSheet(
      double screenHeight, AppThemeExtension ext) {
    final sheetHeight = screenHeight * _keypadSheetMaxFraction;
    final effectiveFraction =
        _keypadDragValue ?? _keypadPanelAnimation?.value ?? 0;
    final currentHeight = sheetHeight * effectiveFraction;
    const r =
        BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusSheet));

    return GestureDetector(
      onVerticalDragStart: _onKeypadDragStart,
      onVerticalDragUpdate: (d) => _onKeypadDragUpdate(d, sheetHeight),
      onVerticalDragEnd: (_) => _onKeypadDragEnd(sheetHeight),
      child: AnimatedContainer(
        duration:
            _keypadDragValue != null ? Duration.zero : _keypadSnapDuration,
        curve: _keypadSnapCurve,
        height: currentHeight,
        child: ClipRRect(
          borderRadius: r,
          clipBehavior: Clip.hardEdge,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: sheetHeight,
              child: ColoredBox(
                color: ext.surface,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeArea(
                      top: false,
                      left: false,
                      right: false,
                      child: Column(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(top: DesignTokens.space3),
                            child: Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color:
                                      ext.textTertiary.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          if (_keypadDigits.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                DesignTokens.space6,
                                DesignTokens.space2,
                                DesignTokens.space6,
                                DesignTokens.space2,
                              ),
                              child: Text(
                                _keypadDigits,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: ext.textPrimary,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 1.2,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                              ),
                            ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final w = constraints.maxWidth;
                                final keyD = (w * 0.195).clamp(68.0, 80.0);
                                final gapH = (w * 0.045).clamp(12.0, 20.0);
                                final gapV = gapH * 0.92;
                                final t = DialerThemeTokens.inCallDtmf(context);
                                const itu = {
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
                                const order = [
                                  '1', '2', '3', '4', '5', '6',
                                  '7', '8', '9', '*', '0', '#',
                                ];
                                return Center(
                                  child: IosDialKeypad(
                                    keyDiameter: keyD,
                                    gapH: gapH,
                                    gapV: gapV,
                                    ituLetters: itu,
                                    keyOrder: order,
                                    tokens: t,
                                    visualMode: DialKeyVisualMode.inCallDtmf,
                                    onDigit: (key) {
                                      setState(() => _keypadDigits += key);
                                    },
                                    onBackspace: () {
                                      if (_keypadDigits.isEmpty) return;
                                      setState(() {
                                        _keypadDigits = _keypadDigits.substring(
                                          0,
                                          _keypadDigits.length - 1,
                                        );
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: DesignTokens.space2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialMode(double bottomInset) {
    final entry = _dialEntryNotifier;
    if (entry == null) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: CrmIosDialerShell(
        dialNotifier: entry,
        inAppCrmSession: widget.inAppCrmSession,
        bottomInset: bottomInset,
        onControlPrefsChanged: (prefs) => _dialControlPrefs = prefs,
        onDismiss: () {
          AppFeedback.lightImpact();
          context.pop();
        },
        onStartCall: _startCallWithDialNumber,
      ),
    );
  }

  Future<void> _endCall() async {
    if (_callState == CallUIState.ending) return;
    AppFeedback.heavyImpact();
    setState(() => _callState = CallUIState.ending);
    final uid = _signedInUid;
    final phone = widget.phone ??
        (_dialDigits.trim().isNotEmpty ? _dialDigits.trim() : null);
    try {
      if (uid != null) {
        await runWithResilienceWidget(
          ref: ref,
          () => FirestoreService.setAgentStatus(agentId: uid, status: 'Müsait'),
        );
        await runWithResilienceWidget(
          ref: ref,
          () => FirestoreService.createCallRecord(
            advisorId: uid,
            direction: 'outgoing',
            outcome: AppConstants.callOutcomeCompleted,
            durationSeconds: _elapsedSeconds,
            phoneNumber: phone,
            customerId: widget.customerId,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oturum yok: çağrı kaydı Firestore’a yazılamadı.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (!mounted) return;
      final extra = <String, dynamic>{
        'durationSec': _elapsedSeconds,
        'outcome': AppConstants.callOutcomeCompleted,
      };
      final customerId = widget.customerId;
      if (customerId != null && customerId.isNotEmpty) {
        extra['customerId'] = customerId;
      }
      if (phone != null && phone.isNotEmpty) extra['phone'] = phone;
      context.push(AppRouter.routeCallSummary, extra: extra);
    } catch (e) {
      if (mounted) _enterConnected(anchorWallClock: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_usesOutboundHandoff) {
      return OutboundSystemHandoffPage(
        customerId: widget.customerId,
        phone: widget.phone,
        startedFromScreen: widget.startedFromScreen ?? 'unknown',
      );
    }
    final ext = AppThemeExtension.of(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ext.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _CallSessionBackdrop(ext: ext)),
          if (_isDialMode) _buildDialMode(bottomInset),
          if (!_isDialMode)
            _InCallSessionBody(
              topPadding: topPadding,
              bottomInset: bottomInset,
              callState: _callState,
              elapsedSeconds: _elapsedSeconds,
              isMuted: _isMuted,
              isSpeakerOn: _isSpeakerOn,
              isKeypadOpen: _isKeypadOpen,
              isMagicCallSession: widget.inAppCrmSession,
              customerId: widget.customerId,
              displayPhone:
                  widget.phone ?? (_dialDigits.isNotEmpty ? _dialDigits : null),
              onPop: () {
                AppFeedback.lightImpact();
                context.pop();
              },
              onEndCall: _endCall,
              onToggleMute: () {
                AppFeedback.selectionClick();
                setState(() => _isMuted = !_isMuted);
              },
              onToggleSpeaker: () {
                AppFeedback.selectionClick();
                setState(() => _isSpeakerOn = !_isSpeakerOn);
              },
              onToggleKeypad: () {
                AppFeedback.selectionClick();
                if (_isKeypadOpen) {
                  _closeKeypadPanel();
                } else {
                  _openKeypadPanel();
                }
              },
            ),
          if (!_isDialMode)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: !_isKeypadOpen,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: _isKeypadOpen ? 1.0 : 0.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          AppFeedback.lightImpact();
                          _closeKeypadPanel();
                        },
                        child: Container(
                          color: ext.shadowColor.withValues(alpha: 0.55),
                          height:
                              screenHeight * (1.0 - _keypadSheetMaxFraction),
                        ),
                      ),
                      _buildDraggableKeypadSheet(screenHeight, ext),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatElapsed(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

class _CallSessionBackdrop extends StatelessWidget {
  const _CallSessionBackdrop({required this.ext});

  final AppThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ext.background,
            Color.lerp(ext.background, ext.surfaceElevated, 0.42)!,
            ext.background,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _CallStatusChip extends StatelessWidget {
  const _CallStatusChip(
      {required this.state, required this.isMagicCallSession});

  final CallUIState state;
  final bool isMagicCallSession;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (state) {
      case CallUIState.connecting:
        label = isMagicCallSession ? 'Hazırlanıyor' : 'Bağlanıyor';
        bg = ext.warning.withValues(alpha: 0.16);
        fg = ext.warning;
      case CallUIState.connected:
        label = isMagicCallSession ? 'Akıllı görüşme · kayıt' : 'Çağrıda';
        bg = ext.success.withValues(alpha: 0.14);
        fg = ext.success;
      case CallUIState.ending:
        label = 'Sonlandırılıyor';
        bg = ext.danger.withValues(alpha: 0.14);
        fg = ext.danger;
    }
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
          border: Border.all(color: fg.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: fg,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _CallHeroCard extends ConsumerWidget {
  const _CallHeroCard({
    required this.customerId,
    required this.displayPhone,
    required this.callState,
    required this.isMagicCallSession,
  });

  final String? customerId;
  final String? displayPhone;
  final CallUIState callState;
  final bool isMagicCallSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid;

    Widget identity() {
      if (customerId == null || customerId!.isEmpty) {
        final phone = displayPhone?.trim();
        return Column(
          children: [
            Icon(Icons.phone_in_talk_rounded,
                size: 44, color: ext.accent.withValues(alpha: 0.9)),
            const SizedBox(height: DesignTokens.space4),
            Text(
              phone != null && phone.isNotEmpty ? phone : 'Numara belirtilmedi',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              isMagicCallSession
                  ? 'Akıllı görüşme · kayıt (gerçek GSM hattı değil)'
                  : 'Doğrudan arama',
              style:
                  theme.textTheme.bodySmall?.copyWith(color: ext.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }
      final async = ref.watch(customerEntityByIdProvider(customerId!));
      return async.when(
        data: (c) {
          final name = c?.fullName?.trim().isNotEmpty == true
              ? c!.fullName!.trim()
              : 'Müşteri';
          final initial =
              name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
          final phoneLine = c?.primaryPhone?.trim();
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ext.accent.withValues(alpha: 0.45)),
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: ext.surface,
                  child: Text(
                    initial,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.space4),
              Text(
                name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: ext.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (phoneLine != null && phoneLine.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.space2),
                Text(
                  phoneLine,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: ext.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
              const SizedBox(height: DesignTokens.space2),
              Text(
                isMagicCallSession
                    ? 'Uygulama içi kayıt oturumu · akıllı asistan altta'
                    : 'Çağrı kaydı · akıllı asistan altta',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: ext.textTertiary),
                textAlign: TextAlign.center,
              ),
              if (c?.source != null && c!.source!.trim().isNotEmpty) ...[
                const SizedBox(height: DesignTokens.space2),
                Text(
                  'Kaynak: ${c.source!.trim()}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ext.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => Padding(
          padding: const EdgeInsets.all(DesignTokens.space6),
          child: Center(
              child:
                  CircularProgressIndicator(color: ext.accent, strokeWidth: 2)),
        ),
        error: (_, __) => Text(
          'Müşteri bilgisi alınamadı',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: ext.textSecondary),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.space5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
        color: ext.surfaceElevated,
        border: Border.all(color: ext.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: ext.shadowColor.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CallStatusChip(
              state: callState, isMagicCallSession: isMagicCallSession),
          const SizedBox(height: DesignTokens.space5),
          identity(),
          const SizedBox(height: DesignTokens.space5),
          if (uid != null && uid.isNotEmpty)
            _AgentLocationRow(uid: uid)
          else
            Text(
              'Hat konumu: profilden tanımlanır',
              textAlign: TextAlign.center,
              style:
                  theme.textTheme.labelSmall?.copyWith(color: ext.textTertiary),
            ),
        ],
      ),
    );
  }
}

class _CallTimerSection extends StatelessWidget {
  const _CallTimerSection({
    required this.callState,
    required this.elapsedSeconds,
  });

  final CallUIState callState;
  final int elapsedSeconds;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    late final String hint;
    switch (callState) {
      case CallUIState.connecting:
        hint = 'Ses oturumu ve kayıt eşlemesi hazırlanıyor';
      case CallUIState.connected:
        hint = 'Aktif süre';
      case CallUIState.ending:
        hint = 'Çağrı kapanıyor ve özet hazırlanıyor';
    }
    return Column(
      children: [
        Text(
          _formatElapsed(elapsedSeconds),
          style: theme.textTheme.displaySmall?.copyWith(
            color: ext.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
            height: 1.05,
          ),
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: ext.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _InCallSessionBody extends ConsumerWidget {
  const _InCallSessionBody({
    required this.topPadding,
    required this.bottomInset,
    required this.callState,
    required this.elapsedSeconds,
    required this.isMuted,
    required this.isSpeakerOn,
    required this.isKeypadOpen,
    required this.isMagicCallSession,
    required this.customerId,
    required this.displayPhone,
    required this.onPop,
    required this.onEndCall,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onToggleKeypad,
  });

  final double topPadding;
  final double bottomInset;
  final CallUIState callState;
  final int elapsedSeconds;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isKeypadOpen;
  final bool isMagicCallSession;
  final String? customerId;
  final String? displayPhone;
  final VoidCallback onPop;
  final Future<void> Function() onEndCall;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleKeypad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ext = AppThemeExtension.of(context);
    return Positioned.fill(
      child: Column(
        children: [
          SizedBox(height: topPadding),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: DesignTokens.space2),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: ext.textSecondary),
                  onPressed: onPop,
                ),
                const Spacer(),
                Consumer(
                  builder: (ctx, ref, _) {
                    final async = ref.watch(currentOfficeProvider);
                    final name = async.valueOrNull?.name;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusPill),
                        border: Border.all(
                            color: ext.border.withValues(alpha: 0.45)),
                        color: ext.surfaceElevated.withValues(alpha: 0.9),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.business_rounded,
                              size: 16, color: ext.accent),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              name != null && name.isNotEmpty
                                  ? name
                                  : 'Ofis hattı',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: ext.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: DesignTokens.space6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: DesignTokens.space4),
                  _CallHeroCard(
                    customerId: customerId,
                    displayPhone: displayPhone,
                    callState: callState,
                    isMagicCallSession: isMagicCallSession,
                  ),
                  const SizedBox(height: DesignTokens.space6),
                  _CallTimerSection(
                    callState: callState,
                    elapsedSeconds: elapsedSeconds,
                  ),
                  const SizedBox(height: DesignTokens.space5),
                  Center(child: _SiriWaveBars(isActive: !isMuted)),
                  const SizedBox(height: DesignTokens.space6),
                  AiSalesAssistantPanel(customerId: customerId),
                  const SizedBox(height: DesignTokens.space8),
                ],
              ),
            ),
          ),
          _CallBottomDeck(
            callState: callState,
            isMuted: isMuted,
            isSpeakerOn: isSpeakerOn,
            isKeypadOpen: isKeypadOpen,
            bottomInset: bottomInset,
            onEndCall: onEndCall,
            onToggleMute: onToggleMute,
            onToggleSpeaker: onToggleSpeaker,
            onToggleKeypad: onToggleKeypad,
          ),
        ],
      ),
    );
  }
}

class _CallBottomDeck extends StatelessWidget {
  const _CallBottomDeck({
    required this.callState,
    required this.isMuted,
    required this.isSpeakerOn,
    required this.isKeypadOpen,
    required this.bottomInset,
    required this.onEndCall,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onToggleKeypad,
  });

  final CallUIState callState;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isKeypadOpen;
  final double bottomInset;
  final Future<void> Function() onEndCall;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleKeypad;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final dangerForeground = Theme.of(context).colorScheme.onError;
    return Material(
      color: ext.surfaceElevated.withValues(alpha: 0.94),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: ext.border.withValues(alpha: 0.45)),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          DesignTokens.space4,
          DesignTokens.space5,
          DesignTokens.space4,
          bottomInset + DesignTokens.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: callState == CallUIState.ending ? null : () => onEndCall(),
              child: IgnorePointer(
                ignoring: callState == CallUIState.ending,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: callState == CallUIState.ending
                        ? ext.danger.withValues(alpha: 0.55)
                        : ext.danger,
                    boxShadow: [
                      BoxShadow(
                        color: ext.danger.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: callState == CallUIState.ending
                      ? Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              color: dangerForeground,
                              strokeWidth: 2.5,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.call_end_rounded,
                          color: dangerForeground,
                          size: 36,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _RoundIconButton(
                    icon: Icons.mic_off_rounded,
                    label: 'Sessiz',
                    isActive: isMuted,
                    onTap: onToggleMute,
                  ),
                ),
                Expanded(
                  child: _RoundIconButton(
                    icon: Icons.dialpad_rounded,
                    label: 'Tuş takımı',
                    isActive: isKeypadOpen,
                    onTap: onToggleKeypad,
                  ),
                ),
                Expanded(
                  child: _RoundIconButton(
                    icon: Icons.volume_up_rounded,
                    label: 'Hoparlör',
                    isActive: isSpeakerOn,
                    onTap: onToggleSpeaker,
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

/// Siri tarzı minimal beyaz ses dalgaları (5 çubuk).
class _SiriWaveBars extends StatelessWidget {
  final bool isActive;

  const _SiriWaveBars({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: _SiriWaveBarsAnimated(isActive: isActive),
    );
  }
}

class _SiriWaveBarsAnimated extends StatefulWidget {
  final bool isActive;

  const _SiriWaveBarsAnimated({required this.isActive});

  @override
  State<_SiriWaveBarsAnimated> createState() => _SiriWaveBarsAnimatedState();
}

class _SiriWaveBarsAnimatedState extends State<_SiriWaveBarsAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  void _syncAnimationState() {
    final shouldAnimate =
        widget.isActive && !AppLifecyclePowerService.shouldReduceMotion;
    if (shouldAnimate) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    AppLifecyclePowerService.isInBackground.addListener(_syncAnimationState);
    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant _SiriWaveBarsAnimated oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncAnimationState();
    }
  }

  @override
  void dispose() {
    AppLifecyclePowerService.isInBackground.removeListener(_syncAnimationState);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    const barCount = 5;
    const barWidth = 4.0;
    const gap = 6.0;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final activeFactor = widget.isActive ? 1.0 : 0.15;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(barCount, (i) {
            final phase = (i / barCount) * 2 * math.pi;
            final t = _controller.value * 2 * math.pi + phase;
            final height = 8 + 24 * activeFactor * (0.5 + 0.5 * math.sin(t));
            final barColor = Color.lerp(
              ext.textTertiary.withValues(alpha: 0.35),
              ext.accent.withValues(alpha: 0.88),
              activeFactor * (0.5 + 0.5 * math.sin(t)),
            )!;
            return Container(
              margin: EdgeInsets.only(left: i == 0 ? 0 : gap),
              width: barWidth,
              height: height.clamp(8.0, 32.0),
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(barWidth / 2),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Görüşme alt şeridi: ikincil kontroller — büyük dokunma, net hiyerarşi.
class _AgentLocationRow extends ConsumerWidget {
  const _AgentLocationRow({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    final snap = ref.watch(agentDocProvider(uid)).valueOrNull;
    var district = '—';
    var city = '—';
    if (snap != null && snap.exists) {
      final d = snap.data();
      final c = d?['locationCity'] as String?;
      final dist = d?['locationDistrict'] as String?;
      if (c != null && c.isNotEmpty) city = c;
      if (dist != null && dist.isNotEmpty) district = dist;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.place_outlined, size: 16, color: ext.textTertiary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$district · $city',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: ext.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  static const double _diameter = 72;
  static const double _iconSize = 28;

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _RoundIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              splashColor: ext.accent.withValues(alpha: 0.14),
              highlightColor: ext.accent.withValues(alpha: 0.06),
              onTap: () {
                AppFeedback.selectionClick();
                onTap();
              },
              child: Ink(
                width: _diameter,
                height: _diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? ext.accent.withValues(alpha: 0.18)
                      : Color.lerp(ext.surface, ext.surfaceElevated, 0.4)!,
                  border: Border.all(
                    color: isActive
                        ? ext.accent.withValues(alpha: 0.5)
                        : ext.border.withValues(alpha: 0.52),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ext.shadowColor
                          .withValues(alpha: isActive ? 0.16 : 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isActive ? ext.accent : ext.textSecondary,
                    size: _iconSize,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isActive ? ext.textPrimary : ext.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0.12,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
