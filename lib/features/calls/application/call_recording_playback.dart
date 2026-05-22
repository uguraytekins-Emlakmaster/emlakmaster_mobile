import 'package:audioplayers/audioplayers.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Çağrı kaydı dinleme — URL varsa uygulama içi, yoksa özet ekranı.
abstract final class CallRecordingPlayback {
  CallRecordingPlayback._();

  static final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  static Future<void> playOrOpenDetail({
    required BuildContext context,
    required String? recordingUrl,
    String? firestoreDocId,
    VoidCallback? onFallback,
  }) async {
    final url = recordingUrl?.trim();
    if (url != null && url.isNotEmpty) {
      try {
        await _player.stop();
        await _player.play(UrlSource(url));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kayıt oynatılıyor…'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      } catch (_) {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
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
