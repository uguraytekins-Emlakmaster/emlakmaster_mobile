// Takiplerim workspace — yalnızca GERÇEK takip kuyruğu sinyalleri: ≥7 gün sessiz
// müşteriler, gerçek son temas, CRM müşteri bağlantısı, kural tabanlı sıcaklık.
// Uydurma takip skoru, sahte AI aciliyeti veya icat edilmiş kapanış analitiği YOK.

import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';

/// Yatay filtreler — grounded. "Tamamlanan" sunucuda ayrı alan olmadığı için
/// gösterilmez (kuyruk yalnızca aktif sessiz müşterileri listeler).
enum FollowUpWorkspaceFilter {
  all,
  overdue,
  today,
  active,
  partial,
  matched,
  priority,
}

extension FollowUpWorkspaceFilterLabel on FollowUpWorkspaceFilter {
  String get label => switch (this) {
        FollowUpWorkspaceFilter.all => 'Tümü',
        FollowUpWorkspaceFilter.overdue => 'Geciken',
        FollowUpWorkspaceFilter.today => 'Bugün',
        FollowUpWorkspaceFilter.active => 'Aktif',
        FollowUpWorkspaceFilter.partial => 'Kısmi',
        FollowUpWorkspaceFilter.matched => 'Müşteri bağlı',
        FollowUpWorkspaceFilter.priority => 'Öncelikli',
      };
}

enum FollowUpTone {
  overdue,
  today,
  hot,
  cold,
  partial,
  matched,
  neutral,
}

class FollowUpRowView {
  const FollowUpRowView({
    required this.customerId,
    required this.item,
    required this.displayName,
    required this.phoneLine,
    required this.statusLabel,
    required this.lastContactLabel,
    required this.contextLine,
    required this.nextActionLabel,
    required this.tone,
    required this.isOverdue,
    required this.isToday,
    required this.isActive,
    required this.isPartial,
    required this.isMatched,
    required this.isPriority,
    required this.quickResolvable,
    required this.partialNote,
    required this.callablePhone,
    required this.sortRank,
    required this.searchText,
  });

  final String customerId;
  final ResurrectionQueueItem item;
  final String displayName;
  final String phoneLine;
  final String statusLabel;
  final String lastContactLabel;
  final String contextLine;
  final String nextActionLabel;
  final FollowUpTone tone;

  final bool isOverdue;
  final bool isToday;
  final bool isActive;
  final bool isPartial;
  final bool isMatched;
  final bool isPriority;
  final bool quickResolvable;
  final String partialNote;

  final bool callablePhone;
  final int sortRank;
  final String searchText;
}

class FollowUpWorkspaceSummary {
  const FollowUpWorkspaceSummary({
    required this.active,
    required this.overdue,
    required this.today,
    required this.matched,
    required this.partial,
  });

  final int active;
  final int overdue;
  final int today;
  final int matched;
  final int partial;

  static const empty = FollowUpWorkspaceSummary(
    active: 0,
    overdue: 0,
    today: 0,
    matched: 0,
    partial: 0,
  );
}

class FollowUpWorkspaceSnapshot {
  const FollowUpWorkspaceSnapshot({
    required this.rows,
    required this.overdueRows,
    required this.quickCloseRows,
    required this.summary,
    required this.coverageNote,
    required this.isEmpty,
    required this.dateChipLabel,
  });

  final List<FollowUpRowView> rows;
  final List<FollowUpRowView> overdueRows;
  final List<FollowUpRowView> quickCloseRows;
  final FollowUpWorkspaceSummary summary;
  final String coverageNote;
  final bool isEmpty;
  final String dateChipLabel;
}
