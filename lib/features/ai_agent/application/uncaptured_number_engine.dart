import '../domain/axion_agent_models.dart';
import '../domain/axion_phone_matcher.dart';
import '../domain/axion_uncaptured_number.dart';

/// Kayıtsız Numara Motoru — saf, deterministik, AI'sız.
///
/// Çağrı geçmişinden CRM'de müşteri kaydı olmayan numaraları çıkarır.
/// Amaç: yoğunlukta hiçbir numaranın kaybolmaması; tek dokunuşla kayıt.
///
/// Kurallar:
/// - Yalnızca `customerId` bağlantısı OLMAYAN ve bilinen müşteri
///   telefonlarıyla EŞLEŞMEYEN çağrılar değerlendirilir.
/// - Aynı numaranın çağrıları gruplanır (son 10 hane anahtarı).
/// - Anlamsız/kısa numaralar (7 haneden az) atlanır.
/// - En son çağrı en üstte; sonuç sınırı sabittir.
abstract final class UncapturedNumberEngine {
  static const Duration defaultLookback = Duration(days: 14);
  static const int defaultMaxResults = 10;

  static List<AxionUncapturedNumber> detect({
    required List<AxionCallSnapshot> calls,
    required Set<String> knownPhoneKeys,
    required DateTime now,
    Duration lookback = defaultLookback,
    int maxResults = defaultMaxResults,
  }) {
    final cutoff = now.subtract(lookback);
    final groups = <String, _NumberGroup>{};

    for (final call in calls) {
      if (call.customerId != null && call.customerId!.isNotEmpty) continue;
      final raw = call.phoneNumber?.trim() ?? '';
      if (raw.isEmpty) continue;
      if (call.at.isBefore(cutoff)) continue;

      final key = AxionPhoneMatcher.normalize(raw);
      if (!AxionPhoneMatcher.isMeaningful(key)) continue;
      if (knownPhoneKeys.contains(key)) continue;

      final g = groups.putIfAbsent(key, () => _NumberGroup(key));
      g.add(call, raw);
    }

    final result = [for (final g in groups.values) g.build()]
      ..sort((a, b) => b.lastCallAt.compareTo(a.lastCallAt));
    if (result.length <= maxResults) return result;
    return result.sublist(0, maxResults);
  }
}

class _NumberGroup {
  _NumberGroup(this.key);

  final String key;
  int callCount = 0;
  int missedCount = 0;
  DateTime? lastCallAt;
  bool lastCallWasMissed = false;
  String displayNumber = '';
  final List<({String id, DateTime at})> _docs = [];

  void add(AxionCallSnapshot call, String rawNumber) {
    callCount++;
    if (call.isMissedOrNoAnswer) missedCount++;
    if (lastCallAt == null || call.at.isAfter(lastCallAt!)) {
      lastCallAt = call.at;
      lastCallWasMissed = call.isMissedOrNoAnswer;
      displayNumber = rawNumber;
    }
    _docs.add((id: call.id, at: call.at));
  }

  AxionUncapturedNumber build() {
    _docs.sort((a, b) => b.at.compareTo(a.at));
    return AxionUncapturedNumber(
      normalizedKey: key,
      displayNumber: displayNumber,
      callCount: callCount,
      missedCount: missedCount,
      lastCallAt: lastCallAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      lastCallWasMissed: lastCallWasMissed,
      callDocIds: [for (final d in _docs) d.id],
    );
  }
}
