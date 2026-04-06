import 'package:emlakmaster_mobile/core/services/sync_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Anlık çevrimiçi durumu (UI banner için; debounce yok).
final connectivityOnlineProvider = StreamProvider<bool>((ref) {
  return SyncManager.onlineStream;
});

/// Ağ dalgalanmasında tekrarlayan işleri azaltmak için debounce'lu çevrimiçi (senkron tetikleri).
final connectivityOnlineDebouncedProvider = StreamProvider<bool>((ref) {
  return SyncManager.onlineStreamDebounced;
});
