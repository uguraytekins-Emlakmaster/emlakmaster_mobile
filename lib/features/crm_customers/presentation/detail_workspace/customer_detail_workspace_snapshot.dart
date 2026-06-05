import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/core/utils/last_contact_label.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/customer_detail_workspace_types.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

const _followUpSilentDays = 7;

CustomerDetailWorkspaceSnapshot computeCustomerDetailWorkspaceSnapshot(
  CustomerDetailWorkspaceInput input,
) {
  final entity = input.entity;
  if (entity == null) {
    return CustomerDetailWorkspaceSnapshot(
      customerId: input.customerId,
      displayName: 'Müşteri bulunamadı',
      identityLine: '',
      summary: CustomerDetailWorkspaceSummary.empty,
      sections: const [],
      coverageNote:
          'Kayıt sunucuda bulunamadı veya erişim yok. Uydurma profil verisi gösterilmez.',
      dateChipLabel: '',
      isNotFound: true,
      isPartial: false,
      partialNote: '',
      nextActionLabel: '',
      callablePhone: false,
      phone: null,
      portfolioLoading: false,
      quickActions: const [],
    );
  }

  final name = entity.fullName?.trim().isNotEmpty == true
      ? entity.fullName!.trim()
      : 'İsimsiz müşteri';
  final phone = entity.primaryPhone?.trim() ?? '';
  final email = entity.email?.trim() ?? '';
  final callable =
      phone.isNotEmpty && OutboundPhoneDial.isLikelyCallablePhone(phone);

  final identityLine = callable
      ? phone
      : (email.isNotEmpty ? email : 'İletişim bilgisi eksik');

  final nameMissing = entity.fullName?.trim().isEmpty ?? true;
  final contactMissing = phone.isEmpty && email.isEmpty;
  final isPartial = nameMissing || contactMissing;
  final partialNote = _partialNote(
    nameMissing: nameMissing,
    phoneMissing: phone.isEmpty,
    emailMissing: email.isEmpty,
  );

  final lastContact = LastContactLabel.label(entity.lastInteractionAt);
  final daysSilent = entity.lastInteractionAt != null
      ? input.now.difference(entity.lastInteractionAt!).inDays
      : null;
  final activeFollowUp =
      daysSilent != null && daysSilent >= _followUpSilentDays ? 1 : 0;

  final openTasks = input.openTasks;
  final portfolioCount = input.matchedListings.length;

  final summary = CustomerDetailWorkspaceSummary(
    lastContact: lastContact,
    activeTasks: openTasks.length,
    activeFollowUp: activeFollowUp,
    callRelation: entity.callsCount,
    isPartial: isPartial,
    portfolioCount: portfolioCount,
  );

  final sections = <CustomerDetailSectionView>[
    _basicSection(entity, name),
    if (_hasContactSection(phone, email))
      _contactSection(phone: phone, email: email, callable: callable),
    _tasksFollowUpSection(
      openTasks: openTasks,
      activeFollowUp: activeFollowUp,
      daysSilent: daysSilent,
      nextSuggested: entity.nextSuggestedAction,
    ),
    _lastInteractionSection(entity, lastContact),
    if (input.portfolioLoading || input.matchedListings.isNotEmpty)
      _portfolioSection(
        listings: input.matchedListings,
        loading: input.portfolioLoading,
      ),
    if (isPartial && partialNote.isNotEmpty)
      CustomerDetailSectionView(
        kind: CustomerDetailSectionKind.partialNote,
        title: 'Eksik bilgi',
        note: partialNote,
      ),
  ];

  final nextAction = _nextAction(
    callable: callable,
    openTasks: openTasks.length,
    activeFollowUp: activeFollowUp,
    nextSuggested: entity.nextSuggestedAction,
  );

  final quickActions = <CustomerDetailQuickAction>[
    if (callable) CustomerDetailQuickAction.call,
    if (callable) CustomerDetailQuickAction.message,
    if (callable) CustomerDetailQuickAction.whatsapp,
    CustomerDetailQuickAction.tasks,
    if (activeFollowUp > 0) CustomerDetailQuickAction.followUp,
    CustomerDetailQuickAction.portfolio,
  ];

  final dateChipLabel = activeFollowUp > 0 || openTasks.isNotEmpty
      ? '${input.now.day.toString().padLeft(2, '0')}.${input.now.month.toString().padLeft(2, '0')}.${input.now.year}'
      : '';

  return CustomerDetailWorkspaceSnapshot(
    customerId: input.customerId,
    displayName: name,
    identityLine: identityLine,
    summary: summary,
    sections: sections,
    coverageNote:
        'Özet yalnızca gerçek müşteri kaydı, açık görevler ve son temas '
        'alanlarından türetilir. Portföy eşleşmeleri varsa yalnızca ilan '
        'başlıkları gösterilir — uydurma CRM skoru, AI lead skoru veya '
        'icat edilmiş zaman çizelgesi yok.',
    dateChipLabel: dateChipLabel,
    isNotFound: false,
    isPartial: isPartial,
    partialNote: partialNote,
    nextActionLabel: nextAction,
    callablePhone: callable,
    phone: callable ? phone : null,
    portfolioLoading: input.portfolioLoading,
    quickActions: quickActions,
  );
}

