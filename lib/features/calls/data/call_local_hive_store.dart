import 'dart:convert';

import 'package:emlakmaster_mobile/core/cache/app_cache_service.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
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
        clearNextRetry: true,
      ),
    );
  }

  /// `local_…` → `hf_…` yükseltmesinde doküman kimliği güncellenir.
  Future<void> replaceFirestoreDocumentId({
    required String agentId,
    required String localId,
    required String firestoreDocumentId,
  }) async {
    final existing = await get(agentId, localId);
    if (existing == null) return;
    await putRecord(existing.copyWith(firestoreDocumentId: firestoreDocumentId));
  }

  /// Hızlı kayıt — yerel önce; senkron için bayrak kapanır.
  Future<void> patchQuickCapture({
    required String agentId,
    required String localId,
    required String outcomeCode,
    String? notes,
    int? followUpReminderAtMs,
  }) async {
    final existing = await get(agentId, localId);
    if (existing == null) return;
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

  Future<void> markSynced({
    required String agentId,
    required String localId,
  }) async {
    final existing = await get(agentId, localId);
    if (existing == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await putRecord(
      existing.copyWith(
        isSynced: true,
        lastSyncAt: now,
        syncAttemptCount: 0,
        clearNextRetry: true,
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
        syncAttemptCount: nextAttempt,
        nextRetryAtMs:
            DateTime.now().millisecondsSinceEpoch + backoffMs,
      ),
    );
  }

  static int _computeBackoffMs(int attempt) {
    const base = 2000;
    const cap = 600000;
    final exp = (base * (1 << (attempt.clamp(1, 8) - 1))).clamp(base, cap);
    return exp;
  }

  /// Senkron için hazır: `!isSynced` ve backoff süresi dolmuş.
  Future<List<LocalCallRecord>> listReadyToSync(String agentId) async {
    await ensureInit();
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
      if (r.nextRetryAtMs != null && now < r.nextRetryAtMs!) continue;
      out.add(r);
    }
    out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
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
