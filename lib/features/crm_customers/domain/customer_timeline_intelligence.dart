/// Müşteri detay “canlı zaman çizelgesi” — mevcut CRM verisinden üç kısa satır.
library customer_timeline_intelligence;

import 'package:emlakmaster_mobile/features/calls/domain/call_transcript_snapshot.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_ai_enrichment.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/crm_intelligence_explanations.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_insight_snapshot.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

/// Son temas · şu an ne önemli · sonraki adım (tek bakışta).
class CustomerTimelineIntelligenceLines {
  const CustomerTimelineIntelligenceLines({
    this.recentTouchpointLine,
    this.currentStatusLine,
    this.nextActionLine,
  });

  final String? recentTouchpointLine;
  final String? currentStatusLine;
  final String? nextActionLine;

  bool get hasAny =>
      _nonEmpty(recentTouchpointLine) ||
      _nonEmpty(currentStatusLine) ||
      _nonEmpty(nextActionLine);

  static bool _nonEmpty(String? s) => s != null && s.trim().isNotEmpty;
}

CustomerTimelineIntelligenceLines buildCustomerTimelineIntelligenceLines(
  CustomerInsightSnapshot insight,
) {
  final e = insight.entity;
  if (e == null) {
    final now = _trimOrNull(insight.heat.heatReasonSummary, 140);
    final next = _buildNextLine(insight);
    return CustomerTimelineIntelligenceLines(
      currentStatusLine: now,
      nextActionLine: next,
    );
  }

  String? recent = _buildRecentLineForEntity(e);
  if (e.lastCallTranscript != null &&
      e.lastCallTranscript!.transcriptStatus == TranscriptStatus.ready &&
      (e.lastCallTranscript!.rawTranscriptText?.trim().isNotEmpty ?? false)) {
    if (recent != null) {
      recent = '$recent · Ham kayıt';
    } else {
      recent = 'Ham transkript var; kısa çağrı özeti önerilir.';
    }
  }

  final now = _trimOrNull(
    explainHeatNarrative(e, insight.heat, insight.extras),
    140,
  );
  final next = _buildNextLine(insight);

  return CustomerTimelineIntelligenceLines(
    recentTouchpointLine: recent,
    currentStatusLine: now,
    nextActionLine: next,
  );
}

String? _buildRecentLineForEntity(CustomerEntity e) {
  final summary = e.lastCallSummary?.trim();
  if (summary != null && summary.isNotEmpty) {
    return 'Son kayıt: ${_truncate(summary, 100)}';
  }
  final ai = savedAiInsightSnippetTr(e.lastCallAiEnrichment);
  if (ai != null && ai.trim().isNotEmpty) {
    return 'AI içgörü: ${_truncate(ai.trim(), 90)}';
  }
  final vn = e.voiceNoteSummary?.trim();
  if (vn != null && vn.isNotEmpty) {
    return 'Ses özeti: ${_truncate(vn, 80)}';
  }
  final last = e.lastInteractionAt;
  if (last != null) {
    return 'Son temas: ${_relativeLastContactTr(last)}';
  }
  return null;
}

String? _buildNextLine(CustomerInsightSnapshot insight) {
  final label = insight.nextBest.labelTr.trim();
  final why = _trimOrNull(
    explainNextBestNarrative(insight.nextBest, insight.heat),
    95,
  );
  if (label.isEmpty && (why == null || why.isEmpty)) return null;
  if (why == null || why.isEmpty) return label;
  if (label.isEmpty) return why;
  return '$label — $why';
}

String _truncate(String s, int max) {
  final t = s.trim();
  if (t.length <= max) return t;
  var cut = t.substring(0, max);
  final sp = cut.lastIndexOf(' ');
  if (sp > 24) cut = cut.substring(0, sp);
  return '$cut…';
}

String? _trimOrNull(String? s, int max) {
  if (s == null) return null;
  final t = s.trim();
  if (t.isEmpty) return null;
  return _truncate(t, max);
}

String _relativeLastContactTr(DateTime last) {
  final days = DateTime.now().difference(last).inDays;
  if (days <= 0) return 'bugün';
  if (days == 1) return 'dün';
  if (days < 14) return '$days gün önce';
  if (days < 60) return '${days ~/ 7} hafta önce';
  return '${days ~/ 30} ay önce';
}
