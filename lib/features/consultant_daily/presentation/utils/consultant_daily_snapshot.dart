import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_types.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

/// Saf/test edilebilir türetme. Tüm gösterim metni burada önceden hesaplanır;
/// build() içinde pahalı string/tarih işi yapılmaz. Yalnızca gerçek, scoped
/// sinyaller: görevler, atanmış müşteriler (+deterministik heat), bugünkü temas.
ConsultantDailySnapshot computeConsultantDailySnapshot({
  required List<DailyTaskInput> tasks,
  required List<CustomerEntity> customers,
  required int todayContactCount,
  String greetingName = '',
  DateTime? now,
}) {
  final ref = now ?? DateTime.now();
  final todayFloor = DateTime(ref.year, ref.month, ref.day);

  final entries = <ConsultantDailyEntry>[];
  var overdueTaskCount = 0;
  var staleFollowUpCount = 0;
  var hotCount = 0;

  // ——— Görevler (yalnızca tamamlanmamış) ———
  for (final t in tasks) {
    if (t.done) continue;
    final due = t.dueAt;
    final DailyTone tone;
    final String status;
    final String timeLabel;
    final bool isToday;
    final bool isOverdue;
    var rank = 7;

    if (due == null) {
      tone = DailyTone.neutral;
      status = 'Vade yok';
      timeLabel = 'Vade yok';
      isToday = false;
      isOverdue = false;
      rank = 9;
    } else {
      final dueDay = DateTime(due.year, due.month, due.day);
      final diff = dueDay.difference(todayFloor).inDays;
      if (diff < 0) {
        tone = DailyTone.danger;
        status = 'Gecikti';
        timeLabel = diff == -1 ? 'Dün (geçti)' : '${-diff} gün gecikti';
        isToday = false;
        isOverdue = true;
        overdueTaskCount++;
        rank = 0;
      } else if (diff == 0) {
        tone = DailyTone.warning;
        status = 'Bugün';
        timeLabel = 'Bugün';
        isToday = true;
        isOverdue = false;
        rank = 4;
      } else {
        tone = DailyTone.info;
        status = 'Yaklaşan';
        timeLabel = diff == 1 ? 'Yarın' : '$diff gün içinde';
        isToday = false;
        isOverdue = false;
        rank = 7;
      }
    }

    entries.add(
      ConsultantDailyEntry(
        id: 'task:${t.id}',
        kind: DailyKind.task,
        title: t.title,
        typeLabel: 'Görev',
        timeLabel: timeLabel,
        detail: 'Planlı görev',
        context: t.customerId != null ? 'Müşteriye bağlı görev' : 'Kişisel görev',
        statusLabel: status,
        tone: tone,
        actionLabel: t.customerId != null ? 'Müşteriye git' : 'Görevlere git',
        actionKind: t.customerId != null
            ? DailyActionKind.openCustomer
            : DailyActionKind.openTasks,
        customerId: t.customerId,
        searchText: '${t.title} görev $status'.toLowerCase(),
        needsAttention: isOverdue || isToday,
        isToday: isToday,
        isOverdue: isOverdue,
        isPriority: isOverdue,
        isPartial: false,
        sortRank: rank,
      ),
    );
  }

  // ——— Müşteriler: geciken takip / sıcak baskı / kısmi (scoped) ———
  for (final c in customers) {
    final heat = computeCustomerHeat(c);
    final name = (c.fullName ?? '').trim().isNotEmpty
        ? c.fullName!.trim()
        : 'İsimsiz müşteri';
    final stage = c.lifecycleStage?.label ?? 'Aşama yok';
    final lastInt = c.lastInteractionAt;

    if (lastInt == null) {
      // Temas geçmişi yok → dürüst kısmi kayıt (uydurma baskı yok).
      entries.add(
        ConsultantDailyEntry(
          id: 'cust:${c.id}',
          kind: DailyKind.customer,
          title: name,
          typeLabel: 'Müşteri',
          timeLabel: 'Temas bilgisi yok',
          detail: 'Son temas tarihi kayıtlı değil',
          context: stage,
          statusLabel: 'Kısmi',
          tone: DailyTone.neutral,
          actionLabel: 'Müşteriye git',
          actionKind: DailyActionKind.openCustomer,
          customerId: c.id,
          phone: c.primaryPhone,
          searchText: '$name müşteri kısmi $stage'.toLowerCase(),
          needsAttention: false,
          isToday: false,
          isOverdue: false,
          isPriority: false,
          isPartial: true,
          sortRank: 8,
        ),
      );
      continue;
    }

    final daysSilent = todayFloor
        .difference(DateTime(lastInt.year, lastInt.month, lastInt.day))
        .inDays;

    if (daysSilent >= 7) {
      // Geciken takip — gerçek lastInteractionAt'tan türetilir.
      staleFollowUpCount++;
      final DailyTone tone;
      final int rank;
      if (daysSilent >= 30) {
        tone = DailyTone.danger;
        rank = 1;
      } else if (daysSilent >= 14) {
        tone = DailyTone.warning;
        rank = 2;
      } else {
        tone = DailyTone.info;
        rank = 3;
      }
      final next = (c.nextSuggestedAction ?? '').trim();
      entries.add(
        ConsultantDailyEntry(
          id: 'follow:${c.id}',
          kind: DailyKind.followUp,
          title: name,
          typeLabel: 'Takip',
          timeLabel: '$daysSilent gün sessiz',
          detail: next.isNotEmpty ? next : 'Yeniden temas önerilir',
          context: stage,
          statusLabel: 'Geciken takip',
          tone: tone,
          actionLabel: 'Müşteriye git',
          actionKind: DailyActionKind.openCustomer,
          customerId: c.id,
          phone: c.primaryPhone,
          searchText: '$name takip geciken $stage'.toLowerCase(),
          needsAttention: true,
          isToday: false,
          isOverdue: daysSilent >= 14,
          isPriority: daysSilent >= 14,
          isPartial: false,
          sortRank: rank,
        ),
      );
      continue;
    }

    // Güncel müşteri: yalnızca grounded "sıcak/ılık" baskıyı göster.
    if (heat.heatLevel == CustomerHeatLevel.hot ||
        heat.heatLevel == CustomerHeatLevel.warm) {
      final isHot = heat.heatLevel == CustomerHeatLevel.hot;
      if (isHot) hotCount++;
      entries.add(
        ConsultantDailyEntry(
          id: 'cust:${c.id}',
          kind: DailyKind.customer,
          title: name,
          typeLabel: 'Müşteri',
          timeLabel: heatLevelLabelTr(heat.heatLevel),
          detail: heat.heatReasonSummary,
          context: stage,
          statusLabel: isHot ? 'Sıcak' : 'Ilık',
          tone: isHot ? DailyTone.danger : DailyTone.warning,
          actionLabel: 'Müşteriye git',
          actionKind: DailyActionKind.openCustomer,
          customerId: c.id,
          phone: c.primaryPhone,
          searchText:
              '$name müşteri ${isHot ? 'sıcak' : 'ılık'} $stage'.toLowerCase(),
          needsAttention: isHot,
          isToday: false,
          isOverdue: false,
          isPriority: isHot,
          isPartial: false,
          sortRank: isHot ? 5 : 6,
        ),
      );
    }
    // cool/cold + güncel müşteriler: gerçek baskı yok → sessiz gizleme.
  }

  // Stabil önceliklendirme: önce sortRank, sonra tanım sırası.
  final ordered = [...entries];
  ordered.sort((a, b) => a.sortRank.compareTo(b.sortRank));

  final summary = ConsultantDailySummary(
    activeTasks: tasks.where((t) => !t.done).length,
    overdue: overdueTaskCount + staleFollowUpCount,
    todayContacts: todayContactCount,
    hotCustomers: hotCount,
    customers: customers.length,
  );

  return ConsultantDailySnapshot(
    entries: ordered,
    summary: summary,
    greetingName: greetingName,
    coverageNote:
        'Liste yalnızca size atanmış görev ve müşterilerden türetilir; '
        'müşteri sıcaklığı kural tabanlıdır (AI değil). Performans skoru, '
        'kaçırılan çağrı (iOS) ve verimlilik trendi sunucuda tutulmaz, gösterilmez.',
    isEmpty: ordered.isEmpty,
  );
}
