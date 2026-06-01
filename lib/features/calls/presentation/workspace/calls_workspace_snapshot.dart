import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/core/utils/last_contact_label.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/crm_call_record_display.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_record_premium_tile.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/workspace/calls_workspace_types.dart';

/// Saf/test edilebilir türetme — tüm gösterim metni önceden hesaplanır.
CallsWorkspaceSnapshot computeCallsWorkspaceSnapshot(
  List<CallWorkspaceInput> inputs, {
  required DateTime now,
}) {
  final rows = <CallRowView>[];
  final startOfToday = DateTime(now.year, now.month, now.day);

  for (final c in inputs) {
    final title = CrmCallRecordDisplay.primaryTitle(
      customerFullName: c.customerFullName,
      contactDisplayName: c.contactDisplayName,
      rawPhone: c.rawPhone.isEmpty ? null : c.rawPhone,
    );
    final formattedPhone = c.rawPhone.isNotEmpty
        ? CrmCallRecordDisplay.formatPhone(c.rawPhone)
        : '—';
    final showPhone = CrmCallRecordDisplay.shouldShowPhoneUnderTitle(
      title: title,
      formattedPhone: formattedPhone,
    );
    final phoneLine = showPhone ? formattedPhone : '';

    final directionDuration = CallRecordPremiumTile.formatDirectionDuration(
      isIncoming: c.isIncoming,
      durationSec: c.durationSec,
    );

    final isToday = !c.createdAt.isBefore(startOfToday);
    final oc = (c.outcomeCode ?? '').trim().toLowerCase();
    final isUnanswered = oc == 'missed' ||
        oc == 'no_answer' ||
        oc == 'busy' ||
        oc == 'failed' ||
        oc == 'cevapsiz';
    final needsCallback = oc == 'callback_scheduled' ||
        c.isHandoffPending ||
        !c.hasCaptureCompleted ||
        c.isLocalDraft;
    final isMatched =
        c.customerId != null && c.customerId!.trim().isNotEmpty;
    final isPartial = _isPartialRecord(c);
    final partialNote = _partialNote(c, isPartial: isPartial);

    final contextLine = _contextLine(c);
    final nextAction = _nextActionLabel(c, needsCallback: needsCallback);

    final timestampLabel = LastContactLabel.label(c.createdAt);
    final timestampColorType = LastContactLabel.colorType(c.createdAt);

    final callable = c.rawPhone.isNotEmpty &&
        OutboundPhoneDial.isLikelyCallablePhone(c.rawPhone);

    rows.add(
      CallRowView(
        recordKey: c.recordKey,
        firestoreDocId: c.firestoreDocId,
        title: title,
        phoneLine: phoneLine,
        directionDuration: directionDuration,
        outcomeLabel: c.outcomeLabel,
        timestampLabel: timestampLabel,
        timestampColorType: timestampColorType,
        contextLine: contextLine,
        nextActionLabel: nextAction,
        tone: _toneFor(
          needsCallback: needsCallback,
          isUnanswered: isUnanswered,
          isMatched: isMatched,
          isPartial: isPartial,
          isLocalDraft: c.isLocalDraft,
        ),
        isToday: isToday,
        needsCallback: needsCallback,
        isMatched: isMatched,
        isPartial: isPartial,
        isUnanswered: isUnanswered,
        isOutgoing: !c.isIncoming,
        isIncoming: c.isIncoming,
        isLocalDraft: c.isLocalDraft,
        partialNote: partialNote,
        customerId: c.customerId,
        rawPhone: c.rawPhone,
        callablePhone: callable,
        sortRank: _sortRank(
          needsCallback: needsCallback,
          isUnanswered: isUnanswered,
          isPartial: isPartial,
          isLocalDraft: c.isLocalDraft,
        ),
        searchText:
            '$title $formattedPhone ${c.outcomeLabel} ${c.notes ?? ''}'
                .toLowerCase(),
        createdAtMs: c.createdAt.millisecondsSinceEpoch,
      ),
    );
  }

  rows.sort((a, b) {
    final r = a.sortRank.compareTo(b.sortRank);
    if (r != 0) return r;
    return b.createdAtMs.compareTo(a.createdAtMs);
  });

  final attentionRows = rows.where((r) => r.needsCallback).toList(growable: false);

  final summary = CallsWorkspaceSummary(
    today: rows.where((r) => r.isToday).length,
    callback: attentionRows.length,
    matched: rows.where((r) => r.isMatched).length,
    partial: rows.where((r) => r.isPartial).length,
    unanswered: rows.where((r) => r.isUnanswered).length,
  );

  final dateChipLabel = summary.today > 0
      ? '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}'
      : '';

  return CallsWorkspaceSnapshot(
    rows: rows,
    attentionRows: attentionRows,
    summary: summary,
    coverageNote:
        'Liste yalnızca CRM kayıtları ve bu cihazdaki bekleyen taslakları '
        'gösterir. iOS’ta sistem arama günlüğü okunamaz; yalnızca uygulama '
        'içi görüşmeler listelenir. Android’de telefon geçmişi içe aktarımı '
        'isteğe bağlıdır. Cevapsız/kaçan yalnızca kayıtlı sonuç kodlarından '
        'gösterilir; uydurma KPI veya AI skoru yok.',
    isEmpty: rows.isEmpty,
    dateChipLabel: dateChipLabel,
  );
}

