import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/domain/local_call_record_firestore_match.dart';
import 'package:emlakmaster_mobile/features/calls/domain/local_call_sync_ui_state.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/local_call_records_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_sync_status_icon.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yönetici: müşteri kartında son CRM çağrı kayıtları (telekom kesinliği yok).
class ManagerCustomerCrmCallStrip extends ConsumerWidget {
  const ManagerCustomerCrmCallStrip({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.callsByCustomerStream(customerId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.space4),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }
        if (snap.hasError) {
          return const SizedBox.shrink();
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();
        final locals =
            ref.watch(localCallRecordsStreamProvider).valueOrNull ?? [];
        final currentUid = ref.watch(currentUserProvider).valueOrNull?.uid;
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space4),
          child: Material(
            borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
            color: ext.surfaceElevated,
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone_callback_rounded,
                          color: ext.accent, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'CRM çağrı kayıtları (yönetici)',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: ext.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.titleSubtitleGap),
                  Text(
                    'Uygulamada kayıtlı handoff / sonuç / notlar. Operatör doğrulamalı hat süresi burada yoktur.',
                    style: AppTypography.meta(context),
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  for (final d in docs.take(5))
                    _CallLine(doc: d, locals: locals, currentUid: currentUid),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CallLine extends ConsumerWidget {
  const _CallLine({
    required this.doc,
    required this.locals,
    required this.currentUid,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final List<LocalCallRecord> locals;
  final String? currentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final data = doc.data();
    final agent = CrmCallRecordHelpers.agentIdOf(data);
    final consultantDoc = agent.isEmpty
        ? null
        : ref.watch(userDocStreamProvider(agent)).valueOrNull;
    final consultantName = (consultantDoc?.name?.trim().isNotEmpty ?? false)
        ? consultantDoc!.name!.trim()
        : (consultantDoc?.email?.trim().isNotEmpty ?? false)
            ? consultantDoc!.email!.trim()
            : (agent.isEmpty ? 'Danışman bilgisi yok' : _shortAgent(agent));
    final created = CrmCallRecordHelpers.createdAtOf(data);
    final timeStr = created != null
        ? '${created.day}.${created.month}.${created.year} ${created.hour}:${created.minute.toString().padLeft(2, '0')}'
        : '—';
    final outcome = CrmCallRecordHelpers.outcomeDisplayTr(data, const {
      'handoff_pending': 'Sonuç bekleniyor',
      'reached': 'Ulaşıldı',
      'no_answer': 'Cevap yok',
      'completed': 'Tamamlandı',
    });
    final cap = CrmCallRecordHelpers.captureStatusTr(data);
    final note = (data['quickCaptureNote'] as String? ?? '').trim();
    final phone = _formatPhone(
      (data['phoneNumber'] as String? ?? data['phone'] as String? ?? '—')
          .trim(),
    );
    final localMatch = matchLocalCallRecordForFirestoreDoc(
      locals: locals,
      docId: doc.id,
      data: data,
    );
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    Widget? syncIcon;
    if (localMatch != null) {
      final syncState = deriveLocalCallSyncUiState(localMatch, nowMs: nowMs);
      VoidCallback? onRetry;
      if (syncState == LocalCallSyncUiState.failedPermanent &&
          currentUid != null &&
          currentUid == localMatch.agentId) {
        onRetry = () => unawaited(retryLocalCallRecordSync(localMatch));
      }
      syncIcon = Tooltip(
        message: 'Senkron durumu',
        child: CallSyncStatusIcon(
          record: localMatch,
          onManualRetry: onRetry,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space3),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space3),
        decoration: BoxDecoration(
          color: ext.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: ext.border.withValues(alpha: 0.45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ext.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Icon(Icons.call_rounded, color: ext.accent, size: 18),
            ),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phone,
                    style: AppTypography.cardHeading(context)
                        .copyWith(fontSize: DesignTokens.fontSizeMd),
                  ),
                  const SizedBox(height: DesignTokens.metricLabelGap),
                  Wrap(
                    spacing: DesignTokens.space2,
                    runSpacing: DesignTokens.space1,
                    children: [
                      _MetaPill(label: outcome, accent: ext.accent),
                      _MetaPill(
                        label: cap,
                        accent: cap.contains('tamamlandı')
                            ? ext.success
                            : ext.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    'Danışman: $consultantName',
                    style: AppTypography.body(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DesignTokens.space1),
                  Text(
                    timeStr,
                    style: AppTypography.meta(context),
                  ),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      note,
                      style: AppTypography.meta(context)
                          .copyWith(color: ext.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (syncIcon != null) ...[
              const SizedBox(width: DesignTokens.space2),
              syncIcon,
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space2,
        vertical: DesignTokens.space1,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.metricLabel(context).copyWith(color: accent),
      ),
    );
  }
}

String _shortAgent(String agent) {
  final trimmed = agent.trim();
  if (trimmed.length <= 6) return trimmed;
  return '...${trimmed.substring(trimmed.length - 6)}';
}

String _formatPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) {
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 8)} ${digits.substring(8)}';
  }
  if (digits.length == 11 && digits.startsWith('0')) {
    return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7, 9)} ${digits.substring(9)}';
  }
  return raw;
}
