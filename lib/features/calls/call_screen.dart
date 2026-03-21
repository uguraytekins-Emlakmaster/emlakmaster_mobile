import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/resilience/safe_operation.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/ai_sales_assistant/presentation/widgets/ai_sales_assistant_panel.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
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
  const CallScreen({super.key, this.customerId, this.phone});

  final String? customerId;
  final String? phone;

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

  String get _agentId {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    return uid != null && uid.isNotEmpty ? uid : 'demoAgent1';
  }

  @override
  void initState() {
    super.initState();
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
      final agentId = _agentId;
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
      final agentId = _agentId;
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

  static const double _keypadSheetMaxFraction = 0.48;

  Widget _buildDraggableKeypadSheet(double screenHeight) {
    final sheetHeight = screenHeight * _keypadSheetMaxFraction;
    final effectiveFraction = _keypadDragValue ?? _keypadPanelAnimation.value;
    final currentHeight = sheetHeight * effectiveFraction;

    return GestureDetector(
      onVerticalDragStart: _onKeypadDragStart,
      onVerticalDragUpdate: (d) => _onKeypadDragUpdate(d, sheetHeight),
      onVerticalDragEnd: (_) => _onKeypadDragEnd(sheetHeight),
      child: AnimatedContainer(
        duration: _keypadDragValue != null ? Duration.zero : _keypadSnapDuration,
        curve: _keypadSnapCurve,
        height: currentHeight,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.hardEdge,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: sheetHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                        border: Border(
                          top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                          left: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                          right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _KeypadSheet(
                            onKeyPressed: (key) {
                              HapticFeedback.selectionClick();
                              setState(() => _keypadDigits += key);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialMode(ThemeData theme, double topPadding) {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: topPadding),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  color: Colors.white70,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.pop();
                  },
                ),
                const Spacer(),
                Text(
                  'Numara çevir',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _dialDigits.isEmpty ? 'Numara girin' : _dialDigits,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: _dialDigits.isEmpty ? Colors.white38 : Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_dialDigits.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.backspace_outlined),
                    color: Colors.white70,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _dialDigits = _dialDigits.isEmpty ? '' : _dialDigits.substring(0, _dialDigits.length - 1));
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _KeypadSheet(
              onKeyPressed: (key) {
                HapticFeedback.selectionClick();
                setState(() => _dialDigits += key);
              },
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _dialDigits.trim().isEmpty ? null : _startCallWithDialNumber,
            icon: const Icon(Icons.call_rounded, size: 22),
            label: const Text('Ara'),
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _endCall() async {
    if (_callState == CallUIState.ending) return;
    HapticFeedback.heavyImpact();
    setState(() => _callState = CallUIState.ending);
    try {
      await runWithResilience(
        ref: ref as Ref<Object?>,
        () => FirestoreService.setAgentStatus(agentId: _agentId, status: 'Müsait'),
      );
      final phone = widget.phone ?? (_dialDigits.trim().isNotEmpty ? _dialDigits.trim() : null);
      await runWithResilience(
        ref: ref as Ref<Object?>,
        () => FirestoreService.createCallRecord(
          advisorId: _agentId,
          direction: 'outgoing',
          outcome: AppConstants.callOutcomeCompleted,
          durationSeconds: _elapsedSeconds,
          phoneNumber: phone,
          customerId: widget.customerId,
        ),
      );
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
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: DesignTokens.scaffoldDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isDialMode) _buildDialMode(theme, topPadding),
          if (!_isDialMode)
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                SizedBox(height: topPadding),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        color: Colors.white70,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.pop();
                        },
                      ),
                      const Spacer(),
                      Text(
                        'Ofis Hattı',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _ClientInfoHeader(customerId: widget.customerId, displayPhone: _dialDigits.isNotEmpty ? _dialDigits : null),
                const SizedBox(height: 16),
                _SiriWaveBars(isActive: !_isMuted),
                const SizedBox(height: 8),
                Text(
                  _formatElapsed(_elapsedSeconds),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  _callState == CallUIState.connecting
                      ? 'Aranıyor...'
                      : _callState == CallUIState.ending
                          ? 'Sonlandırılıyor...'
                          : 'Arama devam ediyor',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AiSalesAssistantPanel(customerId: widget.customerId),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _callState == CallUIState.ending ? null : _endCall,
                        child: IgnorePointer(
                          ignoring: _callState == CallUIState.ending,
                          child: Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _callState == CallUIState.ending
                                  ? DesignTokens.danger.withValues(alpha: 0.6)
                                  : DesignTokens.danger,
                            ),
                            child: _callState == CallUIState.ending
                                ? const SizedBox(
                                    width: 34,
                                    height: 34,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.call_end_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _RoundIconButton(
                            icon: Icons.mic_off_rounded,
                            label: 'Sessiz',
                            isActive: _isMuted,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _isMuted = !_isMuted;
                              });
                            },
                          ),
                          const SizedBox(width: 24),
                          _RoundIconButton(
                            icon: Icons.dialpad_rounded,
                            label: 'Tuş Takımı',
                            isActive: _isKeypadOpen,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              if (_isKeypadOpen) {
                                _closeKeypadPanel();
                              } else {
                                _openKeypadPanel();
                              }
                            },
                          ),
                          const SizedBox(width: 24),
                          _RoundIconButton(
                            icon: Icons.volume_up_rounded,
                            label: 'Hoparlör',
                            isActive: _isSpeakerOn,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _isSpeakerOn = !_isSpeakerOn;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                        color: Colors.black26,
                        height: screenHeight * 0.52,
                      ),
                    ),
                    _buildDraggableKeypadSheet(screenHeight),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: topPadding + 8,
            right: 12,
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.agentDocStream(_agentId),
              builder: (context, snap) {
                String district = 'Bağlar';
                String city = 'Diyarbakır';
                if (snap.hasData && snap.data!.exists) {
                  final d = snap.data!.data();
                  final c = d?['locationCity'] as String?;
                  final dist = d?['locationDistrict'] as String?;
                  if (c != null && c.isNotEmpty) city = c;
                  if (dist != null && dist.isNotEmpty) district = dist;
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withValues(alpha: 0.35),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        'Konum: $district / $city',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
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
            return Container(
              margin: EdgeInsets.only(left: i == 0 ? 0 : gap),
              width: barWidth,
              height: height.clamp(8.0, 32.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(barWidth / 2),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ClientInfoHeader extends ConsumerWidget {
  const _ClientInfoHeader({this.customerId, this.displayPhone});

  final String? customerId;
  final String? displayPhone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (customerId == null || customerId!.isEmpty) {
      return Column(
        children: [
          const CircleAvatar(radius: 40, backgroundColor: DesignTokens.surfaceDarkCard),
          const SizedBox(height: 12),
          Text(
            displayPhone != null && displayPhone!.isNotEmpty ? displayPhone! : 'Arama',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayPhone != null && displayPhone!.isNotEmpty ? 'Aranan numara' : 'Potansiyel Alıcı',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      );
    }
    final customerAsync = ref.watch(customerEntityByIdProvider(customerId!));
    return customerAsync.when(
      data: (customer) {
        final name = customer?.fullName ?? 'Müşteri';
        final initial = name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase();
        return Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: DesignTokens.surfaceDarkCard,
              child: Text(
                initial,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Potansiyel Alıcı • AI hazır',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        );
      },
      loading: () => Column(
        children: [
          const CircleAvatar(radius: 40, backgroundColor: DesignTokens.surfaceDarkCard),
          const SizedBox(height: 12),
          Text('Yükleniyor...', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
        ],
      ),
      error: (_, __) => Column(
        children: [
          const CircleAvatar(radius: 40, backgroundColor: DesignTokens.surfaceDarkCard),
          const SizedBox(height: 12),
          Text('Müşteri', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
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
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.selectionClick(),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.06),
            ),
            child: Icon(
              icon,
              color: isActive ? DesignTokens.primary : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isActive ? Colors.white : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeypadSheet extends StatelessWidget {
  const _KeypadSheet({this.onKeyPressed});

  final void Function(String key)? onKeyPressed;

  static const double _keyDiameter = 76.0;
  static const double _keySpacing = 14.0;
  static const int _columns = 3;
  static const int _rows = 4;

  @override
  Widget build(BuildContext context) {
    final keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '*', '0', '#',
    ];
    return Opacity(
      opacity: 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: DesignTokens.scaffoldDark.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox(
          width: _columns * _keyDiameter + (_columns - 1) * _keySpacing,
          height: _rows * _keyDiameter + (_rows - 1) * _keySpacing,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columns,
              mainAxisSpacing: _keySpacing,
              crossAxisSpacing: _keySpacing,
              mainAxisExtent: _keyDiameter,
            ),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final keyLabel = keys[index];
              return GestureDetector(
                onTapDown: (_) => HapticFeedback.selectionClick(),
                onTap: () => onKeyPressed?.call(keyLabel),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      keyLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
