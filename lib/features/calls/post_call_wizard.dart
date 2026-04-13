import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'dart:math' as math;

import 'package:emlakmaster_mobile/core/ai/ai_gate.dart';
import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/resilience/safe_operation.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/widgets/ai_usage_indicator.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/widgets/upgrade_bottom_sheet.dart';
import 'package:emlakmaster_mobile/features/monetization/services/usage_service.dart';
import 'package:emlakmaster_mobile/features/contact_save/presentation/widgets/save_contact_sheet.dart';
import 'package:emlakmaster_mobile/features/crm_customers/domain/customer_heat_score.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_insight_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_ai_enrichment_service.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_transcript_ingestion.dart';
import 'package:emlakmaster_mobile/features/calls/domain/transcript_ingest_payload.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_ai_enrichment.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_ai_enrichment_input.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:emlakmaster_mobile/features/voice_crm/presentation/widgets/push_to_talk_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Çağrı özeti ana yol olarak manuel düzenlenir. Push-to-Talk STT metni özete eklenir; aynı metin
/// (kullanıcı transkript alanını elle değiştirmediyse) `lastCallTranscript` için [mergeSpeechToTextHandoffIfPresent] ile kaydedilir.
/// Duygu durumu: AI görüşme tonuna göre 5 seçenekten biri.
enum CallSentiment {
  veryPositive, // 🤩 Çok Heyecanlı/Pozitif
  uncertain, // 🤔 Kararsız/Düşünceli
  analytical, // 🧐 Analitik/Sorgulayıcı
  lowInterest, // 📉 Düşük İlgi
  urgent, // ⚠️ Acelesi Var
}

/// Arama bittiğinde AI'ın çıkardığı 4 kritik alan + sonraki adım + duygu.
class CallExtraction {
  final String customerIntent;
  final String budgetRange;
  final String preferredRegions;
  final String urgency;
  final String nextStepSuggestion;
  final CallSentiment sentiment;
  final String fullSummary;

  const CallExtraction({
    required this.customerIntent,
    required this.budgetRange,
    required this.preferredRegions,
    required this.urgency,
    required this.nextStepSuggestion,
    required this.sentiment,
    required this.fullSummary,
  });
}

class PostCallSummarySaveResult {
  const PostCallSummarySaveResult({
    required this.savedSuccessfully,
    required this.taskCreated,
    required this.customerLinked,
    required this.detachedCallSummarySaved,
    required this.aiLimited,
    this.firestoreCallId,
    this.customerId,
    this.callSummaryId,
  });

  final bool savedSuccessfully;
  final bool taskCreated;
  final bool customerLinked;
  final bool detachedCallSummarySaved;
  final bool aiLimited;
  final String? firestoreCallId;
  final String? customerId;
  final String? callSummaryId;
}

String _normalizeTranscriptLanguage(String? localeId) {
  final s = localeId?.trim();
  if (s == null || s.isEmpty) return 'tr';
  return s;
}

String sentimentToStorage(CallSentiment s) {
  switch (s) {
    case CallSentiment.veryPositive:
      return 'very_positive';
    case CallSentiment.uncertain:
      return 'uncertain';
    case CallSentiment.analytical:
      return 'analytical';
    case CallSentiment.lowInterest:
      return 'low_interest';
    case CallSentiment.urgent:
      return 'urgent';
  }
}

/// Tüm duygu durumları (çeşitlilik için).
const List<CallSentiment> _allSentiments = CallSentiment.values;

