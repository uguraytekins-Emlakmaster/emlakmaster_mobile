import 'package:emlakmaster_mobile/features/external_listings/domain/entities/external_listing_entity.dart';
import 'package:flutter/material.dart';

/// «Son senkron» + üçüncü taraf veri uyarısı (Market Pulse liste bölümü).
class MarketPulseListingsMeta extends StatelessWidget {
  const MarketPulseListingsMeta({
    super.key,
    required this.listings,
    required this.textSecondary,
  });

  final List<ExternalListingEntity> listings;
  final Color textSecondary;

  static String _formatDateTimeTr(DateTime d) {
    String p2(int n) => n.toString().padLeft(2, '0');
    return '${p2(d.day)}.${p2(d.month)}.${d.year} ${p2(d.hour)}:${p2(d.minute)}';
  }

  static String? _ingestSourceLabel(String? by) {
    if (by == null || by.isEmpty) return null;
    switch (by) {
      case 'github_actions':
        return 'GitHub Actions';
      case 'csv_import':
        return 'CSV içe aktarma';
      case 'client':
        return 'Uygulama senkronu';
      default:
        return by;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = ExternalListingEntity.latestIngestTime(listings);
    final src = ExternalListingEntity.ingestSourceAtLatestTime(listings);
    final sourceLabel = _ingestSourceLabel(src);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sync != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.sync_rounded,
                  size: 14,
                  color: textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sourceLabel != null
                        ? 'Son senkron: ${_formatDateTimeTr(sync)} · $sourceLabel'
                        : 'Son senkron: ${_formatDateTimeTr(sync)}',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 10.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Harici ilan verileri üçüncü taraf sitelerden veya otomasyonla '
                'gelir; doğruluk ve kullanım koşulları kaynağa bağlıdır. '
                'Yatırım kararı için resmi kaynakları kontrol edin.',
                style: TextStyle(
                  color: textSecondary.withValues(alpha: 0.88),
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
