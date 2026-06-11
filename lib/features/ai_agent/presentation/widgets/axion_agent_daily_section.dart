import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/audit_event_builder.dart';
import '../../domain/axion_agent_enums.dart';
import '../../domain/axion_agent_models.dart';
import '../providers/axion_agent_providers.dart';
import 'axion_agent_honesty_note.dart';
import 'axion_agent_message_draft_card.dart';
import 'axion_agent_suggestion_card.dart';

/// "Benim Günüm" için Axion Agent öneri bölümü.
///
/// - Plan boşsa hiçbir şey çizmez (sahte içerik yok, ölü alan yok)
/// - En fazla 3 öncelik kartı gösterir (performans + sakin kompozisyon)
/// - İncele → müşteri detayına gerçek navigasyon
/// - Reddet → yerel gizleme + denetim kaydı
/// - Mesaj taslağı → kopyalanabilir taslak sheet'i (otomatik gönderim YOK)
class AxionAgentDailySection extends ConsumerStatefulWidget {
  const AxionAgentDailySection({super.key});

  @override
  ConsumerState<AxionAgentDailySection> createState() =>
      _AxionAgentDailySectionState();
}

class _AxionAgentDailySectionState
    extends ConsumerState<AxionAgentDailySection> {
  final Set<String> _rejectedIds = {};

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(axionDailyPlanProvider);
    final plan = planAsync.valueOrNull;
    if (plan == null || plan.isEmpty) return const SizedBox.shrink();

    final visible = plan.topPriorities
        .where((s) => !_rejectedIds.contains(s.id))
        .take(3)
        .toList(growable: false);
    if (visible.isEmpty) return const SizedBox.shrink();

    final t = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space2,
        DesignTokens.space4,
        DesignTokens.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 16, color: t.accent),
              const SizedBox(width: DesignTokens.space2),
              Text(
                'Axion Agent önerileri',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBase,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              Text(
                'Kural tabanlı · ücretsiz',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXs,
                  color: t.textPassive,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space3),
          for (final s in visible) ...[
            AxionAgentSuggestionCard(
              suggestion: s,
              onReview: s.targetType == 'customer' && s.targetId.isNotEmpty
                  ? () => context.push('/customer/${s.targetId}')
                  : null,
              onDraftMessage: _draftFor(plan, s) != null
                  ? () => _showDraftSheet(context, _draftFor(plan, s)!)
                  : null,
              onReject: () => _reject(s),
            ),
            const SizedBox(height: DesignTokens.space3),
          ],
          if (plan.honestyNote != null)
            AxionAgentHonestyNote(note: plan.honestyNote!),
        ],
      ),
    );
  }

  AxionMessageDraft? _draftFor(AxionDailyPlan plan, AxionAgentSuggestion s) {
    if (s.targetType != 'customer') return null;
    for (final d in plan.messageDrafts) {
      if (d.targetCustomerId == s.targetId) return d;
    }
    return null;
  }

  void _reject(AxionAgentSuggestion s) {
    setState(() => _rejectedIds.add(s.id));
    final ctx = ref.read(axionConsultantContextProvider);
    if (ctx == null) return;
    ref.read(axionAgentEngineProvider).audit.record(
          AuditEventBuilder.fromSuggestion(
            eventType: AxionAuditEventType.suggestionRejected,
            suggestion: s.copyWith(
              approvalStatus: AxionAgentApprovalStatus.rejected,
            ),
            userId: ctx.userId,
            role: ctx.role,
            workspaceId: ctx.workspaceId,
          ),
        );
  }

  void _showDraftSheet(BuildContext context, AxionMessageDraft draft) {
    final t = AppThemeExtension.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusSheet),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: AxionAgentMessageDraftCard(
            draft: draft,
            onCopied: () {
              Navigator.of(sheetContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Taslak panoya kopyalandı')),
              );
            },
          ),
        ),
      ),
    );
  }
}