/// Demo görüşme metninden (ileride Whisper + GPT-4o ile gerçek) ayıklama simülasyonu.
/// Duygu: metin uzunluğu/içeriğe göre simüle; demo için 5 durumdan biri seçilir.
CallExtraction extractFromConversation(String conversationText) {
  final rnd = math.Random(conversationText.hashCode);
  final sentiment = _allSentiments[rnd.nextInt(_allSentiments.length)];

  final summaries = {
    CallSentiment.veryPositive:
        'Müşteri 3+1 oturumluk, Bağlar/Kayapınar bölgesinde 5-8M TL bütçeyle 15 gün içinde taşınmak istiyor. Çok istekli.',
    CallSentiment.uncertain:
        'Müşteri 3+1 düşünüyor, bütçe 5-8M TL. Bağlar/Kayapınar ilgi var ama henüz karar vermedi.',
    CallSentiment.analytical:
        'Müşteri 3+1 için detaylı sorular sordu: metrekare, aidat, deprem. 5-8M TL, Bağlar/Kayapınar.',
    CallSentiment.lowInterest:
        'Müşteri 3+1 ve 5-8M TL dedi ama acil değil; takip listesine alındı.',
    CallSentiment.urgent:
        'Müşteri 15 gün içinde taşınmak istiyor, 3+1 Bağlar/Kayapınar 5-8M TL. Sıcak fırsat.',
  };

  final nextSteps = {
    CallSentiment.veryPositive:
        'Müşteriye yarın sabah portföydeki 3+1 Bağlar dairesinin sunumunu gönder.',
    CallSentiment.uncertain: 'Bir hafta içinde tekrar arayıp kararını sor.',
    CallSentiment.analytical:
        'Detaylı fiyat/kullanım özeti ve kıyaslama tablosu hazırla.',
    CallSentiment.lowInterest:
        'Takip listesine ekle; 2 hafta sonra hatırlatma notu at.',
    CallSentiment.urgent: 'Müşteriye bugün içinde 3 uygun ilan listesi gönder.',
  };

  return CallExtraction(
    customerIntent: 'Oturumluk',
    budgetRange: '5M - 8M TL arası',
    preferredRegions: 'Bağlar, Kayapınar',
    urgency: '15 gün içinde taşınmak istiyor',
    nextStepSuggestion: nextSteps[sentiment]!,
    sentiment: sentiment,
    fullSummary: summaries[sentiment]!,
  );
}

class PostCallWizardScreen extends ConsumerStatefulWidget {
  const PostCallWizardScreen({
    super.key,
    this.callDurationSec,
    this.callOutcome,
    this.linkedCustomerId,
    this.phoneNumber,
    this.callSessionId,
  });

  /// AI token optimizasyonu: kısa veya yanlış numara ise derin analiz atlanır.
  final int? callDurationSec;
  final String? callOutcome;

  /// Müşteri detaydan açılan aramada özet bu müşteriye bağlanır.
  final String? linkedCustomerId;

  /// Sistem telefonuna devredilen aramada kullanılan numara (CRM bağlamı).
  final String? phoneNumber;

  /// `calls` koleksiyonundaki handoff oturumu kimliği (opsiyonel).
  final String? callSessionId;

  @override
  ConsumerState<PostCallWizardScreen> createState() =>
      _PostCallWizardScreenState();
}