bool _hasContactSection(String phone, String email) =>
    phone.isNotEmpty || email.isNotEmpty;

CustomerDetailSectionView _basicSection(CustomerEntity entity, String name) {
  final fields = <CustomerDetailFieldRow>[
    CustomerDetailFieldRow(label: 'Ad', value: name),
    if (entity.customerType != null)
      CustomerDetailFieldRow(
        label: 'Tür',
        value: entity.customerType!.label,
      ),
    if (entity.source?.trim().isNotEmpty == true)
      CustomerDetailFieldRow(label: 'Kaynak', value: entity.source!.trim()),
    if (entity.lifecycleStage != null)
      CustomerDetailFieldRow(
        label: 'Aşama',
        value: entity.lifecycleStage!.label,
      ),
    if (entity.regionPreferences.isNotEmpty)
      CustomerDetailFieldRow(
        label: 'Bölge',
        value: entity.regionPreferences.join(' · '),
      ),
  ];
  return CustomerDetailSectionView(
    kind: CustomerDetailSectionKind.basic,
    title: 'Temel bilgi',
    fields: fields,
  );
}

CustomerDetailSectionView _contactSection({
  required String phone,
  required String email,
  required bool callable,
}) {
  return CustomerDetailSectionView(
    kind: CustomerDetailSectionKind.contact,
    title: 'İletişim',
    fields: [
      if (phone.isNotEmpty)
        CustomerDetailFieldRow(
          label: 'Telefon',
          value: phone,
          isEmpty: !callable,
        ),
      if (email.isNotEmpty)
        CustomerDetailFieldRow(label: 'E-posta', value: email),
    ],
  );
}

CustomerDetailSectionView _tasksFollowUpSection({
  required List<CustomerDetailLinkedRow> openTasks,
  required int activeFollowUp,
  required int? daysSilent,
  required String? nextSuggested,
}) {
  final fields = <CustomerDetailFieldRow>[];
  if (activeFollowUp > 0) {
    fields.add(
      CustomerDetailFieldRow(
        label: 'Takip',
        value: daysSilent != null
            ? '$daysSilent gündür kayıtlı temas yok'
            : 'Temas gerekli',
      ),
    );
  }
  if ((nextSuggested ?? '').trim().isNotEmpty) {
    fields.add(
      CustomerDetailFieldRow(
        label: 'Önerilen',
        value: nextSuggested!.trim(),
      ),
    );
  }
  return CustomerDetailSectionView(
    kind: CustomerDetailSectionKind.tasksFollowUp,
    title: 'Görev & takip',
    secondary: openTasks.isNotEmpty ? '${openTasks.length} açık' : null,
    fields: fields,
    linkedRows: openTasks.take(5).toList(growable: false),
  );
}

CustomerDetailSectionView _lastInteractionSection(
  CustomerEntity entity,
  String lastContact,
) {
  final fields = <CustomerDetailFieldRow>[
    CustomerDetailFieldRow(label: 'Son temas', value: lastContact),
  ];
  final summary = entity.lastCallSummary?.trim();
  if (summary != null && summary.isNotEmpty) {
    final line =
        summary.length > 120 ? '${summary.substring(0, 117)}…' : summary;
    fields.add(CustomerDetailFieldRow(label: 'Son görüşme', value: line));
  }
  if (entity.callsCount > 0) {
    fields.add(
      CustomerDetailFieldRow(
        label: 'Çağrı kaydı',
        value: '${entity.callsCount} kayıtlı çağrı',
      ),
    );
  }
  return CustomerDetailSectionView(
    kind: CustomerDetailSectionKind.lastInteraction,
    title: 'Son etkileşim',
    fields: fields,
  );
}

CustomerDetailSectionView _portfolioSection({
  required List<CustomerDetailListingRow> listings,
  required bool loading,
}) {
  return CustomerDetailSectionView(
    kind: CustomerDetailSectionKind.portfolio,
    title: 'İlgili portföy',
    secondary: loading
        ? 'yükleniyor…'
        : (listings.isNotEmpty ? '${listings.length} ilan' : null),
    listings: listings.take(4).toList(growable: false),
    note: listings.isEmpty && !loading
        ? 'Bu müşteri için kayıtlı portföy eşleşmesi yok.'
        : (listings.isNotEmpty
            ? 'Yalnızca ilan başlıkları gösterilir; skor veya AI yorumu yok.'
            : null),
  );
}

String _partialNote({
  required bool nameMissing,
  required bool phoneMissing,
  required bool emailMissing,
}) {
  final missing = <String>[];
  if (nameMissing) missing.add('ad');
  if (phoneMissing) missing.add('telefon');
  if (emailMissing) missing.add('e-posta');
  if (missing.isEmpty) return '';
  return 'Eksik: ${missing.join(' · ')}';
}

String _nextAction({
  required bool callable,
  required int openTasks,
  required int activeFollowUp,
  required String? nextSuggested,
}) {
  if ((nextSuggested ?? '').trim().isNotEmpty) return nextSuggested!.trim();
  if (openTasks > 0) return 'Açık görevi tamamla';
  if (activeFollowUp > 0 && callable) return 'Takip için ara veya mesaj gönder';
  if (callable) return 'Müşteriyi ara';
  return 'İletişim bilgisini tamamla';
}
