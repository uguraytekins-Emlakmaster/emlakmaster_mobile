import 'dart:async' show Timer, unawaited;

import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/voice_crm/data/turkish_speech_locale.dart';
import 'package:emlakmaster_mobile/features/voice_crm/domain/entities/voice_crm_intent.dart';
import 'package:emlakmaster_mobile/features/voice_crm/domain/usecases/extract_voice_crm_intent.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Ses tanıma oturumu özeti — müşteri kaydı vb. için güven ve locale bilgisi.
class PushToTalkSpeechResult {
  const PushToTalkSpeechResult({
    this.text,
    this.shouldReview = false,
    this.activeLocaleId,
    this.confidence,
    this.hadFinalSegments = false,
    this.attemptedSilentRetry = false,
    this.noSpeechAfterRetries = false,
    this.textFromPartialOnly = false,
  });

  /// Birleştirilmiş metin (yoksa null).
  final String? text;

  /// Kısmi sonuçtan düşük güven veya `isConfident` false ise true — kullanıcı düzenlemeli.
  final bool shouldReview;

  /// Kullanılan STT localeId.
  final String? activeLocaleId;

  /// Son segment(ler) için güven (0–1); platform desteklemiyorsa null.
  final double? confidence;

  /// En az bir `finalResult` segmenti alındı mı?
  final bool hadFinalSegments;

  /// Boş sonuçtan sonra bir kez sessizce tekrar dinleme yapıldı mı?
  final bool attemptedSilentRetry;

  /// İlk + sessiz yeniden denemeden sonra hâlâ metin yok (yalnızca [attemptedSilentRetry] true ise anlamlı).
  final bool noSpeechAfterRetries;

  /// Metin yalnızca kısmi sonuçlardan türetildi (final hiç gelmedi).
  final bool textFromPartialOnly;
}

/// idle → listening → waitingFinal (parmak kalktı, grace) → processing → … → idle
enum _PttPhase {
  idle,
  listening,
  waitingFinal,
  processing,
  retryListening,
}

/// Derin zaman damgası (ms epoch) — iOS ayıklama.
class _PttInst {
  int? tapDownMs;
  int? listenStartedMs;
  int? firstPartialMs;
  int? firstFinalMs;
  int? tapUpMs;
  int? stopCallMs;
  int? cancelCallMs;
  int? deliveryMs;
  bool lastTextPartialOnly = false;

  void reset() {
    tapDownMs = null;
    listenStartedMs = null;
    firstPartialMs = null;
    firstFinalMs = null;
    tapUpMs = null;
    stopCallMs = null;
    cancelCallMs = null;
    deliveryMs = null;
    lastTextPartialOnly = false;
  }

  int _now() => DateTime.now().millisecondsSinceEpoch;

  void markTapDown() => tapDownMs = _now();
  void markListenStart() => listenStartedMs = _now();
  void markFirstPartial() => firstPartialMs ??= _now();
  void markFirstFinal() => firstFinalMs ??= _now();
  void markTapUp() => tapUpMs = _now();
  void markStop() => stopCallMs = _now();
  void markCancel() => cancelCallMs = _now();
  void markDelivery() => deliveryMs = _now();

  void logSummary(String prefix) {
    if (!kDebugMode) return;
    debugPrint(
      '$prefix tapDown→listen=${listenStartedMs != null && tapDownMs != null ? listenStartedMs! - tapDownMs! : null}ms '
      'firstPartial=${firstPartialMs != null && listenStartedMs != null ? firstPartialMs! - listenStartedMs! : null}ms '
      'firstFinal=${firstFinalMs != null && listenStartedMs != null ? firstFinalMs! - listenStartedMs! : null}ms '
      'tapUp→stop=${stopCallMs != null && tapUpMs != null ? stopCallMs! - tapUpMs! : null}ms '
      'stop→deliver=${deliveryMs != null && stopCallMs != null ? deliveryMs! - stopCallMs! : null}ms '
      'partialOnly=$lastTextPartialOnly',
    );
  }
}

/// Hands-Free CRM: Push-to-Talk + STT + intent extraction.
class PushToTalkButton extends StatefulWidget {
  const PushToTalkButton({
    super.key,
    this.onSpeechResult,
    this.onResult,
    this.onIntent,
    this.onPhaseChanged,
    this.size = 64,
  });

