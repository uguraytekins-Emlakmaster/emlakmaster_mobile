import '../data/axion_agent_audit_repository.dart';
import '../data/axion_agent_local_cache.dart';
import '../domain/axion_agent_enums.dart';
import '../domain/axion_agent_models.dart';
import '../domain/axion_agent_repository.dart';
import 'audit_event_builder.dart';
import 'axion_agent_cache_key_builder.dart';
import 'axion_agent_gate.dart';
import 'broker_operations_brief_engine.dart';
import 'consultant_daily_plan_engine.dart';
import 'heuristic_task_engine.dart';
import 'listing_quality_engine.dart';
import 'message_template_engine.dart';
import 'portfolio_match_rule_engine.dart';
import 'suggestion_ranker.dart';

/// Axion Agent ana facade'i.
///
/// Akış: Gate → Cache → Motor → Audit. Hiçbir adımda ağ veya ücretli
/// sağlayıcı yoktur. Tüm hesaplama kullanıcı tetiklemesiyle, snapshot
/// üzerinden, senkron-hızlı çalışır (startup'ta ASLA çağrılmaz).
class AxionAgentEngine {
  AxionAgentEngine({
    AxionAgentLocalCache? cache,
    AxionAgentAuditRepository? auditRepository,
  })  : _cache = cache ?? AxionAgentLocalCache(),
        _audit = auditRepository ?? LocalAxionAgentAuditRepository();

  final AxionAgentLocalCache _cache;
  final AxionAgentAuditRepository _audit;

  AxionAgentAuditRepository get audit => _audit;

  /// Danışman önerileri (kural tabanlı, sıralı, tekilleştirilmiş, sınırlı).
  Future<List<AxionAgentSuggestion>> generateSuggestions(
    AxionAgentContext ctx,
  ) async {
    const op = AxionAgentOperation.generateSuggestions;
    final gate = _gate(ctx, op);
    if (!gate.allowed) return const [];

    final key = _key(ctx, op);
    if (gate.useCache || _cache.contains(key)) {
      final cached = _cache.get<List<AxionAgentSuggestion>>(key);
      if (cached != null) return cached;
    }

    final suggestions = SuggestionRanker.rank(HeuristicTaskEngine.generate(ctx));
    _cache.put(key, suggestions);

    for (final s in suggestions) {
      await _audit.record(AuditEventBuilder.fromSuggestion(
        eventType: AxionAuditEventType.suggestionCreated,
        suggestion: s,
        userId: ctx.userId,
        role: ctx.role,
        workspaceId: ctx.workspaceId,
        timestamp: ctx.now,
      ));
    }
    return suggestions;
  }

  /// Danışman günlük planı.
  Future<AxionDailyPlan?> generateDailyPlan(AxionAgentContext ctx) async {
    const op = AxionAgentOperation.generateDailyPlan;
    final gate = _gate(ctx, op);
    if (!gate.allowed) return null;

    final key = _key(ctx, op);
    final cached = _cache.get<AxionDailyPlan>(key);
    if (cached != null) return cached;

    final plan = ConsultantDailyPlanEngine.generate(ctx);
    _cache.put(key, plan);
    return plan;
  }

  /// Broker/Admin operasyon özeti (rol korumalı).
  Future<AxionBrokerBrief?> generateBrokerBrief(AxionAgentContext ctx) async {
    const op = AxionAgentOperation.generateBrokerBrief;
    final gate = _gate(ctx, op);
    if (!gate.allowed) {
      await _audit.record(AuditEventBuilder.build(
        eventType: AxionAuditEventType.gateBlockedAction,
        userId: ctx.userId,
        role: ctx.role,
        workspaceId: ctx.workspaceId,
        sourceType: AxionAgentSourceType.rules,
        metadata: {'operation': op.name, 'reason': gate.blockedReason},
        timestamp: ctx.now,
      ));
      return null;
    }

    final key = _key(ctx, op);
    final cached = _cache.get<AxionBrokerBrief>(key);
    if (cached != null) return cached;

    final brief = BrokerOperationsBriefEngine.generate(ctx);
    _cache.put(key, brief);
    return brief;
  }

