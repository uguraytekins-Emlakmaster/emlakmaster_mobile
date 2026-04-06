import 'package:cloud_firestore/cloud_firestore.dart';

/// Çağrı listesini CSV satırlarına dönüştürür (başlık + veri). UTF-8 BOM ile Excel uyumlu.
String callsToCsv(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
  const bom = '\uFEFF';
  final sb = StringBuffer(bom);
  sb.writeln(
    'id,agentId,customerId,phoneNumber,source,handoffMode,outcome,quickOutcomeLabelTr,quickCaptureNote,captureCompletedAt,durationSec,createdAt',
  );
  for (final d in docs) {
    final data = d.data();
    final id = d.id;
    final agentId = data['agentId'] as String? ?? data['advisorId'] as String? ?? '';
    final customerId = data['customerId'] as String? ?? '';
    final phone = data['phoneNumber'] as String? ?? data['phone'] as String? ?? '';
    final source = data['source'] as String? ?? '';
    final handoff = data['handoffMode'] == true ? 'true' : '';
    final outcome = data['outcome'] as String? ?? data['callOutcome'] as String? ?? '';
    final quickLabel = data['quickOutcomeLabelTr'] as String? ?? '';
    final quickNote = (data['quickCaptureNote'] as String? ?? '').replaceAll('"', '""');
    final cap = data['captureCompletedAt'];
    String capStr = '';
    if (cap is Timestamp) capStr = cap.toDate().toIso8601String();
    final duration = data['durationSec'] as num?;
    final createdAt = data['createdAt'];
    String createdAtStr = '';
    if (createdAt is Timestamp) {
      createdAtStr = createdAt.toDate().toIso8601String();
    }
    sb.writeln(
      '"$id","$agentId","$customerId","$phone","$source","$handoff","$outcome","$quickLabel","$quickNote","$capStr",${duration?.toInt() ?? ''},"$createdAtStr"',
    );
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
