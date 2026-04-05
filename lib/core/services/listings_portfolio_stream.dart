import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/external_integrations/data/integration_listings_repository.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_synced_listing_entity.dart';
import 'package:emlakmaster_mobile/features/listings/data/listing_row_factory.dart';
import 'package:emlakmaster_mobile/features/listings/domain/listing_row_view.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Ofis envanteri: canonical `listings` (ownerUserId ve/veya officeId) + legacy `integration_listings`.
/// [external_listings] pazar akışı burada **yok**.
///
/// `integration_listings` satırı, aynı `sourcePlatform|sourceListingId` canonical `listings` ile
/// çakışıyorsa düşürülür (çift kart önlenir).
class ListingsPortfolioStream {
  ListingsPortfolioStream._();

  static String _dedupeKey(ListingRowView r) => '${r.sourcePlatform}|${r.sourceListingId}';

  /// [officeId] — `users.officeId`; canonical ofis kapsamı için ikinci sorgu.
  static Stream<List<ListingRowView>> owned({
    required String uid,
    String? officeId,
  }) {
    final controller = StreamController<List<ListingRowView>>();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subOwner;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subOffice;
    StreamSubscription<List<IntegrationSyncedListingEntity>>? subIntegration;

    QuerySnapshot<Map<String, dynamic>>? lastOwner;
    QuerySnapshot<Map<String, dynamic>>? lastOffice;
    List<IntegrationSyncedListingEntity> lastIntegration = const [];

    void emit() {
      if (controller.isClosed) return;

      final byDocId = <String, ListingRowView>{};
      for (final d in lastOwner?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
        byDocId[d.id] = listingRowFromInternalDoc(d);
      }
      for (final d in lastOffice?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
        if (!byDocId.containsKey(d.id)) {
          byDocId[d.id] = listingRowFromInternalDoc(d);
        }
      }

      final canonicalKeys = <String>{};
      for (final r in byDocId.values) {
        canonicalKeys.add(_dedupeKey(r));
      }

      final integrationRows = <ListingRowView>[];
      for (final e in lastIntegration) {
        final k = '${e.platform.storageKey}|${e.externalListingId}';
        if (canonicalKeys.contains(k)) {
          continue;
        }
        integrationRows.add(listingRowFromIntegration(e));
      }

      final merged = <ListingRowView>[...byDocId.values, ...integrationRows];
      merged.sort((a, b) {
        final ga = _groupOrder(a.rowKind);
        final gb = _groupOrder(b.rowKind);
        if (ga != gb) return ga.compareTo(gb);
        final ta = a.lastSyncedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.lastSyncedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      controller.add(merged);
    }

    FirestoreService.ensureInitialized().then((_) {
      if (controller.isClosed) return;
      if (!FirestoreService.isFirestoreReady) {
        controller.add(const <ListingRowView>[]);
        return;
      }

      final fs = FirebaseFirestore.instance;

      subOwner = fs
          .collection(AppConstants.colListings)
          .where('ownerUserId', isEqualTo: uid)
          .snapshots()
          .listen(
            (s) {
              lastOwner = s;
              emit();
            },
            onError: (Object e, StackTrace st) {
              if (kDebugMode) debugPrint('ListingsPortfolioStream ownerUserId: $e');
              lastOwner = null;
              emit();
            },
          );

      final oid = officeId?.trim() ?? '';
      if (oid.isNotEmpty) {
        subOffice = fs
            .collection(AppConstants.colListings)
            .where('officeId', isEqualTo: oid)
            .snapshots()
            .listen(
              (s) {
                lastOffice = s;
                emit();
              },
              onError: (Object e, StackTrace st) {
                if (kDebugMode) debugPrint('ListingsPortfolioStream officeId: $e');
                lastOffice = null;
                emit();
              },
            );
      }

      subIntegration = IntegrationListingsRepository.instance.streamForOwner(uid).listen(
        (list) {
          lastIntegration = list;
          emit();
        },
        onError: (Object e, StackTrace st) {
          if (kDebugMode) debugPrint('ListingsPortfolioStream integration: $e');
          lastIntegration = const [];
          emit();
        },
      );
    });

    controller.onCancel = () {
      subOwner?.cancel();
      subOffice?.cancel();
      subIntegration?.cancel();
    };

    return controller.stream;
  }

  static int _groupOrder(ListingRowKind k) {
    switch (k) {
      case ListingRowKind.officePortfolio:
        return 0;
      case ListingRowKind.connectedPlatform:
        return 1;
      case ListingRowKind.market:
        return 2;
    }
  }
}
