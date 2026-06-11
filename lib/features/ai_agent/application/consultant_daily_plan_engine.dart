import '../domain/axion_agent_enums.dart';
import '../domain/axion_agent_models.dart';
import '../domain/axion_agent_policy.dart';
import 'heuristic_task_engine.dart';
import 'message_template_engine.dart';
import 'suggestion_ranker.dart';

/// Danışman günlük planı — anında üretim, sahte üretkenlik skoru YOK.
///
/// Bölümler: "Önce bunları yap", "Geri dönülecek müşteriler",
/// "Geciken görevler", "Eksik bilgisi olan müşteriler",
/// "Portföy eşleşmesi kontrol edilecekler", "Bugün önerilen mesaj taslakları".
abstract final class ConsultantDailyPlanEngine {
  static AxionDailyPlan generate(AxionAgentContext ctx) {
    final all = HeuristicTaskEngine.generate(ctx);
    final ranked = SuggestionRanker.rank(all);

    final overdue = <AxionAgentSuggestion>[];
    final toCall = <AxionAgentSuggestion>[];
    final incomplete = <AxionAgentSuggestion>[];
    final matchReviews = <AxionAgentSuggestion>[];

    for (final s in ranked) {
      switch (s.actionType) {
        case AxionAgentActionType.createTask when s.targetType == 'task':
          overdue.add(s);
        case AxionAgentActionType.callCustomer:
        case AxionAgentActionType.scheduleFollowUp:
          toCall.add(s);
        case AxionAgentActionType.updateCustomerInfo:
          incomplete.add(s);
        case AxionAgentActionType.reviewPortfolioMatch:
          matchReviews.add(s);
        default:
          // createTask (müşteri hedefli) öncelik listesinde değerlendirilir.
          break;
      }
    }

    // "Önce bunları yap": sıralamadaki ilk N (zaten aciliyete göre sıralı).
    final topPriorities = ranked
        .take(AxionAgentPolicy.maxDailyPlanTopPriorities)
        .toList(growable: false);

    // Mesaj taslakları: geri dönüş bekleyen ilk 3 müşteri için.
    final drafts = <AxionMessageDraft>[];
    final customerById = {
      for (final c in ctx.customerSnapshots) c.id: c,
    };
    for (final s in toCall.take(3)) {
      final customer = customerById[s.targetId];
      if (customer == null) continue;
      drafts.add(MessageTemplateEngine.generate(AxionMessageTemplateInput(
        category: s.actionType == AxionAgentActionType.callCustomer
            ? AxionMessageTemplateCategory.noAnswerCallback
            : AxionMessageTemplateCategory.silentCustomerReactivation,
        customerName: customer.name,
        region: customer.region,
        targetCustomerId: customer.id,
      )));
    }

    // Dürüstlük: kısmi veri varsa not ekle.
    final hasPartialData = ranked.any((s) => s.missingData.isNotEmpty) ||
        ctx.customerSnapshots.isEmpty;

    return AxionDailyPlan(
      date: DateTime(ctx.now.year, ctx.now.month, ctx.now.day),
      consultantId: ctx.userId,
      topPriorities: topPriorities,
      overdueTasks: overdue,
      customersToCall: toCall,
      messageDrafts: drafts,
      incompleteRecords: incomplete,
      portfolioMatchReviews: matchReviews,
      honestyNote: hasPartialData
          ? AxionAgentPolicy.partialDataNote
          : AxionAgentPolicy.freeRulesNote,
      generatedAt: ctx.now,
    );
  }
}
