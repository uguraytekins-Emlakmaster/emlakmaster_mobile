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
                          style: AppTypography.cardHeading(context),
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

class _CallLine extends StatelessWidget {
  const _CallLine({
    required this.doc,
    required this.locals,
    required this.currentUid,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final List<LocalCallRecord> locals;
  final String? currentUid;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final data = doc.data();
    final agent = CrmCallRecordHelpers.agentIdOf(data);
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
    final quickNote =
        (data['quickCaptureNote'] as String?)?.trim().isNotEmpty == true
            ? (data['quickCaptureNote'] as String).trim()
            : null;
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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: ext.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Icon(Icons.call_rounded, size: 18, color: ext.accent),
            ),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: DesignTokens.space2,
                    runSpacing: DesignTokens.space2,
                    children: [
                      _ManagerCallBadge(label: outcome, color: ext.accent),
                      _ManagerCallBadge(label: cap, color: ext.textSecondary),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    'Danışman: ${agent.isEmpty ? '—' : _shortAgent(agent)}',
                    style: AppTypography.bodyStrong(context),
                  ),
                  const SizedBox(height: DesignTokens.space1),
                  Text(
                    timeStr,
                    style: AppTypography.meta(context),
                  ),
                  if (quickNote != null) ...[
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      quickNote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(context),
                    ),
                  ],
                ],
              ),
            ),
            if (syncIcon != null) syncIcon,
          ],
        ),
      ),
    );
  }
}

String _shortAgent(String value) {
  final v = value.trim();
  if (v.length <= 8) return v;
  return '${v.substring(0, 4)}...${v.substring(v.length - 4)}';
}

class _ManagerCallBadge extends StatelessWidget {
  const _ManagerCallBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space2,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.meta(context).copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
