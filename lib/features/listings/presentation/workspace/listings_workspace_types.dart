// Portföyüm workspace — yalnızca gerçek ilan kayıtları ve mevcut alanlar.
// Uydurma ilan skoru, sahte görüntülenme veya AI kalite puanı YOK.

import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';

enum ListingsWorkspaceFilter {
  all,
  active,
  missing,
  ready,
  partial,
  attention,
  residential,
  land,
  commercial,
}

extension ListingsWorkspaceFilterLabel on ListingsWorkspaceFilter {
  String get label => switch (this) {
        ListingsWorkspaceFilter.all => 'Tümü',
        ListingsWorkspaceFilter.active => 'Aktif',
        ListingsWorkspaceFilter.missing => 'Eksik',
        ListingsWorkspaceFilter.ready => 'Hazır',
        ListingsWorkspaceFilter.partial => 'Kısmi',
        ListingsWorkspaceFilter.attention => 'Dikkat',
        ListingsWorkspaceFilter.residential => 'Konut',
        ListingsWorkspaceFilter.land => 'Arsa',
        ListingsWorkspaceFilter.commercial => 'İşyeri',
      };
}

enum ListingPropertyCategory {
  residential,
  land,
  commercial,
  unknown,
}

enum ListingWorkspaceTone {
  ready,
  attention,
  missing,
  partial,
  active,
  neutral,
}

class ListingWorkspaceRowView {
  const ListingWorkspaceRowView({
    required this.row,
    required this.title,
    required this.typeLabel,
    required this.priceDisplay,
    required this.locationLine,
    required this.statusLabel,
    required this.contextLine,
    required this.nextActionLabel,
    required this.tone,
    required this.isActive,
    required this.isMissing,
    required this.isReady,
    required this.isPartial,
    required this.needsAttention,
    required this.propertyCategory,
    required this.partialNote,
    required this.canOpenDetail,
    required this.canOpenExternal,
    required this.canShare,
    required this.canSync,
    required this.sortRank,
    required this.searchText,
  });

  final ListingRowView row;
  final String title;
  final String typeLabel;
  final String priceDisplay;
  final String locationLine;
  final String statusLabel;
  final String contextLine;
  final String nextActionLabel;
  final ListingWorkspaceTone tone;

  final bool isActive;
  final bool isMissing;
  final bool isReady;
  final bool isPartial;
  final bool needsAttention;
  final ListingPropertyCategory propertyCategory;
  final String partialNote;

  final bool canOpenDetail;
  final bool canOpenExternal;
  final bool canShare;
  final bool canSync;

  final int sortRank;
  final String searchText;

  String get id => row.id;
}

class ListingsWorkspaceSummary {
  const ListingsWorkspaceSummary({
    required this.active,
    required this.missing,
    required this.ready,
    required this.partial,
    required this.attention,
  });

  final int active;
  final int missing;
  final int ready;
  final int partial;
  final int attention;

  static const empty = ListingsWorkspaceSummary(
    active: 0,
    missing: 0,
    ready: 0,
    partial: 0,
    attention: 0,
  );
}

class ListingsWorkspaceSnapshot {
  const ListingsWorkspaceSnapshot({
    required this.rows,
    required this.incompleteRows,
    required this.readyRows,
    required this.summary,
    required this.coverageNote,
    required this.isEmpty,
    required this.dateChipLabel,
    required this.canManage,
  });

  final List<ListingWorkspaceRowView> rows;
  final List<ListingWorkspaceRowView> incompleteRows;
  final List<ListingWorkspaceRowView> readyRows;
  final ListingsWorkspaceSummary summary;
  final String coverageNote;
  final bool isEmpty;
  final String dateChipLabel;
  final bool canManage;
}
