import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Aynı başlık + fiyat + konum → aynı grup (farklı platformlardan duplikasyon).
abstract final class DuplicateGrouping {
  DuplicateGrouping._();

  static String normalizeTitle(String title) =>
      title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String normalizeLocation(String location) =>
      location.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String normalizePriceKey(double price) => price.toStringAsFixed(2);

  /// Deterministik grup kimliği (hash tabanlı).
  static String computeGroupId({
    required String title,
    required double price,
    required String location,
  }) {
    final payload = utf8.encode(
      '${normalizeTitle(title)}|${normalizePriceKey(price)}|${normalizeLocation(location)}',
    );
    final digest = sha256.convert(payload);
    return 'dg_${digest.toString().substring(0, 24)}';
  }
}
