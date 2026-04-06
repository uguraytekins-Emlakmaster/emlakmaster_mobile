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
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final state = deriveLocalCallSyncUiState(record, nowMs: nowMs);
    final tooltip = _tooltipTr(state);
    final child = switch (state) {
      LocalCallSyncUiState.pending => Tooltip(
          message: tooltip,
          child: Icon(Icons.circle, size: 10, color: Colors.amber.shade700),
        ),
      LocalCallSyncUiState.syncing => Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      LocalCallSyncUiState.synced => Tooltip(
          message: tooltip,
          child: Icon(Icons.check_circle_rounded, size: 14, color: Colors.green.shade600),
        ),
      LocalCallSyncUiState.failedRetry => Tooltip(
          message: tooltip,
          child: Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red.shade400),
        ),
      LocalCallSyncUiState.failedPermanent => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: tooltip,
              child: Icon(Icons.error_outline_rounded, size: 14, color: Colors.red.shade700),
            ),
            if (onManualRetry != null)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                iconSize: 16,
                tooltip: 'Tekrar dene',
                onPressed: onManualRetry,
                icon: Icon(Icons.refresh_rounded, color: Theme.of(context).colorScheme.primary),
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
      LocalCallSyncUiState.failedRetry => 'Tekrar deneme zamanlandı',
      LocalCallSyncUiState.failedPermanent => 'Senkron başarısız (süre aşımı)',
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
