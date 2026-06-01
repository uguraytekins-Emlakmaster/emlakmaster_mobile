import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/providers/owned_listing_rows_display_provider.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/providers/owned_listing_rows_provider.dart';
import 'package:emlakmaster_mobile/features/listings/presentation/workspace/listings_workspace_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Portföyüm workspace aksiyonları — mevcut ilan akışları korunur.
abstract final class ListingsWorkspaceActions {
  ListingsWorkspaceActions._();

  static void _snack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  static void refresh(WidgetRef ref) {
    ref.invalidate(ownedListingRowsProvider);
    ref.invalidate(ownedListingRowsStaleCacheProvider);
  }

  static Future<void> openListingRow(
    BuildContext context,
    ListingRowView row,
  ) async {
    AppFeedback.lightImpact();
    final detail = row.detailListingId;
    if (detail != null && detail.isNotEmpty) {
      if (!context.mounted) return;
      context.push(AppRouter.routeListingDetail.replaceFirst(':id', detail));
      return;
    }
    final link = row.openInBrowserUrl;
    if (link != null && link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri == null) {
        if (!context.mounted) return;
        _snack(
          context,
          AppLocalizations.of(context).t('listing_external_no_link'),
        );
        return;
      }
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _snack(
          context,
          AppLocalizations.of(context).t('listing_external_open_failed'),
        );
      }
      return;
    }
    if (!context.mounted) return;
    _snack(context, AppLocalizations.of(context).t('listing_external_no_link'));
  }

  static Future<void> openListing(
    BuildContext context,
    ListingWorkspaceRowView row,
  ) async {
    await openListingRow(context, row.row);
  }

  static Future<void> shareRow(BuildContext context, ListingRowView row) async {
    AppFeedback.lightImpact();
    final price = row.priceLabel.contains('₺') || row.priceLabel == '—'
        ? row.priceLabel
        : '${row.priceLabel} ₺';
    final text = [
      row.title.isNotEmpty ? row.title : 'İlan',
      row.locationLabel,
      price,
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    final premium = PremiumThemeExtension.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'İlan metni panoya kopyalandı — WhatsApp veya SMS ile paylaşabilirsiniz.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: premium.champagneGold,
      ),
    );
  }

  static void edit(BuildContext context) {
    AppFeedback.lightImpact();
    _snack(
      context,
      'İlan düzenleme sihirbazı yakında. Şimdilik içe aktarma veya bağlı platformları kullanın.',
    );
  }

  static Future<void> share(
    BuildContext context,
    ListingWorkspaceRowView row,
  ) async {
    AppFeedback.lightImpact();
    final text = [
      row.title,
      row.locationLine,
      row.priceDisplay,
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    final premium = PremiumThemeExtension.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'İlan metni panoya kopyalandı — WhatsApp veya SMS ile paylaşabilirsiniz.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: premium.champagneGold,
      ),
    );
  }

  static void sync(
    BuildContext context,
    WidgetRef ref,
    ListingWorkspaceRowView row, {
    required bool canManage,
  }) {
    AppFeedback.lightImpact();
    if (canManage) {
      context.push(AppRouter.routeConnectedAccounts);
      return;
    }
    _snack(
      context,
      'Senkron yönetimi için ofis yöneticisi yetkisi gerekir.',
    );
  }

  static void openImportHub(BuildContext context) {
    AppFeedback.lightImpact();
    context.push(AppRouter.routeImportHub);
  }

  static void openConnectedAccounts(BuildContext context) {
    AppFeedback.lightImpact();
    context.push(AppRouter.routeConnectedAccounts);
  }

  static void showActionSheet(
    BuildContext context,
    WidgetRef ref,
    ListingWorkspaceRowView row, {
    required bool canManage,
  }) {
    AppFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text('Durum: ${row.statusLabel}',
                    style: Theme.of(ctx).textTheme.bodySmall),
                Text(row.contextLine,
                    style: Theme.of(ctx).textTheme.bodySmall),
                if (row.partialNote.isNotEmpty)
                  Text(row.partialNote,
                      style: Theme.of(ctx).textTheme.bodySmall),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (row.canOpenDetail || row.canOpenExternal)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          openListing(context, row);
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: Text(
                          row.canOpenDetail ? 'İlana git' : 'Harici aç',
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        edit(context);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Düzenle'),
                    ),
                    if (row.canShare)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          share(context, row);
                        },
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('Mesaj'),
                      ),
                    if (row.canSync)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          sync(context, ref, row, canManage: canManage);
                        },
                        icon: const Icon(Icons.sync_rounded, size: 18),
                        label: const Text('Tamamla'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
