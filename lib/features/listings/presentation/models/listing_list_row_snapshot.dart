import 'package:emlakmaster_mobile/features/listings/data/listing_row_factory.dart';
import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/utils/listing_list_filter.dart';

/// Satır başına türetilmiş etiketler — provider tekrarı yok.
class ListingListRowSnapshot {
  const ListingListRowSnapshot({
    required this.statusLabel,
    required this.statusTone,
    required this.sourceLabel,
    required this.metaLine,
    required this.priceDisplay,
    required this.needsAttention,
    required this.canOpenDetail,
    required this.canOpenExternal,
    required this.canShare,
    required this.canSyncHint,
  });

  final String statusLabel;
  final ListingRowStatusTone statusTone;
  final String sourceLabel;
  final String metaLine;
  final String priceDisplay;
  final bool needsAttention;
  final bool canOpenDetail;
  final bool canOpenExternal;
  final bool canShare;
  final bool canSyncHint;

  factory ListingListRowSnapshot.fromRow(ListingRowView row) {
    final platform = tryPlatformForRow(row);
    final sourceLabel =
        sourcePlatformDisplayLabel(row.sourcePlatform, platform: platform);
    final syncLabel = listingSyncStatusLabel(row.syncStatus);
    final typeLabel = row.listingType?.trim();
    final metaParts = <String>[
      if (typeLabel != null && typeLabel.isNotEmpty) typeLabel,
      if (row.surface == ListingSurface.owned) syncLabel,
    ];
    if (row.lastSyncedAt != null && row.surface == ListingSurface.owned) {
      metaParts.add(_shortDate(row.lastSyncedAt!));
    }

    final tone = switch (row.syncStatus) {
      ListingSyncStatus.error => ListingRowStatusTone.danger,
      ListingSyncStatus.stale => ListingRowStatusTone.warning,
      ListingSyncStatus.pending => ListingRowStatusTone.info,
      ListingSyncStatus.synced => listingRowIsPublished(row)
          ? ListingRowStatusTone.success
          : ListingRowStatusTone.neutral,
      ListingSyncStatus.unknown => ListingRowStatusTone.neutral,
    };

    final statusLabel = row.surface == ListingSurface.marketFeed
        ? 'Pazar'
        : listingRowIsDraft(row)
            ? 'Taslak'
            : listingRowIsPublished(row)
                ? 'Yayında'
                : syncLabel;

    final price = row.priceLabel.contains('₺') || row.priceLabel == '—'
        ? row.priceLabel
        : '${row.priceLabel} ₺';

    return ListingListRowSnapshot(
      statusLabel: statusLabel,
      statusTone: tone,
      sourceLabel: sourceLabel,
      metaLine: metaParts.join(' · '),
      priceDisplay: price,
      needsAttention: listingRowNeedsAttention(row),
      canOpenDetail:
          row.detailListingId != null && row.detailListingId!.isNotEmpty,
      canOpenExternal:
          row.openInBrowserUrl != null && row.openInBrowserUrl!.isNotEmpty,
      canShare: row.title.isNotEmpty,
      canSyncHint: row.rowKind == ListingRowKind.connectedPlatform ||
          row.syncStatus == ListingSyncStatus.error ||
          row.syncStatus == ListingSyncStatus.stale,
    );
  }
}

enum ListingRowStatusTone { success, warning, danger, info, neutral }

String _shortDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year}';
}
