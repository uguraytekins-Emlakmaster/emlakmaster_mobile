import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// İlan detay: galeri (tek görsel), başlık, fiyat, konum, açıklama.
class ListingDetailPage extends StatelessWidget {
  const ListingDetailPage({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirestoreService.listingDocStream(listingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF41), strokeWidth: 2),
            );
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Colors.white54),
                    const SizedBox(height: 16),
                    Text(
                      snapshot.hasError ? 'İlan yüklenemedi.' : 'İlan bulunamadı.',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF00FF41)),
                      label: const Text('Geri', style: TextStyle(color: Color(0xFF00FF41))),
                    ),
                  ],
                ),
              ),
            );
          }

          final d = snapshot.data!.data() ?? <String, dynamic>{};
          final imageUrl = d['imageUrl'] as String?;
          final title = d['title'] as String? ?? 'İlan';
          final priceRaw = d['price'];
          final priceStr = priceRaw is String
              ? priceRaw
              : (priceRaw as num?)?.toString() ?? '—';
          final location = d['location'] as String? ?? d['district'] as String? ?? '—';
          final description = d['description'] as String? ?? '';
          final roomCount = d['roomCount'] as String? ?? d['rooms'] as String?;
          final m2 = d['m2'] as num? ?? d['area'] as num?;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: const Color(0xFF0D1117),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.pop();
                  },
                ),
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => LayoutBuilder(
                            builder: (context, c) => ShimmerPlaceholder(
                              width: c.maxWidth > 0 ? c.maxWidth : 400,
                              height: c.maxHeight > 0 ? c.maxHeight : 220,
                            ),
                          ),
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: Colors.white70),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (roomCount != null && roomCount.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Oda: $roomCount',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                      if (m2 != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'm²: ${m2 is int ? m2 : (m2 as double).toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        priceStr.contains('₺') ? priceStr : '$priceStr ₺',
                        style: const TextStyle(
                          color: Color(0xFF00FF41),
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Açıklama',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF161B22),
      child: Center(
        child: Icon(Icons.home_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
      ),
    );
  }
}
