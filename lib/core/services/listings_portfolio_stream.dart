import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// İlan Portföyü satırı: ofis [listings] veya harici [external_listings].
class PortfolioListingItem {
  const PortfolioListingItem({
    required this.id,
    required this.isExternal,
    required this.title,
    required this.price,
    required this.location,
    this.imageUrl,
    this.externalLink,
  });

  final String id;
  final bool isExternal;
  final String title;
  final String price;
  final String location;
  final String? imageUrl;
  final String? externalLink;
}

/// [listings] + [external_listings] birleşik akışı (tek abonelikte güncellenir).
class ListingsPortfolioStream {
  ListingsPortfolioStream._();

  static const int _externalLimit = 60;

  /// Her çağrı yeni bir stream döner; [StatefulWidget] içinde bir kez saklayın.
  static Stream<List<PortfolioListingItem>> combined() {
    final controller = StreamController<List<PortfolioListingItem>>();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subInternal;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subExternal;

    QuerySnapshot<Map<String, dynamic>>? lastInternal;
    QuerySnapshot<Map<String, dynamic>>? lastExternal;

    void emit() {
      if (controller.isClosed) return;
      controller.add(_merge(lastInternal, lastExternal));
    }

    FirestoreService.ensureInitialized().then((_) {
      if (controller.isClosed) return;
      if (!FirestoreService.isFirestoreReady) {
        controller.add(const <PortfolioListingItem>[]);
        return;
      }

      final fs = FirebaseFirestore.instance;

      subInternal = fs.collection(AppConstants.colListings).snapshots().listen(
        (s) {
          lastInternal = s;
          emit();
        },
        onError: (Object e, StackTrace st) {
          if (kDebugMode) debugPrint('ListingsPortfolioStream internal: $e');
          lastInternal = null;
          emit();
        },
      );

      final externalQuery = fs
          .collection(AppConstants.colExternalListings)
          .orderBy('postedAt', descending: true)
          .limit(_externalLimit);

      subExternal = externalQuery.snapshots().listen(
        (s) {
          lastExternal = s;
          emit();
        },
        onError: (Object e, StackTrace st) {
          if (kDebugMode) debugPrint('ListingsPortfolioStream external: $e');
          lastExternal = null;
          emit();
        },
      );
    });

    controller.onCancel = () {
      subInternal?.cancel();
      subExternal?.cancel();
    };

    return controller.stream;
  }

  static List<PortfolioListingItem> _merge(
    QuerySnapshot<Map<String, dynamic>>? internal,
    QuerySnapshot<Map<String, dynamic>>? external,
  ) {
    final out = <PortfolioListingItem>[];

    for (final doc in internal?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
      final d = doc.data();
      final priceRaw = d['price'];
      final priceStr = priceRaw is String
          ? priceRaw
          : (priceRaw as num?)?.toString() ?? '—';
      final loc = d['location'] as String? ?? d['district'] as String? ?? '—';
      out.add(
        PortfolioListingItem(
          id: doc.id,
          isExternal: false,
          title: d['title'] as String? ?? '',
          price: priceStr,
          location: loc,
          imageUrl: d['imageUrl'] as String?,
        ),
      );
    }

    for (final doc in external?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
      final d = doc.data();
      final priceText = d['priceText'] as String?;
      final priceVal = d['priceValue'];
      final priceStr = (priceText != null && priceText.isNotEmpty)
          ? priceText
          : (priceVal is num ? priceVal.toString() : '—');
      final city = d['cityName'] as String? ?? d['cityCode'] as String? ?? '';
      final district = d['districtName'] as String?;
      final locParts = <String>[];
      if (city.isNotEmpty) locParts.add(city);
      if (district != null && district.isNotEmpty) locParts.add(district);
      final loc = locParts.join(' · ');
      out.add(
        PortfolioListingItem(
          id: doc.id,
          isExternal: true,
          title: d['title'] as String? ?? '',
          price: priceStr,
          location: loc.isEmpty ? '—' : loc,
          imageUrl: d['imageUrl'] as String?,
          externalLink: d['link'] as String?,
        ),
      );
    }

    return out;
  }
}
