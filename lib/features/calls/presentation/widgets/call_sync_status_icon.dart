import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/domain/local_call_sync_ui_state.dart';
import 'package:flutter/material.dart';

/// Yerel çağrı senkron durumu — küçük ikon (satırı kalabalık etmez).
class CallSyncStatusIcon extends StatelessWidget {
  const CallSyncStatusIcon({
    super.key,
    required this.record,
    this.onManualRetry,
  });

  final LocalCallRecord record;
  final VoidCallback? onManualRetry;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final scheme = Theme.of(context).colorScheme;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final state = deriveLocalCallSyncUiState(record, nowMs: nowMs);
    final tooltip = _tooltipTr(state);
    final child = switch (state) {
      LocalCallSyncUiState.pending => Tooltip(
          message: tooltip,
          child: Icon(Icons.circle, size: 10, color: ext.warning),
        ),
      LocalCallSyncUiState.syncing => Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: scheme.primary.withValues(alpha: 0.85),
            ),
          ),
        ),
      LocalCallSyncUiState.synced => Tooltip(
          message: tooltip,
          child: Icon(Icons.check_circle_rounded, size: 14, color: ext.success),
        ),
      LocalCallSyncUiState.failedRetry => Tooltip(
          message: tooltip,
          child: Icon(Icons.schedule_rounded,
              size: 13, color: ext.warning.withValues(alpha: 0.9)),
        ),
      LocalCallSyncUiState.failedPermanent => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: tooltip,
              child: Icon(Icons.cloud_off_outlined,
                  size: 13, color: ext.danger.withValues(alpha: 0.82)),
            ),
            if (onManualRetry != null)
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                iconSize: 15,
                tooltip: 'Tekrar dene',
                onPressed: onManualRetry,
                icon: Icon(Icons.refresh_rounded,
                    color: scheme.primary.withValues(alpha: 0.9)),
              ),
          ],
        ),
    };
    return child;
  }

  static String _tooltipTr(LocalCallSyncUiState s) {
    return switch (s) {
      LocalCallSyncUiState.pending => 'Senkron bekleniyor',
      LocalCallSyncUiState.syncing => 'Senkronize ediliyor…',
      LocalCallSyncUiState.synced => 'Buluta kaydedildi',
      LocalCallSyncUiState.failedRetry => 'Otomatik yeniden denenecek',
      LocalCallSyncUiState.failedPermanent =>
        'Buluta iletilemedi · Tekrar deneyin',
    };
  }
}

/// Firestore’da olan, bu cihazda eşleşen Hive satırı olmayan çağrılar — aynı hizayı korur, sade gösterge.
class ServerOnlyCallSourceIcon extends StatelessWidget {
  const ServerOnlyCallSourceIcon({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.42);
    return Tooltip(
      message: 'Sunucu kaydı — bu cihazda bekleyen yerel senkron kuyruğu yok',
      child: Icon(Icons.cloud_done_outlined, size: size, color: muted),
    );
  }
}
