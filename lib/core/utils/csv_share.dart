import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// CSV içeriğini gerçek bir `.csv` dosyasına yazıp sistem paylaşım sayfasını açar.
///
/// Pano kopyalamanın aksine bu, kullanıcıya gerçek bir dosya (Dosyalar'a kaydet,
/// e-posta eki, WhatsApp belgesi vb.) sunar. Başarısızsa `false` döner; çağıran
/// tarafta panoya kopyalama gibi bir yedeğe düşülebilir.
Future<bool> shareCsvAsFile({
  required String csv,
  required String fileName,
  String? subject,
}) async {
  try {
    final dir = await getTemporaryDirectory();
    final safeName = fileName.endsWith('.csv') ? fileName : '$fileName.csv';
    final file = File('${dir.path}/$safeName');
    await file.writeAsString(csv, flush: true);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv', name: safeName)],
        subject: subject,
      ),
    );
    return result.status == ShareResultStatus.success ||
        result.status == ShareResultStatus.dismissed;
  } catch (e, st) {
    if (kDebugMode) debugPrint('shareCsvAsFile: $e $st');
    return false;
  }
}

/// `gorusme_kayitlari_2026-06-02_1437.csv` biçiminde dosya adı üretir.
String timestampedCsvName(String prefix, [DateTime? now]) {
  final t = now ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${prefix}_${t.year}-${two(t.month)}-${two(t.day)}_'
      '${two(t.hour)}${two(t.minute)}.csv';
}
