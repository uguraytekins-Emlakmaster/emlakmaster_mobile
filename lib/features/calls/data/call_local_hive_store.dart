import 'dart:convert';

import 'package:emlakmaster_mobile/core/cache/app_cache_service.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/features/calls/data/call_record_sync_constants.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/data/pending_handoff_outbound_queue.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Çağrı kayıtları — önce yerel (Hive), sonra arka planda Firestore.
class CallLocalHiveStore {
  CallLocalHiveStore._();
  static final CallLocalHiveStore instance = CallLocalHiveStore._();

  static const String _boxName = 'call_records_local_v1';
  Box<String>? _box;
  bool _initDone = false;

  String _key(String agentId, String localId) => '$agentId::$localId';

  Future<void> ensureInit() async {
    if (_initDone) return;
    try {
      await AppCacheService.instance.ensureInit();
      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox<String>(_boxName);
      } else {
        _box = Hive.box<String>(_boxName);
      }
      _initDone = true;
    } catch (e, st) {
      AppLogger.e('CallLocalHiveStore init', e, st);
    }
  }

  Box<String>? get _b => _box;

  Future<void> putRecord(LocalCallRecord record) async {
    await ensureInit();
    final b = _b;
    if (b == null) return;
    await b.put(_key(record.agentId, record.id), jsonEncode(record.toJson()));
  }

  Future<LocalCallRecord?> get(String agentId, String localId) async {
    await ensureInit();
    final b = _b;
    if (b == null) return null;
    return LocalCallRecord.tryDecode(b.get(_key(agentId, localId)));
  }

  /// Takılı senkron kilitlerini temizler.
  Future<void> applyStaleSyncingLocks(String agentId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await ensureInit();
    final b = _b;
    if (b == null || agentId.isEmpty) return;
    final prefix = '$agentId::';
    for (final key in b.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;
      final r = LocalCallRecord.tryDecode(b.get(key));
      if (r == null || !r.isSyncing || r.syncingSinceMs == null) continue;
      if (now - r.syncingSinceMs! <= CallRecordSyncConstants.staleSyncingLockMs) {
        continue;
      }
      await putRecord(
        r.copyWith(
          isSyncing: false,
          clearSyncingSince: true,
        ),
      );
    }
  }

  /// 24 saat penceresi aşıldıysa kalıcı başarısız işaretler.
  Future<void> applyExpiredPermanentWindow(String agentId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await ensureInit();
    final b = _b;
    if (b == null || agentId.isEmpty) return;
    final prefix = '$agentId::';
    for (final key in b.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;
      final r = LocalCallRecord.tryDecode(b.get(key));
      if (r == null || r.isSynced || r.syncFailedPermanent) continue;
      if (now <= r.createdAt + CallRecordSyncConstants.maxRetryWindowMs) continue;
      await putRecord(r.copyWith(syncFailedPermanent: true));
    }
  }

  /// Arama başında — idempotent (aynı [localId] tekrar yazılmaz).
  Future<void> insertCallStart({
    required String agentId,
    required String localId,
    required String phoneNumber,
    int? createdAtMs,
    String? customerId,
    required String startedFromScreen,
  }) async {
    await ensureInit();
    final b = _b;
    if (b == null) return;
    final key = _key(agentId, localId);
    if (b.containsKey(key)) return;

    final now = createdAtMs ?? DateTime.now().millisecondsSinceEpoch;
    final record = LocalCallRecord(
      id: localId,
      phoneNumber: phoneNumber,
      agentId: agentId,
      createdAt: now,
      startedFromScreen: startedFromScreen,
      customerId: customerId,
    );
    await b.put(key, jsonEncode(record.toJson()));
  }

  Future<void> setSyncing({
    required String agentId,
    required String localId,
    required bool syncing,
  }) async {
    final existing = await get(agentId, localId);
    if (existing == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await putRecord(
      existing.copyWith(
        isSyncing: syncing,
        syncingSinceMs: syncing ? now : null,
        clearSyncingSince: !syncing,
      ),
    );
  }

  /// CRM oturumu Firestore’a yazıldığında — sunucuda satır var sayılır.
  Future<void> linkFirestoreSession({
    required String agentId,
    required String localId,
    required String firestoreDocumentId,
  }) async {
    final existing = await get(agentId, localId);
    if (existing == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await putRecord(
      existing.copyWith(
        firestoreDocumentId: firestoreDocumentId,
        isSynced: true,
        lastSyncAt: now,
        syncAttemptCount: 0,
        isSyncing: false,
        clearSyncingSince: true,
        clearNextRetry: true,
      ),
    );
  }

  Future<void> replaceFirestoreDocumentId({
    required String agentId,
    required String localId,
    required String firestoreDocumentId,
  }) async {
    final existing = await get(agentId, localId);
    if (existing == null) return;
    await putRecord(existing.copyWith(firestoreDocumentId: firestoreDocumentId));
  }

  static Map<String, dynamic> _mergePendingJson(
    String? existingJson,
    String outcomeCode,
    String? notes,
    int? followUpReminderAtMs,
  ) {
    Map<String, dynamic> base = {};
    if (existingJson != null && existingJson.trim().isNotEmpty) {
      try {
        base = Map<String, dynamic>.from(
          jsonDecode(existingJson) as Map<dynamic, dynamic>,
        );
      } catch (_) {}
    }
    base['outcome'] = outcomeCode;
    if (notes != null) {
      base['notes'] = notes;
    } else {
      base.remove('notes');
    }
    if (followUpReminderAtMs != null) {
      base['followUpReminderAtMs'] = followUpReminderAtMs;
    } else {
      base.remove('followUpReminderAtMs');
    }
    return base;
  }

  /// Hızlı kayıt — senkron sırasında kuyruk; aksi halde doğrudan alanlar.
  Future<void> patchQuickCapture({
    required String agentId,
    required String localId,
    required String outcomeCode,
    String? notes,
    int? followUpReminderAtMs,
  }) async {
    final existing = await get(agentId, localId);
    if (existing == null) return;

    if (existing.isSyncing) {
      final merged = _mergePendingJson(
        existing.pendingCapturePatchJson,
        outcomeCode,
        notes,
        followUpReminderAtMs,
      );
      await putRecord(
        existing.copyWith(
          pendingCapturePatchJson: jsonEncode(merged),
        ),
      );
      return;
    }

    await putRecord(
      existing.copyWith(
        outcome: outcomeCode,
        notes: notes,
        followUpReminderAtMs: followUpReminderAtMs,
        isSynced: false,
        clearNextRetry: true,
      ),
    );
  }

  /// Senkron bittikten sonra kuyruğu ana alanlara taşır; gerekirse tekrar senkron gerekir.
  Future<void> applyPendingCapturePatchIfAny({
    required String agentId,
    required String localId,
  }) async {
    final existing = await get(agentId, localId);
    if (existing == null) return;
    final raw = existing.pendingCapturePatchJson;
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final outcome = m['outcome'] as String?;
      final notes = m['notes'] as String?;
      final fu = (m['followUpReminderAtMs'] as num?)?.toInt();
      await putRecord(
        existing.copyWith(
          outcome: outcome,
          notes: notes,
          followUpReminderAtMs: fu,
          isSynced: false,
          clearPendingPatch: true,
          clearNextRetry: true,
        ),
      );
    } catch (_) {
      await putRecord(existing.copyWith(clearPendingPatch: true));
    }
  }

  Future<void> markSynced({
    required String agentId,
    required String localId,
    /// Hızlı kayıt tamamlandığında bekleyen kuyruğu temizle.
    bool clearPendingCapture = false,
  }) async {
    final existing = await get(agentId, localId);
    if (existing == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await putRecord(
      existing.copyWith(
        isSynced: true,
        lastSyncAt: now,
        syncAttemptCount: 0,
        isSyncing: false,
        clearSyncingSince: true,
        clearNextRetry: true,
        clearPendingPatch: clearPendingCapture,
      ),
    );
  }

  Future<void> recordSyncFailure({
    required String agentId,
    required String localId,
  }) async {
    final existing = await get(agentId, localId);
    if (existing == null) return;
    final nextAttempt = existing.syncAttemptCount + 1;
    final backoffMs = _computeBackoffMs(nextAttempt);
    await putRecord(
      existing.copyWith(
        isSyncing: false,
        clearSyncingSince: true,
        syncAttemptCount: nextAttempt,
        nextRetryAtMs:
            DateTime.now().millisecondsSinceEpoch + backoffMs,
      ),
    );
  }

  Future<void> resetPermanentForManualRetry({
    required String agentId,
    required String localId,
  }) async {
    final existing = await get(agentId, localId);
    if (existing == null) return;
    await putRecord(
      existing.copyWith(
        syncFailedPermanent: false,
        syncAttemptCount: 0,
        clearNextRetry: true,
      ),
    );
  }

  static int _computeBackoffMs(int attempt) {
    const base = 2000;
    const cap = 600000;
    final exp = (base * (1 << (attempt.clamp(1, 8) - 1))).clamp(base, cap);
    return exp;
  }

  /// Öncelik: syncAttemptCount==0 (yeni), sonra tekrar; ikincil sıra createdAt DESC.
  Future<List<LocalCallRecord>> listReadyToSync(String agentId) async {
    await ensureInit();
    await applyStaleSyncingLocks(agentId);
    await applyExpiredPermanentWindow(agentId);
    final b = _b;
    if (b == null || agentId.isEmpty) return [];
    final now = DateTime.now().millisecondsSinceEpoch;
    final prefix = '$agentId::';
    final out = <LocalCallRecord>[];
    for (final key in b.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;
      final raw = b.get(key);
      final r = LocalCallRecord.tryDecode(raw);
      if (r == null || r.isSynced) continue;
      if (r.syncFailedPermanent) continue;
      if (r.isSyncing) continue;
      if (r.nextRetryAtMs != null && now < r.nextRetryAtMs!) continue;
      out.add(r);
    }
    out.sort((a, b) {
      final aNew = a.syncAttemptCount == 0 ? 0 : 1;
      final bNew = b.syncAttemptCount == 0 ? 0 : 1;
      final primary = aNew.compareTo(bNew);
      if (primary != 0) return primary;
      return b.createdAt.compareTo(a.createdAt);
    });
    return out;
  }

  Future<List<LocalCallRecord>> listAllForAgent(String agentId) async {
    await ensureInit();
    await applyStaleSyncingLocks(agentId);
    await applyExpiredPermanentWindow(agentId);
    final b = _b;
    if (b == null || agentId.isEmpty) return [];
    final prefix = '$agentId::';
    final out = <LocalCallRecord>[];
    for (final key in b.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;
      final r = LocalCallRecord.tryDecode(b.get(key));
      if (r != null) out.add(r);
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  Future<void> migrateLegacyPendingQueue(String agentId) async {
    if (agentId.isEmpty) return;
    final legacy = await PendingHandoffOutboundQueue.load(agentId);
    if (legacy.isEmpty) return;
    for (final item in legacy) {
      await insertCallStart(
        agentId: item.advisorId,
        localId: item.localDraftId,
        phoneNumber: item.phoneNumber,
        createdAtMs: item.createdAtMs,
        customerId: item.customerId,
        startedFromScreen: item.startedFromScreen,
      );
      await PendingHandoffOutboundQueue.removeByLocalDraftId(
        agentId,
        item.localDraftId,
      );
    }
  }
}
