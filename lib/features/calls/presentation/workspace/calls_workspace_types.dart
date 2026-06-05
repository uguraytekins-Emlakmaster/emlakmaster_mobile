// Çağrılarım workspace — yalnızca GERÇEK çağrı kayıtları: Firestore CRM
// kayıtları, cihaz taslakları ve gerçek müşteri eşleşmesi. Uydurma cevap
// oranı, sahte AI skoru, icat edilmiş kaçan arama geçmişi veya operatör
// kesinliği iddia edilmez.

/// Yatay filtreler — yalnızca grounded kategoriler.
enum CallsWorkspaceFilter {
  all,
  today,
  callback,
  matched,
  partial,
  unanswered,
  outgoing,
  incoming,
}

extension CallsWorkspaceFilterLabel on CallsWorkspaceFilter {
  String get label => switch (this) {
        CallsWorkspaceFilter.all => 'Tümü',
        CallsWorkspaceFilter.today => 'Bugün',
        CallsWorkspaceFilter.callback => 'Geri dön',
        CallsWorkspaceFilter.matched => 'Eşleşen',
        CallsWorkspaceFilter.partial => 'Kısmi',
        CallsWorkspaceFilter.unanswered => 'Cevapsız',
        CallsWorkspaceFilter.outgoing => 'Giden',
        CallsWorkspaceFilter.incoming => 'Gelen',
      };
}

/// Renk tonu — widget katmanında tema rengine eşlenir.
enum CallTone {
  attention,
  callback,
  missed,
  matched,
  partial,
  local,
  neutral,
}

/// Önceden hesaplanmış satır görünümü.
class CallRowView {
  const CallRowView({
    required this.recordKey,
    required this.firestoreDocId,
    required this.title,
    required this.phoneLine,
    required this.directionDuration,
    required this.outcomeLabel,
    required this.timestampLabel,
    required this.timestampColorType,
    required this.contextLine,
    required this.nextActionLabel,
    required this.tone,
    required this.isToday,
    required this.needsCallback,
    required this.isMatched,
    required this.isPartial,
    required this.isUnanswered,
    required this.isOutgoing,
    required this.isIncoming,
    required this.isLocalDraft,
    required this.partialNote,
    required this.customerId,
    required this.rawPhone,
    required this.callablePhone,
    required this.sortRank,
    required this.searchText,
    required this.createdAtMs,
  });

  final String recordKey;
  final String? firestoreDocId;
  final String title;
  final String phoneLine;
  final String directionDuration;
  final String outcomeLabel;
  final String timestampLabel;
  final int timestampColorType;
  final String contextLine;
  final String nextActionLabel;
  final CallTone tone;

  final bool isToday;
  final bool needsCallback;
  final bool isMatched;
  final bool isPartial;
  final bool isUnanswered;
  final bool isOutgoing;
  final bool isIncoming;
  final bool isLocalDraft;
  final String partialNote;

  final String? customerId;
  final String rawPhone;
  final bool callablePhone;

  final int sortRank;
  final String searchText;
  final int createdAtMs;
}

/// Özet şeridi — yalnızca gerçek sayımlar.
class CallsWorkspaceSummary {
  const CallsWorkspaceSummary({
    required this.today,
    required this.callback,
    required this.matched,
    required this.partial,
    required this.unanswered,
  });

  final int today;
  final int callback;
  final int matched;
  final int partial;
  final int unanswered;

  static const empty = CallsWorkspaceSummary(
    today: 0,
    callback: 0,
    matched: 0,
    partial: 0,
    unanswered: 0,
  );
}

class CallsWorkspaceSnapshot {
  const CallsWorkspaceSnapshot({
    required this.rows,
    required this.attentionRows,
    required this.summary,
    required this.coverageNote,
    required this.isEmpty,
    required this.dateChipLabel,
    this.hasMore = false,
    this.uid = '',
    this.pendingLocalCount = 0,
  });

  /// Dikkat-önce sıralı tam liste.
  final List<CallRowView> rows;

  /// Geri dönülmesi gerekenler — yalnızca gerçek callback/bekleyen kayıt.
  final List<CallRowView> attentionRows;
  final CallsWorkspaceSummary summary;
  final String coverageNote;
  final bool isEmpty;
  final String dateChipLabel;
  final bool hasMore;
  final String uid;
  final int pendingLocalCount;

  CallsWorkspaceSnapshot copyWith({
    bool? hasMore,
    String? uid,
    int? pendingLocalCount,
  }) {
    return CallsWorkspaceSnapshot(
      rows: rows,
      attentionRows: attentionRows,
      summary: summary,
      coverageNote: coverageNote,
      isEmpty: isEmpty,
      dateChipLabel: dateChipLabel,
      hasMore: hasMore ?? this.hasMore,
      uid: uid ?? this.uid,
      pendingLocalCount: pendingLocalCount ?? this.pendingLocalCount,
    );
  }
}

/// Saf/test edilebilir giriş DTO'su.
class CallWorkspaceInput {
  const CallWorkspaceInput({
    required this.recordKey,
    required this.sourceKind,
    this.firestoreDocId,
    required this.rawPhone,
    this.customerId,
    this.customerFullName,
    this.contactDisplayName,
    required this.isIncoming,
    this.durationSec,
    this.outcomeCode,
    required this.outcomeLabel,
    required this.createdAt,
    required this.isHandoffPending,
    required this.hasCaptureCompleted,
    required this.isLocalDraft,
    this.notes,
  });

  final String recordKey;
  final String sourceKind;
  final String? firestoreDocId;
  final String rawPhone;
  final String? customerId;
  final String? customerFullName;
  final String? contactDisplayName;
  final bool isIncoming;
  final int? durationSec;
  final String? outcomeCode;
  final String outcomeLabel;
  final DateTime createdAt;
  final bool isHandoffPending;
  final bool hasCaptureCompleted;
  final bool isLocalDraft;
  final String? notes;
}
