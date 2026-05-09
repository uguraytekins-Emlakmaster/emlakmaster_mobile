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
import 'package:emlakmaster_mobile/features/calls/presentation/providers/firestore_agent_display_names_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/local_call_records_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/crm_call_record_display.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_sync_status_icon.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/crm_call_record_list_item.dart';
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
        final agentNames =
            ref.watch(firestoreAgentDisplayNamesProvider).valueOrNull ??
                const <String, String>{};
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
                          'Son görüşmeler',
                          style: AppTypography.cardHeading(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.titleSubtitleGap),
                  Text(
                    'Uygulamadaki sonuç ve notlar. Hat süresi operatör kayıtlarıyla doğrulanmaz.',
                    style: AppTypography.meta(context),
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  for (final d in docs.take(5))
                    _CallLine(
                      doc: d,
                      locals: locals,
                      currentUid: currentUid,
                      agentNames: agentNames,
                    ),
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
    required this.agentNames,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final List<LocalCallRecord> locals;
  final String? currentUid;
  final Map<String, String> agentNames;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final data = doc.data();
    final agent = CrmCallRecordHelpers.agentIdOf(data);
    final created = CrmCallRecordHelpers.createdAtOf(data);
    final timeStr = created != null
        ? '${created.day}.${created.month}.${created.year} ${created.hour}:${created.minute.toString().padLeft(2, '0')}'
        : '—';
    final outcome = CrmCallRecordHelpers.outcomeDisplayTrDefault(data);
    final cap = CrmCallRecordHelpers.captureStatusTr(data);
    final rawPhone = (data['phoneNumber'] ?? data['phone'] ?? '').toString();
    final hasDigits = rawPhone.replaceAll(RegExp(r'\D'), '').isNotEmpty;
    final formattedPhone =
        hasDigits ? CrmCallRecordDisplay.formatPhone(rawPhone) : '—';
    final title = CrmCallRecordDisplay.primaryTitle(
      contactDisplayName: CrmCallRecordDisplay.contactNameFromCallData(data),
      rawPhone: hasDigits ? rawPhone : null,
    );
    final phoneUnder = CrmCallRecordDisplay.shouldShowPhoneUnderTitle(
      title: title,
      formattedPhone: formattedPhone,
    )
        ? formattedPhone
        : null;
    final advisorPart = CrmCallRecordDisplay.advisorContext(
      advisorAgentId: agent,
      currentUid: currentUid,
      agentNames: agentNames,
    );
    final contextLine = CrmCallRecordDisplay.contextLine(
      advisorPart: advisorPart,
      dateTime: timeStr,
    );
    final quickNote =
        CrmCallRecordDisplay.notePreviewFromFirestoreData(data);
    final foot = CrmCallRecordDisplay.technicalFootnote(
      firestoreDocId: doc.id,
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
      child: Material(
        color: ext.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: ext.border.withValues(alpha: 0.45)),
          ),
          child: CrmCallRecordListItem(
            title: title,
            phoneSubtitle: phoneUnder,
            outcomeLabel: outcome,
            captureLabel: cap,
            contextLine: contextLine,
            notePreview: quickNote,
            technicalFootnote: foot,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ext.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Icon(Icons.call_rounded, size: 20, color: ext.accent),
            ),
            trailing: syncIcon,
            padding: const EdgeInsets.all(DesignTokens.space3),
          ),
        ),
      ),
    );
  }
}
