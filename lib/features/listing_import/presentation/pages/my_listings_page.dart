import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/listing_import/application/listings_filter_service.dart';
import 'package:emlakmaster_mobile/features/listing_import/data/listings_repository.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/listing_entity.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/import_task_status.dart';
import 'package:emlakmaster_mobile/features/listing_import/domain/listing_import_task_entity.dart';
import 'package:emlakmaster_mobile/features/listing_import/presentation/providers/listing_import_providers.dart';
import 'package:emlakmaster_mobile/features/listing_import/presentation/widgets/listing_import_shimmer.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
/// İçe aktarılan ilanlar — gerçek veri (yerel motor, Phase 1.5).
class MyListingsPage extends ConsumerStatefulWidget {
  const MyListingsPage({
    super.key,
    this.initialImportTaskId,
  });

  /// Geçmiş ekranından filtre için.
  final String? initialImportTaskId;

  @override
  ConsumerState<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends ConsumerState<MyListingsPage> {
  String? _platformFilter;
  double? _minPrice;
  double? _maxPrice;
  DateTime? _from;
  DateTime? _to;
  bool _favoritesOnly = false;
  bool _groupDuplicates = true;
  String? _focusTaskId;

  @override
  void initState() {
    super.initState();
    _focusTaskId = widget.initialImportTaskId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
    final listingsAsync = ref.watch(myListingsProvider);
    final historyAsync = ref.watch(importHistoryProvider);
    final canManage = ref.watch(canManagePlatformIntegrationsProvider);

    return Scaffold(
      backgroundColor: AppThemeExtension.of(context).background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    const AppBackButton(),
                    Expanded(
                      child: Text(
                        'Benim ilanlarım',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppThemeExtension.of(context).textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (canManage) ...[
                      IconButton(
                        tooltip: 'İçe aktar',
                        onPressed: () => context.push(AppRouter.routeImportHub),
                        icon: Icon(Icons.add_circle_outline_rounded, color: AppThemeExtension.of(context).accent),
                      ),
                      IconButton(
                        tooltip: 'Geçmiş',
                        onPressed: () => context.push(AppRouter.routeImportHistory),
                        icon: Icon(Icons.history_rounded, color: AppThemeExtension.of(context).textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            listingsAsync.when(
              loading: () => const SliverFillRemaining(child: ListingImportShimmer()),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('$e', style: TextStyle(color: AppThemeExtension.of(context).danger))),
              ),
              data: (all) {
                final filtered = ListingsFilterService.apply(
                  all,
                  platformId: _platformFilter,
                  minPrice: _minPrice,
                  maxPrice: _maxPrice,
                  createdAfter: _from,
                  createdBefore: _to,
                  favoritesOnly: _favoritesOnly,
                ).where((l) {
                  if (_focusTaskId == null || _focusTaskId!.isEmpty) return true;
                  return l.importTaskId == _focusTaskId;
                }).toList();

                final lastImport = historyAsync.maybeWhen(
                  data: (list) => list.isEmpty ? null : list.first,
                  orElse: () => null,
                );

                return SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(child: _HeaderStats(total: all.length, last: lastImport)),
                    SliverToBoxAdapter(
                      child: _FilterBar(
                        platform: _platformFilter,
                        minPrice: _minPrice,
                        maxPrice: _maxPrice,
                        from: _from,
                        to: _to,
                        favoritesOnly: _favoritesOnly,
                        groupDuplicates: _groupDuplicates,
                        focusTaskId: _focusTaskId,
                        onClearTask: () => setState(() => _focusTaskId = null),
                        onPlatform: (v) => setState(() => _platformFilter = v),
                        onPriceRange: (min, max) => setState(() {
                          _minPrice = min;
                          _maxPrice = max;
                        }),
                        onDateRange: (a, b) => setState(() {
                          _from = a;
                          _to = b;
                        }),
                        onFavorites: (v) => setState(() => _favoritesOnly = v),
                        onGroup: (v) => setState(() => _groupDuplicates = v),
                      ),
                    ),
                    if (filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: uid == null
                            ? Center(
                                child: Text(
                                  'Giriş yapın.',
                                  style: TextStyle(color: AppThemeExtension.of(context).textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Builder(
                                builder: (context) {
                                  final l10n = AppLocalizations.of(context);
                                  if (all.isEmpty) {
                                    return EmptyState(
                                      premiumVisual: true,
                                      icon: Icons.home_work_outlined,
                                      title: l10n.t('empty_my_listings_title'),
                                      subtitle: canManage
                                          ? l10n.t('empty_my_listings_sub')
                                          : '${l10n.t('empty_my_listings_sub')}\n\n${l10n.t('integration_connections_read_only_notice')}',
                                      actionLabel: canManage ? l10n.t('empty_my_listings_cta_import') : null,
                                      onAction: canManage
                                          ? () => context.push(AppRouter.routeImportHub)
                                          : null,
                                      outlinedActionLabel:
                                          canManage ? l10n.t('empty_my_listings_cta_accounts') : null,
                                      onOutlinedAction: canManage
                                          ? () => context.push(AppRouter.routeConnectedAccounts)
                                          : null,
                                    );
                                  }
                                  return const EmptyState(
                                    compact: true,
                                    icon: Icons.filter_alt_off_outlined,
                                    title: 'Filtreye uygun ilan yok',
                                    subtitle: 'Filtreleri sıfırlayıp tekrar deneyin.',
                                  );
                                },
                              ),
                      )
                    else if (_groupDuplicates)
                      ..._buildGroupedSlivers(uid, filtered, all)
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: _ListingCard(
                              listing: filtered[i],
                              duplicateCount: _dupCount(all, filtered[i].duplicateGroupId),
                              onFavorite: () => _toggleFavorite(uid, filtered[i]),
                              onNote: () => _editNote(uid, filtered[i]),
                            ),
                          ),
                          childCount: filtered.length,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  int _dupCount(List<ListingEntity> all, String? groupId) {
    if (groupId == null || groupId.isEmpty) return 0;
    return all.where((e) => e.duplicateGroupId == groupId).length;
  }

  List<Widget> _buildGroupedSlivers(
    String? uid,
    List<ListingEntity> filtered,
    List<ListingEntity> all,
  ) {
    final groups = ListingsFilterService.groupByDuplicate(filtered);
    final multiIds = groups.entries.where((e) => e.value.length >= 2).map((e) => e.key).toSet();
    final singles = filtered.where((e) => e.duplicateGroupId == null || !multiIds.contains(e.duplicateGroupId)).toList();

    final slivers = <Widget>[];

    if (multiIds.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Olası duplikasyonlar',
              style: TextStyle(
                color: AppThemeExtension.of(context).textSecondary.withValues(alpha: 0.9),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
      for (final e in groups.entries) {
        if (e.value.length < 2) continue;
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: _DuplicateGroupTile(
                listings: e.value,
                onFavorite: (l) => _toggleFavorite(uid, l),
                onNote: (l) => _editNote(uid, l),
              ),
            ),
          ),
        );
      }
    }

    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Liste',
            style: TextStyle(
              color: AppThemeExtension.of(context).textSecondary.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
    slivers.add(
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final l = singles[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: _ListingCard(
                listing: l,
                duplicateCount: _dupCount(all, l.duplicateGroupId),
                onFavorite: () => _toggleFavorite(uid, l),
                onNote: () => _editNote(uid, l),
              ),
            );
          },
          childCount: singles.length,
        ),
      ),
    );
    return slivers;
  }

  void _toggleFavorite(String? uid, ListingEntity l) {
    if (uid == null) return;
    ListingsRepository.instance.updateFavorite(uid, l.id, !l.isFavorite);
    ref.invalidate(myListingsProvider);
  }

  Future<void> _editNote(String? uid, ListingEntity l) async {
    if (uid == null) return;
    final ctrl = TextEditingController(text: l.quickNote ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hızlı not'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Bu ilan için not…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
        ],
      ),
    );
    if (ok == true && mounted) {
      ListingsRepository.instance.updateNote(uid, l.id, ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
      ref.invalidate(myListingsProvider);
    }
  }
}

class _HeaderStats extends StatelessWidget {
  const _HeaderStats({required this.total, this.last});

  final int total;
  final ListingImportTaskEntity? last;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd('tr_TR');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Material(
        color: AppThemeExtension.of(context).card,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.home_work_outlined, color: AppThemeExtension.of(context).accent, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total ilan',
                      style: TextStyle(
                        color: AppThemeExtension.of(context).textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      last == null
                          ? 'Henüz içe aktarma yok'
                          : 'Son içe aktarma: ${fmt.format(last!.createdAt ?? DateTime.now())} · ${last!.status.wireValue}',
                      style: TextStyle(color: AppThemeExtension.of(context).textSecondary, fontSize: 12),
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.platform,
    required this.minPrice,
    required this.maxPrice,
    required this.from,
    required this.to,
    required this.favoritesOnly,
    required this.groupDuplicates,
    required this.focusTaskId,
    required this.onClearTask,
    required this.onPlatform,
    required this.onPriceRange,
    required this.onDateRange,
    required this.onFavorites,
    required this.onGroup,
  });

  final String? platform;
  final double? minPrice;
  final double? maxPrice;
  final DateTime? from;
  final DateTime? to;
  final bool favoritesOnly;
  final bool groupDuplicates;
  final String? focusTaskId;
  final VoidCallback onClearTask;
  final ValueChanged<String?> onPlatform;
  final void Function(double? min, double? max) onPriceRange;
  final void Function(DateTime? a, DateTime? b) onDateRange;
  final ValueChanged<bool> onFavorites;
  final ValueChanged<bool> onGroup;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (focusTaskId != null && focusTaskId!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: AppThemeExtension.of(context).warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                child: ListTile(
                  leading: Icon(Icons.filter_alt_rounded, color: AppThemeExtension.of(context).warning),
                  title: const Text('Görev filtresi aktif', style: TextStyle(fontSize: 13)),
                  trailing: TextButton(onPressed: onClearTask, child: const Text('Temizle')),
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Tüm platformlar'),
                selected: platform == null,
                onSelected: (_) => onPlatform(null),
              ),
              for (final p in const ['sahibinden', 'hepsiemlak', 'emlakjet', 'manual', 'file'])
                ChoiceChip(
                  label: Text(p),
                  selected: platform == p,
                  onSelected: (_) => onPlatform(p),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Min ₺',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (s) {
                    final v = double.tryParse(s.replaceAll('.', ''));
                    onPriceRange(v, maxPrice);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max ₺',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (s) {
                    final v = double.tryParse(s.replaceAll('.', ''));
                    onPriceRange(minPrice, v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final r = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (r != null) onDateRange(r.start, r.end);
                  },
                  icon: const Icon(Icons.date_range_rounded, size: 18),
                  label: Text(
                    from == null ? 'Tarih aralığı' : '${from!.day}.${from!.month} — ${to?.day}.${to?.month}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Favoriler'),
                selected: favoritesOnly,
                onSelected: onFavorites,
              ),
              FilterChip(
                label: const Text('Grupla'),
                selected: groupDuplicates,
                onSelected: onGroup,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listing,
    required this.duplicateCount,
    required this.onFavorite,
    required this.onNote,
  });

  final ListingEntity listing;
  final int duplicateCount;
  final VoidCallback onFavorite;
  final VoidCallback onNote;

  @override
  Widget build(BuildContext context) {
    final priceFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    return Material(
      color: AppThemeExtension.of(context).card,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: listing.images.isNotEmpty
                  ? Image.network(
                      listing.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppThemeExtension.of(context).surfaceElevated,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    )
                  : Container(
                      color: AppThemeExtension.of(context).surfaceElevated,
                      child: const Icon(Icons.photo_outlined),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _PlatformBadge(label: listing.platformId),
                      if (duplicateCount > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppThemeExtension.of(context).warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Benzer $duplicateCount',
                            style: TextStyle(fontSize: 11, color: AppThemeExtension.of(context).warning),
                          ),
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        onPressed: onFavorite,
                        icon: Icon(
                          listing.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: listing.isFavorite ? AppThemeExtension.of(context).warning : AppThemeExtension.of(context).textSecondary,
                        ),
                      ),
                      IconButton(
                        onPressed: onNote,
                        icon: const Icon(Icons.sticky_note_2_outlined, size: 22),
                      ),
                    ],
                  ),
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppThemeExtension.of(context).textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    priceFmt.format(listing.price),
                    style: TextStyle(
                      color: AppThemeExtension.of(context).accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.location,
                    style: TextStyle(color: AppThemeExtension.of(context).textSecondary, fontSize: 12),
                  ),
                  if (listing.quickNote != null && listing.quickNote!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        listing.quickNote!,
                        style: TextStyle(color: AppThemeExtension.of(context).textTertiary, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  const _PlatformBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppThemeExtension.of(context).accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: AppThemeExtension.of(context).accent, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DuplicateGroupTile extends StatelessWidget {
  const _DuplicateGroupTile({
    required this.listings,
    required this.onFavorite,
    required this.onNote,
  });

  final List<ListingEntity> listings;
  final ValueChanged<ListingEntity> onFavorite;
  final ValueChanged<ListingEntity> onNote;

  @override
  Widget build(BuildContext context) {
    final priceFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    final first = listings.first;
    return Material(
      color: AppThemeExtension.of(context).surfaceElevated,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(
          first.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w700, color: AppThemeExtension.of(context).textPrimary),
        ),
        subtitle: Text(
          '${priceFmt.format(first.price)} · ${listings.length} kayıt',
          style: TextStyle(fontSize: 12, color: AppThemeExtension.of(context).textSecondary),
        ),
        children: [
          for (final l in listings)
            ListTile(
              leading: _PlatformBadge(label: l.platformId),
              title: Text(l.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(priceFmt.format(l.price)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(l.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded),
                    onPressed: () => onFavorite(l),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sticky_note_2_outlined),
                    onPressed: () => onNote(l),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
