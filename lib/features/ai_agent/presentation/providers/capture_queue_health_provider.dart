import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CaptureQueueHealthSnapshot {
  const CaptureQueueHealthSnapshot({
    required this.pendingSaves,
    required this.pendingLinks,
    required this.nativeCandidates,
  });

  final int pendingSaves;
  final int pendingLinks;
  final int nativeCandidates;

  int get totalPending => pendingSaves + pendingLinks + nativeCandidates;
}

final captureQueueHealthProvider =
    FutureProvider.autoDispose<CaptureQueueHealthSnapshot>(
  (_) async {
    final prefs = await SharedPreferences.getInstance();
    final saves = _safeListLen(prefs.getString('axion_pending_capture_saves_v1'));
    final links = _safeMapLen(prefs.getString('axion_pending_capture_links_v1'));
    final native = _safeListLen(prefs.getString('axion_native_capture_queue_v1'));
    return CaptureQueueHealthSnapshot(
      pendingSaves: saves,
      pendingLinks: links,
      nativeCandidates: native,
    );
  },
);

int _safeListLen(String? raw) {
  if (raw == null || raw.isEmpty) return 0;
  try {
    final decoded = jsonDecode(raw);
    return decoded is List ? decoded.length : 0;
  } catch (_) {
    return 0;
  }
}

int _safeMapLen(String? raw) {
  if (raw == null || raw.isEmpty) return 0;
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map ? decoded.length : 0;
  } catch (_) {
    return 0;
  }
}

