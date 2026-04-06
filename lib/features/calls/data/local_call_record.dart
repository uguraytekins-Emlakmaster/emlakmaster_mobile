import 'dart:convert';

import 'package:emlakmaster_mobile/features/calls/data/call_record_sync_constants.dart';
import 'package:equatable/equatable.dart';

/// Yerel çağrı kaydı — Hive’da tutulur; senkron öncesi tek kaynak.
class LocalCallRecord extends Equatable {
  const LocalCallRecord({
    required this.id,
    required this.phoneNumber,
    required this.agentId,
    required this.createdAt,
    this.outcome,
    this.notes,
    this.isSynced = false,
    this.syncAttemptCount = 0,
    this.lastSyncAt,
    this.firestoreDocumentId,
    this.nextRetryAtMs,
    this.customerId,
    required this.startedFromScreen,
    this.followUpReminderAtMs,
    this.isSyncing = false,
    this.syncingSinceMs,
    this.syncFailedPermanent = false,
    this.pendingCapturePatchJson,
  });

  /// `local_<timestamp>` veya `local_…` biçimi.
  final String id;
  final String phoneNumber;
  final String agentId;

  /// Oluşturulma zamanı (epoch ms).
  final int createdAt;
  final String? outcome;
  final String? notes;
  final bool isSynced;
  final int syncAttemptCount;
  final int? lastSyncAt;
  final String? firestoreDocumentId;
  final int? nextRetryAtMs;
  final String? customerId;
  final String startedFromScreen;
  final int? followUpReminderAtMs;

  /// Senkron işlemi sırasında kullanıcı düzenlemesini korumak için yumuşak kilit.
  final bool isSyncing;
  final int? syncingSinceMs;

  /// 24 saat penceresi aşıldı veya manuel kalıcı başarısız.
  final bool syncFailedPermanent;

  /// [isSyncing] iken gelen hızlı kayıt — senkron bitince uygulanır (JSON).
  final String? pendingCapturePatchJson;

  bool get hasQuickCapturePayload =>
      outcome != null && outcome!.trim().isNotEmpty;

  /// Sunucu güvenli tekilleştirme anahtarı (dakika yuvarlama).
  String get dedupeKeyMinute =>
      '$agentId|$phoneNumber|${createdAt ~/ 60000}';

  bool get isPastMaxRetryWindow {
    final now = DateTime.now().millisecondsSinceEpoch;
    return !isSynced && now > createdAt + CallRecordSyncConstants.maxRetryWindowMs;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phoneNumber': phoneNumber,
        'agentId': agentId,
        'createdAt': createdAt,
        if (outcome != null) 'outcome': outcome,
        if (notes != null) 'notes': notes,
        'isSynced': isSynced,
        'syncAttemptCount': syncAttemptCount,
        if (lastSyncAt != null) 'lastSyncAt': lastSyncAt,
        if (firestoreDocumentId != null) 'firestoreDocumentId': firestoreDocumentId,
        if (nextRetryAtMs != null) 'nextRetryAtMs': nextRetryAtMs,
        if (customerId != null && customerId!.isNotEmpty) 'customerId': customerId,
        'startedFromScreen': startedFromScreen,
        if (followUpReminderAtMs != null) 'followUpReminderAtMs': followUpReminderAtMs,
        'isSyncing': isSyncing,
        if (syncingSinceMs != null) 'syncingSinceMs': syncingSinceMs,
        'syncFailedPermanent': syncFailedPermanent,
        if (pendingCapturePatchJson != null) 'pendingCapturePatchJson': pendingCapturePatchJson,
      };

  factory LocalCallRecord.fromJson(Map<String, dynamic> m) {
    return LocalCallRecord(
      id: m['id'] as String,
      phoneNumber: m['phoneNumber'] as String,
      agentId: m['agentId'] as String,
      createdAt: (m['createdAt'] as num).toInt(),
      outcome: m['outcome'] as String?,
      notes: m['notes'] as String?,
      isSynced: m['isSynced'] as bool? ?? false,
      syncAttemptCount: (m['syncAttemptCount'] as num?)?.toInt() ?? 0,
      lastSyncAt: (m['lastSyncAt'] as num?)?.toInt(),
      firestoreDocumentId: m['firestoreDocumentId'] as String?,
      nextRetryAtMs: (m['nextRetryAtMs'] as num?)?.toInt(),
      customerId: m['customerId'] as String?,
      startedFromScreen: (m['startedFromScreen'] as String?) ?? 'unknown',
      followUpReminderAtMs: (m['followUpReminderAtMs'] as num?)?.toInt(),
      isSyncing: m['isSyncing'] as bool? ?? false,
      syncingSinceMs: (m['syncingSinceMs'] as num?)?.toInt(),
      syncFailedPermanent: m['syncFailedPermanent'] as bool? ?? false,
      pendingCapturePatchJson: m['pendingCapturePatchJson'] as String?,
    );
  }

  static LocalCallRecord? tryDecode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return LocalCallRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  LocalCallRecord copyWith({
    String? id,
    String? phoneNumber,
    String? agentId,
    int? createdAt,
    String? outcome,
    String? notes,
    bool? isSynced,
    int? syncAttemptCount,
    int? lastSyncAt,
    String? firestoreDocumentId,
    int? nextRetryAtMs,
    String? customerId,
    String? startedFromScreen,
    int? followUpReminderAtMs,
    bool? isSyncing,
    int? syncingSinceMs,
    bool? syncFailedPermanent,
    String? pendingCapturePatchJson,
    bool clearOutcome = false,
    bool clearNotes = false,
    bool clearFirestoreDocumentId = false,
    bool clearFollowUpReminder = false,
    bool clearNextRetry = false,
    bool clearSyncingSince = false,
    bool clearPendingPatch = false,
  }) {
    return LocalCallRecord(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      agentId: agentId ?? this.agentId,
      createdAt: createdAt ?? this.createdAt,
      outcome: clearOutcome ? null : (outcome ?? this.outcome),
      notes: clearNotes ? null : (notes ?? this.notes),
      isSynced: isSynced ?? this.isSynced,
      syncAttemptCount: syncAttemptCount ?? this.syncAttemptCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      firestoreDocumentId: clearFirestoreDocumentId
          ? null
          : (firestoreDocumentId ?? this.firestoreDocumentId),
      nextRetryAtMs:
          clearNextRetry ? null : (nextRetryAtMs ?? this.nextRetryAtMs),
      customerId: customerId ?? this.customerId,
      startedFromScreen: startedFromScreen ?? this.startedFromScreen,
      followUpReminderAtMs: clearFollowUpReminder
          ? null
          : (followUpReminderAtMs ?? this.followUpReminderAtMs),
      isSyncing: isSyncing ?? this.isSyncing,
      syncingSinceMs:
          clearSyncingSince ? null : (syncingSinceMs ?? this.syncingSinceMs),
      syncFailedPermanent: syncFailedPermanent ?? this.syncFailedPermanent,
      pendingCapturePatchJson: clearPendingPatch
          ? null
          : (pendingCapturePatchJson ?? this.pendingCapturePatchJson),
    );
  }

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        agentId,
        createdAt,
        outcome,
        notes,
        isSynced,
        syncAttemptCount,
        lastSyncAt,
        firestoreDocumentId,
        nextRetryAtMs,
        customerId,
        startedFromScreen,
        followUpReminderAtMs,
        isSyncing,
        syncingSinceMs,
        syncFailedPermanent,
        pendingCapturePatchJson,
      ];
}
