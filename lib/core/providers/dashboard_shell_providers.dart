import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/finance_service.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ofis ticker — MasterTicker + War Room paylaşır.
final officeTickerProvider = StreamProvider.autoDispose<List<String>>((ref) {
  return FirestoreService.officeTickerStream;
});

/// Ekonomi şeridi — FinanceBar tek abonelik.
final financeRatesProvider = StreamProvider.autoDispose<FinanceRates>((ref) {
  return FinanceService.ratesStream;
});

/// Dashboard AI gündem kartı.
final dashboardNewsProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((ref) {
  return FirestoreService.newsStream();
});
