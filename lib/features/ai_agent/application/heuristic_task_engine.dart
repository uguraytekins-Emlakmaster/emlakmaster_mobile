import '../domain/axion_agent_enums.dart';
import '../domain/axion_agent_models.dart';
import '../domain/axion_agent_policy.dart';
import 'customer_signal_engine.dart';
import 'suggestion_deduplicator.dart';

/// Deterministik görev/öneri motoru — danışman kuralları.
///
/// Saf fonksiyon: aynı girdi → aynı çıktı. Ağ yok, yan etki yok.
abstract final class HeuristicTaskEngine {
  static List<AxionAgentSuggestion> generate(AxionAgentContext ctx) {
    final now = ctx.now;
    final suggestions = <AxionAgentSuggestion>[];

    // Performans: girdileri sınırla (cap-before-process).
    final customers = ctx.customerSnapshots
        .take(AxionAgentPolicy.maxInputSnapshotCap)
        .toList(growable: false);
    final tasks = ctx.taskSnapshots
        .take(AxionAgentPolicy.maxInputSnapshotCap)
        .toList(growable: false);
    final calls = ctx.callSnapshots
        .take(AxionAgentPolicy.maxInputSnapshotCap)
        .toList(growable: false);

    // Müşteri bazlı görünümler tek geçişte kurulur (O(n)).
    final tasksByCustomer = <String, List<AxionTaskSnapshot>>{};
    for (final t in tasks) {
      final cid = t.customerId;
      if (cid == null || cid.isEmpty) continue;
      (tasksByCustomer[cid] ??= []).add(t);
    }
    final callsByCustomer = <String, List<AxionCallSnapshot>>{};
    for (final c in calls) {
      final cid = c.customerId;
      if (cid == null || cid.isEmpty) continue;
      (callsByCustomer[cid] ??= []).add(c);
    }
    final customerById = {for (final c in customers) c.id: c};

    // ---- Kural 1: Geciken görevler ----
    for (final t in tasks) {
      if (!t.isOverdue(now)) continue;
      final overdue = now.difference(t.dueAt!);
      final urgency = overdue.inDays >= AxionAgentPolicy.overdueCriticalDays
          ? AxionAgentUrgency.critical
          : overdue.inHours >= AxionAgentPolicy.overdueHighHours
              ? AxionAgentUrgency.high
              : AxionAgentUrgency.medium;
      final customer =
          t.customerId == null ? null : customerById[t.customerId];
      suggestions.add(AxionAgentSuggestion(
        id: 'overdue-task-${t.id}',
        title: 'Geciken görevi tamamla',
        description: t.title.isEmpty ? 'Görev gecikmiş durumda.' : t.title,
        reason: 'Bu görev zamanında tamamlanmamış.',
        sourceType: AxionAgentSourceType.rules,
        confidence: AxionAgentConfidence.high,
        urgency: urgency,
        actionType: AxionAgentActionType.createTask,
        recommendedAction: AxionRecommendedAction(
          type: AxionAgentActionType.createTask,
          title: 'Görevi yeniden planla veya tamamla',
          requiresApproval: true,
          payload: {'taskId': t.id, 'customerId': t.customerId},
        ),
        targetType: 'task',
        targetId: t.id,
        createdAt: now,
        expiresAt: now.add(AxionAgentPolicy.suggestionTtl),
        evidence: [
          'Son tarih: ${_fmtDate(t.dueAt!)} (${overdue.inDays} gün gecikme)',
          if (customer != null && customer.name.isNotEmpty)
            'Müşteri: ${customer.name}',
        ],
      ));
    }

    // ---- Müşteri bazlı kurallar (2-7) ----
    for (final customer in customers) {
      final signals = CustomerSignalEngine.compute(
        customer: customer,
        tasks: tasksByCustomer[customer.id] ?? const [],
        calls: callsByCustomer[customer.id] ?? const [],
        now: now,
        hasPortfolioCandidates: ctx.portfolioSnapshots.isNotEmpty ||
            ctx.listingSnapshots.isNotEmpty,
      );

      // Kural 2: Sessiz müşteri
      if (signals.isSilent && customer.isActive) {
        final urgency = switch (customer.temperature) {
          AxionCustomerTemperature.hot => AxionAgentUrgency.high,
          AxionCustomerTemperature.warm => AxionAgentUrgency.medium,
          _ => AxionAgentUrgency.low,
        };
        suggestions.add(AxionAgentSuggestion(
          id: 'silent-${customer.id}',
          title: 'Sessiz müşteriyle iletişime geç',
          description:
              '${_displayName(customer)} ile ${signals.silentDays} gündür temas yok.',
          reason: 'Son temas tarihi belirlenen eşiği aştı.',
          sourceType: AxionAgentSourceType.rules,
          confidence: customer.lastContactAt == null
              ? AxionAgentConfidence.low
              : AxionAgentConfidence.high,
          urgency: urgency,
          actionType: customer.hasPhone
              ? AxionAgentActionType.scheduleFollowUp
              : AxionAgentActionType.draftMessage,
          recommendedAction: AxionRecommendedAction(
            type: AxionAgentActionType.scheduleFollowUp,
            title: 'Takip planla',
            requiresApproval: true,
            payload: {'customerId': customer.id},
          ),
          targetType: 'customer',
          targetId: customer.id,
          createdAt: now,
          expiresAt: now.add(AxionAgentPolicy.suggestionTtl),
          evidence: [
            if (customer.lastContactAt != null)
              'Son temas: ${_fmtDate(customer.lastContactAt!)}',
            'Sıcaklık: ${_tempLabel(customer.temperature)}',
          ],
          honestyNote: customer.lastContactAt == null
              ? AxionAgentPolicy.partialDataNote
              : null,
          missingData: [
            if (customer.lastContactAt == null) 'lastContactAt',
          ],
        ));
      }

      // Kural 3: Cevapsız arama + takip görevi yok
      if (signals.hasMissedCall && signals.hasNoActiveFollowUp) {
        final lastMissed = (callsByCustomer[customer.id] ?? const [])
            .where((c) => c.isMissedOrNoAnswer)
            .fold<DateTime?>(null, (acc, c) =>
                acc == null || c.at.isAfter(acc) ? c.at : acc);
        final daysAgo =
            lastMissed == null ? null : now.difference(lastMissed).inDays;
        suggestions.add(AxionAgentSuggestion(
          id: 'missed-call-${customer.id}',
          title: 'Cevapsız aramaya geri dön',
          description:
              '${_displayName(customer)} için dönüş yapılmamış cevapsız arama var.',
          reason: 'Cevapsız arama sonrası takip görevi oluşturulmamış.',
          sourceType: AxionAgentSourceType.rules,
          confidence: AxionAgentConfidence.high,
          urgency: (daysAgo ?? 0) >= AxionAgentPolicy.missedCallMediumDays
              ? AxionAgentUrgency.medium
              : AxionAgentUrgency.high,
          actionType: AxionAgentActionType.callCustomer,
          recommendedAction: AxionRecommendedAction(
            type: AxionAgentActionType.callCustomer,
            title: 'Müşteriyi ara',
            requiresApproval: true,
            payload: {'customerId': customer.id, 'phone': customer.phone},
          ),
          targetType: 'customer',
          targetId: customer.id,
          createdAt: now,
          expiresAt: now.add(AxionAgentPolicy.suggestionTtl),
          evidence: [
            if (lastMissed != null) 'Cevapsız: ${_fmtDate(lastMissed)}',
          ],
        ));
      }

      // Kural 4: Sıcak müşteri ama aktif takip yok
      if (signals.isHot &&
          signals.hasNoActiveFollowUp &&
          !signals.hasMissedCall) {
        suggestions.add(AxionAgentSuggestion(
          id: 'hot-no-task-${customer.id}',
          title: 'Sıcak müşteri için görev oluştur',
          description:
              '${_displayName(customer)} sıcak ama aktif takip görünmüyor.',
          reason: 'Sıcak müşteri için aktif takip görünmüyor.',
          sourceType: AxionAgentSourceType.rules,
          confidence: AxionAgentConfidence.high,
          urgency: AxionAgentUrgency.high,
          actionType: AxionAgentActionType.createTask,
          recommendedAction: AxionRecommendedAction(
            type: AxionAgentActionType.createTask,
            title: 'Takip görevi oluştur',
            requiresApproval: true,
            payload: {'customerId': customer.id},
          ),
          targetType: 'customer',
          targetId: customer.id,
          createdAt: now,
          expiresAt: now.add(AxionAgentPolicy.suggestionTtl),
          evidence: ['Sıcaklık: ${_tempLabel(customer.temperature)}'],
        ));
      }

      // Kural 5: Eksik müşteri verisi
      final missing = <String>[
        if (signals.hasMissingBudget) 'bütçe',
        if (signals.hasMissingRegion) 'bölge',
        if (!customer.hasPropertyType) 'mülk tipi',
        if (signals.hasMissingIntent) 'niyet',
        if (signals.hasMissingPhone) 'telefon',
      ];
      if (missing.isNotEmpty && customer.isActive) {
        suggestions.add(AxionAgentSuggestion(
          id: 'missing-data-${customer.id}',
          title: 'Eksik müşteri bilgisini tamamla',
          description:
              '${_displayName(customer)}: ${missing.join(', ')} bilgisi eksik.',
          reason: 'Eksik bilgi, doğru portföy önerisini zorlaştırır.',
          sourceType: AxionAgentSourceType.rules,
          confidence: AxionAgentConfidence.high,
          urgency: signals.hasMissingPhone || missing.length >= 3
              ? AxionAgentUrgency.medium
              : AxionAgentUrgency.low,
          actionType: AxionAgentActionType.updateCustomerInfo,
          recommendedAction: AxionRecommendedAction(
            type: AxionAgentActionType.updateCustomerInfo,
            title: 'Bilgileri güncelle',
            requiresApproval: true,
            payload: {'customerId': customer.id, 'missing': missing},
          ),
          targetType: 'customer',
          targetId: customer.id,
          createdAt: now,
          expiresAt: now.add(AxionAgentPolicy.suggestionTtl),
          missingData: missing,
          evidence: ['Veri tamlığı: %${signals.dataCompletenessPercent}'],
          honestyNote: AxionAgentPolicy.partialDataNote,
        ));
      }

      // Kural 6: Eskiyen aktif fırsat
      if (customer.isActive &&
          !signals.isSilent &&
          signals.silentDays != null &&
          signals.silentDays! > AxionAgentPolicy.staleOpportunityDays &&
          signals.hasNoActiveFollowUp) {
        suggestions.add(AxionAgentSuggestion(
          id: 'stale-opp-${customer.id}',
          title: 'Eskiyen fırsatı tazele',
          description:
              '${_displayName(customer)} aktif ama ${signals.silentDays} gündür etkileşim yok.',
          reason: 'Aktif fırsatta uzun süredir etkileşim yok.',
          sourceType: AxionAgentSourceType.rules,
          confidence: AxionAgentConfidence.medium,
          urgency: AxionAgentUrgency.medium,
          actionType: AxionAgentActionType.scheduleFollowUp,
          recommendedAction: AxionRecommendedAction(
            type: AxionAgentActionType.scheduleFollowUp,
            title: 'Takip planla',
            requiresApproval: true,
            payload: {'customerId': customer.id},
          ),
          targetType: 'customer',
          targetId: customer.id,
          createdAt: now,
          expiresAt: now.add(AxionAgentPolicy.suggestionTtl),
        ));
      }

      // Kural 7: Eşleşme incelemesi bekleyen profil
      if (signals.hasPortfolioMatchPotential) {
        suggestions.add(AxionAgentSuggestion(
          id: 'match-review-${customer.id}',
          title: 'Portföy eşleşmesini incele',
          description:
              '${_displayName(customer)} için kriterlere uygun portföyler olabilir.',
          reason:
              'Bölge, bütçe ve mülk tipi dolu; eşleşme incelemesi yapılmamış.',
          sourceType: AxionAgentSourceType.rules,
          confidence: AxionAgentConfidence.medium,
          urgency: AxionAgentUrgency.low,
          actionType: AxionAgentActionType.reviewPortfolioMatch,
          recommendedAction: AxionRecommendedAction(
            type: AxionAgentActionType.reviewPortfolioMatch,
            title: 'Eşleşmeleri görüntüle',
            requiresApproval: true,
            payload: {'customerId': customer.id},
          ),
          targetType: 'customer',
          targetId: customer.id,
          createdAt: now,
          expiresAt: now.add(AxionAgentPolicy.suggestionTtl),
        ));
      }
    }

    return SuggestionDeduplicator.dedupe(suggestions);
  }

  static String _displayName(AxionCustomerSnapshot c) =>
      c.name.trim().isEmpty ? 'Müşteri' : c.name.trim();

  static String _tempLabel(AxionCustomerTemperature t) => switch (t) {
        AxionCustomerTemperature.hot => 'Sıcak',
        AxionCustomerTemperature.warm => 'Ilık',
        AxionCustomerTemperature.cold => 'Soğuk',
        AxionCustomerTemperature.unknown => 'Bilinmiyor',
      };

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
