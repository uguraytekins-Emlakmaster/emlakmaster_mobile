import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/core/resilience/safe_operation.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/ai_sales_assistant/presentation/widgets/ai_sales_assistant_panel.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/outbound_system_handoff_page.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with SingleTickerProviderStateMixin {
  CallUIState _callState = CallUIState.connecting;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isKeypadOpen = false;
  /// Sürükleme sırasında anlık değer (animasyonsuz); null = panel fraction kullan
  double? _keypadDragValue;
  int _elapsedSeconds = 0;
  Timer? _ticker;
  /// Numara girişi (Magic Call açıldığında numara yoksa)
  String _dialDigits = '';
  /// Arama ekranı: true = sadece numara gir / tuş takımı; false = arama simülasyonu
  bool _isDialMode = false;
  /// Tuş takımından basılan rakamlar (aramada DTMF gösterimi)
  String _keypadDigits = '';
  /// Sürükleme başlangıç Y ve fraction (drag callback için)
  double _keypadDragStartY = 0;
  double _keypadDragStartFraction = 0;

  static const Duration _keypadSnapDuration = Duration(milliseconds: 280);
  static const Curve _keypadSnapCurve = Curves.easeOutCubic;

  late AnimationController _keypadPanelController;
  late Animation<double> _keypadPanelAnimation;

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
    HapticFeedback.lightImpact();
    _isDialMode = widget.phone == null && widget.customerId == null;
    if (!_isDialMode) _dialDigits = widget.phone ?? '';

    _keypadPanelController = AnimationController(
      vsync: this,
      duration: _keypadSnapDuration,
    );
    _keypadPanelAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _keypadPanelController, curve: _keypadSnapCurve),
    );
    _keypadPanelController.addListener(() => setState(() {}));
    _keypadPanelController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && _isKeypadOpen) {
        setState(() => _isKeypadOpen = false);
      }
    });

    if (!_isDialMode) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_callState != CallUIState.connected) return;
      setState(() {
        _elapsedSeconds++;
      });
    });

    // connecting → connected (kısa gecikme ile arama “açılıyor” hissi)
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _callState = CallUIState.connected);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final agentId = _signedInUid;
      if (agentId == null) return;
      unawaited(runWithResilience(
        ref: ref as Ref<Object?>,
        () => FirestoreService.setAgentStatus(agentId: agentId, status: 'Görüşmede'),
      ));
    });
    }
  }

  void _startCallWithDialNumber() {
    final number = _dialDigits.replaceAll(RegExp(r'\s'), '').trim();
    if (number.isEmpty) return;
    HapticFeedback.mediumImpact();

    // Varsayılan: gerçek GSM — sistem telefonuna devret (Magic Call modunda değilsek).
    if (!widget.inAppCrmSession) {
      if (!OutboundPhoneDial.isLikelyCallablePhone(number)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geçerli bir telefon numarası girin.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      context.pushReplacement(
        AppRouter.routeCall,
        extra: {
          'phone': number,
          'startedFromScreen': widget.startedFromScreen ?? 'call_dial_pad',
        },
      );
      return;
    }

    setState(() {
      _isDialMode = false;
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_callState != CallUIState.connected) return;
        setState(() => _elapsedSeconds++);
      });
    });
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _callState = CallUIState.connected);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final agentId = _signedInUid;
      if (agentId == null) return;
      unawaited(runWithResilience(
        ref: ref as Ref<Object?>,
        () => FirestoreService.setAgentStatus(agentId: agentId, status: 'Görüşmede'),
      ));
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _keypadPanelController.dispose();
    super.dispose();
  }

  void _openKeypadPanel() {
    setState(() => _isKeypadOpen = true);
    _keypadPanelController.forward(from: 0);
  }

  void _closeKeypadPanel() {
    _keypadPanelController.reverse();
  }

  void _onKeypadDragStart(DragStartDetails details) {
    _keypadDragStartY = details.globalPosition.dy;
    _keypadDragStartFraction = _keypadDragValue ?? _keypadPanelAnimation.value;
  }

  void _onKeypadDragUpdate(DragUpdateDetails details, double sheetHeight) {
    final delta = details.globalPosition.dy - _keypadDragStartY;
    final newFraction = (_keypadDragStartFraction - delta / sheetHeight).clamp(0.0, 1.0);
    setState(() => _keypadDragValue = newFraction);
  }

  void _onKeypadDragEnd(double sheetHeight) {
    final current = _keypadDragValue ?? _keypadPanelAnimation.value;
    setState(() => _keypadDragValue = null);
    if (current < 0.5) {
      _keypadPanelController.value = current;
      _keypadPanelController.reverse();
    } else {
      _keypadPanelController.value = current;
      _keypadPanelController.forward();
    }
  }

  /// Kompakt tuş takımı + tutamaç + güvenli alan için yeterli yükseklik (kesilme önleme).
  static const double _keypadSheetMaxFraction = 0.58;

  Widget _buildDraggableKeypadSheet(double screenHeight, AppThemeExtension ext) {
    final sheetHeight = screenHeight * _keypadSheetMaxFraction;
    final effectiveFraction = _keypadDragValue ?? _keypadPanelAnimation.value;
    final currentHeight = sheetHeight * effectiveFraction;
    const r = BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusSheet));

    return GestureDetector(
      onVerticalDragStart: _onKeypadDragStart,
      onVerticalDragUpdate: (d) => _onKeypadDragUpdate(d, sheetHeight),
      onVerticalDragEnd: (_) => _onKeypadDragEnd(sheetHeight),
      child: AnimatedContainer(
        duration: _keypadDragValue != null ? Duration.zero : _keypadSnapDuration,
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
                            padding: const EdgeInsets.only(top: DesignTokens.space3),
                            child: Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: ext.textTertiary.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          if (_keypadDigits.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                DesignTokens.space6,
                                DesignTokens.space3,
                                DesignTokens.space6,
                                DesignTokens.space2,
                              ),
                              child: Text(
                                'Ton: $_keypadDigits',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: ext.textSecondary,
                                    ),
                              ),
                            ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space2),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: constraints.maxWidth,
                                        maxHeight: constraints.maxHeight,
                                      ),
                                      child: _KeypadSheet(
                                        onKeyPressed: (key) {
                                          setState(() => _keypadDigits += key);
                                        },
                                      ),
                                    ),
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

  Widget _buildDialMode(
    ThemeData theme,
    AppThemeExtension ext,
    double bottomInset,
  ) {
    return Positioned.fill(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space2,
                DesignTokens.space1,
                DesignTokens.space2,
                0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: ext.textSecondary),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.pop();
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Yeni arama',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            if (widget.inAppCrmSession)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space5,
                  0,
                  DesignTokens.space5,
                  DesignTokens.space2,
                ),
                child: Text(
                  'Magic Call — gerçek GSM araması bu ekran değildir; sistem telefonu için müşteri kartından arayın.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ext.textTertiary,
                    height: 1.35,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space5,
                  0,
                  DesignTokens.space5,
                  DesignTokens.space2,
                ),
                child: Text(
                  'Numarayı girin; ardından sistem telefonu açılır (gerçek GSM hattı).',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ext.textTertiary,
                    height: 1.35,
                  ),
                ),
              ),
            Consumer(
              builder: (context, ref, _) {
                final officeAsync = ref.watch(currentOfficeProvider);
                return _DialModeLineContext(
                  theme: theme,
                  ext: ext,
                  officeName: officeAsync.valueOrNull?.name,
                );
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: DesignTokens.space1),
                    Expanded(
                      child: Center(
                        child: _DialModeDialSurface(
                          ext: ext,
                          hero: _DialHeroNumberField(
                            digits: _dialDigits,
                            ext: ext,
                            theme: theme,
                            embedded: true,
                            onBackspace: () {
                              HapticFeedback.lightImpact();
                              setState(() => _dialDigits = _dialDigits.isEmpty
                                  ? ''
                                  : _dialDigits.substring(0, _dialDigits.length - 1));
                            },
                          ),
                          keypad: _KeypadSheet(
                            dialMode: true,
                            embeddedDial: true,
                            onKeyPressed: (key) {
                              setState(() => _dialDigits += key);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.space5,
                DesignTokens.space4,
                DesignTokens.space5,
                bottomInset + DesignTokens.space4,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _dialDigits.trim().isEmpty ? null : _startCallWithDialNumber,
                  icon: Icon(Icons.call_rounded, size: 22, color: ext.onBrand),
                  label: Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      'Aramayı başlat',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: ext.onBrand,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: ext.accent,
                    foregroundColor: ext.onBrand,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                    alignment: Alignment.center,
                    elevation: 0,
                    shadowColor: ext.shadowColor.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _endCall() async {
    if (_callState == CallUIState.ending) return;
    HapticFeedback.heavyImpact();
    setState(() => _callState = CallUIState.ending);
    final uid = _signedInUid;
    final phone = widget.phone ?? (_dialDigits.trim().isNotEmpty ? _dialDigits.trim() : null);
    try {
      if (uid != null) {
        await runWithResilience(
          ref: ref as Ref<Object?>,
          () => FirestoreService.setAgentStatus(agentId: uid, status: 'Müsait'),
        );
        await runWithResilience(
          ref: ref as Ref<Object?>,
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
      if (customerId != null && customerId.isNotEmpty) extra['customerId'] = customerId;
      if (phone != null && phone.isNotEmpty) extra['phone'] = phone;
      context.push(AppRouter.routeCallSummary, extra: extra);
    } catch (e) {
      if (mounted) setState(() => _callState = CallUIState.connected);
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
    final theme = Theme.of(context);
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
          if (_isDialMode) _buildDialMode(theme, ext, bottomInset),
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
              displayPhone: widget.phone ?? (_dialDigits.isNotEmpty ? _dialDigits : null),
              onPop: () {
                HapticFeedback.lightImpact();
                context.pop();
              },
              onEndCall: _endCall,
              onToggleMute: () {
                HapticFeedback.selectionClick();
                setState(() => _isMuted = !_isMuted);
              },
              onToggleSpeaker: () {
                HapticFeedback.selectionClick();
                setState(() => _isSpeakerOn = !_isSpeakerOn);
              },
              onToggleKeypad: () {
                HapticFeedback.selectionClick();
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
                          HapticFeedback.lightImpact();
                          _closeKeypadPanel();
                        },
                        child: Container(
                          color: ext.shadowColor.withValues(alpha: 0.55),
                          height: screenHeight * (1.0 - _keypadSheetMaxFraction),
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

/// Tek yüzey: numara + ince ayırıcı + tuş takımı — ayrı bloklar yerine tek “çevir” kompozisyonu.
class _DialModeDialSurface extends StatelessWidget {
  const _DialModeDialSurface({
    required this.ext,
    required this.hero,
    required this.keypad,
  });

  final AppThemeExtension ext;
  final Widget hero;
  final Widget keypad;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
          border: Border.all(color: ext.accent.withValues(alpha: 0.22)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ext.surfaceElevated,
              Color.lerp(ext.surfaceElevated, ext.background, 0.1)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: ext.shadowColor.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              hero,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space5),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ext.border.withValues(alpha: 0.0),
                        ext.border.withValues(alpha: 0.45),
                        ext.border.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              keypad,
            ],
          ),
        ),
      ),
    );
  }
}

/// Çevir ekranı: ofis hattı + kısa yardım — ürünleşmiş satır.
class _DialModeLineContext extends StatelessWidget {
  const _DialModeLineContext({
    required this.theme,
    required this.ext,
    required this.officeName,
  });

  final ThemeData theme;
  final AppThemeExtension ext;
  final String? officeName;

  @override
  Widget build(BuildContext context) {
    final hasName = officeName != null && officeName!.trim().isNotEmpty;
    final lineTitle = hasName ? officeName!.trim() : 'Kurumsal çıkış hattı';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space5,
        DesignTokens.space1,
        DesignTokens.space5,
        DesignTokens.space1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                  border: Border.all(color: ext.border.withValues(alpha: 0.42)),
                  color: ext.surfaceElevated.withValues(alpha: 0.88),
                  boxShadow: [
                    BoxShadow(
                      color: ext.shadowColor.withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.corporate_fare_rounded, size: 18, color: ext.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Giden hat',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: ext.textTertiary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.35,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lineTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: ext.textPrimary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.05,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            'Numarayı girin veya yapıştırın',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: ext.textTertiary,
              letterSpacing: 0.12,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialHeroNumberField extends StatelessWidget {
  const _DialHeroNumberField({
    required this.digits,
    required this.ext,
    required this.theme,
    required this.onBackspace,
    this.embedded = false,
  });

  final String digits;
  final AppThemeExtension ext;
  final ThemeData theme;
  final VoidCallback onBackspace;
  /// [_DialModeDialSurface] içinde: dış kart yok, tek kompozisyon hissi.
  final bool embedded;

  static double _letterSpacingForDigits(String d) {
    final n = d.replaceAll(RegExp(r'\s'), '').length;
    if (n <= 11) return 1.35;
    if (n <= 15) return 1.0;
    if (n <= 19) return 0.65;
    if (n <= 24) return 0.42;
    return 0.28;
  }

  @override
  Widget build(BuildContext context) {
    final numberBlock = digits.isEmpty
        ? Text(
            'Numara girin',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: ext.textTertiary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              height: 1.12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              final style = theme.textTheme.headlineMedium?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: _letterSpacingForDigits(digits),
                height: 1.12,
              );
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: Text(
                    digits,
                    style: style,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          );

    final row = Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space1),
            child: numberBlock,
          ),
        ),
        if (digits.isNotEmpty)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBackspace,
              customBorder: const CircleBorder(),
              splashColor: ext.accent.withValues(alpha: 0.12),
              highlightColor: ext.accent.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ext.border.withValues(alpha: 0.5)),
                    color: ext.surface.withValues(alpha: 0.65),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.backspace_rounded,
                      size: 20,
                      color: ext.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (embedded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.space4,
          DesignTokens.space5,
          DesignTokens.space4,
          DesignTokens.space4,
        ),
        child: row,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space4,
        DesignTokens.space3,
        DesignTokens.space4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
        color: ext.surfaceElevated,
        border: Border.all(color: ext.accent.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: ext.shadowColor.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: row,
    );
  }
}

class _CallStatusChip extends StatelessWidget {
  const _CallStatusChip({required this.state, required this.isMagicCallSession});

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
        label = isMagicCallSession ? 'Magic Call · CRM' : 'Görüşmede';
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
            Icon(Icons.phone_in_talk_rounded, size: 44, color: ext.accent.withValues(alpha: 0.9)),
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
                  ? 'Magic Call · CRM (gerçek GSM hattı değil)'
                  : 'Doğrudan arama',
              style: theme.textTheme.bodySmall?.copyWith(color: ext.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }
      final async = ref.watch(customerEntityByIdProvider(customerId!));
      return async.when(
        data: (c) {
          final name = c?.fullName?.trim().isNotEmpty == true ? c!.fullName!.trim() : 'Müşteri';
          final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
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
                    ? 'Uygulama içi CRM oturumu · AI asistan altta'
                    : 'CRM kaydı · AI asistan altta',
                style: theme.textTheme.labelSmall?.copyWith(color: ext.textTertiary),
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
          child: Center(child: CircularProgressIndicator(color: ext.accent, strokeWidth: 2)),
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
          _CallStatusChip(state: callState, isMagicCallSession: isMagicCallSession),
          const SizedBox(height: DesignTokens.space5),
          identity(),
          const SizedBox(height: DesignTokens.space5),
          if (uid != null && uid.isNotEmpty)
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.agentDocStream(uid),
              builder: (context, snap) {
                var district = '—';
                var city = '—';
                if (snap.hasData && snap.data!.exists) {
                  final d = snap.data!.data();
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
              },
            )
          else
            Text(
              'Hat konumu: profilden tanımlanır',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(color: ext.textTertiary),
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
        hint = 'Ses oturumu ve CRM senkronu hazırlanıyor';
      case CallUIState.connected:
        hint = 'Aktif süre';
      case CallUIState.ending:
        hint = 'Görüşme kapatılıyor ve özet hazırlanıyor';
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
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space2),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: ext.textSecondary),
                  onPressed: onPop,
                ),
                const Spacer(),
                Consumer(
                  builder: (ctx, ref, _) {
                    final async = ref.watch(currentOfficeProvider);
                    final name = async.valueOrNull?.name;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                        border: Border.all(color: ext.border.withValues(alpha: 0.45)),
                        color: ext.surfaceElevated.withValues(alpha: 0.9),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.business_rounded, size: 16, color: ext.accent),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              name != null && name.isNotEmpty ? name : 'Ofis hattı',
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
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space6),
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
                      ? const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.call_end_rounded,
                          color: Colors.white,
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
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
                HapticFeedback.selectionClick();
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
                      color: ext.shadowColor.withValues(alpha: isActive ? 0.16 : 0.1),
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

class _KeypadSheet extends StatelessWidget {
  const _KeypadSheet({
    this.onKeyPressed,
    this.dialMode = false,
    this.embeddedDial = false,
  });

  final void Function(String key)? onKeyPressed;

  /// Çevir ekranı: daha büyük tuşlar ve panel; görüşme içi tuş takımı: kompakt.
  final bool dialMode;

  /// [_DialModeDialSurface] içinde: dış kutu yok; klasik *0# öncesi ekstra nefes.
  final bool embeddedDial;

  static const double _keyDiameterCompact = 72.0;
  static const double _keySpacingCompact = 12.0;

  /// Çevir modu: daha geniş dokunma, klasik telefon ritmi (yatay/dikey boşluk ayrı ayarlı).
  static const double _keyDiameterDial = 88.0;
  static const double _dialGapH = 17.0;
  static const double _dialGapV = 15.0;
  /// ITU E.161 — tanıdık çevir hissi; marka renkleriyle, Apple kopyası değil.
  static const Map<String, String> _dialLetterRow = {
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

  static const int _columns = 3;
  static const int _rows = 4;

  void _tapKey(String keyLabel) {
    HapticFeedback.selectionClick();
    onKeyPressed?.call(keyLabel);
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    final d = dialMode ? _keyDiameterDial : _keyDiameterCompact;
    final gapH = dialMode ? _dialGapH : _keySpacingCompact;
    final gapV = dialMode ? _dialGapV : _keySpacingCompact;
    final labelSize = dialMode ? 31.0 : 24.0;
    final padH = dialMode ? DesignTokens.space5 : DesignTokens.space4;
    final padV = dialMode ? DesignTokens.space5 : DesignTokens.space4;

    final keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '*', '0', '#',
    ];

    if (embeddedDial && dialMode) {
      final rowW = _columns * d + (_columns - 1) * gapH;
      final extraBeforeBottomRow = gapV * 0.52;

      Widget keyCell(String label) {
        return _KeypadDialKey(
          label: label,
          diameter: d,
          labelFontSize: labelSize,
          dialMode: true,
          letterRow: _dialLetterRow[label],
          ext: ext,
          theme: theme,
          onTap: () => _tapKey(label),
        );
      }

      Widget row3(int a, int b, int c) {
        return SizedBox(
          width: rowW,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              keyCell(keys[a]),
              keyCell(keys[b]),
              keyCell(keys[c]),
            ],
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(padH, DesignTokens.space4, padH, padV),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
            gradient: RadialGradient(
              center: const Alignment(0, -0.32),
              radius: 1.4,
              colors: [
                Color.lerp(ext.surfaceElevated, ext.accent, 0.055)!.withValues(alpha: 0.5),
                ext.surfaceElevated.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              row3(0, 1, 2),
              SizedBox(height: gapV),
              row3(3, 4, 5),
              SizedBox(height: gapV),
              row3(6, 7, 8),
              SizedBox(height: gapV + extraBeforeBottomRow),
              row3(9, 10, 11),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
        border: Border.all(
          color: ext.border.withValues(alpha: dialMode ? 0.52 : 0.48),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(ext.surfaceElevated, ext.surface, 0.12)!,
            ext.surfaceElevated,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: ext.shadowColor.withValues(alpha: dialMode ? 0.26 : 0.22),
            blurRadius: dialMode ? 18 : 14,
            offset: Offset(0, dialMode ? 7 : 6),
          ),
        ],
      ),
      child: SizedBox(
        width: _columns * d + (_columns - 1) * gapH,
        height: _rows * d + (_rows - 1) * gapV,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columns,
            mainAxisSpacing: gapV,
            crossAxisSpacing: gapH,
            mainAxisExtent: d,
          ),
          itemCount: keys.length,
          itemBuilder: (context, index) {
            final keyLabel = keys[index];
            return _KeypadDialKey(
              label: keyLabel,
              diameter: d,
              labelFontSize: labelSize,
              dialMode: dialMode,
              letterRow: dialMode ? _dialLetterRow[keyLabel] : null,
              ext: ext,
              theme: theme,
              onTap: () => _tapKey(keyLabel),
            );
          },
        ),
      ),
    );
  }
}

class _KeypadDialKey extends StatelessWidget {
  const _KeypadDialKey({
    required this.label,
    required this.diameter,
    required this.labelFontSize,
    required this.dialMode,
    this.letterRow,
    required this.ext,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final double diameter;
  final double labelFontSize;
  final bool dialMode;
  /// ITU E.161 harf satırı (2–9, 0 altında +); * / # boş.
  final String? letterRow;
  final AppThemeExtension ext;
  final ThemeData theme;
  final VoidCallback onTap;

  /// Kömür yüzey + ince altın rim — lüks CRM, dünya çapı çevir ergonomisi.
  BoxDecoration _dialModeFaceDecoration() {
    final charcoalTop = Color.lerp(ext.surface, ext.surfaceElevated, 0.55)!;
    final charcoalMid = Color.lerp(ext.surface, ext.background, 0.35)!;
    final charcoalBottom = Color.lerp(ext.surface, ext.background, 0.55)!;
    final goldRim = Color.lerp(ext.border, ext.accent, 0.28)!.withValues(alpha: 0.42);
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(charcoalTop, ext.accent, 0.045)!,
          charcoalMid,
          charcoalBottom,
        ],
        stops: const [0.0, 0.42, 1.0],
      ),
      border: Border.all(color: goldRim, width: 0.75),
      boxShadow: [
        BoxShadow(
          color: ext.shadowColor.withValues(alpha: 0.55),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: ext.accent.withValues(alpha: 0.085),
          blurRadius: 20,
          offset: const Offset(0, 7),
          spreadRadius: -6,
        ),
      ],
    );
  }

  BoxDecoration _compactFaceDecoration() {
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(ext.surface, ext.surfaceElevated, 0.35)!,
          ext.surface.withValues(alpha: 0.97),
        ],
      ),
      border: Border.all(
        color: ext.border.withValues(alpha: 0.52),
      ),
      boxShadow: [
        BoxShadow(
          color: ext.shadowColor.withValues(alpha: 0.1),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLetters = letterRow != null && letterRow!.isNotEmpty;
    final warmSplash =
        Color.lerp(ext.accent, ext.surfaceElevated, 0.18)!.withValues(alpha: dialMode ? 0.22 : 0.14);
    final warmHighlight =
        Color.lerp(ext.accent, ext.surfaceElevated, 0.3)!.withValues(alpha: dialMode ? 0.095 : 0.07);

    final digitColor = dialMode
        ? Color.lerp(ext.textPrimary, ext.accent, 0.06)
        : ext.textPrimary;

    final labelStyle = theme.textTheme.headlineSmall?.copyWith(
      color: digitColor,
      fontWeight: FontWeight.w500,
      fontSize: labelFontSize,
      height: 1.0,
      fontFeatures: const [FontFeature.tabularFigures()],
      shadows: dialMode
          ? [
              Shadow(
                color: ext.shadowColor.withValues(alpha: 0.5),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ]
          : null,
    );

    final letterStyle = theme.textTheme.labelSmall?.copyWith(
      color: Color.lerp(ext.textTertiary, ext.accent, 0.22),
      fontWeight: FontWeight.w600,
      fontSize: (diameter * 0.108).clamp(9.0, 11.0),
      letterSpacing: 0.65,
      height: 1.0,
    );

    final content = hasLetters
        ? Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: labelStyle),
              SizedBox(height: diameter * 0.028),
              Text(letterRow!, style: letterStyle),
            ],
          )
        : Text(label, style: labelStyle);

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        splashColor: warmSplash,
        highlightColor: warmHighlight,
        splashFactory: InkRipple.splashFactory,
        onTap: onTap,
        child: Ink(
          height: diameter,
          width: diameter,
          decoration: dialMode ? _dialModeFaceDecoration() : _compactFaceDecoration(),
          child: Center(child: content),
        ),
      ),
    );
  }
}
