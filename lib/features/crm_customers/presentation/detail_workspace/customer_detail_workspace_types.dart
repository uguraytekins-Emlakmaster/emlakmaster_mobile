// Müşteri detay workspace — yalnızca gerçek CRM alanları ve bağlantılar.
// Uydurma CRM skoru, sahte AI lead skoru veya icat edilmiş zaman çizelgesi YOK.

import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

enum CustomerDetailQuickAction {
  call,
  message,
  whatsapp,
  tasks,
  followUp,
  portfolio,
}

enum CustomerDetailSectionKind {
  basic,
  contact,
  tasksFollowUp,
  lastInteraction,
  portfolio,
  partialNote,
}

class CustomerDetailFieldRow {
  const CustomerDetailFieldRow({
    required this.label,
    required this.value,
    this.isEmpty = false,
  });

  final String label;
  final String value;
  final bool isEmpty;
}

class CustomerDetailLinkedRow {
  const CustomerDetailLinkedRow({
    required this.id,
    required this.title,
    required this.statusLabel,
    this.nextActionLabel = '',
  });

  final String id;
  final String title;
  final String statusLabel;
  final String nextActionLabel;
}

class CustomerDetailListingRow {
  const CustomerDetailListingRow({
    required this.listingId,
    required this.title,
  });

  final String listingId;
  final String title;
}

class CustomerDetailSectionView {
  const CustomerDetailSectionView({
    required this.kind,
    required this.title,
    this.secondary,
    this.fields = const [],
    this.linkedRows = const [],
    this.listings = const [],
    this.note,
  });

  final CustomerDetailSectionKind kind;
  final String title;
  final String? secondary;
  final List<CustomerDetailFieldRow> fields;
  final List<CustomerDetailLinkedRow> linkedRows;
  final List<CustomerDetailListingRow> listings;
  final String? note;
}

class CustomerDetailWorkspaceSummary {
  const CustomerDetailWorkspaceSummary({
    required this.lastContact,
    required this.activeTasks,
    required this.activeFollowUp,
    required this.callRelation,
    required this.isPartial,
    required this.portfolioCount,
  });

  final String lastContact;
  final int activeTasks;
  final int activeFollowUp;
  final int callRelation;
  final bool isPartial;
  final int portfolioCount;

  static const empty = CustomerDetailWorkspaceSummary(
    lastContact: '—',
    activeTasks: 0,
    activeFollowUp: 0,
    callRelation: 0,
    isPartial: false,
    portfolioCount: 0,
  );
}

class CustomerDetailWorkspaceSnapshot {
  const CustomerDetailWorkspaceSnapshot({
    required this.customerId,
    required this.displayName,
    required this.identityLine,
    required this.summary,
    required this.sections,
    required this.coverageNote,
    required this.dateChipLabel,
    required this.isNotFound,
    required this.isPartial,
    required this.partialNote,
    required this.nextActionLabel,
    required this.callablePhone,
    required this.phone,
    required this.portfolioLoading,
    required this.quickActions,
  });

  final String customerId;
  final String displayName;
  final String identityLine;
  final CustomerDetailWorkspaceSummary summary;
  final List<CustomerDetailSectionView> sections;
  final String coverageNote;
  final String dateChipLabel;
  final bool isNotFound;
  final bool isPartial;
  final String partialNote;
  final String nextActionLabel;
  final bool callablePhone;
  final String? phone;
  final bool portfolioLoading;
  final List<CustomerDetailQuickAction> quickActions;
}

/// Provider girdisi — test ve türetme için.
class CustomerDetailWorkspaceInput {
  const CustomerDetailWorkspaceInput({
    required this.customerId,
    this.entity,
    this.openTasks = const [],
    this.matchedListings = const [],
    this.portfolioLoading = false,
    required this.now,
  });

  final String customerId;
  final CustomerEntity? entity;
  final List<CustomerDetailLinkedRow> openTasks;
  final List<CustomerDetailListingRow> matchedListings;
  final bool portfolioLoading;
  final DateTime now;
}
