/// Zenginleştirme girdisi — manuel özet kaynağı ile AI bağlamını ayırır.
/// Deterministik CRM (`lastCallSummary`, `lastCallSummarySignals`) yalnızca kayıt akışındaki özetten gelir.
library post_call_ai_enrichment_input;

import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';

/// Güvenli zenginleştirme modları (debug / Firestore `enrichmentInputMode`).
enum PostCallAiEnrichmentInputMode {
  /// Yalnız manuel özet; sinyaller özetten türetilir.
  summaryOnly('summary_only'),

  /// Özet + transkript; AI bağlamı yapılandırılmış birleşim, sinyaller birleşik metinden (yalnızca AI katmanı).
  summaryPlusTranscript('summary_plus_transcript'),

  /// Yalnız transkript (özet boş); AI zenginleştirmesi transkriptten, CRM sinyali **uydurulmaz** (fallback).
  transcriptOnly('transcript_only');

  const PostCallAiEnrichmentInputMode(this.storageId);
  final String storageId;

  static PostCallAiEnrichmentInputMode? tryParse(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final e in PostCallAiEnrichmentInputMode.values) {
      if (e.storageId == id) return e;
    }
    return null;
  }
}

/// Birleşik zenginleştirme girdisi — string birleştirme burada merkezi.
class PostCallAiEnrichmentInput {
  const PostCallAiEnrichmentInput._({
    required this.mode,
    required this.summaryForCrm,
    this.transcriptRaw,
  });

  /// Kayıtlı manuel özet ile aynı metin (CRM kaynak doğruluğu).
  final String summaryForCrm;
  final String? transcriptRaw;
  final PostCallAiEnrichmentInputMode mode;

  /// Özet + transkript için sabit ayraç (sunucu ile uyumlu etiket).
  static const String transcriptSectionLabel = '— Transkript —';

  factory PostCallAiEnrichmentInput.resolve({
    required String summary,
    String? transcript,
  }) {
    final s = summary.trim();
    final t = transcript?.trim() ?? '';
    final mode = _resolveMode(s, t);
    return PostCallAiEnrichmentInput._(
      mode: mode,
      summaryForCrm: summary,
      transcriptRaw: t.isEmpty ? null : t,
    );
  }

  static PostCallAiEnrichmentInputMode _resolveMode(String sTrim, String tTrim) {
    if (sTrim.isEmpty && tTrim.isEmpty) {
      return PostCallAiEnrichmentInputMode.summaryOnly;
    }
    if (sTrim.isNotEmpty && tTrim.isEmpty) {
      return PostCallAiEnrichmentInputMode.summaryOnly;
    }
    if (sTrim.isNotEmpty && tTrim.isNotEmpty) {
      return PostCallAiEnrichmentInputMode.summaryPlusTranscript;
    }
    return PostCallAiEnrichmentInputMode.transcriptOnly;
  }

  /// Heuristic / Cloud için tek metin bağlamı (birleştirme tek yerde).
  String get enrichmentContextText {
    final s = summaryForCrm.trim();
    final t = transcriptRaw?.trim() ?? '';
    switch (mode) {
      case PostCallAiEnrichmentInputMode.summaryOnly:
        return summaryForCrm;
      case PostCallAiEnrichmentInputMode.transcriptOnly:
        return transcriptRaw ?? '';
      case PostCallAiEnrichmentInputMode.summaryPlusTranscript:
        if (t.isEmpty) return summaryForCrm;
        if (s.isEmpty) return t;
        return '$s\n\n$transcriptSectionLabel\n$t';
    }
  }

  /// Sezgisel zenginleştirmede kullanılacak sinyaller.
  /// [transcriptOnly]: CRM sinyali **türetilmez** (deterministik motoru taklit etmeyiz).
  PostCallCrmSignals? signalsForAiHeuristicLayer() {
    final ctx = enrichmentContextText.trim();
    switch (mode) {
      case PostCallAiEnrichmentInputMode.summaryOnly:
        if (summaryForCrm.trim().isEmpty) return null;
        return extractPostCallCrmSignals(summaryForCrm);
      case PostCallAiEnrichmentInputMode.summaryPlusTranscript:
        if (ctx.isEmpty) return null;
        return extractPostCallCrmSignals(ctx);
      case PostCallAiEnrichmentInputMode.transcriptOnly:
        return PostCallCrmSignals.fallback();
    }
  }
}
