import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/consultant_customers_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/detail_workspace/customer_detail_workspace_types.dart';
import 'package:flutter/material.dart';

class CustomerDetailSectionCard extends StatelessWidget {
  const CustomerDetailSectionCard({
    super.key,
    required this.section,
    this.onListingTap,
    this.onLinkedRowTap,
  });

  final CustomerDetailSectionView section;
  final void Function(String listingId)? onListingTap;
  final VoidCallback? onLinkedRowTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);

    if (section.kind == CustomerDetailSectionKind.partialNote &&
        section.note != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          ConsultantCustomersTokens.horizontal,
          0,
          ConsultantCustomersTokens.horizontal,
          ConsultantCustomersTokens.chromeGap,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ext.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ext.warning.withValues(alpha: 0.28)),
          ),
          child: Text(
            section.note!,
            style: TextStyle(
              color: ext.textSecondary,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          ConsultantCustomersTokens.horizontal,
          0,
          ConsultantCustomersTokens.horizontal,
          ConsultantCustomersTokens.chromeGap + 2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: ext.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ext.border.withValues(alpha: 0.32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final f in section.fields) _FieldRow(field: f),
            for (final row in section.linkedRows)
              _LinkedRowTile(
                row: row,
                onTap: onLinkedRowTap,
              ),
            for (final listing in section.listings)
              _ListingRowTile(
                row: listing,
                onTap: onListingTap,
              ),
            if (section.note != null &&
                section.kind != CustomerDetailSectionKind.partialNote) ...[
              const SizedBox(height: 4),
              Text(
                section.note!,
                style: TextStyle(
                  color: ext.textTertiary,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field});
  final CustomerDetailFieldRow field;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              field.label,
              style: TextStyle(
                color: ext.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              field.value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: field.isEmpty ? ext.textTertiary : ext.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedRowTile extends StatelessWidget {
  const _LinkedRowTile({required this.row, this.onTap});
  final CustomerDetailLinkedRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(Icons.task_alt_rounded, size: 14, color: ext.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      row.statusLabel,
                      style: TextStyle(
                        color: ext.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingRowTile extends StatelessWidget {
  const _ListingRowTile({required this.row, this.onTap});
  final CustomerDetailListingRow row;
  final void Function(String listingId)? onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null ? () => onTap!(row.listingId) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(Icons.home_work_outlined, size: 14, color: ext.success),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  row.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ext.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: ext.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
