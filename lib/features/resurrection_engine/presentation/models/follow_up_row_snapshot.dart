import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/utils/follow_up_list_filter.dart';

/// Takip satırı görünüm modeli — yalnızca gerçek kuyruk alanları.
class FollowUpRowSnapshot {
  const FollowUpRowSnapshot({
    required this.displayName,
    required this.phoneLine,
    required this.lastInteractionLine,
    required this.followUpReason,
    required this.urgencyLabel,
    required this.heatChipLabel,
    required this.staleAgeLine,
    required this.showCallbackTag,
    required this.showNoPhoneTag,
    required this.linkedStateLabel,
    required this.metaLine,
    required this.emphasizeUrgent,
    required this.canCall,
    required this.canWhatsApp,
    required this.canOpenCustomer,
    required this.canCreateTask,
    required this.canSnooze,
  });

  final String displayName;
  final String phoneLine;
  final String lastInteractionLine;
  final String followUpReason;
  final String urgencyLabel;
  final String? heatChipLabel;
  final String staleAgeLine;
  final bool showCallbackTag;
  final bool showNoPhoneTag;
  final String linkedStateLabel;
  final String metaLine;
  final bool emphasizeUrgent;
  final bool canCall;
  final bool canWhatsApp;
  final bool canOpenCustomer;
  final bool canCreateTask;
  final bool canSnooze;

  factory FollowUpRowSnapshot.fromItem(ResurrectionQueueItem item) {
    final days = item.daysSilent ?? 0;
    final name = (item.customerName?.trim().isNotEmpty == true)
        ? item.customerName!.trim()
        : item.customerId;
    final phone = item.primaryPhone?.trim() ?? '';
    final hasPhone = item.hasCallablePhone;

    final lastLine = item.lastInteractionAt != null
        ? _relativeLastTouch(item.lastInteractionAt!)
        : '$days gün sessiz';

    final action = item.nextSuggestedAction?.trim();
    final followUpReason = (action != null && action.isNotEmpty)
        ? action
        : (item.segment?.label ?? '$days gün sessiz');

    final heatLabel =
        item.heatLevel != null ? heatLevelLabelTr(item.heatLevel!) : null;

    final heatScore = item.heatScore;
    final summaryBit = item.lastCallSummary?.trim();
    final metaParts = <String>[
      if (heatScore != null && heatLabel != null) '$heatLabel · $heatScore',
      if (summaryBit != null && summaryBit.isNotEmpty)
        summaryBit.length > 48 ? '${summaryBit.substring(0, 45)}…' : summaryBit,
      'CRM bağlı',
    ];

    return FollowUpRowSnapshot(
      displayName: name,
      phoneLine: hasPhone ? phone : 'Telefon yok',
      lastInteractionLine: lastLine,
      followUpReason: followUpReason,
      urgencyLabel: _urgencyFromDays(days),
      heatChipLabel: heatLabel,
      staleAgeLine: '$days gün sessiz',
      showCallbackTag: hasPhone,
      showNoPhoneTag: !hasPhone,
      linkedStateLabel: 'Müşteri kaydı',
      metaLine: metaParts.where((e) => e.isNotEmpty).join(' · '),
      emphasizeUrgent: followUpRowNeedsUrgentEmphasis(item),
      canCall: hasPhone,
      canWhatsApp: hasPhone,
      canOpenCustomer: true,
      canCreateTask: true,
      canSnooze: true,
    );
  }
}

String _relativeLastTouch(DateTime at) {
  final days = DateTime.now().difference(at).inDays;
  if (days <= 0) return 'Son temas: bugün';
  if (days == 1) return 'Son temas: dün';
  return 'Son temas: $days gün önce';
}

String _urgencyFromDays(int days) {
  if (days >= 30) return '30+ gün';
  if (days >= 14) return '14+ gün';
  return '7 gün';
}
