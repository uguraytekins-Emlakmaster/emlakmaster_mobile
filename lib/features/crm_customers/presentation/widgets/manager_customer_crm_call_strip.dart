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
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_surface_contextual_insight.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_surface_card_rhythm.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_card_memory_hints.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_sync_status_icon.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/crm_call_operating_card.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/crm_call_record_list_item.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_identity_quick_actions_sheet.dart';
import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(DesignTokens.radiusCardPrimary),
                border: Border.all(
                  color: ext.border.withValues(alpha: 0.68),
                ),
              ),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ext.textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.42,
                          ),
                    ),
                    const SizedBox(height: DesignTokens.space3),
                    for (final d in docs.take(5))
                      _CallLine(
                        doc: d,
                        locals: locals,
                        currentUid: currentUid,
                        agentNames: agentNames,
                        crmCustomerId: customerId,
                      ),
                  ],
                ),
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
    required this.crmCustomerId,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final List<LocalCallRecord> locals;
  final String? currentUid;
  final Map<String, String> agentNames;
  final String crmCustomerId;

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
    final custFromDoc = CrmCallRecordHelpers.customerIdOf(data);
    final linkedCustomerId = (custFromDoc != null && custFromDoc.isNotEmpty)
        ? custFromDoc
        : crmCustomerId;
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
      customerId: linkedCustomerId,
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
    final callable =
        hasDigits && OutboundPhoneDial.isLikelyCallablePhone(rawPhone);
    final rowInsight = CallSurfaceContextualInsight.forFirestoreData(
      data,
      notePreview: quickNote,
      hasCallablePhone: callable,
    );
    final rhythm = CallSurfaceCardRhythmLogic.forFirestore(data);
    final showRail = CallSurfacePriorityMarkers.railForFirestore(data);
    final memoryHint =
        CallCardMemoryHints.forFirestore(data, notePreview: quickNote);
    final cid = linkedCustomerId.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space3),
      child: CrmCallOperatingCard(
        margin: EdgeInsets.zero,
        rhythm: rhythm,
        showPriorityRail: showRail,
        child: CrmCallRecordListItem(
          title: title,
          phoneSubtitle: phoneUnder,
          outcomeLabel: outcome,
          captureLabel: cap,
          contextLine: contextLine,
          notePreview: quickNote,
          technicalFootnote: foot,
          contextualInsight: rowInsight,
          memoryHint: memoryHint,
          onOpenCustomerCard: cid.isNotEmpty
              ? () => context.push('/customer/$cid')
              : null,
          onIdentityTap: callable
              ? () => showCallIdentityQuickActionsSheet(
                    context,
                    rawPhone: rawPhone,
                    customerId: linkedCustomerId,
                    displayLabel: title,
                    firestoreCallDocId: doc.id,
                  )
              : null,
          onIdentityLongPress: callable
              ? () {
                  unawaited(OutboundPhoneDial.launchDial(rawPhone));
                }
              : null,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ext.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(
                color: ext.accent.withValues(alpha: 0.28),
              ),
            ),
            child: Icon(Icons.call_rounded, size: 22, color: ext.accent),
          ),
          trailing: syncIcon,
          padding: const EdgeInsets.all(DesignTokens.space3),
        ),
      ),
    );
  }
}
