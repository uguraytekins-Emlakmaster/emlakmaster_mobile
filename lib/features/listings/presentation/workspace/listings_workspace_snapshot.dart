import 'package:emlakmaster_mobile/features/listings/data/listing_row_factory.dart';
import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/models/listing_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/utils/listing_list_filter.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_types.dart';

ListingsWorkspaceSnapshot computeListingsWorkspaceSnapshot(
  List<ListingRowView> source, {
  required DateTime now,
  required bool canManage,
}) {
  final owned =
      source.where((r) => r.surface == ListingSurface.owned).toList();
  final rows = <ListingWorkspaceRowView>[];

  for (final row in owned) {
    final snap = ListingListRowSnapshot.fromRow(row);
    final title = row.title.trim().isNotEmpty ? row.title.trim() : 'İsimsız ilan';
    final titleOk = row.title.trim().length >= 3;
    final priceOk = _priceOk(row.priceLabel);
    final locOk = _locationOk(row.locationLabel);
    final imageOk =
        row.imageUrl != null && row.imageUrl!.trim().isNotEmpty;

    final isMissing = !titleOk || !priceOk || !locOk;
    final isPartial =
        !isMissing && (!priceOk || !locOk || !imageOk || row.title.trim().length < 8);
    final needsAttention = listingRowNeedsAttention(row);
    final isActive = listingRowIsActive(row);
    final isReady = !isMissing &&
        !needsAttention &&
        listingRowIsPublished(row) &&
        row.syncStatus == ListingSyncStatus.synced;

    final category = _propertyCategory(row);
    final typeLabel = _typeLabel(row);
    final partialNote = _partialNote(
      titleOk: titleOk,
      priceOk: priceOk,
      locOk: locOk,
      imageOk: imageOk,
    );

    final contextLine = snap.metaLine.isNotEmpty
        ? snap.metaLine
        : sourcePlatformDisplayLabel(
            row.sourcePlatform,
            platform: tryPlatformForRow(row),
          );

    rows.add(
      ListingWorkspaceRowView(
        row: row,
        title: title,
        typeLabel: typeLabel,
        priceDisplay: snap.priceDisplay,
        locationLine: locOk ? row.locationLabel : 'Konum yok',
        statusLabel: snap.statusLabel,
        contextLine: contextLine,
        nextActionLabel: _nextAction(
          row: row,
          isMissing: isMissing,
          isReady: isReady,
          needsAttention: needsAttention,
          canOpenDetail: snap.canOpenDetail,
        ),
        tone: _toneFor(
          isMissing: isMissing,
          isPartial: isPartial,
          isReady: isReady,
          needsAttention: needsAttention,
          isActive: isActive,
        ),
        isActive: isActive,
        isMissing: isMissing,
        isReady: isReady,
        isPartial: isPartial && !isMissing,
        needsAttention: needsAttention,
        propertyCategory: category,
        partialNote: partialNote,
        canOpenDetail: snap.canOpenDetail,
        canOpenExternal: snap.canOpenExternal,
        canShare: snap.canShare,
        canSync: snap.canSyncHint,
        sortRank: _sortRank(
          isMissing: isMissing,
          needsAttention: needsAttention,
          isReady: isReady,
          isPartial: isPartial,
        ),
        searchText:
            '$title ${row.locationLabel} ${row.priceLabel} ${row.listingType ?? ''} $typeLabel'
                .toLowerCase(),
      ),
    );
  }

  rows.sort((a, b) {
    final r = a.sortRank.compareTo(b.sortRank);
    if (r != 0) return r;
    return a.title.compareTo(b.title);
  });

  final incompleteRows =
      rows.where((r) => r.isMissing).toList(growable: false);
  final readyRows = rows.where((r) => r.isReady).toList(growable: false);

  final summary = ListingsWorkspaceSummary(
    active: rows.where((r) => r.isActive).length,
    missing: rows.where((r) => r.isMissing).length,
    ready: rows.where((r) => r.isReady).length,
    partial: rows.where((r) => r.isPartial).length,
    attention: rows.where((r) => r.needsAttention).length,
  );

  final dateChipLabel = summary.attention > 0 || summary.missing > 0
      ? '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}'
      : '';

  return ListingsWorkspaceSnapshot(
    rows: rows,
    incompleteRows: incompleteRows,
    readyRows: readyRows,
    summary: summary,
    coverageNote:
        'Özet yalnızca ofis portföyündeki (sahip) ilanlardan türetilir. '
        'Eksik/kısmi: başlık, fiyat, konum ve görsel alanlarına göre kural tabanlıdır; '
        'sunucuda ayrı “kalite skoru” yok. Görüntülenme veya AI sıralaması gösterilmez.',
    isEmpty: rows.isEmpty,
    dateChipLabel: dateChipLabel,
    canManage: canManage,
  );
}

