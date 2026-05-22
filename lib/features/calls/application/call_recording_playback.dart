import 'package:audioplayers/audioplayers.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_recording_player_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Çağrı kaydı oynatma durumu — mini oynatıcı sheet ile paylaşılır.
class CallRecordingPlaybackState {
  const CallRecordingPlaybackState({
    this.url,
    this.position = Duration.zero,
    this.duration,
    this.playing = false,
    this.loading = false,
  });

  final String? url;
  final Duration position;
  final Duration? duration;
  final bool playing;
  final bool loading;

  CallRecordingPlaybackState copyWith({
    String? url,
    Duration? position,
    Duration? duration,
    bool? playing,
    bool? loading,
    bool clearUrl = false,
  }) {
    return CallRecordingPlaybackState(
      url: clearUrl ? null : (url ?? this.url),
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playing: playing ?? this.playing,
      loading: loading ?? this.loading,
    );
  }
}

/// Çağrı kaydı dinleme — uygulama içi oynatıcı, yoksa özet ekranı.
abstract final class CallRecordingPlayback {
  CallRecordingPlayback._();

  static final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  static final ValueNotifier<CallRecordingPlaybackState> notifier =
      ValueNotifier(const CallRecordingPlaybackState());

  static bool _listenersAttached = false;

  static void _ensureListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;
    _player.onPositionChanged.listen((position) {
      notifier.value = notifier.value.copyWith(position: position);
    });
    _player.onDurationChanged.listen((duration) {
      notifier.value = notifier.value.copyWith(duration: duration);
    });
    _player.onPlayerComplete.listen((_) {
      notifier.value = notifier.value.copyWith(
        playing: false,
        position: Duration.zero,
      );
    });
    _player.onPlayerStateChanged.listen((state) {
      final urlActive = notifier.value.url != null;
      notifier.value = notifier.value.copyWith(
        playing: state == PlayerState.playing,
        loading: urlActive &&
            state != PlayerState.playing &&
            state != PlayerState.paused &&
            state != PlayerState.completed,
      );
    });
  }

  static Future<void> stop() async {
    await _player.stop();
    notifier.value = const CallRecordingPlaybackState();
  }

  static Future<bool> start(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    _ensureListeners();
    notifier.value = CallRecordingPlaybackState(
      url: trimmed,
      loading: true,
      position: Duration.zero,
    );
    try {
      await _player.stop();
      await _player.play(UrlSource(trimmed));
      return true;
    } catch (_) {
      notifier.value = const CallRecordingPlaybackState();
      return false;
    }
  }

  static Future<void> togglePause() async {
    if (notifier.value.playing) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  static Future<void> seek(Duration position) async {
    await _player.seek(position);
    notifier.value = notifier.value.copyWith(position: position);
  }

  static Future<void> playOrOpenDetail({
    required BuildContext context,
    required String? recordingUrl,
    String? firestoreDocId,
    String? title,
    VoidCallback? onFallback,
  }) async {
    final url = recordingUrl?.trim();
    if (url != null && url.isNotEmpty) {
      final started = await start(url);
      if (started && context.mounted) {
        await showCallRecordingPlayerSheet(
          context,
          title: title,
        );
        return;
      }
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    final docId = firestoreDocId?.trim();
    if (docId != null && docId.isNotEmpty && context.mounted) {
      context.push(
        AppRouter.routeCallSummary,
        extra: {'callDocId': docId},
      );
      return;
    }
    onFallback?.call();
  }
}
