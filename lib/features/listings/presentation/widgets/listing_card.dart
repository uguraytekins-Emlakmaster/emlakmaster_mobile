import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/models/listing_list_row_snapshot.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/widgets/listing_list_operating_card.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/widgets/listing_list_premium_tile.dart';
import 'package:flutter/material.dart';

/// İlan kartı — operating card + premium tile.
class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.row,
    required this.snapshot,
    this.onTap,
    this.onDetail,
    this.onEdit,
    this.onShare,
    this.onSync,
  });

  final ListingRowView row;
  final ListingListRowSnapshot snapshot;
  final VoidCallback? onTap;
  final VoidCallback? onDetail;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onSync;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${row.title} ilanı',
      button: true,
      child: ListingListOperatingCard(
        emphasizeAttention: snapshot.needsAttention,
        child: ListingListPremiumTile(
          row: row,
          snapshot: snapshot,
          onTap: onTap,
          onDetail: onDetail,
          onEdit: onEdit,
          onShare: onShare,
          onSync: onSync,
        ),
      ),
    );
  }
}
