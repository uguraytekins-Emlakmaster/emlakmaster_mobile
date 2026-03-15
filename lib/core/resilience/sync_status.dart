import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sync_manager.dart';

/// Uygulama senkron durumu: çevrimiçi/çevrimdışı, son senkron zamanı.
/// UI "Son senkron: 2 dk önce" veya "Çevrimdışı" göstermek için kullanır.
class SyncStatus {
  const SyncStatus({
    required this.isOnline,
    this.lastSyncAt,
  });

  final bool isOnline;
  final DateTime? lastSyncAt;

  String get shortLabel {
    if (!isOnline) return 'Çevrimdışı';
    if (lastSyncAt == null) return 'Bağlandı';
    final diff = DateTime.now().difference(lastSyncAt!);
    if (diff.inSeconds < 60) return 'Şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    return '${diff.inDays} gün önce';
  }
}

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  SyncStatusNotifier() : super(SyncStatus(isOnline: SyncManager.instance.isOnline, lastSyncAt: SyncManager.instance.isOnline ? DateTime.now() : null)) {
    _sub = SyncManager.onlineStream.listen((online) {
      final now = DateTime.now();
      state = SyncStatus(
        isOnline: online,
        lastSyncAt: online ? (state.lastSyncAt ?? now) : state.lastSyncAt,
      );
    });
  }

  late final StreamSubscription<bool> _sub;

  void recordSyncSuccess() {
    state = SyncStatus(isOnline: state.isOnline, lastSyncAt: DateTime.now());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  return SyncStatusNotifier();
});
