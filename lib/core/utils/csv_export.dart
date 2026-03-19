import 'package:cloud_firestore/cloud_firestore.dart';

/// Çağrı listesini CSV satırlarına dönüştürür (başlık + veri). UTF-8 BOM ile Excel uyumlu.
String callsToCsv(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
  const bom = '\uFEFF';
  final sb = StringBuffer(bom);
  sb.writeln('id,agentId,durationSec,outcome,createdAt');
  for (final d in docs) {
    final data = d.data();
    final id = d.id;
    final agentId = data['agentId'] as String? ?? '';
    final duration = data['durationSec'] as num?;
    final outcome = data['outcome'] as String? ?? data['callOutcome'] as String? ?? '';
    final createdAt = data['createdAt'];
    String createdAtStr = '';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      createdAtStr = dt.toIso8601String();
    }
    sb.writeln('"$id","$agentId",${duration?.toInt() ?? ''},"$outcome","$createdAtStr"');
  }
  return sb.toString();
}

/// Çağrı listesini telefon ve yön dahil CSV'ye dönüştürür (danışman çağrı listesi / toplu SMS için).
String callsToCsvWithPhones(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
  const bom = '\uFEFF';
  final sb = StringBuffer(bom);
  sb.writeln('id,tarih,yon,telefon,sure_sn,sonuc,createdAt');
  for (final d in docs) {
    final data = d.data();
    final id = d.id;
    final direction = data['direction'] as String? ?? data['callDirection'] as String? ?? '';
    final phone = data['phoneNumber'] as String? ?? data['phone'] as String? ?? '';
    final duration = data['durationSec'] as num?;
    final outcome = data['outcome'] as String? ?? data['callOutcome'] as String? ?? '';
    final createdAt = data['createdAt'];
    String createdAtStr = '';
    String dateStr = '';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      createdAtStr = dt.toIso8601String();
      dateStr = '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    sb.writeln('"$id","$dateStr","$direction","$phone",${duration?.toInt() ?? ''},"$outcome","$createdAtStr"');
  }
  return sb.toString();
}
