import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/domain/entities/resurrection_segment.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/workspace/follow_up_workspace_types.dart';

FollowUpWorkspaceSnapshot computeFollowUpWorkspaceSnapshot(
  List<ResurrectionQueueItem> items, {
  required DateTime now,
}) {
  final rows = <FollowUpRowView>[];

  for (final item in items) {
    final days = item.daysSilent ?? 0;
    final name = (item.customerName?.trim().isNotEmpty == true)
        ? item.customerName!.trim()
        : item.customerId;
    final phone = item.primaryPhone?.trim() ?? '';
    final callable = phone.isNotEmpty &&
        OutboundPhoneDial.isLikelyCallablePhone(phone);

    final isOverdue = days >= 14;
    final isToday = item.segment == ResurrectionSegment.silent7;
    final isHot = item.heatLevel == CustomerHeatLevel.hot ||
        item.heatLevel == CustomerHeatLevel.warm;
    final isPartial = name == item.customerId ||
        !callable ||
        ((item.nextSuggestedAction ?? '').trim().isEmpty &&
            (item.lastCallSummary ?? '').trim().isEmpty);
    final isMatched =
        item.customerId.trim().isNotEmpty && item.customerName != null;
    final isPriority = isOverdue || isToday || isHot;
    final quickResolvable = isToday && callable;

    final statusLabel = _statusLabel(item, days);
    final lastContact = item.lastInteractionAt != null
        ? _relativeLastTouch(item.lastInteractionAt!, now)
        : '$days gün sessiz';
    final contextLine = _contextLine(item, days);
    final nextAction = _nextAction(item, isOverdue: isOverdue, isToday: isToday);

    rows.add(
      FollowUpRowView(
        customerId: item.customerId,
        item: item,
        displayName: name,
        phoneLine: callable ? phone : 'Telefon yok',
        statusLabel: statusLabel,
        lastContactLabel: lastContact,
        contextLine: contextLine,
        nextActionLabel: nextAction,
        tone: _toneFor(
          isOverdue: isOverdue,
          isToday: isToday,
          isHot: isHot,
          isPartial: isPartial,
        ),
        isOverdue: isOverdue,
        isToday: isToday,
        isActive: true,
        isPartial: isPartial,
        isMatched: isMatched,
        isPriority: isPriority,
        quickResolvable: quickResolvable,
        partialNote: _partialNote(
          nameMissing: item.customerName?.trim().isEmpty ?? true,
          noPhone: !callable,
          thinContext: (item.nextSuggestedAction ?? '').trim().isEmpty &&
              (item.lastCallSummary ?? '').trim().isEmpty,
        ),
        callablePhone: callable,
        sortRank: _sortRank(
          isOverdue: isOverdue,
          isToday: isToday,
          isHot: isHot,
          isPartial: isPartial,
        ),
        searchText:
            '$name $phone ${item.lastCallSummary ?? ''} ${item.nextSuggestedAction ?? ''} ${item.segment?.label ?? ''}'
                .toLowerCase(),
      ),
    );
  }

  rows.sort((a, b) {
    final r = a.sortRank.compareTo(b.sortRank);
    if (r != 0) return r;
    return (b.item.daysSilent ?? 0).compareTo(a.item.daysSilent ?? 0);
  });

  final overdueRows =
      rows.where((r) => r.isOverdue).toList(growable: false);
  final quickCloseRows =
      rows.where((r) => r.quickResolvable).toList(growable: false);

  final summary = FollowUpWorkspaceSummary(
    active: rows.length,
    overdue: rows.where((r) => r.isOverdue).length,
    today: rows.where((r) => r.isToday).length,
    matched: rows.where((r) => r.isMatched).length,
    partial: rows.where((r) => r.isPartial).length,
  );

  final dateChipLabel = summary.today > 0 || summary.overdue > 0
      ? '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}'
      : '';

  return FollowUpWorkspaceSnapshot(
    rows: rows,
    overdueRows: overdueRows,
    quickCloseRows: quickCloseRows,
    summary: summary,
    coverageNote:
        'Liste yalnızca ≥7 gündür kayıtlı teması olmayan müşterileri gösterir '
        '(gerçek son etkileşim). Öncelik kural tabanlıdır (geciken, 7 gün bandı, '
        'sıcaklık); sunucuda ayrı “tamamlandı” alanı yok — kapanış görev kaydı ile '
        'işaretlenir. Uydurma takip skoru veya AI aciliyeti yok.',
    isEmpty: rows.isEmpty,
    dateChipLabel: dateChipLabel,
  );
}

String _statusLabel(ResurrectionQueueItem item, int days) {
  final seg = item.segment?.label;
  if (seg != null && seg.isNotEmpty) return seg;
  if (days >= 30) return '30+ gün sessiz';
  if (days >= 14) return '14+ gün sessiz';
  return '7 gün sessiz';
}

String _relativeLastTouch(DateTime at, DateTime now) {
  final days = now.difference(at).inDays;
  if (days <= 0) return 'Son temas: bugün';
  if (days == 1) return 'Son temas: dün';
  return 'Son temas: $days gün önce';
}

String _contextLine(ResurrectionQueueItem item, int days) {
  final action = item.nextSuggestedAction?.trim();
  if (action != null && action.isNotEmpty) return action;
  final summary = item.lastCallSummary?.trim();
  if (summary != null && summary.isNotEmpty) {
    return summary.length > 56 ? '${summary.substring(0, 53)}…' : summary;
  }
  return '$days gündür kayıtlı temas yok';
}

String _nextAction(
  ResurrectionQueueItem item, {
  required bool isOverdue,
  required bool isToday,
}) {
  if (isOverdue) return 'Önce ara veya mesaj gönder';
  if (isToday) return 'Bugün temas kur';
  if (item.hasCallablePhone) return 'Müşteriye git';
  return 'Kayıt tamamla';
}

String _partialNote({
  required bool nameMissing,
  required bool noPhone,
  required bool thinContext,
}) {
  final missing = <String>[];
  if (nameMissing) missing.add('ad');
  if (noPhone) missing.add('telefon');
  if (thinContext) missing.add('bağlam');
  if (missing.isEmpty) return '';
  return 'Eksik: ${missing.join(' · ')}';
}

int _sortRank({
  required bool isOverdue,
  required bool isToday,
  required bool isHot,
  required bool isPartial,
}) {
  if (isOverdue && isHot) return 0;
  if (isOverdue) return 1;
  if (isToday) return 2;
  if (isHot) return 3;
  if (isPartial) return 4;
  return 5;
}

FollowUpTone _toneFor({
  required bool isOverdue,
  required bool isToday,
  required bool isHot,
  required bool isPartial,
}) {
  if (isOverdue) return FollowUpTone.overdue;
  if (isToday) return FollowUpTone.today;
  if (isHot) return FollowUpTone.hot;
  if (isPartial) return FollowUpTone.partial;
  return FollowUpTone.neutral;
}