  final void Function(PushToTalkSpeechResult result)? onSpeechResult;
  final void Function(String? text)? onResult;
  final void Function(VoiceCrmIntent intent)? onIntent;
  final void Function(String phaseLabel)? onPhaseChanged;
  final double size;

  @override
  State<PushToTalkButton> createState() => _PushToTalkButtonState();
}

class _PushToTalkButtonState extends State<PushToTalkButton> {
  _PttPhase _phase = _PttPhase.idle;
  bool _isRecording = false;
  bool _available = false;
  String _previewWords = '';
  final StringBuffer _finalSegments = StringBuffer();
  bool _hadAnyFinal = false;
  double? _lastConfidence;
  String _localeId = 'tr_TR';
  bool _localeIsTurkish = true;

  bool _silentRetryConsumed = false;
  bool _isAutoRetrySession = false;
  bool _suppressStatusRecordingReset = false;

  DateTime? _listenStartedAt;
  Timer? _autoRetryMaxTimer;
  Timer? _stallWatchdogTimer;
  Timer? _graceAfterTapUpTimer;

  bool _outcomeDelivered = false;
  final _PttInst _inst = _PttInst();

  /// kDebugMode altında mikrofon altı etiket
  String _debugUiLabel = 'idle';

  final stt.SpeechToText _speech = stt.SpeechToText();
  final ExtractVoiceCrmIntent _extractor = ExtractVoiceCrmIntent();

  static const Duration _listenFor = Duration(seconds: 45);
  static const Duration _pauseFor = Duration(seconds: 9);
  static const Duration _retryListenFor = Duration(seconds: 45);
  static const Duration _pauseForRetry = Duration(seconds: 10);

  static const Duration _postStopSettleBase = Duration(milliseconds: 320);
  static const Duration _beforeSilentRetry = Duration(milliseconds: 400);
  static const Duration _stallWatchdogDuration = Duration(seconds: 110);

  /// Parmak kalktıktan sonra [stop] öncesi — iOS’ta geç gelen final/kısmi için.
  Duration get _graceAfterTapUp =>
      _isIOS ? const Duration(milliseconds: 480) : const Duration(milliseconds: 280);

  static const int _minPartialCharsForAccept = 2;

  static const int _idlePollMaxIterations = 50;
  static const Duration _idlePollInterval = Duration(milliseconds: 40);

  bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Duration get _postStopSettle =>
      _isIOS ? const Duration(milliseconds: 520) : _postStopSettleBase;

  Duration get _preRelistenDelay =>
      _isIOS ? const Duration(milliseconds: 620) : const Duration(milliseconds: 280);

