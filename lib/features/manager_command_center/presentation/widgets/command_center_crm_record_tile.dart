import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/application/start_crm_outbound_call.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/domain/call_confidence.dart';
import 'package:emlakmaster_mobile/features/calls/domain/local_call_record_firestore_match.dart';
import 'package:emlakmaster_mobile/features/calls/domain/local_call_sync_ui_state.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_card_memory_hints.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_surface_card_rhythm.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_surface_contextual_insight.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/local_call_records_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/crm_call_record_display.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_identity_quick_actions_sheet.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_sync_status_icon.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/crm_call_operating_card.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/crm_call_record_list_item.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

/// Tek CRM çağrı satırı — slidable aksiyonlar ve yerel senkron rozeti.
class CommandCenterCrmRecordTile extends ConsumerWidget {
  const CommandCenterCrmRecordTile({
    super.key,
    required this.doc,
    required this.agentNames,
    required this.locals,
    required this.currentUid,
    required this.customerFullNameById,
    required this.nowMs,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Map<String, String> agentNames;
  final List<LocalCallRecord> locals;
  final String? currentUid;
  final Map<String, String> customerFullNameById;
  final int nowMs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = doc.data();
    final id = doc.id;
    final agentId = CrmCallRecordHelpers.agentIdOf(data);
    final duration = data['durationSec'] as num?;
    final durationStr = duration != null ? '${duration.toInt()} sn' : null;
    final outcomeStr = CrmCallRecordHelpers.outcomeDisplayTrDefault(data);
    final rawPhone = (data['phoneNumber'] ?? data['phone'] ?? '').toString();
    final hasDigits = rawPhone.replaceAll(RegExp(r'\D'), '').isNotEmpty;
    final formattedPhone =
        hasDigits ? CrmCallRecordDisplay.formatPhone(rawPhone) : '—';
    final contactName = CrmCallRecordDisplay.contactNameFromCallData(data);
    final custId = CrmCallRecordHelpers.customerIdOf(data);
    final resolvedCustomerName =
        custId != null ? customerFullNameById[custId]?.trim() : null;
    final title = CrmCallRecordDisplay.primaryTitle(
      customerFullName:
          resolvedCustomerName != null && resolvedCustomerName.isNotEmpty
              ? resolvedCustomerName
              : null,
      contactDisplayName: contactName,
      rawPhone: hasDigits ? rawPhone : null,
    );
    final phoneUnder = CrmCallRecordDisplay.shouldShowPhoneUnderTitle(
      title: title,
      formattedPhone: formattedPhone,
    )
        ? formattedPhone
        : null;
    final createdAt = data['createdAt'];
    String timeStr = '—';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      timeStr =
          '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    final cap = CrmCallRecordHelpers.captureStatusTr(data);
    final shortNote = CrmCallRecordDisplay.notePreviewFromFirestoreData(
      data,
      maxLen: 80,
    );
    final advisorPart = CrmCallRecordDisplay.advisorContext(
      advisorAgentId: agentId,
      currentUid: currentUid,
      agentNames: agentNames,
    );
    final contextLine = CrmCallRecordDisplay.contextLine(
      advisorPart: advisorPart,
      dateTime: timeStr,
      duration: durationStr,
    );
    final foot = CrmCallRecordDisplay.technicalFootnote(
      firestoreDocId: id,
      customerId: custId,
    );
    final localMatch = matchLocalCallRecordForFirestoreDoc(
      locals: locals,
      docId: id,
      data: data,
    );
    Widget? trailing;
    if (localMatch != null) {
      final syncState = deriveLocalCallSyncUiState(localMatch, nowMs: nowMs);
      VoidCallback? onRetry;
      if (syncState == LocalCallSyncUiState.failedPermanent &&
          currentUid != null &&
          currentUid == localMatch.agentId) {
        onRetry = () => unawaited(retryLocalCallRecordSync(localMatch));
      }
      trailing = Tooltip(
        message: 'Aktarım durumu',
        child: CallSyncStatusIcon(
          record: localMatch,
          onManualRetry: onRetry,
        ),
      );
    }
    final ext = AppThemeExtension.of(context);
    final identityHint = (custId == null || custId.isEmpty) &&
            (contactName?.trim().isEmpty ?? true)
        ? 'Yeni kişi · Müşteri kartına bağlı değil'
        : null;
    final callable =
        hasDigits && OutboundPhoneDial.isLikelyCallablePhone(rawPhone);
    final hasCustomerSlide = custId != null && custId.isNotEmpty;
    final rowInsight = CallSurfaceContextualInsight.forFirestoreData(
      data,
      notePreview: shortNote,
      hasCallablePhone: callable,
    );
    final cardRhythm = CallSurfaceCardRhythmLogic.forFirestore(data);
    final showPriorityRail =
        CallSurfacePriorityMarkers.railForFirestore(data);
    final memoryHint =
        CallCardMemoryHints.forFirestore(data, notePreview: shortNote);
    final confidenceKind = CallConfidenceLabels.resolveForRecord(
      startedFromScreen: data['startedFromScreen'] as String?,
      outcome: (data['outcome'] as String?) ?? (data['callOutcome'] as String?),
      quickOutcomeCode: data['quickOutcomeCode'] as String?,
      memoryHint: memoryHint,
    );
    final cidTrim = custId?.trim();

    final card = CrmCallOperatingCard(
      dense: true,
      rhythm: cardRhythm,
      showPriorityRail: showPriorityRail,
      child: CrmCallRecordListItem(
        dense: true,
        title: title,
        phoneSubtitle: phoneUnder,
        outcomeLabel: outcomeStr,
        captureLabel: cap,
        contextLine: contextLine,
        notePreview: shortNote,
        technicalFootnote: foot,
        identityFootnote: identityHint,
        contextualInsight: rowInsight,
        memoryHint: memoryHint,
        confidenceKind: confidenceKind,
        onOpenCustomerCard: cidTrim != null && cidTrim.isNotEmpty
            ? () => context.push('/customer/$cidTrim')
            : null,
        onIdentityTap: callable
            ? () => showCallIdentityQuickActionsSheet(
                  context,
                  rawPhone: rawPhone,
                  customerId: custId,
                  displayLabel: title,
                  firestoreCallDocId: id,
                  onOpenCustomerDirectory: () {
                    AppFeedback.lightImpact();
                    ref
                        .read(mainShellShortcutProvider.notifier)
                        .enqueue(MainShellShortcut.openHomeTab);
                    context.go(AppRouter.routeHome);
                  },
                )
            : null,
        onIdentityLongPress: callable
            ? () {
                AppFeedback.mediumImpact();
                startCrmOutboundCall(
                  context,
                  phone: rawPhone,
                  customerId: custId,
                  startedFromScreen: 'command_center',
                );
              }
            : null,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ext.accent.withValues(alpha: 0.078),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm + 2),
            border: Border.all(
              color: ext.accent.withValues(alpha: 0.20),
            ),
          ),
          child: Icon(Icons.call_rounded, color: ext.accent, size: 18),
        ),
        trailing: trailing,
      ),
    );

    if (!hasCustomerSlide && !callable) return card;
    if (hasCustomerSlide && !callable) {
      return Slidable(
        key: ValueKey('cc_call_$id'),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.22,
          children: [
            SlidableAction(
              onPressed: (_) {
                AppFeedback.mediumImpact();
                context.push('/customer/$custId');
              },
              backgroundColor: ext.accent,
              foregroundColor: Colors.white,
              icon: Icons.person_search_rounded,
              label: 'Kart',
            ),
          ],
        ),
        child: card,
      );
    }
    if (!hasCustomerSlide && callable) {
      return Slidable(
        key: ValueKey('cc_call_$id'),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.2,
          children: [
            SlidableAction(
              onPressed: (_) {
                AppFeedback.mediumImpact();
                startCrmOutboundCall(
                  context,
                  phone: rawPhone,
                  customerId: custId,
                  startedFromScreen: 'command_center',
                );
              },
              backgroundColor: ext.success,
              foregroundColor: Colors.white,
              icon: Icons.call_rounded,
              label: 'Ara',
            ),
          ],
        ),
        child: card,
      );
    }
    return Slidable(
      key: ValueKey('cc_call_$id'),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) {
              AppFeedback.mediumImpact();
              context.push('/customer/$custId');
            },
            backgroundColor: ext.accent,
            foregroundColor: Colors.white,
            icon: Icons.person_search_rounded,
            label: 'Kart',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.2,
        children: [
          SlidableAction(
            onPressed: (_) {
              AppFeedback.mediumImpact();
              startCrmOutboundCall(
                context,
                phone: rawPhone,
                customerId: custId,
                startedFromScreen: 'command_center',
              );
            },
            backgroundColor: ext.success,
            foregroundColor: Colors.white,
            icon: Icons.call_rounded,
            label: 'Ara',
          ),
        ],
      ),
      child: card,
    );
  }
}
