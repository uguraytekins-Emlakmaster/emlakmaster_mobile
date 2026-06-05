// Görevlerim workspace — yalnızca GERÇEK görev kayıtları: Firestore görevleri,
// gerçek vade/ durum, müşteri bağlantısı. Uydurma verimlilik skoru, sahte AI
// önceliklendirme veya icat edilmiş tamamlanma trendi GÖSTERİLMEZ.

/// Yatay filtreler — grounded. "Öncelikli" = geciken veya bugün vadeli açık
/// görevler (kural tabanlı; sunucuda priority alanı yok).
enum TasksWorkspaceFilter {
  all,
  overdue,
  today,
  active,
  completed,
  partial,
  matched,
  priority,
}

extension TasksWorkspaceFilterLabel on TasksWorkspaceFilter {
  String get label => switch (this) {
        TasksWorkspaceFilter.all => 'Tümü',
        TasksWorkspaceFilter.overdue => 'Geciken',
        TasksWorkspaceFilter.today => 'Bugün',
        TasksWorkspaceFilter.active => 'Aktif',
        TasksWorkspaceFilter.completed => 'Tamamlanan',
        TasksWorkspaceFilter.partial => 'Kısmi',
        TasksWorkspaceFilter.matched => 'Müşteri bağlı',
        TasksWorkspaceFilter.priority => 'Öncelikli',
      };
}

enum TaskTone { overdue, today, upcoming, completed, partial, matched, neutral }

class TaskRowView {
  const TaskRowView({
    required this.id,
    required this.title,
    required this.done,
    required this.dueLabel,
    required this.statusLabel,
    required this.contextLine,
    required this.nextActionLabel,
    required this.tone,
    required this.isOverdue,
    required this.isToday,
    required this.isActive,
    required this.isCompleted,
    required this.isPartial,
    required this.isMatched,
    required this.isPriority,
    required this.quickCloseable,
    required this.partialNote,
    required this.customerId,
    required this.customerName,
    required this.callablePhone,
    required this.phone,
    required this.hasRecurrence,
    required this.recurrenceLabel,
    required this.sortRank,
    required this.searchText,
    required this.rawData,
  });

  final String id;
  final String title;
  final bool done;
  final String dueLabel;
  final String statusLabel;
  final String contextLine;
  final String nextActionLabel;
  final TaskTone tone;

  final bool isOverdue;
  final bool isToday;
  final bool isActive;
  final bool isCompleted;
  final bool isPartial;
  final bool isMatched;
  final bool isPriority;
  final bool quickCloseable;
  final String partialNote;

  final String? customerId;
  final String customerName;
  final bool callablePhone;
  final String? phone;

  final bool hasRecurrence;
  final String? recurrenceLabel;

  final int sortRank;
  final String searchText;

  /// Orijinal Firestore verisi — sheet/CRUD akışları için.
  final Map<String, dynamic> rawData;
}

class TasksWorkspaceSummary {
  const TasksWorkspaceSummary({
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

  static const empty = TasksWorkspaceSummary(
    active: 0,
    overdue: 0,
    today: 0,
    matched: 0,
    partial: 0,
  );
}

class TasksWorkspaceSnapshot {
  const TasksWorkspaceSnapshot({
    required this.rows,
    required this.overdueRows,
    required this.quickCloseRows,
    required this.summary,
    required this.coverageNote,
    required this.isEmpty,
    required this.dateChipLabel,
    this.uid = '',
  });

  final List<TaskRowView> rows;
  final List<TaskRowView> overdueRows;
  final List<TaskRowView> quickCloseRows;
  final TasksWorkspaceSummary summary;
  final String coverageNote;
  final bool isEmpty;
  final String dateChipLabel;
  final String uid;

  TasksWorkspaceSnapshot copyWith({String? uid}) {
    return TasksWorkspaceSnapshot(
      rows: rows,
      overdueRows: overdueRows,
      quickCloseRows: quickCloseRows,
      summary: summary,
      coverageNote: coverageNote,
      isEmpty: isEmpty,
      dateChipLabel: dateChipLabel,
      uid: uid ?? this.uid,
    );
  }
}

class TaskWorkspaceInput {
  const TaskWorkspaceInput({
    required this.id,
    required this.title,
    required this.done,
    this.dueAt,
    this.customerId,
    this.customerName,
    this.phone,
    required this.callablePhone,
    this.recurrence,
    required this.rawData,
  });

  final String id;
  final String title;
  final bool done;
  final DateTime? dueAt;
  final String? customerId;
  final String? customerName;
  final String? phone;
  final bool callablePhone;
  final String? recurrence;
  final Map<String, dynamic> rawData;
}