  Duration get _iosRetryExtraBackoff =>
      _isIOS ? const Duration(milliseconds: 220) : Duration.zero;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[PushToTalk] $message');
    AppLogger.d('[PushToTalk] $message');
  }

  void _setDebugLabel(String label) {
    _debugUiLabel = label;
    if (kDebugMode && mounted) setState(() {});
  }

  Future<void> _initSpeech() async {
    _log('inst init START');
    try {
      _available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      if (_available) {
        _localeId = await resolveTurkishLocaleId(_speech);
        _localeIsTurkish = isTurkishLocaleId(_localeId);
        _log('init OK locale=$_localeId turkish=$_localeIsTurkish');
      }
      if (mounted) setState(() {});
    } catch (e, st) {
      AppLogger.w('PushToTalk init', e, st);
      if (mounted) setState(() => _available = false);
    }
  }

  void _emitPhase(String label) {
    widget.onPhaseChanged?.call(label);
  }

  void _setPhase(_PttPhase p, {required String reason}) {
    if (kDebugMode) {
      debugPrint('[PushToTalk] phase ${_phase.name} → ${p.name} ($reason)');
    }
    _phase = p;
    if (kDebugMode) {
      _setDebugLabel(switch (p) {
        _PttPhase.idle => 'idle',
        _PttPhase.listening => 'listening',
        _PttPhase.waitingFinal => 'waiting-final',
        _PttPhase.processing => 'processing',
        _PttPhase.retryListening => 'retry-listening',
      });
    }
  }

  void _endSessionToIdle({required String reason}) {
    _graceAfterTapUpTimer?.cancel();
    _graceAfterTapUpTimer = null;
    _stallWatchdogTimer?.cancel();
    _stallWatchdogTimer = null;
    _autoRetryMaxTimer?.cancel();
    _autoRetryMaxTimer = null;
    _isAutoRetrySession = false;
    _suppressStatusRecordingReset = false;
    _setPhase(_PttPhase.idle, reason: reason);
    if (mounted) setState(() => _isRecording = false);
    if (kDebugMode) _setDebugLabel('idle');
  }

  void _armStallWatchdog() {
    _stallWatchdogTimer?.cancel();
    _stallWatchdogTimer = Timer(_stallWatchdogDuration, () {
      if (!mounted || _phase == _PttPhase.idle) return;
      _log('WATCHDOG');
      unawaited(_recoverStalledSession());
    });
  }

  Future<void> _recoverStalledSession() async {
    if (!mounted || _phase == _PttPhase.idle) return;
    _graceAfterTapUpTimer?.cancel();
    _autoRetryMaxTimer?.cancel();
    _isAutoRetrySession = false;
    await _forceSpeechIdle(reason: 'stall_watchdog');
    if (!mounted) return;
    if (!_outcomeDelivered) {
      _deliverResult(
        text: null,
        listenDuration: Duration.zero,
        attemptedSilentRetry: _silentRetryConsumed,
        forceNoSpeechAfterRetries: true,
        textFromPartialOnly: false,
      );
    }
    _endSessionToIdle(reason: 'stall_watchdog');
    _emitPhase('');
  }

  Future<void> _waitUntilNotListening({required String reason}) async {
    for (var i = 0; i < _idlePollMaxIterations; i++) {
      if (!_speech.isListening) {
        _log('idleOK reason=$reason after ${i * _idlePollInterval.inMilliseconds}ms');
        return;
      }
      await Future<void>.delayed(_idlePollInterval);
    }
    if (_speech.isListening) {
      _log('idleWARN still listening after poll reason=$reason');
    }
  }

  Future<void> _forceSpeechIdle({required String reason}) async {
    _inst.markCancel();
    _log('RESET cancel reason=$reason isListening=${_speech.isListening}');
    try {
      await _speech.cancel();
    } catch (e, st) {
      AppLogger.w('PushToTalk cancel', e, st);
    }
    await Future<void>.delayed(_preRelistenDelay);
    if (_speech.isListening) {
      _inst.markStop();
      try {
        await _speech.stop();
      } catch (e, st) {
        AppLogger.w('PushToTalk stop', e, st);
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    await _waitUntilNotListening(reason: 'forceIdle');
  }

  Future<void> _ensureReadyBeforeListen({required String reason}) async {
    if (_speech.isListening) {
      await _forceSpeechIdle(reason: 'preclean:$reason');
    }
    if (_isIOS) {
      await Future<void>.delayed(_iosRetryExtraBackoff);
    }
  }

  void _onStatus(String status) {
    if (kDebugMode) {
      debugPrint(
        '[PushToTalk] onStatus=$status phase=${_phase.name} autoRetry=$_isAutoRetrySession '
        'grace=${_graceAfterTapUpTimer != null} isListening=${_speech.isListening}',
      );
    }
    if (_phase == _PttPhase.waitingFinal) {
      return;
    }
    if (_isAutoRetrySession && (status == 'done' || status == 'notListening')) {
      if (_graceAfterTapUpTimer != null) return;
      _autoRetryMaxTimer?.cancel();
      _autoRetryMaxTimer = null;
      unawaited(_finalizeAutoRetryStop(trigger: 'status:$status'));
      return;
    }
    if ((status == 'done' || status == 'notListening') &&
        _isRecording &&
        !_suppressStatusRecordingReset &&
        !_isAutoRetrySession &&
        _phase != _PttPhase.waitingFinal) {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  void _onError(SpeechRecognitionError error) {
    _log(
      'onError ${error.errorMsg} permanent=${error.permanent}',
    );
    AppLogger.w('PushToTalk STT', error.errorMsg);
    unawaited(_recoverFromSpeechError(error));
  }

  Future<void> _recoverFromSpeechError(SpeechRecognitionError error) async {
    if (!mounted || _phase == _PttPhase.idle) return;
    _graceAfterTapUpTimer?.cancel();
    _graceAfterTapUpTimer = null;
    _setPhase(_PttPhase.processing, reason: 'error_incoming');
    if (kDebugMode) _setDebugLabel('recovered-from-error');
    _autoRetryMaxTimer?.cancel();
    _isAutoRetrySession = false;
    await _forceSpeechIdle(reason: 'onError:${error.errorMsg}');
    if (!mounted) return;
    _deliverResult(
      text: null,
      listenDuration: Duration.zero,
      attemptedSilentRetry: _silentRetryConsumed,
      forceNoSpeechAfterRetries: true,
      textFromPartialOnly: false,
    );
    _endSessionToIdle(reason: 'error_recovery');
    _emitPhase('');
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (kDebugMode) {
      final w = result.recognizedWords;
      debugPrint(
        '[PushToTalk] onResult final=${result.finalResult} conf=${result.confidence} '
        'len=${w.length} words="${w.length > 60 ? '${w.substring(0, 60)}…' : w}"',
      );
    }
    _previewWords = result.recognizedWords;
    if (!result.finalResult && result.recognizedWords.trim().isNotEmpty) {
      _inst.markFirstPartial();
      _emitPhase('Anlıyorum…');
    }
    if (result.finalResult) {
      _inst.markFirstFinal();
      _hadAnyFinal = true;
      final seg = result.recognizedWords.trim();
      if (seg.isNotEmpty) {
        if (_finalSegments.isNotEmpty) _finalSegments.write(' ');
        _finalSegments.write(seg);
      }
      _lastConfidence = result.confidence;
    }
    if (mounted) setState(() {});
  }

  bool _isMeaningfulPartial(String s) => s.trim().length >= _minPartialCharsForAccept;

  /// Final buffer öncelikli; yoksa anlamlı kısmi metin (iOS’ta final gecikebilir).
  String? _composeRecognizedText() {
    final committed = _finalSegments.toString().trim();
    final preview = _previewWords.trim();
    if (committed.isNotEmpty) {
      _inst.lastTextPartialOnly = false;
      return committed;
    }
    if (_isMeaningfulPartial(preview)) {
      _inst.lastTextPartialOnly = true;
      return preview;
    }
    _inst.lastTextPartialOnly = false;
    return null;
  }

  Future<void> _startListening() async {
    if (!_available || _phase != _PttPhase.idle) return;
    await _ensureReadyBeforeListen(reason: 'tap_down');

    _inst.reset();
    _inst.markTapDown();
    _silentRetryConsumed = false;
    _outcomeDelivered = false;
    HapticFeedback.mediumImpact();
    _finalSegments.clear();
    _hadAnyFinal = false;
    _previewWords = '';
    _lastConfidence = null;
    _listenStartedAt = DateTime.now();
    _setPhase(_PttPhase.listening, reason: 'listen_start');
    _inst.markListenStart();
    setState(() => _isRecording = true);
    _emitPhase('Sesiniz alınıyor');
    _armStallWatchdog();
    _log('listen START locale=$_localeId');

    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: _listenFor,
        pauseFor: _pauseFor,
        localeId: _localeId,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e, st) {
      AppLogger.w('PushToTalk listen', e, st);
      await _forceSpeechIdle(reason: 'listen_catch');
      _endSessionToIdle(reason: 'listen_failed');
      _emitPhase('');
    }
  }

  Future<void> _stopListening() async {
    if (_isAutoRetrySession || _phase == _PttPhase.retryListening) {
      _graceAfterTapUpTimer?.cancel();
      _inst.markTapUp();
      _setPhase(_PttPhase.waitingFinal, reason: 'retry_tap_grace');
      _suppressStatusRecordingReset = true;
      HapticFeedback.lightImpact();
      _emitPhase('Sonuç bekleniyor…');
      if (kDebugMode) _setDebugLabel('waiting-final');
      setState(() => _isRecording = false);
      _graceAfterTapUpTimer = Timer(_graceAfterTapUp, () {
        unawaited(_finalizeAutoRetryStop(trigger: 'user_after_grace'));
      });
      return;
    }

    if (_phase != _PttPhase.listening) return;

    _graceAfterTapUpTimer?.cancel();
    _inst.markTapUp();
    _setPhase(_PttPhase.waitingFinal, reason: 'tap_up_grace');
    _suppressStatusRecordingReset = true;
    HapticFeedback.lightImpact();
    _emitPhase('Sonuç bekleniyor…');
    if (kDebugMode) _setDebugLabel('waiting-final');
    setState(() => _isRecording = false);

    if (kDebugMode) {
      debugPrint(
        '[PushToTalk] GRACE ${_graceAfterTapUp.inMilliseconds}ms before stop()',
      );
    }

    _graceAfterTapUpTimer = Timer(_graceAfterTapUp, () {
      unawaited(_completeFirstPassStopAfterGrace());
    });
  }

  Future<void> _completeFirstPassStopAfterGrace() async {
    if (!mounted) return;
    if (_outcomeDelivered) return;
    if (_phase != _PttPhase.waitingFinal) return;

    _setPhase(_PttPhase.processing, reason: 'grace_done_stop');
    _inst.markStop();
    _log('stop() after grace');
    try {
      await _speech.stop();
    } catch (e, st) {
      AppLogger.w('PushToTalk stop', e, st);
    }
    await Future<void>.delayed(_postStopSettle);
    _suppressStatusRecordingReset = false;

    final tAfterStop = DateTime.now();
    final listened = _listenStartedAt != null
        ? tAfterStop.difference(_listenStartedAt!)
        : Duration.zero;

    final text = _composeRecognizedText();
    final partialOnly = _inst.lastTextPartialOnly;

    if (kDebugMode) {
      debugPrint(
        '[PushToTalk] afterStop textLen=${text?.length ?? 0} partialOnly=$partialOnly '
        'hadFinal=$_hadAnyFinal preview="${_previewWords.length > 40 ? '${_previewWords.substring(0, 40)}…' : _previewWords}"',
      );
    }

    if (text != null &&
        text.isNotEmpty &&
        partialOnly &&
        !_hadAnyFinal) {
      _emitPhase('Tamamlanıyor…');
      _deliverResult(
        text: text,
        listenDuration: listened,
        attemptedSilentRetry: false,
        forceNoSpeechAfterRetries: false,
        textFromPartialOnly: true,
      );
      _inst.markDelivery();
      _inst.logSummary('[PushToTalk] INST');
      _endSessionToIdle(reason: 'partial_only_ok');
      _emitPhase('');
      return;
    }

    if ((text == null || text.isEmpty) && !_silentRetryConsumed) {
      _silentRetryConsumed = true;
      await _forceSpeechIdle(reason: 'empty_before_retry');
      await Future<void>.delayed(_beforeSilentRetry);
      if (_isIOS) await Future<void>.delayed(_iosRetryExtraBackoff);
      await _waitUntilNotListening(reason: 'pre_retry_listen');

      if (!mounted || !_available) {
        _isAutoRetrySession = false;
        _deliverResult(
          text: null,
          listenDuration: listened,
          attemptedSilentRetry: true,
          forceNoSpeechAfterRetries: true,
          textFromPartialOnly: false,
        );
        _inst.markDelivery();
        _endSessionToIdle(reason: 'unmounted_before_retry');
        _emitPhase('');
        return;
      }

      _isAutoRetrySession = true;
      _setPhase(_PttPhase.retryListening, reason: 'silent_retry');
      _emitPhase('Bir kez daha dinliyorum');
      _finalSegments.clear();
      _hadAnyFinal = false;
      _previewWords = '';
      _lastConfidence = null;
      _listenStartedAt = DateTime.now();
      _inst.markListenStart();
      setState(() => _isRecording = true);

      try {
        await _speech.listen(
          onResult: _onSpeechResult,
          listenFor: _retryListenFor,
          pauseFor: _pauseForRetry,
          localeId: _localeId,
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.dictation,
          ),
        );
      } catch (e, st) {
        AppLogger.w('PushToTalk retry listen', e, st);
        await _forceSpeechIdle(reason: 'retry_listen_catch');
        _deliverResult(
          text: null,
          listenDuration: listened,
          attemptedSilentRetry: true,
          forceNoSpeechAfterRetries: true,
          textFromPartialOnly: false,
        );
        _inst.markDelivery();
        _endSessionToIdle(reason: 'retry_listen_failed');
        _emitPhase('');
        return;
      }

      _autoRetryMaxTimer?.cancel();
      _autoRetryMaxTimer = Timer(_retryListenFor, () {
        if (mounted && _isRecording) {
          unawaited(_finalizeAutoRetryStop(trigger: 'retry_timer_max'));
        }
      });
      return;
    }

    _emitPhase('Tamamlanıyor…');
    _deliverResult(
      text: text,
      listenDuration: listened,
      attemptedSilentRetry: false,
      forceNoSpeechAfterRetries: false,
      textFromPartialOnly: partialOnly && !_hadAnyFinal,
    );
    _inst.markDelivery();
    _inst.logSummary('[PushToTalk] INST');
    _endSessionToIdle(reason: 'done_first_pass');
    _emitPhase('');
  }

  Future<void> _finalizeAutoRetryStop({required String trigger}) async {
    if (_outcomeDelivered) return;
    if (!_isAutoRetrySession) return;
    _graceAfterTapUpTimer?.cancel();
    _graceAfterTapUpTimer = null;
    _isAutoRetrySession = false;
    _autoRetryMaxTimer?.cancel();
    _autoRetryMaxTimer = null;

    _setPhase(_PttPhase.processing, reason: 'finalize_retry:$trigger');
    _emitPhase('Hazırlanıyor…');
    _suppressStatusRecordingReset = true;
    _inst.markStop();
    try {
      await _speech.stop();
    } catch (e, st) {
      AppLogger.w('PushToTalk retry stop', e, st);
    }
    await Future<void>.delayed(_postStopSettle);
    _suppressStatusRecordingReset = false;

    await _forceSpeechIdle(reason: 'after_retry_$trigger');
    if (_isIOS) await Future<void>.delayed(_iosRetryExtraBackoff);

    final endedAt = DateTime.now();
    final listened = _listenStartedAt != null
        ? endedAt.difference(_listenStartedAt!)
        : Duration.zero;

    final text = _composeRecognizedText();
    final partialOnly = _inst.lastTextPartialOnly;

    _emitPhase('Tamamlanıyor…');
    final empty = text == null || text.isEmpty;
    _deliverResult(
      text: text,
      listenDuration: listened,
      attemptedSilentRetry: true,
      forceNoSpeechAfterRetries: empty,
      textFromPartialOnly: partialOnly && !_hadAnyFinal && !empty,
    );
    _inst.markDelivery();
    _inst.logSummary('[PushToTalk] INST retry');
    _endSessionToIdle(reason: 'retry_complete');
    _emitPhase('');
  }

  void _deliverResult({
    required String? text,
    required Duration listenDuration,
    required bool attemptedSilentRetry,
    required bool forceNoSpeechAfterRetries,
    required bool textFromPartialOnly,
  }) {
    if (_outcomeDelivered) {
      _log('DELIVER duplicate blocked');
      return;
    }
    _outcomeDelivered = true;
    if (!mounted) return;

    var shouldReview = false;
    if (text != null && text.isNotEmpty) {
      if (textFromPartialOnly || !_hadAnyFinal) {
        shouldReview = true;
      } else if (_lastConfidence != null &&
          _lastConfidence != SpeechRecognitionWords.missingConfidence &&
          _lastConfidence! < SpeechRecognitionWords.confidenceThreshold) {
        shouldReview = true;
      }
    }

    var noSpeech = forceNoSpeechAfterRetries ||
        (attemptedSilentRetry && (text == null || text.isEmpty));
    if (text != null && text.isNotEmpty) {
      noSpeech = false;
    }

    if (kDebugMode) {
      debugPrint(
        '[PushToTalk] DELIVER textLen=${text?.length ?? 0} shouldReview=$shouldReview '
        'partialOnly=$textFromPartialOnly noSpeech=$noSpeech',
      );
    }

    double? deliveredConfidence;
    if (text != null && text.isNotEmpty) {
      final c = _lastConfidence;
      if (c != null && c != SpeechRecognitionWords.missingConfidence) {
        deliveredConfidence = c.clamp(0.0, 1.0);
      }
    }

    final out = PushToTalkSpeechResult(
      text: text,
      shouldReview: shouldReview,
      activeLocaleId: _localeId,
      confidence: deliveredConfidence,
      hadFinalSegments: _hadAnyFinal,
      attemptedSilentRetry: attemptedSilentRetry,
      noSpeechAfterRetries: noSpeech,
      textFromPartialOnly: textFromPartialOnly,
    );
    widget.onSpeechResult?.call(out);
    widget.onResult?.call(text);
    if (text != null && text.isNotEmpty) {
      final intent = _extractor.call(text);
      widget.onIntent?.call(intent);
    }
  }

  @override
  void dispose() {
    _graceAfterTapUpTimer?.cancel();
    _stallWatchdogTimer?.cancel();
    _autoRetryMaxTimer?.cancel();
    unawaited(_speech.cancel());
    super.dispose();
  }

  bool get _showActiveMic =>
      _phase == _PttPhase.listening ||
      _phase == _PttPhase.retryListening ||
      _phase == _PttPhase.waitingFinal ||
      _phase == _PttPhase.processing;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final borderWidth = _phase == _PttPhase.idle ? 0.0 : 2.0;
    final borderColor = switch (_phase) {
      _PttPhase.idle => Colors.transparent,
      _PttPhase.listening => ext.accent,
      _PttPhase.waitingFinal => ext.warning,
      _PttPhase.processing => ext.textTertiary,
      _PttPhase.retryListening => ext.warning,
    };
    final circleColor = !_available
        ? ext.textTertiary
        : switch (_phase) {
            _PttPhase.idle => ext.accent,
            _PttPhase.listening => ext.danger,
            _PttPhase.retryListening => ext.danger,
            _PttPhase.waitingFinal => ext.surfaceElevated,
            _PttPhase.processing => ext.surfaceElevated,
          };
    final shadowColor = switch (_phase) {
      _PttPhase.processing => ext.textTertiary,
      _PttPhase.waitingFinal => ext.textTertiary,
      _PttPhase.idle => ext.accent,
      _ => ext.danger,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => _startListening(),
          onTapUp: (_) => _stopListening(),
          onTapCancel: _stopListening,
          child: AnimatedContainer(
            duration: DesignTokens.durationFast,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: borderWidth > 0
                  ? Border.all(color: borderColor, width: borderWidth)
                  : null,
              color: circleColor,
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withValues(
                    alpha: (_phase == _PttPhase.processing || _phase == _PttPhase.waitingFinal)
                        ? 0.28
                        : 0.4,
                  ),
                  blurRadius: _showActiveMic ? 14 : 12,
                  spreadRadius: _showActiveMic ? 1 : 0,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_phase == _PttPhase.processing || _phase == _PttPhase.waitingFinal)
                  SizedBox(
                    width: widget.size * 0.38,
                    height: widget.size * 0.38,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ext.accent,
                    ),
                  )
                else
                  Icon(
                    _showActiveMic ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: ext.onAccentLight,
                    size: widget.size * 0.45,
                  ),
                Positioned(
                  right: widget.size * 0.08,
                  bottom: widget.size * 0.08,
                  child: _buildMicroCue(ext),
                ),
              ],
            ),
          ),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 6),
          Text(
            _debugUiLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: ext.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMicroCue(AppThemeExtension ext) {
    if (_phase == _PttPhase.idle) return const SizedBox.shrink();
    final cue = switch (_phase) {
      _PttPhase.waitingFinal => ext.warning,
      _PttPhase.processing => ext.textSecondary,
      _PttPhase.retryListening => ext.warning,
      _ => ext.accent,
    };
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cue,
        border: Border.all(color: Colors.black26, width: 0.5),
        boxShadow: [
          BoxShadow(color: cue.withValues(alpha: 0.5), blurRadius: 3),
        ],
      ),
    );
  }
}
