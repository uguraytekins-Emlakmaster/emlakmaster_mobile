// Benim Günüm — yalnızca GERÇEK, danışmana atanmış (scoped) Firestore sinyalleri:
// görevler (vade türetilir), atanmış müşteriler (lifecycle/lastInteractionAt +
// deterministik heat — LLM yok) ve danışmanın kendi çağrı akışından bugünkü
// temas sayısı. Uydurma performans skoru, sahte AI koçluk, icat edilmiş
// verimlilik/trend YOK. Sunucuda izlenmeyen sinyaller dürüstçe gizlenir/işaretlenir.

/// Günlük aksiyon türü.
enum DailyKind { task, followUp, customer }

/// Yatay filtreler.
enum ConsultantDailyFilter {
  all,
  task,
  followUp,
  customer,
  today,
  overdue,
  priority,
  partial,
}

extension ConsultantDailyFilterLabel on ConsultantDailyFilter {
  String get label => switch (this) {
        ConsultantDailyFilter.all => 'Tümü',
        ConsultantDailyFilter.task => 'Görev',
        ConsultantDailyFilter.followUp => 'Takip',
        ConsultantDailyFilter.customer => 'Müşteri',
        ConsultantDailyFilter.today => 'Bugün',
        ConsultantDailyFilter.overdue => 'Geciken',
        ConsultantDailyFilter.priority => 'Öncelikli',
        ConsultantDailyFilter.partial => 'Kısmi',
      };
}

/// Renk tonu — widget katmanında tema rengine eşlenir.
enum DailyTone { danger, warning, info, success, neutral }

/// Satır için somut sonraki adım türü (dead button yok).
enum DailyActionKind { openTasks, openCustomer, call, message }

class ConsultantDailyEntry {
  const ConsultantDailyEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.typeLabel,
    required this.timeLabel,
    required this.detail,
    required this.context,
    required this.statusLabel,
    required this.tone,
    required this.actionLabel,
    required this.actionKind,
    required this.searchText,
    this.customerId,
    this.phone,
    // Filtre/öncelik için önceden hesaplanmış bayraklar
    required this.needsAttention,
    required this.isToday,
    required this.isOverdue,
    required this.isPriority,
    required this.isPartial,
    required this.sortRank,
  });

  final String id;
  final DailyKind kind;
  final String title;
  final String typeLabel;
  final String timeLabel;
  final String detail;
  final String context;
  final String statusLabel;
  final DailyTone tone;

  final String actionLabel;
  final DailyActionKind actionKind;

  /// Müşteri detayına gitmek / aramak için (varsa).
  final String? customerId;
  final String? phone;

  final String searchText;

  final bool needsAttention;
  final bool isToday;
  final bool isOverdue;
  final bool isPriority;
  final bool isPartial;

  /// Daha düşük = daha öncelikli (stabil sıralama).
  final int sortRank;
}

class ConsultantDailySummary {
  const ConsultantDailySummary({
    required this.activeTasks,
    required this.overdue,
    required this.todayContacts,
    required this.hotCustomers,
    required this.customers,
  });

  final int activeTasks;

  /// Geciken görev + geciken takip toplamı.
  final int overdue;

  /// Danışmanın kendi çağrı akışından bugünkü temas (scoped, gerçek).
  final int todayContacts;

  /// Deterministik heat ile "sıcak" müşteri sayısı (grounded).
  final int hotCustomers;

  /// Toplam atanmış müşteri.
  final int customers;

  static const empty = ConsultantDailySummary(
    activeTasks: 0,
    overdue: 0,
    todayContacts: 0,
    hotCustomers: 0,
    customers: 0,
  );
}

class ConsultantDailySnapshot {
  const ConsultantDailySnapshot({
    required this.entries,
    required this.summary,
    required this.greetingName,
    required this.coverageNote,
    required this.isEmpty,
  });

  final List<ConsultantDailyEntry> entries;
  final ConsultantDailySummary summary;
  final String greetingName;
  final String coverageNote;
  final bool isEmpty;
}

/// Pure compute girişi — Firestore tiplerine bağımlılığı snapshot katmanından
/// uzak tutmak için sade görev DTO'su.
class DailyTaskInput {
  const DailyTaskInput({
    required this.id,
    required this.title,
    required this.done,
    required this.customerId,
    this.dueAt,
  });

  final String id;
  final String title;
  final bool done;
  final String? customerId;
  final DateTime? dueAt;
}
