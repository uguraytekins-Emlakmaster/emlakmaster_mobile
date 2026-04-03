/// Son görüşmeye bağlı ham transkript meta verisi (Firestore `lastCallTranscript`).
/// Özet alanı (`lastCallSummary`) ve kural sinyalleri ayrı kalır; bu yalnızca STT/ASR çıktısı için hazırlık.
library call_transcript_snapshot;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Transkriptin kaynağı (gelecekte STT sağlayıcı eşlemesi).
enum TranscriptSource {
  unknown('unknown'),
  /// Elle yapıştırılmış veya düzenlenmiş
  manual('manual'),
  /// On-device veya kontrollü STT el sıkışması ([TranscriptIngestPayload.speechToTextHandoff]).
  localSpeechToText('local_speech_to_text'),
  /// Yüklenen dosyadan çıkarılmış transkript
  fileUpload('file_upload'),
  /// Arama kaydı → arka plan transkripsiyon (gelecek boru hattı)
  recordingPipeline('recording_pipeline'),
  whisper('whisper'),
  deepgram('deepgram'),
  googleSpeech('google_speech'),
  /// Şema / UI hazırlığı; henüz gerçek veri yok
  placeholder('placeholder');

  const TranscriptSource(this.storageId);
  final String storageId;

  static TranscriptSource fromStorageId(String? id) {
    if (id == null || id.isEmpty) return TranscriptSource.unknown;
    return TranscriptSource.values.firstWhere(
      (e) => e.storageId == id,
      orElse: () => TranscriptSource.unknown,
    );
  }
}

/// İşleme yaşam döngüsü.
enum TranscriptStatus {
  /// Kayıt yok veya kullanılmıyor
  none('none'),
  pending('pending'),
  processing('processing'),
  ready('ready'),
  failed('failed');

  const TranscriptStatus(this.storageId);
  final String storageId;

  static TranscriptStatus fromStorageId(String? id) {
    if (id == null || id.isEmpty) return TranscriptStatus.none;
    return TranscriptStatus.values.firstWhere(
      (e) => e.storageId == id,
      orElse: () => TranscriptStatus.none,
    );
  }
}

/// Müşteri dokümanındaki `lastCallTranscript` haritası.
class CallTranscriptSnapshot {
  const CallTranscriptSnapshot({
    this.rawTranscriptText,
    this.transcriptSource = TranscriptSource.unknown,
    this.transcriptLanguage,
    this.transcriptCreatedAt,
    this.transcriptConfidence,
    this.transcriptStatus = TranscriptStatus.none,
    this.externalReferenceId,
    this.sourceMetadata,
  });

  final String? rawTranscriptText;
  final TranscriptSource transcriptSource;
  /// BCP-47 veya kısa kod, örn. `tr`, `tr-TR`
  final String? transcriptLanguage;
  final DateTime? transcriptCreatedAt;
  /// 0.0–1.0; STT güveni
  final double? transcriptConfidence;
  final TranscriptStatus transcriptStatus;
  /// Sağlayıcı iş / dosya kimliği (opsiyonel)
  final String? externalReferenceId;
  /// Ek iz düşümü (Firestore: düz string map)
  final Map<String, String>? sourceMetadata;

  static CallTranscriptSnapshot? tryFromFirestoreMap(dynamic raw) {
    if (raw == null || raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final text = (m['rawTranscriptText'] as String?)?.trim();
    final status = TranscriptStatus.fromStorageId(m['transcriptStatus'] as String?);
    if ((text == null || text.isEmpty) && status == TranscriptStatus.none) {
      return null;
    }
    final conf = m['transcriptConfidence'];
    return CallTranscriptSnapshot(
      rawTranscriptText: (text == null || text.isEmpty) ? null : text,
      transcriptSource: TranscriptSource.fromStorageId(m['transcriptSource'] as String?),
      transcriptLanguage: m['transcriptLanguage'] as String?,
      transcriptCreatedAt: _ts(m['transcriptCreatedAt']),
      transcriptConfidence: conf is num ? conf.toDouble().clamp(0.0, 1.0) : null,
      transcriptStatus: status,
      externalReferenceId: _trimOrNull(m['externalReferenceId'] as String?),
      sourceMetadata: _stringMapFromFirestore(m['transcriptSourceMetadata']),
    );
  }

  static String? _trimOrNull(String? s) {
    if (s == null) return null;
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  static Map<String, String>? _stringMapFromFirestore(dynamic v) {
    if (v is! Map) return null;
    final out = <String, String>{};
    v.forEach((key, val) {
      if (key is String) {
        out[key] = val?.toString() ?? '';
      }
    });
    return out.isEmpty ? null : out;
  }

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      if (rawTranscriptText != null && rawTranscriptText!.isNotEmpty)
        'rawTranscriptText': rawTranscriptText,
      'transcriptSource': transcriptSource.storageId,
      if (transcriptLanguage != null && transcriptLanguage!.trim().isNotEmpty)
        'transcriptLanguage': transcriptLanguage!.trim(),
      if (transcriptCreatedAt != null) 'transcriptCreatedAt': Timestamp.fromDate(transcriptCreatedAt!),
      if (transcriptConfidence != null) 'transcriptConfidence': transcriptConfidence,
      'transcriptStatus': transcriptStatus.storageId,
      if (externalReferenceId != null && externalReferenceId!.trim().isNotEmpty)
        'externalReferenceId': externalReferenceId!.trim(),
      if (sourceMetadata != null && sourceMetadata!.isNotEmpty)
        'transcriptSourceMetadata': sourceMetadata,
    };
  }
}
