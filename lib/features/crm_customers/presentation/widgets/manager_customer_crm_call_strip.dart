import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
import 'package:flutter/material.dart';

/// Yönetici: müşteri kartında son CRM çağrı kayıtları (telekom kesinliği yok).
class ManagerCustomerCrmCallStrip extends StatelessWidget {
  const ManagerCustomerCrmCallStrip({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context) {
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
                      Icon(Icons.phone_callback_rounded, color: ext.accent, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'CRM çağrı kayıtları (yönetici)',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: ext.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Uygulamada kayıtlı handoff / sonuç / notlar. Operatör doğrulamalı hat süresi burada yoktur.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ext.textTertiary,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 10),
                  for (final d in docs.take(5)) _CallLine(doc: d),
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
  const _CallLine({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.fiber_manual_record, size: 8, color: ext.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$timeStr · $agent · $outcome · $cap',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ext.textSecondary,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