class _PostCallWizardScreenState extends ConsumerState<PostCallWizardScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzing = true;
  CallExtraction? _extraction;
  bool _isSaving = false;
  String? _saveError;

  /// Kayıtta kullanılacak düzenlenebilir özet (AI metni + sesle eklenenler).
  final TextEditingController _summaryController = TextEditingController();

  /// v1: manuel / yapıştırılmış ham transkript (`lastCallTranscript`); özet alanından ayrı.
  final TextEditingController _transcriptController = TextEditingController();

  /// Yalnızca programatik (PTT) eklemelerde true; kullanıcı transkript alanını düzenlerse false.
  bool _suppressTranscriptUserEdit = false;

  /// Elle yapıştırma / düzenleme yapıldıysa true; yalnızca PTT ile dolduysa false → kayıtta STT handoff.
  bool _transcriptUserEditedOnce = false;
  double? _lastSttConfidence;
  String? _lastSttLocaleId;
  String _voiceStatus = '';
  String? _voiceReviewHint;

  late AnimationController _progressController;

  static const String _demoConversation =
      'Müşteri 3+1 daire arıyor, oturumluk. Bütçe 5 ile 8 milyon lira arası. '
      'Bağlar ve Kayapınar bölgelerini istiyor. 15 gün içinde taşınmak istediğini söyledi.';

  bool get _skipFullAnalysis {
    final outcome = widget.callOutcome ?? AppConstants.callOutcomeCompleted;
    if (outcome == AppConstants.callOutcomeSystemHandoff) return false;
    final duration = widget.callDurationSec ?? 999;
    return duration < AppConstants.minCallDurationSecForAnalysis ||
        outcome == AppConstants.callOutcomeWrongNumber;
  }

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    if ((widget.callOutcome ?? '') == AppConstants.callOutcomeSystemHandoff) {
      _isAnalyzing = false;
      _extraction = const CallExtraction(
        customerIntent: '—',
        budgetRange: '—',
        preferredRegions: '—',
        urgency: '—',
        nextStepSuggestion: 'Görüşme notlarınızı kaydedin.',
        sentiment: CallSentiment.uncertain,
        fullSummary: '',
      );
    } else if (_skipFullAnalysis) {
      _isAnalyzing = false;
      _extraction = null;
    } else {
      _progressController.forward();
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        final ext = extractFromConversation(_demoConversation);
        _summaryController.text = ext.fullSummary;
        setState(() {
          _isAnalyzing = false;
          _extraction = ext;
        });
      });
    }
    _transcriptController.addListener(_onTranscriptUserEdit);
  }

  void _onTranscriptUserEdit() {
    if (_suppressTranscriptUserEdit) return;
    _transcriptUserEditedOnce = true;
  }

  @override
  void dispose() {
    _transcriptController.removeListener(_onTranscriptUserEdit);
    _progressController.dispose();
    _summaryController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  void _onPostCallSpeechResult(PushToTalkSpeechResult r) {
    final text = r.text?.trim();
    if (text == null || text.isEmpty) {
      if (r.noSpeechAfterRetries && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Sizi duyamadım, tekrar deneyebilirsiniz. Özeti elle de yazabilirsiniz.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppThemeExtension.of(context).surfaceElevated,
          ),
        );
      }
      return;
    }
    final cur = _summaryController.text.trim();
    if (cur.isEmpty) {
      _summaryController.text = text;
    } else if (!cur.contains(text)) {
      _summaryController.text = '$cur\n$text';
    }
    _appendTranscriptFromStt(text, r);
    setState(() {
      _voiceReviewHint = (r.shouldReview || r.textFromPartialOnly)
          ? 'Ses metni aktarıldı; duraksamalı konuşmalarda küçük farklar olabilir. Kaydetmeden önce göz atmanız yeterli.'
          : null;
    });
  }

  /// PTT metnini özetle aynı kuralda transkript alanına yazar (ExpansionTile kapalıyken görünmez);
  /// Kayıtta [mergeSpeechToTextHandoffIfPresent] yalnızca [_transcriptUserEditedOnce] false iken kullanılır.
  void _appendTranscriptFromStt(String text, PushToTalkSpeechResult r) {
    _suppressTranscriptUserEdit = true;
    try {
      final tcur = _transcriptController.text.trim();
      if (tcur.isEmpty) {
        _transcriptController.text = text;
      } else if (!tcur.contains(text)) {
        _transcriptController.text = '$tcur\n$text';
      }
      _lastSttConfidence = r.confidence;
      _lastSttLocaleId = r.activeLocaleId;
    } finally {
      _suppressTranscriptUserEdit = false;
    }
  }

  Future<void> _onSaveAndClose() async {
    if (_extraction == null || _isSaving) return;
    final summaryText = _summaryController.text.trim();
    HapticFeedback.mediumImpact();
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    final agentId = ref.read(currentUserProvider).valueOrNull?.uid;
    final customerId = widget.linkedCustomerId;
    final callSessionId = widget.callSessionId?.trim();
    if (kDebugMode) {
      AppLogger.d(
        '[post_call_wizard] save start customer=${customerId ?? '-'} '
        'callSession=${callSessionId ?? '-'} summaryChars=${summaryText.length}',
      );
    }
    if (agentId == null || agentId.isEmpty) {
      setState(() {
        _isSaving = false;
        _saveError = 'Oturum bulunamadı. Giriş yapıp tekrar deneyin.';
      });
      return;
    }
    Map<String, dynamic>? summarySignalsPayload;
    try {
      if (summaryText.isNotEmpty) {
        summarySignalsPayload =
            extractPostCallCrmSignals(summaryText).toFirestorePayload();
      }
    } catch (_) {
      summarySignalsPayload = null;
    }

    try {
      final customerLinked = customerId != null && customerId.isNotEmpty;
      String? callSummaryId;
      await runWithResilience(
        ref: ref as Ref<Object?>,
        () async {
          if (customerLinked) {
            await FirestoreService.saveCallExtractionToCustomer(
              customerId: customerId,
              assignedAgentId: agentId,
              customerIntent: _extraction!.customerIntent,
              budgetRange: _extraction!.budgetRange,
              preferredRegions: _extraction!.preferredRegions,
              urgency: _extraction!.urgency,
              nextStepSuggestion: _extraction!.nextStepSuggestion,
              sentiment: sentimentToStorage(_extraction!.sentiment),
              fullSummary: summaryText,
              lastCallSummarySignals: summarySignalsPayload,
            );
            if (summaryText.isNotEmpty) {
              await FirestoreService.saveNote(
                customerId: customerId,
                content: '📞 Çağrı özeti (AI): $summaryText',
                advisorId: agentId,
              );
            }
          }
          callSummaryId = await FirestoreService.saveStructuredCallSummaryDoc(
            assignedAgentId: agentId,
            callId: callSessionId,
            customerId: customerLinked ? customerId : null,
            phoneNumber: widget.phoneNumber,
            customerIntent: _extraction!.customerIntent,
            budgetRange: _extraction!.budgetRange,
            preferredRegions: _extraction!.preferredRegions,
            urgency: _extraction!.urgency,
            nextStepSuggestion: _extraction!.nextStepSuggestion,
            sentiment: sentimentToStorage(_extraction!.sentiment),
            fullSummary: summaryText,
            detachedFromCustomer: !customerLinked,
          );
          if (callSessionId != null &&
              callSessionId.isNotEmpty &&
              summaryText.isNotEmpty) {
            await FirestoreService.mergePostCallSummaryIntoCallRecord(
              callSessionId: callSessionId,
              fullSummary: summaryText,
              nextStepSuggestion: _extraction!.nextStepSuggestion,
              sentiment: sentimentToStorage(_extraction!.sentiment),
              detachedFromCustomer: !customerLinked,
              customerId: customerLinked ? customerId : null,
            );
          }
          await FirestoreService.incrementAgentStatsAfterSummary(
            agentId: agentId,
          );
        },
      );
      if (!mounted) return;
      AppLogger.i(
        customerLinked
            ? '[post_call_wizard] linked summary saved'
            : '[post_call_wizard] detached summary saved',
      );
      final enrichCustomerId = customerId;
      final summaryForAi = summaryText;
      final transcriptForAi = _transcriptController.text.trim();
      final sentimentForAi = sentimentToStorage(_extraction!.sentiment);
      CustomerHeatLevel? heatForEnrich;
      if (customerLinked) {
        try {
          final ent =
              await ref.read(customerEntityByIdProvider(customerId).future);
          if (ent != null) {
            heatForEnrich = computeCustomerHeat(ent).heatLevel;
          }
        } catch (_) {}
        if (transcriptForAi.isNotEmpty) {
          try {
            if (!_transcriptUserEditedOnce) {
              await PostCallTranscriptIngestion
                  .mergeSpeechToTextHandoffIfPresent(
                customerId: customerId,
                rawTranscriptText: transcriptForAi,
                transcriptLanguage:
                    _normalizeTranscriptLanguage(_lastSttLocaleId),
                transcriptConfidence: _lastSttConfidence,
                sourceMetadata: const {'channel': 'post_call_ptt'},
              );
            } else {
              await PostCallTranscriptIngestion.mergePayloadIfPresent(
                customerId: customerId,
                payload: TranscriptIngestPayload.manual(
                  rawTranscriptText: transcriptForAi,
                ),
              );
            }
          } catch (e, st) {
            AppLogger.w('Transkript Firestore kaydı atlandı', e, st);
          }
        }
      }
      if (!mounted) return;
      final enrichmentInput = PostCallAiEnrichmentInput.resolve(
        summary: summaryForAi,
        transcript: transcriptForAi.isEmpty ? null : transcriptForAi,
      );
      if (kDebugMode) {
        AppLogger.d(
          'PostCall save path: mode=${enrichmentInput.mode.storageId} '
          'transcriptChars=${transcriptForAi.length} sttHandoff=${transcriptForAi.isNotEmpty}',
        );
      }
      final featureMap = ref.read(featureFlagsProvider).valueOrNull;
      final callSummaryEnabled =
          featureMap?[AppConstants.keyFeatureCallSummary] ?? true;
      final allowRemote = AiGate.allowPostCallRemote(
        input: enrichmentInput,
        featureCallSummaryEnabled: callSummaryEnabled,
        callDurationSec: widget.callDurationSec,
      );
      final usageService = ref.read(usageServiceProvider);
      await usageService.warmUp();
      final canUseAi = usageService.canUseAi();
      var aiLimited = false;
      if (!canUseAi) {
        aiLimited = true;
        AnalyticsService.instance.logEvent(
          AnalyticsEvents.limitReachedAi,
          {AnalyticsEvents.paramFeature: 'ai_analysis'},
        );
        if (!mounted) return;
        await showUpgradeBottomSheet(context, feature: 'ai_analysis');
      } else {
        await usageService.incrementAiUsage();
        if (customerLinked) {
          Future.microtask(() async {
            try {
              final enrichment =
                  await PostCallAiEnrichmentService.instance.enrich(
                input: enrichmentInput,
                sentimentStorage: sentimentForAi,
                heatLevel: heatForEnrich,
                allowRemoteModel: allowRemote,
              );
              await FirestoreService.mergePostCallAiEnrichment(
                enrichCustomerId!,
                enrichment.toFirestoreMap(),
              );
            } catch (e, stack) {
              AppLogger.e('Post-call AI enrichment merge failed', e, stack);
            }
          });
        }
      }
      ref.invalidate(consultantCallsStreamProvider);
      ref.invalidate(customerListForAgentProvider);
      if (customerLinked) {
        ref.invalidate(customerInsightProvider(customerId));
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final result = PostCallSummarySaveResult(
        savedSuccessfully: true,
        taskCreated: false,
        customerLinked: customerLinked,
        detachedCallSummarySaved: !customerLinked,
        aiLimited: aiLimited,
        firestoreCallId: callSessionId,
        customerId: customerLinked ? customerId : null,
        callSummaryId: callSummaryId,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.customerLinked
                ? 'Çağrı özeti CRM müşterisine kaydedildi.'
                : 'Çağrı özeti müşteri bağlantısı olmadan çağrı kaydı olarak saklandı.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go(AppRouter.routeHome);
    } catch (e, st) {
      if (!mounted) return;
      AppLogger.e('PostCallWizard save failed', e, st);
      setState(() {
        _isSaving = false;
        _saveError = FirestoreService.userFacingErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppThemeExtension.of(context).background,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white70,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.pop();
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Çağrı Özeti Sihirbazı',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if ((widget.callOutcome ?? '') ==
                                AppConstants.callOutcomeSystemHandoff) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.phoneNumber != null &&
                                        widget.phoneNumber!.trim().isNotEmpty
                                    ? 'Gerçek arama cihazın telefonunda (${widget.phoneNumber!.trim()}) — süre burada ölçülmez.'
                                    : 'Gerçek arama cihazın telefonunda yapıldı; süre burada ölçülmez.',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white70,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const AiUsageIndicator(compact: true),
                  const SizedBox(height: 12),
                  if (_isAnalyzing) ...[
                    const _AnalyzingHeader(),
                    const SizedBox(height: 24),
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, _) => _AnalyzingProgressBar(
                        value: _progressController.value.clamp(0.0, 1.0),
                      ),
                    ),
                  ] else if (_skipFullAnalysis) ...[
                    const Expanded(
                      child: _SkippedAnalysisCard(),
                    ),
                  ] else if (_extraction != null) ...[
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _PostCallVoiceRow(
                              voiceStatus: _voiceStatus,
                              onSpeechResult: _onPostCallSpeechResult,
                              onPhaseChanged: (phase) {
                                if (mounted) {
                                  setState(() => _voiceStatus = phase);
                                }
                              },
                            ),
                            if (_voiceReviewHint != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: AppThemeExtension.of(context)
                                      .warning
                                      .withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: AppThemeExtension.of(context)
                                        .warning
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                      color:
                                          AppThemeExtension.of(context).warning,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _voiceReviewHint!,
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          fontSize: 12,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            _ResultSummaryWithSentiment(
                              extraction: _extraction!,
                              summaryController: _summaryController,
                              onSummaryEdited: () {
                                if (_voiceReviewHint != null) {
                                  setState(() => _voiceReviewHint = null);
                                }
                              },
                            ),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _summaryController,
                              builder: (context, value, _) {
                                return _SummarySignalsPreview(
                                  summaryText: value.text,
                                );
                              },
                            ),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _summaryController,
                              builder: (context, value, _) {
                                return ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _transcriptController,
                                  builder: (context, tvalue, _) {
                                    return _PostCallAiEnrichmentInsightPreview(
                                      summaryText: value.text,
                                      transcriptText: tvalue.text,
                                      sentimentStorage: sentimentToStorage(
                                        _extraction!.sentiment,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            Theme(
                              data: Theme.of(context)
                                  .copyWith(dividerColor: Colors.white24),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: Row(
                                  children: [
                                    Icon(
                                      Icons.subtitles_outlined,
                                      size: 18,
                                      color:
                                          AppThemeExtension.of(context).accent,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Transkript (opsiyonel)',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    'STT veya metin yapıştırın. Özet ana kayıt; transkript ayrı saklanır.',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                children: [
                                  TextField(
                                    controller: _transcriptController,
                                    maxLines: 6,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.92),
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor:
                                          Colors.white.withValues(alpha: 0.06),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.white
                                              .withValues(alpha: 0.12),
                                        ),
                                      ),
                                      hintText: 'Ham transkript…',
                                      hintStyle: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.35)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Kritik bilgiler',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ExtractionBentoGrid(extraction: _extraction!),
                            const SizedBox(height: 16),
                            _NextStepCard(
                                suggestion: _extraction!.nextStepSuggestion),
                            if (_saveError != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _saveError!,
                                style: TextStyle(
                                  color: AppThemeExtension.of(context).danger,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppThemeExtension.of(context).accent,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  disabledBackgroundColor: Colors.white24,
                                  disabledForegroundColor: Colors.white54,
                                ),
                                onPressed: _isSaving ? null : _onSaveAndClose,
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Text(
                                        'Özeti Kaydet',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () async {
                                String? name;
                                String? phone;
                                if (widget.linkedCustomerId != null) {
                                  final c = await ref.read(
                                    customerEntityByIdProvider(
                                            widget.linkedCustomerId!)
                                        .future,
                                  );
                                  name = c?.fullName;
                                  phone = c?.primaryPhone;
                                }
                                if (!context.mounted) return;
                                showSaveContactSheet(
                                  context,
                                  initialName: name,
                                  initialPhone: phone,
                                  initialNote:
                                      _summaryController.text.trim().isEmpty
                                          ? null
                                          : _summaryController.text.trim(),
                                  source: 'rehber_aramasi',
                                );
                              },
                              icon: const Icon(Icons.contact_phone_rounded,
                                  size: 20),
                              label: const Text(
                                  'Rehbere ve uygulamaya kaydet (sesli / manuel)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    AppThemeExtension.of(context).accent,
                                side: BorderSide(
                                    color:
                                        AppThemeExtension.of(context).accent),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ] else
                    const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Token optimizasyonu: kısa arama veya yanlış numara – AI analizi atlanır.
class _SkippedAnalysisCard extends StatelessWidget {
  const _SkippedAnalysisCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_off_rounded,
                size: 56, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              'AI analizi atlandı',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Çok kısa arama veya yanlış numara. Derinlemesine analiz yapılmadı; bütçe ve işlemci korundu.',
              style:
                  TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go(AppRouter.routeHome),
              icon: const Icon(Icons.home_rounded, size: 20),
              label: const Text('Ana sayfaya dön'),
              style: FilledButton.styleFrom(
                backgroundColor: AppThemeExtension.of(context).accent,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyzingHeader extends StatelessWidget {
  const _AnalyzingHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Görüşmeyi Analiz Ediyor...',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Niyet, bütçe, bölge ve aciliyet çıkarılıyor.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                height: 1.4,
              ),
        ),
      ],
    );
  }
}

class _AnalyzingProgressBar extends StatelessWidget {
  final double value;

  const _AnalyzingProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
              AppThemeExtension.of(context).accent),
        ),
      ),
    );
  }
}

/// 5 duygu durumu: emoji + kısa açıklama
const Map<CallSentiment, String> _sentimentEmoji = {
  CallSentiment.veryPositive: '🤩',
  CallSentiment.uncertain: '🤔',
  CallSentiment.analytical: '🧐',
  CallSentiment.lowInterest: '📉',
  CallSentiment.urgent: '⚠️',
};

const Map<CallSentiment, String> _sentimentLabel = {
  CallSentiment.veryPositive: 'Çok Heyecanlı / Pozitif',
  CallSentiment.uncertain: 'Kararsız / Düşünceli',
  CallSentiment.analytical: 'Analitik / Sorgulayıcı',
  CallSentiment.lowInterest: 'Düşük İlgi',
  CallSentiment.urgent: 'Acelesi Var',
};

const Map<CallSentiment, String> _sentimentSubtitle = {
  CallSentiment.veryPositive: 'Hemen satış kapatılabilir',
  CallSentiment.uncertain: 'Daha fazla bilgi bekliyor',
  CallSentiment.analytical: 'Detaylara çok önem veriyor',
  CallSentiment.lowInterest: 'Takip listesine alınmalı',
  CallSentiment.urgent: 'Sıcak fırsat',
};

/// PushToTalkButton ile aynı akış: [onSpeechResult], [onPhaseChanged] → dinleme / bekleme / işleme metni.
class _PostCallVoiceRow extends StatelessWidget {
  const _PostCallVoiceRow({
    required this.voiceStatus,
    required this.onSpeechResult,
    required this.onPhaseChanged,
  });

  final String voiceStatus;
  final void Function(PushToTalkSpeechResult) onSpeechResult;
  final void Function(String phase) onPhaseChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Sesle özet ekle',
              style: TextStyle(
                color: AppThemeExtension.of(context).textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            PushToTalkButton(
              size: 44,
              onSpeechResult: onSpeechResult,
              onPhaseChanged: onPhaseChanged,
            ),
          ],
        ),
        if (voiceStatus.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            voiceStatus,
            style: TextStyle(
              color: AppThemeExtension.of(context).textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

String _interestLevelLabelTr(String code) {
  switch (code) {
    case PostCallCrmSignals.interestHigh:
      return 'Yüksek';
    case PostCallCrmSignals.interestMedium:
      return 'Orta';
    case PostCallCrmSignals.interestLow:
      return 'Düşük';
    default:
      return 'Belirsiz';
  }
}

String _followUpUrgencyLabelTr(String code) {
  switch (code) {
    case PostCallCrmSignals.urgencyHigh:
      return 'Yüksek';
    case PostCallCrmSignals.urgencyMedium:
      return 'Orta';
    case PostCallCrmSignals.urgencyLow:
      return 'Düşük';
    default:
      return 'Yok';
  }
}

/// Kayıt öncesi: özet metninden kural tabanlı CRM sinyalleri (kaydedilecek alanlarla uyumlu).
class _SummarySignalsPreview extends StatelessWidget {
  const _SummarySignalsPreview({required this.summaryText});

  final String summaryText;

  @override
  Widget build(BuildContext context) {
    final t = summaryText.trim();
    if (t.isEmpty) return const SizedBox.shrink();

    final s = extractPostCallCrmSignals(t);

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Özetten çıkan sinyaller (CRM)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _signalChip(
                  context,
                  'İlgi',
                  _interestLevelLabelTr(s.interestLevel),
                ),
                _signalChip(
                  context,
                  'Takip aciliyeti',
                  _followUpUrgencyLabelTr(s.followUpUrgency),
                ),
                _signalChip(
                  context,
                  'Randevu',
                  s.appointmentMentioned ? 'Evet' : 'Hayır',
                ),
                _signalChip(
                  context,
                  'Fiyat itirazı',
                  s.priceObjection ? 'Evet' : 'Hayır',
                ),
              ],
            ),
            if (s.nextActionHint.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                s.nextActionHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      height: 1.35,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _signalChip(BuildContext context, String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Text(
        '$k: $v',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

/// Kayıt öncesi: yalnızca yerel sezgisel özet (her tuşta); bulut çağrısı yok.
/// Kayıt sonrası arka planda [PostCallAiEnrichmentService] ile birleştirilir.
class _PostCallAiEnrichmentInsightPreview extends StatelessWidget {
  const _PostCallAiEnrichmentInsightPreview({
    required this.summaryText,
    this.transcriptText = '',
    required this.sentimentStorage,
  });

  /// Bu altında önizleme göstermeyiz (gürültüyü keser).
  static const int _kHideBelowChars = 8;

  /// Canlı ton/takip satırları için minimum uzunluk; altında yumuşak teaser.
  static const int _kFullPreviewMinChars = 28;

  final String summaryText;
  final String transcriptText;
  final String sentimentStorage;

  @override
  Widget build(BuildContext context) {
    final t = summaryText.trim();
    final tr = transcriptText.trim();
    final len = math.max(t.length, tr.length);
    if (len < _kHideBelowChars) return const SizedBox.shrink();
    if (len < _kFullPreviewMinChars) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 15,
                color: Colors.white.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Özet netleştikçe ton ve takip önerileri burada canlı güncellenir.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final previewInput = PostCallAiEnrichmentInput.resolve(
      summary: t,
      transcript: tr.isEmpty ? null : transcriptText,
    );
    final e = computeHeuristicPostCallAiEnrichment(
      input: previewInput,
      signals: previewInput.signalsForAiHeuristicLayer(),
      sentimentLabelTr: sentimentLabelTrFromStorage(sentimentStorage),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: RepaintBoundary(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color:
                  AppThemeExtension.of(context).accent.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: AppThemeExtension.of(context).accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Destekleyici içgörü (canlı önizleme)',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                e.aiSummaryShortTr,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 6),
              _miniLine(context, 'Ton', e.aiCustomerMoodTr),
              _miniLine(context, 'İtiraz', e.aiObjectionTypeTr),
              _miniLine(context, 'Takip', e.aiFollowUpStyleTr),
              _miniLine(context, 'Not', e.aiBrokerNoteTr),
              const SizedBox(height: 6),
              Text(
                'Kayıttan sonra sunucu (varsa) içgörüyü güncelleyebilir; CRM skorları değişmez.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white54,
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniLine(BuildContext context, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white54,
                height: 1.3,
              ),
          children: [
            TextSpan(
              text: '$label · ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultSummaryWithSentiment extends StatelessWidget {
  final CallExtraction extraction;
  final TextEditingController summaryController;
  final VoidCallback onSummaryEdited;

  const _ResultSummaryWithSentiment({
    required this.extraction,
    required this.summaryController,
    required this.onSummaryEdited,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emoji = _sentimentEmoji[extraction.sentiment] ?? '😐';
    final label = _sentimentLabel[extraction.sentiment] ?? '';
    final sub = _sentimentSubtitle[extraction.sentiment] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (sub.isNotEmpty)
                Text(
                  sub,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Özet',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: summaryController,
                  onChanged: (_) => onSummaryEdited(),
                  minLines: 3,
                  maxLines: 8,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText:
                        'Özeti düzenleyebilir veya sesle ekleyebilirsiniz',
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtractionBentoGrid extends StatelessWidget {
  final CallExtraction extraction;

  const _ExtractionBentoGrid({required this.extraction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cards = <_BentoItem>[
      _BentoItem(
          'Müşteri Niyeti', extraction.customerIntent, Icons.touch_app_rounded),
      _BentoItem('Bütçe Aralığı', extraction.budgetRange,
          Icons.account_balance_wallet_rounded),
      _BentoItem('Tercih Edilen Bölgeler', extraction.preferredRegions,
          Icons.location_on_rounded),
      _BentoItem('Aciliyet Durumu', extraction.urgency, Icons.schedule_rounded),
    ];

    return Column(
      children: cards.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppThemeExtension.of(context)
                        .accent
                        .withValues(alpha: 0.2),
                  ),
                  child: Icon(e.icon,
                      color: AppThemeExtension.of(context).accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white54,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BentoItem {
  final String label;
  final String value;
  final IconData icon;
  _BentoItem(this.label, this.value, this.icon);
}

class _NextStepCard extends StatelessWidget {
  final String suggestion;

  const _NextStepCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppThemeExtension.of(context).accent.withValues(alpha: 0.12),
        border: Border.all(
            color: AppThemeExtension.of(context).accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_rounded,
            color: AppThemeExtension.of(context).accent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sonraki Adım Önerisi',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppThemeExtension.of(context).accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  suggestion,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
