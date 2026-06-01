import 'package:emlakmaster_mobile/core/utils/last_contact_label.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/workspace/customer_workspace_types.dart';

/// ≥ bu kadar gün kayıtlı aktivite yoksa "Temas gerekli" (durağan temas) sayılır.
const int _staleContactDays = 14;

/// Son [_freshDays] günde oluşturulan kayıt "Yeni" sayılır.
const int _freshDays = 7;

/// Saf/test edilebilir türetme. Tüm gösterim metni önceden hesaplanır; yalnızca
/// gerçek sinyaller kullanılır (kural tabanlı sıcaklık, gerçek tarih, kayıt
/// bütünlüğü). [now] testler için enjekte edilir — determinizm.
CustomerWorkspaceSnapshot computeCustomerWorkspaceSnapshot(
  List<CustomerWorkspaceInput> inputs, {
  required DateTime now,
}) {
  final rows = <CustomerRowView>[];

  for (final c in inputs) {
    final name = (c.name ?? '').trim();
    final phone = (c.phone ?? '').trim();
    final email = (c.email ?? '').trim();
    final hasPhone = phone.isNotEmpty;
    final hasEmail = email.isNotEmpty;

    final displayName = name.isNotEmpty ? name : 'İsimsiz kayıt';
    final initialSource = name.isNotEmpty
        ? name
        : (phone.isNotEmpty ? phone : (email.isNotEmpty ? email : '?'));
    final initial = initialSource.isNotEmpty
        ? initialSource.substring(0, 1).toUpperCase()
        : '?';

    final contactLine = hasPhone
        ? phone
        : (hasEmail ? email : 'İletişim bilgisi eksik');

    // Kayıtlı aktivite zamanı (gerçek son etkileşim; yoksa kayıt güncellemesi).
    final activityAt = c.lastInteractionAt ?? c.updatedAt;
    final lastContactLabel = LastContactLabel.label(c.lastInteractionAt);
    final lastContactColorType =
        LastContactLabel.colorType(c.lastInteractionAt);

    final daysSinceActivity = now.difference(activityAt).inDays;
    final daysSinceCreated = now.difference(c.createdAt).inDays;

    final isHot = c.heatLevel == CustomerHeatLevel.hot;
    final isWarm = c.heatLevel == CustomerHeatLevel.warm;
    final isCold = c.heatLevel == CustomerHeatLevel.cool ||
        c.heatLevel == CustomerHeatLevel.cold;
    final isToday = _isSameDay(activityAt, now);
    final isFresh = daysSinceCreated >= 0 && daysSinceCreated < _freshDays;
    final needsContact = daysSinceActivity >= _staleContactDays;

    // Eksik kayıt: ad yok VEYA hiç iletişim yolu yok.
    final isPartial = name.isEmpty || (!hasPhone && !hasEmail);
    final partialNote = _partialNote(
      nameMissing: name.isEmpty,
      hasPhone: hasPhone,
      hasEmail: hasEmail,
    );

    final nextAction = (c.nextSuggestedAction ?? '').trim();
    final contextLine = nextAction.isNotEmpty
        ? nextAction
        : (c.heatReason.isNotEmpty ? c.heatReason : 'Sıcaklık: ${c.heatScore}');

    rows.add(
      CustomerRowView(
        id: c.id,
        name: displayName,
        initial: initial,
        contactLine: contactLine,
        heatLevel: c.heatLevel,
        heatLabel: heatLevelLabelTr(c.heatLevel),
        heatScore: c.heatScore,
        heatReason: c.heatReason,
        lastContactLabel: lastContactLabel,
        lastContactColorType: lastContactColorType,
        contextLine: contextLine,
        nextActionLabel: nextAction,
        tone: _toneFor(
          heat: c.heatLevel,
          needsContact: needsContact,
          isPartial: isPartial,
        ),
        isHot: isHot,
        isWarm: isWarm,
        isCold: isCold,
        isToday: isToday,
        isFresh: isFresh,
        needsContact: needsContact,
        isPartial: isPartial,
        partialNote: partialNote,
        callablePhone: c.callablePhone,
        phone: c.callablePhone ? phone : null,
        hasPhone: hasPhone,
        hasEmail: hasEmail,
        syncRisk: c.syncRisk,
        isDemo: c.isDemo,
        sortRank: _sortRank(
          syncRisk: c.syncRisk,
          isHot: isHot,
          needsContact: needsContact,
          isWarm: isWarm,
        ),
        searchText:
            '$displayName $phone $email ${c.heatReason}'.toLowerCase(),
      ),
    );
  }

  // Dikkat-önce sıralama: sortRank artan, eşitlikte daha güncel aktivite üstte.
  final indexed = <(int, CustomerRowView)>[
    for (var i = 0; i < rows.length; i++) (i, rows[i]),
  ];
  indexed.sort((a, b) {
    final r = a.$2.sortRank.compareTo(b.$2.sortRank);
    if (r != 0) return r;
    // Stabil: orijinal sıra (sağlayıcı zaten güncellik/sync-risk sıralı).
    return a.$1.compareTo(b.$1);
  });
  final sorted = [for (final e in indexed) e.$2];

  final summary = CustomerWorkspaceSummary(
    active: rows.length,
    hot: rows.where((r) => r.isHot).length,
    needsContact: rows.where((r) => r.needsContact).length,
    partial: rows.where((r) => r.isPartial).length,
    today: rows.where((r) => r.isToday).length,
  );

  return CustomerWorkspaceSnapshot(
    rows: sorted,
    summary: summary,
    coverageNote:
        'Sıcaklık kural tabanlı (deterministik, yapay zekâ değil) hesaplanır; '
        'son temas gerçek kayıt aktivitesini yansıtır. SLA/“geciken” alanı '
        'sunucuda tutulmaz — “Temas gerekli”, $_staleContactDays+ gündür aktivite '
        'olmayan kayıtların dürüst göstergesidir. Uydurma skor veya eşleşme yok.',
    isEmpty: rows.isEmpty,
  );
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int _sortRank({
  required bool syncRisk,
  required bool isHot,
  required bool needsContact,
  required bool isWarm,
}) {
  if (syncRisk) return 0;
  if (isHot) return 1;
  if (needsContact) return 2;
  if (isWarm) return 3;
  return 4;
}

CustomerTone _toneFor({
  required CustomerHeatLevel heat,
  required bool needsContact,
  required bool isPartial,
}) {
  return switch (heat) {
    CustomerHeatLevel.hot => CustomerTone.hot,
    CustomerHeatLevel.warm => CustomerTone.warm,
    CustomerHeatLevel.cool =>
      needsContact ? CustomerTone.attention : CustomerTone.cool,
    CustomerHeatLevel.cold =>
      needsContact ? CustomerTone.attention : CustomerTone.cold,
  };
}

String _partialNote({
  required bool nameMissing,
  required bool hasPhone,
  required bool hasEmail,
}) {
  final missing = <String>[];
  if (nameMissing) missing.add('ad');
  if (!hasPhone) missing.add('telefon');
  if (!hasEmail) missing.add('e-posta');
  if (missing.isEmpty) return '';
  return 'Eksik: ${missing.join(' · ')}';
}
