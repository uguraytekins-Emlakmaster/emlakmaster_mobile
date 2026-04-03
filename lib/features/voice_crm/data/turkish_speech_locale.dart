import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:speech_to_text/speech_to_text.dart';

/// [localeId] tr-TR / tr_TR vb. Türkçe tanıma için uygun mu?
bool isTurkishLocaleId(String localeId) {
  final lower = localeId.toLowerCase();
  return lower.startsWith('tr-') ||
      lower.startsWith('tr_') ||
      lower == 'tr' ||
      lower.startsWith('tr@');
}

/// Cihazda yüklü [locales] listesinden Türkçe (Türkiye) tanıma dilini seçer.
/// iOS: genelde `tr-TR`, Android: `tr_TR` vb. farklılık gösterebilir.
Future<String> resolveTurkishLocaleId(SpeechToText speech) async {
  try {
    final locales = await speech.locales();
    if (locales.isEmpty) {
      if (kDebugMode) {
        debugPrint('[TurkishSpeechLocale] locales empty → fallback tr_TR');
      }
      return 'tr_TR';
    }
    final ids = locales.map((e) => e.localeId).toList();
    if (kDebugMode) {
      debugPrint('[TurkishSpeechLocale] device locales (${ids.length}): $ids');
    }
    const preferredOrder = <String>[
      'tr-TR',
      'tr_TR',
      'tr_TR@Turkish',
      'tr_TUR',
      'tr-tur',
    ];
    for (final p in preferredOrder) {
      if (ids.contains(p)) {
        if (kDebugMode) debugPrint('[TurkishSpeechLocale] selected exact: $p');
        _warnIfNotTurkish(p);
        return p;
      }
    }
    for (final l in locales) {
      final id = l.localeId;
      final lower = id.toLowerCase();
      if (lower.startsWith('tr-') || lower.startsWith('tr_')) {
        if (kDebugMode) debugPrint('[TurkishSpeechLocale] selected prefix match: $id');
        _warnIfNotTurkish(id);
        return id;
      }
    }
    final fallback = locales.first.localeId;
    if (kDebugMode) {
      debugPrint(
        '[TurkishSpeechLocale] WARNING: Turkish not in device list; '
        'using first available: $fallback',
      );
    }
    _warnIfNotTurkish(fallback);
    return fallback;
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[TurkishSpeechLocale] error: $e\n$st');
    }
  }
  if (kDebugMode) debugPrint('[TurkishSpeechLocale] fallback tr_TR');
  return 'tr_TR';
}

void _warnIfNotTurkish(String localeId) {
  if (kDebugMode && !isTurkishLocaleId(localeId)) {
    debugPrint(
      '[TurkishSpeechLocale] WARNING: active locale "$localeId" is not Turkish — '
      'speech quality may be poor. Check device speech languages.',
    );
  }
}
