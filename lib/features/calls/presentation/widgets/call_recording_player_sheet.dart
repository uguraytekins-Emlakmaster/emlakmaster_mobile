import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/application/call_recording_playback.dart';
import 'package:flutter/material.dart';

String _formatMmSs(Duration d) {
  final total = d.inSeconds;
  final m = total ~/ 60;
  final s = total % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// Kayıt oynatıcı — duraklat ve ilerleme çubuğu.
Future<void> showCallRecordingPlayerSheet(
  BuildContext context, {
  String? title,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _CallRecordingPlayerSheetBody(title: title),
  ).whenComplete(() async {
    await CallRecordingPlayback.stop();
  });
}

class _CallRecordingPlayerSheetBody extends StatelessWidget {
  const _CallRecordingPlayerSheetBody({this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final label = title?.trim();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space3,
        DesignTokens.space4,
        DesignTokens.space4,
      ),
      decoration: BoxDecoration(
        color: ext.card,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
        border: Border.all(color: ext.border.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ext.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Text(
            label != null && label.isNotEmpty ? label : 'Çağrı kaydı',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ext.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: DesignTokens.space3),
          ValueListenableBuilder<CallRecordingPlaybackState>(
            valueListenable: CallRecordingPlayback.notifier,
            builder: (context, state, _) {
              final duration = state.duration ?? Duration.zero;
              final maxMs = duration.inMilliseconds > 0
                  ? duration.inMilliseconds.toDouble()
                  : 1.0;
              final valueMs = state.position.inMilliseconds
                  .clamp(0, duration.inMilliseconds > 0
                      ? duration.inMilliseconds
                      : 0)
                  .toDouble();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: ext.accent.withValues(alpha: 0.18),
                          foregroundColor: ext.accent,
                        ),
                        onPressed: state.loading
                            ? null
                            : () => CallRecordingPlayback.togglePause(),
                        icon: Icon(
                          state.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.space2),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                          ),
                          child: Slider(
                            value: valueMs,
                            max: maxMs,
                            onChanged: state.loading || duration.inMilliseconds <= 0
                                ? null
                                : (v) => CallRecordingPlayback.seek(
                                      Duration(milliseconds: v.round()),
                                    ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatMmSs(state.position),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: ext.textSecondary,
                              ),
                        ),
                        Text(
                          duration.inMilliseconds > 0
                              ? _formatMmSs(duration)
                              : '—',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: ext.textTertiary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (state.loading)
                    Padding(
                      padding: const EdgeInsets.only(top: DesignTokens.space2),
                      child: LinearProgressIndicator(
                        color: ext.accent,
                        backgroundColor: ext.border.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
