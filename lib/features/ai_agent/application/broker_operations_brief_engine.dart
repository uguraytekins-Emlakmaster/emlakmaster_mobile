import '../domain/axion_agent_enums.dart';
import '../domain/axion_agent_models.dart';
import '../domain/axion_agent_policy.dart';
import 'customer_signal_engine.dart';
import 'listing_quality_engine.dart';
import 'suggestion_ranker.dart';

/// Broker/Admin günlük operasyon özeti — yalnızca GERÇEK sayımlar.
///
/// Sahte trend YOK, sahte satış tahmini YOK, sahte ciro projeksiyonu YOK.
abstract final class BrokerOperationsBriefEngine {
  static AxionBrokerBrief generate(AxionAgentContext ctx) {
    final now = ctx.now;
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final customers = ctx.customerSnapshots
        .take(AxionAgentPolicy.maxInputSnapshotCap)
        .toList(growable: false);
    final tasks = ctx.taskSnapshots
        .take(AxionAgentPolicy.maxInputSnapshotCap)
        .toList(growable: false);
    final calls = ctx.callSnapshots
        .take(AxionAgentPolicy.maxInputSnapshotCap)
        .toList(growable: false);
    final listings = ctx.listingSnapshots
        .take(AxionAgentPolicy.maxInputSnapshotCap)
        .toList(growable: false);

    // --- Gerçek sayımlar ---
    var overdueTasks = 0;
    var tasksDueToday = 0;
    final customersWithFollowUp = <String>{};
    for (final t in tasks) {
      if (t.isOverdue(now)) overdueTasks++;
      if (!t.isCompleted &&
          t.dueAt != null &&
          !t.dueAt!.isBefore(today) &&
          t.dueAt!.isBefore(tomorrow)) {
        tasksDueToday++;
      }
      if (!t.isCompleted && t.customerId != null) {
        customersWithFollowUp.add(t.customerId!);
      }
    }

    final tasksByCustomer = <String, List<AxionTaskSnapshot>>{};
    for (final t in tasks) {
      final cid = t.customerId;
      if (cid == null) continue;
      (tasksByCustomer[cid] ??= []).add(t);
    }
    final callsByCustomer = <String, List<AxionCallSnapshot>>{};
    for (final c in calls) {
      final cid = c.customerId;
      if (cid == null) continue;
      (callsByCustomer[cid] ??= []).add(c);
    }

    var missedNoCallback = 0;
    var customersNoFollowUp = 0;
    var incompleteCustomers = 0;
    var hotWaiting = 0;
    for (final customer in customers) {
      final signals = CustomerSignalEngine.compute(
        customer: customer,
        tasks: tasksByCustomer[customer.id] ?? const [],
        calls: callsByCustomer[customer.id] ?? const [],
        now: now,
      );
      if (signals.hasMissedCall && signals.hasNoActiveFollowUp) {
        missedNoCallback++;
      }
      if (customer.isActive && signals.hasNoActiveFollowUp) {
        customersNoFollowUp++;
      }
      if (signals.dataCompletenessPercent < 60) incompleteCustomers++;
      if (signals.isHot && signals.hasNoActiveFollowUp) hotWaiting++;
    }

    final listingQuality =
        ListingQualityEngine.analyze(listings: listings, now: now);
    final incompleteListings = listingQuality.length;

    final counts = AxionBrokerRealCounts(
      overdueTasks: overdueTasks,
      missedCallsWithoutCallback: missedNoCallback,
      customersWithoutFollowUp: customersNoFollowUp,
      incompleteCustomerRecords: incompleteCustomers,
      incompleteListings: incompleteListings,
      hotCustomersWaiting: hotWaiting,
      tasksDueToday: tasksDueToday,
    );

    // --- Dikkat alanları (yalnızca sıfırdan büyük gerçek sayımlardan) ---
    final attention = <AxionAgentSuggestion>[];
    void addAttention({
      required String id,
      required String title,
      required String description,
      required String reason,
      required AxionAgentUrgency urgency,
      AxionAgentActionType actionType = AxionAgentActionType.brokerReview,
    }) {
      attention.add(AxionAgentSuggestion(
        id: id,
        title: title,
        description: description,
        reason: reason,
        sourceType: AxionAgentSourceType.rules,
        confidence: AxionAgentConfidence.high,
        urgency: urgency,
        actionType: actionType,
        targetType: 'workspace',
        targetId: ctx.workspaceId,
        createdAt: now,
        expiresAt: now.add(AxionAgentPolicy.suggestionTtl),
      ));
    }

    if (hotWaiting > 0) {
      addAttention(
        id: 'brief-hot-waiting',
        title: 'Takip bekleyen sıcak müşteriler',
        description: '$hotWaiting sıcak müşteride aktif takip görünmüyor.',
        reason: 'Sıcak müşteri + takip yok = kayıp riski.',
        urgency: AxionAgentUrgency.high,
      );
    }
    if (overdueTasks > 0) {
      addAttention(
        id: 'brief-overdue',
        title: 'Geciken görev yoğunluğu',
        description: '$overdueTasks görev gecikmiş durumda.',
        reason: 'Geciken görevler müşteri deneyimini düşürür.',
        urgency: overdueTasks >= 10
            ? AxionAgentUrgency.high
            : AxionAgentUrgency.medium,
      );
    }
    if (incompleteListings > 0) {
      addAttention(
        id: 'brief-incomplete-listings',
        title: 'Eksik portföy bilgileri',
        description: '$incompleteListings portföyde eksik alan var.',
        reason: 'Eksik portföy bilgisi eşleşme kalitesini düşürür.',
        urgency: AxionAgentUrgency.medium,
      );
    }
    if (missedNoCallback > 0) {
      addAttention(
        id: 'brief-missed-callbacks',
        title: 'Cevapsız arama dönüşleri',
        description: '$missedNoCallback cevapsız aramaya dönüş yapılmamış.',
        reason: 'Dönüş yapılmayan aramalar fırsat kaybıdır.',
        urgency: AxionAgentUrgency.high,
      );
    }
    if (incompleteCustomers > 0) {
      addAttention(
        id: 'brief-data-quality',
        title: 'Veri kalitesi eksikleri',
        description:
            '$incompleteCustomers müşteri kaydında kritik alanlar eksik.',
        reason: 'Eksik veri, öneri ve eşleşme kalitesini sınırlar.',
        urgency: AxionAgentUrgency.low,
      );
    }

    final rankedAttention = SuggestionRanker.rank(
      attention,
      cap: AxionAgentPolicy.maxBrokerAttentionAreas,
    );

    // --- Önerilen yönetici incelemeleri ---
    final reviews = <AxionAgentSuggestion>[];
    if (hotWaiting > 0) {
      reviews.add(AxionAgentSuggestion(
        id: 'review-hot-customers',
        title: 'Görevsiz sıcak müşterileri incele',
        description:
            'Aktif takibi olmayan $hotWaiting sıcak müşteriyi gözden geçir.',
        reason: 'Sıcak müşteriler için takip ataması gerekebilir.',
        sourceType: AxionAgentSourceType.rules,
        confidence: AxionAgentConfidence.high,
        urgency: AxionAgentUrgency.high,
        actionType: AxionAgentActionType.brokerReview,
        targetType: 'workspace',
        targetId: ctx.workspaceId,
        createdAt: now,
      ));
    }
    if (incompleteListings > 0) {
      reviews.add(AxionAgentSuggestion(
        id: 'review-incomplete-listings',
        title: 'Eksik portföyleri incele',
        description: '$incompleteListings portföyde tamamlanacak alan var.',
        reason: 'Portföy kalitesi sunum ve eşleşmeyi doğrudan etkiler.',
        sourceType: AxionAgentSourceType.rules,
        confidence: AxionAgentConfidence.high,
        urgency: AxionAgentUrgency.medium,
        actionType: AxionAgentActionType.brokerReview,
        targetType: 'workspace',
        targetId: ctx.workspaceId,
        createdAt: now,
      ));
    }

    // --- Eksik veri notları ---
    final dataNotes = <String>[
      if (customers.isEmpty) 'Müşteri verisi bulunamadı.',
      if (tasks.isEmpty) 'Görev verisi bulunamadı.',
      if (calls.isEmpty) 'Çağrı verisi bulunamadı.',
      if (listings.isEmpty) 'Portföy verisi bulunamadı.',
    ];

    return AxionBrokerBrief(
      date: today,
      workspaceId: ctx.workspaceId,
      realCounts: counts,
      attentionAreas: rankedAttention,
      teamRisks: [
        if (overdueTasks >= 10)
          'Görev gecikme yoğunluğu yüksek ($overdueTasks görev).',
        if (missedNoCallback >= 5)
          'Cevapsız arama dönüş oranı düşük ($missedNoCallback bekleyen).',
      ],
      suggestedReviews: reviews,
      incompleteDataNotes: dataNotes,
      honestyNote: AxionAgentPolicy.recordsLimitedNote,
      generatedAt: now,
    );
  }
}
