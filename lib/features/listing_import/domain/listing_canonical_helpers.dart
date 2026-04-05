import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Firestore `listings` / [ListingRowView] ile uyumlu içerik özeti.
String computeListingContentHash({
  required String title,
  required double price,
  required String location,
}) {
  final raw = '${title.trim()}|${price.toStringAsFixed(2)}|${location.trim()}';
  final bytes = utf8.encode(raw);
  return sha256.convert(bytes).toString();
}
