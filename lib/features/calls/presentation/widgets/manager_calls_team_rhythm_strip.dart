import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_surface_quick_filter.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
import 'package:flutter/material.dart';

/// Yönetici çağrı listesi: tek satır, mevcut anlık veriden hafif ekip nabzı.
class ManagerCallsTeamRhythmStrip extends StatelessWidget {
  const ManagerCallsTeamRhythmStrip({
    super.key,
    required this.docs,
    required this.agentNames,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final Map<String, String> agentNames;

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) return const SizedBox.shrink();
    final ext = AppThemeExtension.of(context);
    final start = CallSurfaceQuickFilterLogic.startOfTodayLocal();
    var today = 0;
    var pending = 0;
    final counts = <String, int>{};
    for (final d in docs) {
      final data = d.data();
      final created = CrmCallRecordHelpers.createdAtOf(data);
      if (created != null && !created.isBefore(start)) {
        today++;
      }
      if (!CrmCallRecordHelpers.hasCaptureCompleted(data) ||
          CrmCallRecordHelpers.isHandoffPending(data)) {
        pending++;
      }
      final aid = CrmCallRecordHelpers.agentIdOf(data);
      if (aid.isNotEmpty &&
          created != null &&
          !created.isBefore(start)) {
        counts[aid] = (counts[aid] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntry = sorted.isEmpty ? null : sorted.first;
    final topLabel = topEntry != null && topEntry.value > 0
        ? (agentNames[topEntry.key]?.trim().isNotEmpty == true
            ? agentNames[topEntry.key]!.trim()
            : topEntry.key)
        : null;
    final topN = topEntry?.value ?? 0;
    final pulse = StringBuffer('Bugün $today kayıt');
    if (pending > 0) {
      pulse.write(' · $pending aksiyon açık');
    }
    if (topLabel != null && topN > 0 && today > 0) {
      pulse.write(' · yoğunluk: $topLabel ($topN)');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        0,
        DesignTokens.space4,
        DesignTokens.space2,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ext.surfaceElevated.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: ext.border.withValues(alpha: 0.34)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space3 + 2,
            vertical: DesignTokens.space2,
          ),
          child: Row(
            children: [
              Icon(
                Icons.groups_rounded,
                size: 18,
                color: ext.textSecondary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: DesignTokens.space2 + 2),
              Expanded(
                child: Text(
                  pulse.toString(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w500,
                        height: 1.28,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
