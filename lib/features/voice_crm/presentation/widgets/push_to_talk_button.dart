import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/voice_crm/domain/entities/voice_crm_intent.dart';
import 'package:emlakmaster_mobile/features/voice_crm/domain/usecases/extract_voice_crm_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
/// Hands-Free CRM: Push-to-Talk + STT + intent extraction.
class PushToTalkButton extends StatefulWidget {
  const PushToTalkButton({
    super.key,
    this.onResult,
    this.onIntent,
    this.size = 64,
  });

  /// Ham metin (STT çıktısı).
  final void Function(String? text)? onResult;
  /// Yapılandırılmış aksiyon (teklif, hatırlatma, özet).
  final void Function(VoiceCrmIntent intent)? onIntent;
  final double size;

  @override
  State<PushToTalkButton> createState() => _PushToTalkButtonState();
}

class _PushToTalkButtonState extends State<PushToTalkButton> {
  bool _isRecording = false;
  bool _available = false;
  String _lastWords = '';
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ExtractVoiceCrmIntent _extractor = ExtractVoiceCrmIntent();

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _available = await _speech.initialize(
        onStatus: (s) => _onStatus(s),
        onError: (e) => _onError(e),
      );
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _available = false);
    }
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  void _onError(dynamic error) {
    if (mounted) setState(() => _isRecording = false);
  }

  Future<void> _startListening() async {
    if (!_available || _isRecording) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isRecording = true;
      _lastWords = '';
    });
    try {
      await _speech.listen(
        onResult: (result) {
          if (mounted) setState(() => _lastWords = result.recognizedWords);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        localeId: 'tr_TR',
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  Future<void> _stopListening() async {
    if (!_isRecording) return;
    HapticFeedback.lightImpact();
    await _speech.stop();
    setState(() => _isRecording = false);
    final text = _lastWords.trim().isNotEmpty ? _lastWords.trim() : null;
    widget.onResult?.call(text);
    if (text != null && text.isNotEmpty) {
      final intent = _extractor.call(text);
      widget.onIntent?.call(intent);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startListening(),
      onTapUp: (_) => _stopListening(),
      onTapCancel: _stopListening,
      child: AnimatedContainer(
        duration: DesignTokens.durationFast,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isRecording ? AppThemeExtension.of(context).danger : (_available ? AppThemeExtension.of(context).accent : AppThemeExtension.of(context).textTertiary),
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? AppThemeExtension.of(context).danger : AppThemeExtension.of(context).accent).withValues(alpha: 0.4),
              blurRadius: _isRecording ? 16 : 12,
              spreadRadius: _isRecording ? 2 : 0,
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
          color: AppThemeExtension.of(context).onAccentLight,
          size: widget.size * 0.45,
        ),
      ),
    );
  }
}
