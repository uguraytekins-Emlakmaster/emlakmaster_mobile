/// Gelen transkript girdisi — STT, dosya yükleme veya manuel yapıştırma için ortak model.
/// [CallTranscriptSnapshot] ile eşlenir; CRM özeti alanına dokunulmaz.
library transcript_ingest_payload;

import 'package:emlakmaster_mobile/features/calls/domain/call_transcript_snapshot.dart';

/// Harici kaynaklardan gelen transkript için yapılandırılmış yük.
class TranscriptIngestPayload {
  const TranscriptIngestPayload._({
    required this.rawTranscriptText,
    required this.transcriptSource,
    this.transcriptLanguage,
    this.transcriptConfidence,
    required this.transcriptStatus,
    this.transcriptCreatedAt,
    this.externalReferenceId,
    this.sourceMetadata = const {},
  });

  final String rawTranscriptText;
  final TranscriptSource transcriptSource;
  /// BCP-47 veya kısa kod, örn. `tr`, `tr-TR`
  final String? transcriptLanguage;
  /// 0.0–1.0 (STT güveni)
  final double? transcriptConfidence;
  final TranscriptStatus transcriptStatus;
  final DateTime? transcriptCreatedAt;
  /// Sağlayıcı iş / dosya / oturum kimliği
  final String? externalReferenceId;
  /// Firestore-uyumlu düz anahtar–değer (debug ve entegrasyon izleri)
  final Map<String, String> sourceMetadata;

  /// Elle girilen veya yapıştırılan metin (post-call varsayılan yolu).
  factory TranscriptIngestPayload.manual({
    required String rawTranscriptText,
    String transcriptLanguage = 'tr',
  }) {
    return TranscriptIngestPayload._(
      rawTranscriptText: rawTranscriptText,
      transcriptSource: TranscriptSource.manual,
      transcriptLanguage: transcriptLanguage,
      transcriptCreatedAt: DateTime.now(),
      transcriptStatus: TranscriptStatus.ready,
    );
  }

  /// On-device veya kontrollü STT çıktısı — gerçek mikrofon entegrasyonu buraya bağlanır.
  factory TranscriptIngestPayload.speechToTextHandoff({
    required String rawTranscriptText,
    String transcriptLanguage = 'tr',
    double? transcriptConfidence,
    DateTime? transcriptCreatedAt,
    String? externalReferenceId,
    Map<String, String> sourceMetadata = const {},
  }) {
    return TranscriptIngestPayload._(
      rawTranscriptText: rawTranscriptText,
      transcriptSource: TranscriptSource.localSpeechToText,
      transcriptLanguage: transcriptLanguage,
      transcriptConfidence: transcriptConfidence,
      transcriptCreatedAt: transcriptCreatedAt ?? DateTime.now(),
      transcriptStatus: TranscriptStatus.ready,
      externalReferenceId: externalReferenceId,
      sourceMetadata: sourceMetadata,
    );
  }

  /// Yüklenen transkript dosyasından çıkarılmış metin.
  factory TranscriptIngestPayload.uploadedDocument({
    required String rawTranscriptText,
    String? transcriptLanguage,
    String? externalReferenceId,
    Map<String, String> sourceMetadata = const {},
  }) {
    return TranscriptIngestPayload._(
      rawTranscriptText: rawTranscriptText,
      transcriptSource: TranscriptSource.fileUpload,
      transcriptLanguage: transcriptLanguage,
      transcriptCreatedAt: DateTime.now(),
      transcriptStatus: TranscriptStatus.ready,
      externalReferenceId: externalReferenceId,
      sourceMetadata: sourceMetadata,
    );
  }

  /// Gelecek: arama kaydı → arka plan transkripsiyon işi tamamlandığında.
  factory TranscriptIngestPayload.recordingPipelineJob({
    required String rawTranscriptText,
    required String externalJobId,
    String? transcriptLanguage,
    Map<String, String> sourceMetadata = const {},
  }) {
    return TranscriptIngestPayload._(
      rawTranscriptText: rawTranscriptText,
      transcriptSource: TranscriptSource.recordingPipeline,
      transcriptLanguage: transcriptLanguage,
      transcriptCreatedAt: DateTime.now(),
      transcriptStatus: TranscriptStatus.ready,
      externalReferenceId: externalJobId,
      sourceMetadata: sourceMetadata,
    );
  }

  /// [CallTranscriptSnapshot] + Firestore `lastCallTranscript` için eşleme.
  CallTranscriptSnapshot toCallTranscriptSnapshot() {
    final trimmed = rawTranscriptText.trim();
    double? conf = transcriptConfidence;
    if (conf != null) {
      conf = conf.clamp(0.0, 1.0);
    }
    return CallTranscriptSnapshot(
      rawTranscriptText: trimmed.isEmpty ? null : trimmed,
      transcriptSource: transcriptSource,
      transcriptLanguage: transcriptLanguage,
      transcriptCreatedAt: transcriptCreatedAt ?? DateTime.now(),
      transcriptConfidence: conf,
      transcriptStatus: transcriptStatus,
      externalReferenceId: _trimOrNull(externalReferenceId),
      sourceMetadata: sourceMetadata.isEmpty ? null : Map<String, String>.from(sourceMetadata),
    );
  }

  static String? _trimOrNull(String? s) {
    if (s == null) return null;
    final t = s.trim();
    return t.isEmpty ? null : t;
  }
}
