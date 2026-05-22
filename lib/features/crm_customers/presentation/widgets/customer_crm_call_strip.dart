import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/application/call_record_detail_navigation.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/domain/local_call_record_firestore_match.dart';
import 'package:emlakmaster_mobile/features/calls/domain/local_call_sync_ui_state.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/firestore_agent_display_names_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/local_call_records_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_record_row_summary.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/crm_call_record_display.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_identity_quick_actions_sheet.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_record_premium_tile.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_sync_status_icon.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/crm_call_operating_card.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_feed_providers.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_name_lookup_provider.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Müşteri detay: son CRM görüşmeleri — premium satır, oynatıcı yok.
class CustomerCrmCallStrip extends ConsumerWidget {
  const CustomerCrmCallStrip({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final callsAsync = ref.watch(customerCallsDisplayProvider(customerId));
    return callsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: DesignTokens.space4),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (docs) {
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space4),
            child: PremiumSurfaceCard(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: Text(
                'Bu müşteri için henüz CRM çağrı kaydı yok.',
                style: AppTypography.body(context).copyWith(
                  color: ext.textSecondary,
                ),
              ),
            ),
          );
        }
        final locals =
            ref.watch(localCallRecordsStreamProvider).valueOrNull ?? [];
        final currentUid = ref.watch(currentUserProvider).valueOrNull?.uid;
        final agentNames =
            ref.watch(firestoreAgentDisplayNamesProvider).valueOrNull ??
                const <String, String>{};
        final customerNames = ref.watch(customerNameLookupProvider);

        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Son görüşmeler',
                style: AppTypography.cardHeading(context),
              ),
              const SizedBox(height: DesignTokens.space1),
              Text(
                'Uygulama içi sonuç ve notlar. Kayıt dinleme bu sürümde kapalı.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ext.textSecondary,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: DesignTokens.space3),
              for (final d in docs.take(8))
                _CustomerCallLine(
                  doc: d,
                  locals: locals,
                  currentUid: currentUid,
                  agentNames: agentNames,
                  customerNames: customerNames,
                  customerId: customerId,
                ),
              if (docs.length > 8)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.push(
                      AppRouter.routeCall,
                      extra: {
                        'customerId': customerId,
                        'startedFromScreen': 'customer_detail_calls',
                      },
                    ),
                    child: const Text('Yeni arama başlat'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomerCallLine extends StatelessWidget {
  const _CustomerCallLine({
    required this.doc,
    required this.locals,
    required this.currentUid,
    required this.agentNames,
    required this.customerNames,
    required this.customerId,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final List<LocalCallRecord> locals;
  final String? currentUid;
  final Map<String, String> agentNames;
  final Map<String, String> customerNames;
  final String customerId;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final data = doc.data();
    final id = doc.id;
    final row = CallRecordRowSummary.fromFirestore(doc, customerNames);
    final agentId = CrmCallRecordHelpers.agentIdOf(data);
    final advisorPart = CrmCallRecordDisplay.advisorContext(
      advisorAgentId: agentId,
      currentUid: currentUid,
      agentNames: agentNames,
    );
    final created = CrmCallRecordHelpers.createdAtOf(data);
    final timeStr = created != null
        ? '${created.day}.${created.month}.${created.year} ${created.hour}:${created.minute.toString().padLeft(2, '0')}'
        : null;
    final cap = CrmCallRecordHelpers.captureStatusTr(data);
    final statusLabel =
        cap.trim().isNotEmpty && cap != '—' ? cap : null;
    final metaParts = <String>[
      if (advisorPart.trim().isNotEmpty) advisorPart,
      if (timeStr != null) timeStr,
    ];
    final metaLine = metaParts.isEmpty ? null : metaParts.join(' · ');
    final direction = data['direction'] as String? ??
        data['callDirection'] as String? ??
        '';
    final isIncoming = direction == 'incoming';
    final duration = data['durationSec'] as num?;
    final playLabel =
        CrmCallRecordHelpers.formatDurationMmSs(duration?.toInt());
    final hasDetail = playLabel.isNotEmpty;

    final localMatch = matchLocalCallRecordForFirestoreDoc(
      locals: locals,
      docId: id,
      data: data,
    );
    Widget? trailing;
    if (localMatch != null) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final syncState = deriveLocalCallSyncUiState(localMatch, nowMs: nowMs);
      VoidCallback? onRetry;
      if (syncState == LocalCallSyncUiState.failedPermanent &&
          currentUid != null &&
          currentUid == localMatch.agentId) {
        onRetry = () => unawaited(retryLocalCallRecordSync(localMatch));
      }
      trailing = CallSyncStatusIcon(
        record: localMatch,
        onManualRetry: onRetry,
      );
    }

    final callable =
        OutboundPhoneDial.isLikelyCallablePhone(row.rawPhone);

    void openActions() {
      showCallIdentityQuickActionsSheet(
        context,
        rawPhone: row.rawPhone,
        customerId: customerId,
        displayLabel: row.title,
        firestoreCallDocId: id,
      );
    }

    void onDetailTap() {
      CallRecordDetailNavigation.openSummary(
        context,
        firestoreDocId: id,
        onFallback: openActions,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: CrmCallOperatingCard(
        dense: true,
        child: CallRecordPremiumTile(
          title: row.title,
          directionDuration: row.directionDuration,
          outcomeLabel: row.outcomeLabel,
          statusLabel: statusLabel,
          metaLine: metaLine,
          leadingIcon: isIncoming
              ? Icons.call_received_rounded
              : Icons.call_made_rounded,
          leadingColor: isIncoming ? ext.success : ext.info,
          onMenu: callable ? openActions : null,
          onDetail: hasDetail ? onDetailTap : null,
          playDurationLabel: hasDetail ? playLabel : null,
          trailing: trailing,
          onTap: callable ? openActions : null,
        ),
      ),
    );
  }
}
