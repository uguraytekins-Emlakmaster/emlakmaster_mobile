import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/domain/quick_call_outcome.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/crm_call_record_display.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_record_premium_tile.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';

/// Izgara / özet satırı için ortak çağrı alanları.
class CallRecordRowSummary {
  const CallRecordRowSummary({
    required this.title,
    required this.directionDuration,
    required this.outcomeLabel,
    required this.rawPhone,
    this.customerId,
    this.firestoreDocId,
  });

  final String title;
  final String directionDuration;
  final String outcomeLabel;
  final String rawPhone;
  final String? customerId;
  final String? firestoreDocId;

  static CallRecordRowSummary fromLocal(
    LocalCallRecord record,
    Map<String, String> customerNames,
  ) {
    final custName = record.customerId != null && record.customerId!.isNotEmpty
        ? customerNames[record.customerId!]
        : null;
    return CallRecordRowSummary(
      title: CrmCallRecordDisplay.primaryTitle(
        customerFullName: custName,
        rawPhone: record.phoneNumber,
      ),
      directionDuration: CallRecordPremiumTile.formatDirectionDuration(
        isIncoming: false,
      ),
      outcomeLabel: QuickCallOutcome.labelTr(record.outcome ?? '—'),
      rawPhone: record.phoneNumber,
      customerId: record.customerId,
      firestoreDocId: record.firestoreDocumentId,
    );
  }

  static CallRecordRowSummary fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, String> customerNames,
  ) {
    final data = doc.data();
    final direction = data['direction'] as String? ??
        data['callDirection'] as String? ??
        '';
    final isIncoming = direction == 'incoming';
    final rawPhone = data['phoneNumber'] as String? ??
        data['phone'] as String? ??
        '';
    final duration = data['durationSec'] as num?;
    final contactName = CrmCallRecordDisplay.contactNameFromCallData(data);
    final customerId = (data['customerId'] as String?)?.trim();
    final customerName =
        customerId != null && customerId.isNotEmpty
            ? customerNames[customerId]
            : null;
    return CallRecordRowSummary(
      title: CrmCallRecordDisplay.primaryTitle(
        customerFullName: customerName,
        contactDisplayName: contactName,
        rawPhone: rawPhone.isEmpty ? null : rawPhone,
      ),
      directionDuration: CallRecordPremiumTile.formatDirectionDuration(
        isIncoming: isIncoming,
        durationSec: duration?.toInt(),
      ),
      outcomeLabel: CrmCallRecordHelpers.outcomeDisplayTrDefault(data),
      rawPhone: rawPhone,
      customerId: customerId,
      firestoreDocId: doc.id,
    );
  }
}
