import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/manager_escalation.dart';
import 'package:emlakmaster_mobile/features/dashboard/presentation/providers/manager_escalations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Yönetici taşımaları — broker uyarılarından ayrı, daha seçici.
class ManagerEscalationsCard extends ConsumerWidget {
  const ManagerEscalationsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final async = ref.watch(managerEscalationsProvider);
    return async.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final hasCritical =
            items.any((e) => e.escalationPriority == EscalationPriority.critical);
        return Padding(
          padding: EdgeInsets.only(bottom: hasCritical ? DesignTokens.space5 : DesignTokens.space4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.space4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              color: ext.surfaceElevated,
              border: Border.all(
                color: hasCritical
                    ? ext.danger.withValues(alpha: 0.55)
                    : ext.warning.withValues(alpha: 0.45),
                width: hasCritical ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (hasCritical ? ext.danger : ext.warning)
                      .withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.supervisor_account_rounded,
                      size: 22,
                      color: hasCritical ? ext.danger : ext.warning,
                    ),
                    const SizedBox(width: DesignTokens.space2),
                    Expanded(
                      child: Text(
                        'Yöneticiye taşınan durumlar',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Text(
                      '${items.length}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: ext.textTertiary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  'Operasyon uyarılarından ayrı; müdahale veya koordinasyon gerektirebilir',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ext.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: DesignTokens.space3),
                ...items.map((e) => _EscalationRow(item: e)),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _EscalationRow extends ConsumerStatefulWidget {
  const _EscalationRow({required this.item});

  final ManagerEscalationItem item;

  @override
  ConsumerState<_EscalationRow> createState() => _EscalationRowState();
}

class _EscalationRowState extends ConsumerState<_EscalationRow> {
  bool _busy = false;

  Future<void> _dismiss() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.lightImpact();
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    await ref.read(escalationDedupeStoreProvider).suppress(uid, widget.item.dedupeKey);
    ref.invalidate(managerEscalationsProvider);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final e = widget.item;
    final pColor = switch (e.escalationPriority) {
      EscalationPriority.critical => ext.danger,
      EscalationPriority.high => ext.warning,
      EscalationPriority.medium => ext.textSecondary,
    };
    final pLabel = switch (e.escalationPriority) {
      EscalationPriority.critical => 'KRİTİK',
      EscalationPriority.high => 'YÜKSEK',
      EscalationPriority.medium => 'ORTA',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/customer/${e.relatedCustomerId}'),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: pColor.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.customerName?.trim().isNotEmpty == true
                                  ? e.customerName!.trim()
                                  : 'Müşteri',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: ext.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: pColor.withValues(alpha: 0.12),
                              border: Border.all(color: pColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              pLabel,
                              style: TextStyle(
                                color: pColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.escalationTitleTr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (e.aiInsightLineTr != null &&
                          e.aiInsightLineTr!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 13,
                              color: ext.accent.withValues(alpha: 0.88),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                e.aiInsightLineTr!.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: ext.textSecondary,
                                      height: 1.3,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        e.escalationDescriptionTr,
                        maxLines: e.aiInsightLineTr != null &&
                                e.aiInsightLineTr!.trim().isNotEmpty
                            ? 1
                            : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: ext.textTertiary,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: _busy ? null : _dismiss,
                      icon: Icon(Icons.close_rounded, size: 18, color: ext.textTertiary),
                      tooltip: 'Bugün gösterme',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    Icon(Icons.chevron_right_rounded, color: ext.textTertiary, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