bool _priceOk(String raw) {
  final t = raw.trim();
  return t.isNotEmpty && t != '—' && t != '-';
}

bool _locationOk(String raw) {
  final t = raw.trim();
  return t.isNotEmpty && t != '—' && t != '-';
}

String _typeLabel(ListingRowView row) {
  final lt = row.listingType?.trim();
  if (lt != null && lt.isNotEmpty) return lt;
  return switch (_propertyCategory(row)) {
    ListingPropertyCategory.residential => 'Konut',
    ListingPropertyCategory.land => 'Arsa',
    ListingPropertyCategory.commercial => 'İşyeri',
    ListingPropertyCategory.unknown => 'Tür belirtilmedi',
  };
}

ListingPropertyCategory _propertyCategory(ListingRowView row) {
  final blob =
      '${row.listingType ?? ''} ${row.title}'.toLowerCase();
  if (_matchesLand(blob)) return ListingPropertyCategory.land;
  if (_matchesCommercial(blob)) return ListingPropertyCategory.commercial;
  if (_matchesResidential(blob)) return ListingPropertyCategory.residential;
  return ListingPropertyCategory.unknown;
}

bool _matchesResidential(String l) =>
    l.contains('konut') ||
    l.contains('daire') ||
    l.contains('villa') ||
    l.contains('residence') ||
    l.contains('apartment') ||
    l.contains('flat');

bool _matchesLand(String l) =>
    l.contains('arsa') ||
    l.contains('arazi') ||
    l.contains('land') ||
    l.contains('plot') ||
    l.contains('tarla');

bool _matchesCommercial(String l) =>
    l.contains('işyeri') ||
    l.contains('isyeri') ||
    l.contains('ofis') ||
    l.contains('dükkan') ||
    l.contains('dukkan') ||
    l.contains('commercial') ||
    l.contains('office') ||
    l.contains('shop') ||
    l.contains('mağaza');

String _partialNote({
  required bool titleOk,
  required bool priceOk,
  required bool locOk,
  required bool imageOk,
}) {
  final missing = <String>[];
  if (!titleOk) missing.add('başlık');
  if (!priceOk) missing.add('fiyat');
  if (!locOk) missing.add('konum');
  if (!imageOk) missing.add('görsel');
  if (missing.isEmpty) return '';
  return 'Eksik: ${missing.join(' · ')}';
}

String _nextAction({
  required ListingRowView row,
  required bool isMissing,
  required bool isReady,
  required bool needsAttention,
  required bool canOpenDetail,
}) {
  if (isMissing) return 'Eksik alanları tamamla';
  if (needsAttention) {
    return row.syncStatus == ListingSyncStatus.error
        ? 'Senkron hatasını gider'
        : 'Senkronu kontrol et';
  }
  if (isReady && canOpenDetail) return 'İlana git';
  if (row.openInBrowserUrl != null && row.openInBrowserUrl!.isNotEmpty) {
    return 'Harici ilanı aç';
  }
  return 'Detayı incele';
}

int _sortRank({
  required bool isMissing,
  required bool needsAttention,
  required bool isReady,
  required bool isPartial,
}) {
  if (isMissing && needsAttention) return 0;
  if (isMissing) return 1;
  if (needsAttention) return 2;
  if (isPartial) return 3;
  if (isReady) return 5;
  return 4;
}

ListingWorkspaceTone _toneFor({
  required bool isMissing,
  required bool isPartial,
  required bool isReady,
  required bool needsAttention,
  required bool isActive,
}) {
  if (isMissing) return ListingWorkspaceTone.missing;
  if (needsAttention) return ListingWorkspaceTone.attention;
  if (isReady) return ListingWorkspaceTone.ready;
  if (isPartial) return ListingWorkspaceTone.partial;
  if (isActive) return ListingWorkspaceTone.active;
  return ListingWorkspaceTone.neutral;
}
