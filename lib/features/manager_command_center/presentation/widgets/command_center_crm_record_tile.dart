import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/calls/application/start_crm_outbound_call.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/domain/local_call_record_firestore_match.dart';
import 'package:emlakmaster_mobile/features/calls/domain/local_call_sync_ui_state.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/local_call_records_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/crm_call_record_display.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_identity_quick_actions_sheet.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_record_premium_tile.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_sync_status_icon.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/crm_call_operating_card.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final direction = data['direction'] as String? ??
        data['callDirection'] as String? ??
        '';
    final isIncoming = direction == 'incoming';
    final duration = data['durationSec'] as num?;
    final outcomeStr = CrmCallRecordHelpers.outcomeDisplayTrDefault(data);
    final rawPhone = (data['phoneNumber'] ?? data['phone'] ?? '').toString();
    final hasDigits = rawPhone.replaceAll(RegExp(r'\D'), '').isNotEmpty;
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
    final createdAt = data['createdAt'];
    String timeStr = '—';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      timeStr =
          '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    final cap = CrmCallRecordHelpers.captureStatusTr(data);
    final advisorPart = CrmCallRecordDisplay.advisorContext(
      advisorAgentId: agentId,
      currentUid: currentUid,
      agentNames: agentNames,
    );
    final directionDuration = CallRecordPremiumTile.formatDirectionDuration(
      isIncoming: isIncoming,
      durationSec: duration?.toInt(),
    );
    final metaParts = <String>[
      if (advisorPart.trim().isNotEmpty) advisorPart,
      if (timeStr != '—') timeStr,
    ];
    final metaLine = metaParts.isEmpty ? null : metaParts.join(' · ');
    final statusLabel =
        cap.trim().isNotEmpty && cap != '—' ? cap : null;
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
    final callable =
        hasDigits && OutboundPhoneDial.isLikelyCallablePhone(rawPhone);
    final hasCustomerSlide = custId != null && custId.isNotEmpty;

    final playLabel = CrmCallRecordHelpers.formatDurationMmSs(duration?.toInt());
    final recordingUrl = CrmCallRecordHelpers.playableRecordingUrl(data);
    final hasRecording =
        recordingUrl != null && recordingUrl.trim().isNotEmpty;
    final hasPlay = hasRecording;
    final hasDetail =
        !hasPlay && playLabel.isNotEmpty;
    final customerLinkHint =
        (custId == null || custId.isEmpty) ? 'Müşteri kartı yok' : null;

    void openActions() {
      showCallIdentityQuickActionsSheet(
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
      );
    }

    void onPlayTap() {
      unawaited(launchUrl(
        Uri.parse(recordingUrl!.trim()),
        mode: LaunchMode.externalApplication,
      ));
    }

    void onDetailTap() {
      context.push(
        AppRouter.routeCallSummary,
        extra: {'callDocId': id},
      );
    }

    final card = Semantics(
      label: 'Çağrı kaydı: $title',
      button: true,
      child: CrmCallOperatingCard(
        dense: true,
        child: CallRecordPremiumTile(
          title: title,
          directionDuration: directionDuration,
          outcomeLabel: outcomeStr,
          statusLabel: statusLabel,
          metaLine: metaLine,
          leadingIcon: isIncoming
              ? Icons.call_received_rounded
              : Icons.call_made_rounded,
          leadingColor: isIncoming ? ext.success : ext.info,
          customerLinkHint: customerLinkHint,
          onMenu: callable ? openActions : null,
          onPlay: hasPlay ? onPlayTap : null,
          onDetail: hasDetail ? onDetailTap : null,
          playDurationLabel:
              (hasPlay || hasDetail) && playLabel.isNotEmpty ? playLabel : null,
          trailing: trailing,
          onTap: callable ? openActions : null,
        ),
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