  /// Şablon tabanlı mesaj taslağı (her zaman requiresReview = true).
  Future<AxionMessageDraft?> generateMessageDraft(
    AxionAgentContext ctx,
    AxionMessageTemplateInput input,
  ) async {
    const op = AxionAgentOperation.generateMessageDraft;
    final gate = _gate(ctx, op);
    if (!gate.allowed) return null;

    final draft = MessageTemplateEngine.generate(input);
    await _audit.record(AuditEventBuilder.build(
      eventType: AxionAuditEventType.draftGenerated,
      userId: ctx.userId,
      role: ctx.role,
      workspaceId: ctx.workspaceId,
      sourceType: AxionAgentSourceType.template,
      actionType: AxionAgentActionType.draftMessage,
      targetType: 'customer',
      targetId: input.targetCustomerId,
      timestamp: ctx.now,
    ));
    return draft;
  }

  /// Kural tabanlı portföy eşleşmeleri.
  Future<List<PortfolioMatchSuggestion>> generatePortfolioMatches(
    AxionAgentContext ctx,
    AxionCustomerSnapshot customer,
  ) async {
    const op = AxionAgentOperation.generatePortfolioMatches;
    final gate = _gate(ctx, op);
    if (!gate.allowed) return const [];

    final key = _key(ctx, op, targetId: customer.id);
    final cached = _cache.get<List<PortfolioMatchSuggestion>>(key);
    if (cached != null) return cached;

    final listings = ctx.portfolioSnapshots.isNotEmpty
        ? ctx.portfolioSnapshots
        : ctx.listingSnapshots;
    final matches =
        PortfolioMatchRuleEngine.match(customer: customer, listings: listings);
    _cache.put(key, matches);
    return matches;
  }

  /// Eksik portföy bilgisi önerileri.
  Future<List<AxionAgentSuggestion>> generateListingQuality(
    AxionAgentContext ctx,
  ) async {
    const op = AxionAgentOperation.generateListingQuality;
    final gate = _gate(ctx, op);
    if (!gate.allowed) return const [];

    final key = _key(ctx, op);
    final cached = _cache.get<List<AxionAgentSuggestion>>(key);
    if (cached != null) return cached;

    final result = ListingQualityEngine.analyze(
      listings: ctx.listingSnapshots,
      now: ctx.now,
    );
    _cache.put(key, result);
    return result;
  }

  /// Önbelleği temizle (veri değişiminde manuel tetikleme için).
  void invalidateCache() => _cache.clear();

  AxionAgentGateDecision _gate(
    AxionAgentContext ctx,
    AxionAgentOperation op,
  ) {
    return AxionAgentGate.decide(
      operation: op,
      role: ctx.role,
      mode: ctx.mode,
      permissions: ctx.permissions,
      hasData: ctx.customerSnapshots.isNotEmpty ||
          ctx.taskSnapshots.isNotEmpty ||
          ctx.listingSnapshots.isNotEmpty,
    );
  }

  String _key(
    AxionAgentContext ctx,
    AxionAgentOperation op, {
    String targetId = '',
  }) {
    return AxionAgentCacheKeyBuilder.build(
      workspaceId: ctx.workspaceId,
      userId: ctx.userId,
      role: ctx.role,
      operationType: op,
      targetId: targetId,
      mode: ctx.mode,
      locale: ctx.locale,
      relevantUpdatedAt: [
        for (final c in ctx.customerSnapshots) c.updatedAt,
        for (final t in ctx.taskSnapshots) t.updatedAt,
        for (final l in ctx.listingSnapshots) l.updatedAt,
      ],
    );
  }
}