bool _isPartialRecord(CallWorkspaceInput c) {
  if (c.isLocalDraft && !c.hasCaptureCompleted) return true;
  if (c.isHandoffPending) return true;
  final oc = (c.outcomeCode ?? '').trim();
  if (oc.isEmpty && !c.isLocalDraft) return true;
  final hasCustomer =
      c.customerId != null && c.customerId!.trim().isNotEmpty;
  final hasContact = (c.contactDisplayName ?? '').trim().isNotEmpty ||
      (c.customerFullName ?? '').trim().isNotEmpty;
  if (!hasCustomer && !hasContact) return true;
  return false;
}

String _partialNote(CallWorkspaceInput c, {required bool isPartial}) {
  if (!isPartial) return '';
  final missing = <String>[];
  if (c.customerId == null || c.customerId!.trim().isEmpty) {
    missing.add('müşteri eşleşmesi');
  }
  if ((c.outcomeCode ?? '').trim().isEmpty) missing.add('sonuç');
  if (c.isLocalDraft && !c.hasCaptureCompleted) missing.add('senkron');
  if (c.isHandoffPending) missing.add('sonuç bekleniyor');
  if (missing.isEmpty) return 'Kısmi kayıt';
  return 'Eksik: ${missing.join(' · ')}';
}

String _contextLine(CallWorkspaceInput c) {
  final notes = (c.notes ?? '').trim();
  if (notes.isNotEmpty) return notes;
  if (c.isLocalDraft && !c.hasCaptureCompleted) {
    return 'Cihaz taslağı — senkron bekliyor';
  }
  if (c.isHandoffPending) return 'Telefon devret — sonuç bekleniyor';
  if (c.sourceKind == 'local') return 'Yerel kayıt';
  if (c.hasCaptureCompleted) return 'Kayıt tamamlandı';
  if (c.isHandoffPending) return 'Sonuç bekleniyor';
  return 'Kayıt süreci';
}

String _nextActionLabel(CallWorkspaceInput c, {required bool needsCallback}) {
  final oc = (c.outcomeCode ?? '').trim();
  if (oc == 'callback_scheduled') return 'Tekrar ara';
  if (c.isHandoffPending) return 'Sonucu tamamla';
  if (c.isLocalDraft && !c.hasCaptureCompleted) return 'Kaydı tamamla';
  if (needsCallback) return 'Geri dön';
  if (c.customerId != null && c.customerId!.trim().isNotEmpty) {
    return 'Müşteriye git';
  }
  return '';
}

int _sortRank({
  required bool needsCallback,
  required bool isUnanswered,
  required bool isPartial,
  required bool isLocalDraft,
}) {
  if (needsCallback && isUnanswered) return 0;
  if (needsCallback) return 1;
  if (isUnanswered) return 2;
  if (isPartial || isLocalDraft) return 3;
  return 4;
}

CallTone _toneFor({
  required bool needsCallback,
  required bool isUnanswered,
  required bool isMatched,
  required bool isPartial,
  required bool isLocalDraft,
}) {
  if (needsCallback) return CallTone.callback;
  if (isUnanswered) return CallTone.missed;
  if (isLocalDraft) return CallTone.local;
  if (isPartial) return CallTone.partial;
  if (isMatched) return CallTone.matched;
  return CallTone.neutral;
}
