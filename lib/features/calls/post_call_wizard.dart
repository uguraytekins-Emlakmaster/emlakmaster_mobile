import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'dart:math' as math;
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/resilience/safe_operation.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/contact_save/presentation/widgets/save_contact_sheet.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_insight_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_transcript_ingestion.dart';
import 'package:emlakmaster_mobile/features/calls/domain/transcript_ingest_payload.dart';
import 'package:emlakmaster_mobile/features/calls/domain/post_call_crm_signals.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/post_call_wizard_context_strip.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Çağrı özeti manuel düzenlenir; isteğe bağlı transkript `lastCallTranscript` alanına yazılır.
/// Duygu durumu: görüşme tonuna göre 5 seçenekten biri.
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
    this.firestoreCallId,
    this.customerId,
    this.callSummaryId,
  });

  final bool savedSuccessfully;
  final bool taskCreated;
  final bool customerLinked;
  final bool detachedCallSummarySaved;
  final String? firestoreCallId;
  final String? customerId;
  final String? callSummaryId;
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

  late AnimationController _progressController;
  late final PageController _wizardPageController;
  int _wizardStepIndex = 0;

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
    AppFeedback.mediumImpact();
    _wizardPageController = PageController();

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
        nextStepSuggestion: 'Çağrı notlarınızı kaydedin.',
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
  }

  @override
  void dispose() {
    _wizardPageController.dispose();
    _progressController.dispose();
    _summaryController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  Future<void> _onSaveAndClose() async {
    if (_extraction == null || _isSaving) {
      return;
    }
    final summaryText = _summaryController.text.trim();
    AppFeedback.mediumImpact();
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    final agentId = ref.read(currentUserProvider).valueOrNull?.uid;
    final customerId = widget.linkedCustomerId;
    final callSessionId = widget.callSessionId?.trim();
    AppLogger.forensic(
      'post_call_wizard: Özeti Kaydet pressed linked='
      '${customerId != null && customerId.isNotEmpty} '
      'session=${callSessionId ?? '-'} summaryLen=${summaryText.length}',
    );
    if (kDebugMode) {
      AppLogger.d(
        '[post_call_wizard] save start customer=${customerId ?? '-'} '
        'callSession=${callSessionId ?? '-'} summaryChars=${summaryText.length}',
      );
    }
    if (agentId == null || agentId.isEmpty) {
      AppLogger.forensic('post_call_wizard: ABORT no agentId');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError = 'Oturum bulunamadı. Giriş yapıp tekrar deneyin.';
        });
      }
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
      AppLogger.forensic(
        'post_call_wizard: Firestore runWithResilience start linked=$customerLinked',
      );
      await runWithResilienceWidget(
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
        ref: ref,
      );
      AppLogger.forensic('post_call_wizard: Firestore runWithResilience done');
      if (!mounted) {
        AppLogger.forensic(
          'post_call_wizard: unmounted after Firestore (no UI completion)',
        );
        return;
      }
      AppLogger.i(
        customerLinked
            ? '[post_call_wizard] linked summary saved'
            : '[post_call_wizard] detached summary saved',
      );
      final transcriptText = _transcriptController.text.trim();
      if (customerLinked && transcriptText.isNotEmpty) {
        try {
          await PostCallTranscriptIngestion.mergePayloadIfPresent(
            customerId: customerId,
            payload: TranscriptIngestPayload.manual(
              rawTranscriptText: transcriptText,
            ),
          );
        } catch (e, st) {
          AppLogger.w('Transkript Firestore kaydı atlandı', e, st);
        }
      }
      if (!mounted) {
        AppLogger.forensic(
          'post_call_wizard: unmounted after transcript (no UI completion)',
        );
        return;
      }
      AppLogger.forensic('post_call_wizard: provider invalidate start');
      ref.invalidate(consultantCallsStreamProvider);
      ref.invalidate(customerListForAgentProvider);
      if (customerLinked) {
        ref.invalidate(customerInsightProvider(customerId));
      }
      AppLogger.forensic('post_call_wizard: provider invalidate done');
      if (!mounted) {
        AppLogger.forensic(
          'post_call_wizard: unmounted after invalidate (no UI completion)',
        );
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      final result = PostCallSummarySaveResult(
        savedSuccessfully: true,
        taskCreated: false,
        customerLinked: customerLinked,
        detachedCallSummarySaved: !customerLinked,
        firestoreCallId: callSessionId,
        customerId: customerLinked ? customerId : null,
        callSummaryId: callSummaryId,
      );
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
      AppFeedback.selectionClick();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.customerLinked
                ? 'Harika — özet müşteri kartına işlendi.'
                : 'Tamam — özet çağrı kaydına güvenle yazıldı.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      AppLogger.forensic('post_call_wizard: success SnackBar shown');
      try {
        AppLogger.forensic('post_call_wizard: context.go(routeHome)');
        context.go(AppRouter.routeHome);
        AppLogger.forensic('post_call_wizard: FINAL completion (navigated)');
      } catch (e, st) {
        AppLogger.e('post_call_wizard: context.go failed after save', e, st);
        AppLogger.forensic('post_call_wizard: FINAL navigate error');
        if (mounted) {
          setState(() {
            _saveError =
                'Kayıt tamamlandı; ana ekrana geçiş başarısız. Geri ile çıkıp kontrol edin.';
          });
        }
      }
    } catch (e, st) {
      AppLogger.e('PostCallWizard save failed', e, st);
      AppLogger.forensic('post_call_wizard: FINAL error ${e.runtimeType}');
      if (mounted) {
        setState(() {
          _saveError = FirestoreService.userFacingErrorMessage(e);
        });
      }
    } finally {
      if (mounted && _isSaving) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _openSaveContactSheet() async {
    String? name;
    String? phone;
    if (widget.linkedCustomerId != null) {
      final c = await ref.read(
        customerEntityByIdProvider(widget.linkedCustomerId!).future,
      );
      name = c?.fullName;
      phone = c?.primaryPhone;
    }
    if (!mounted) {
      return;
    }
    showSaveContactSheet(
      context,
      initialName: name,
      initialPhone: phone,
      initialNote: _summaryController.text.trim().isEmpty
          ? null
          : _summaryController.text.trim(),
      source: 'rehber_aramasi',
    );
  }

  Widget _buildWizardStepSummary() {
    final ext = AppThemeExtension.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: DesignTokens.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Konuşmanın özü',
            style: AppTypography.cardHeading(context).copyWith(
              color: ext.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Metin tamamen size ait.',
            style: AppTypography.meta(context).copyWith(
              color: ext.textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          _ResultSummaryWithSentiment(
            extraction: _extraction!,
            summaryController: _summaryController,
          ),
          const SizedBox(height: DesignTokens.space3),
          Text(
            'İsterseniz kısa tutun; ayrıntıları bir sonraki adımda netleştirirsiniz.',
            style: AppTypography.meta(context).copyWith(
              color: ext.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWizardStepDetails() {
    final ext = AppThemeExtension.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: DesignTokens.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sinyaller & kayıt alanları',
            style: AppTypography.cardHeading(context),
          ),
          const SizedBox(height: DesignTokens.space1),
          Text(
            'Özetten çıkanlar ve isteğe bağlı transkript. Hepsi kayıt akışına dahil.',
            style: AppTypography.meta(context).copyWith(
              color: ext.textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _summaryController,
            builder: (context, value, _) {
              return _SummarySignalsPreview(summaryText: value.text);
            },
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              collapsedIconColor: ext.textSecondary,
              iconColor: ext.textSecondary,
              title: Row(
                children: [
                  Icon(
                    Icons.subtitles_outlined,
                    size: 18,
                    color: ext.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Transkript (isteğe bağlı)',
                      style: AppTypography.bodyStrong(context),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Yapıştırın veya yazın. Özet ana kayıt; transkript ayrı tutulur.',
                  style: AppTypography.meta(context).copyWith(
                    color: ext.textTertiary,
                  ),
                ),
              ),
              children: [
                TextField(
                  controller: _transcriptController,
                  maxLines: 6,
                  style: AppTypography.body(context).copyWith(height: 1.35),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: ext.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ext.borderSubtle),
                    ),
                    hintText: 'Ham metin…',
                    hintStyle: AppTypography.meta(context).copyWith(
                      color: ext.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          Text(
            'Öne çıkanlar',
            style: AppTypography.bodyStrong(context).copyWith(
              color: ext.textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          _ExtractionBentoGrid(extraction: _extraction!),
        ],
      ),
    );
  }

  Widget _buildWizardStepReview() {
    final ext = AppThemeExtension.of(context);
    final linked = widget.linkedCustomerId != null &&
        widget.linkedCustomerId!.trim().isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: DesignTokens.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Son kontrol',
            style: AppTypography.cardHeading(context),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            linked
                ? 'Her şey hazırsa kaydedin; müşteri kartı ve çağrı güncellenir.'
                : 'Bağımsız kayıt geçerlidir — özet çağrıyla birlikte saklanır.',
            style: AppTypography.meta(context).copyWith(
              color: ext.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          _NextStepCard(suggestion: _extraction!.nextStepSuggestion),
          const SizedBox(height: DesignTokens.space4),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _summaryController,
            builder: (context, value, _) {
              final t = value.text.trim();
              if (t.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: AppTypography.cardPadding,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    color: ext.surfaceElevated,
                    border: Border.all(color: ext.borderSubtle),
                  ),
                  child: Text(
                    'Özet henüz boş. İlk adımda birkaç cümle ekleyin.',
                    style: AppTypography.body(context),
                  ),
                );
              }
              final preview = t.length > 240 ? '${t.substring(0, 240)}…' : t;
              return Container(
                width: double.infinity,
                padding: AppTypography.cardPadding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  color: ext.surfaceElevated,
                  border: Border.all(color: ext.borderSubtle),
                ),
                child: Text(
                  preview,
                  style: AppTypography.body(context)
                      .copyWith(color: ext.textPrimary),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);

    return PremiumShellBackdrop(
      child: Scaffold(
      backgroundColor: Colors.transparent,
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
                        color: ext.textSecondary,
                        onPressed: () {
                          AppFeedback.lightImpact();
                          context.pop();
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Çağrı sonrası',
                              style:
                                  AppTypography.cardHeading(context).copyWith(
                                color: ext.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.space1),
                            Text(
                              'Özet · sinyaller · kayıt',
                              style: AppTypography.meta(context).copyWith(
                                color: ext.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _WizardProgressHeader(
                            currentStep: _wizardStepIndex,
                            onStepTap: (i) {
                              _wizardPageController.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                              );
                            },
                          ),
                          const SizedBox(height: DesignTokens.space3),
                          PostCallWizardContextStrip(
                            linkedCustomerId: widget.linkedCustomerId,
                            phoneNumber: widget.phoneNumber,
                            callSessionId: widget.callSessionId,
                            isHandoffCall: (widget.callOutcome ?? '') ==
                                AppConstants.callOutcomeSystemHandoff,
                          ),
                          const SizedBox(height: DesignTokens.space3),
                          Expanded(
                            child: PageView(
                              controller: _wizardPageController,
                              onPageChanged: (i) {
                                setState(() => _wizardStepIndex = i);
                              },
                              children: [
                                _buildWizardStepSummary(),
                                _buildWizardStepDetails(),
                                _buildWizardStepReview(),
                              ],
                            ),
                          ),
                          _PostCallWizardBottomBar(
                            stepIndex: _wizardStepIndex,
                            isSaving: _isSaving,
                            saveError: _saveError,
                            customerLinked: widget.linkedCustomerId != null &&
                                widget.linkedCustomerId!.trim().isNotEmpty,
                            onBack: _wizardStepIndex <= 0
                                ? null
                                : () {
                                    _wizardPageController.previousPage(
                                      duration:
                                          const Duration(milliseconds: 280),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                            onNext: _wizardStepIndex >= 2
                                ? null
                                : () {
                                    _wizardPageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 280),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                            onSave: _onSaveAndClose,
                            onSaveContact: _openSaveContactSheet,
                          ),
                        ],
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
    ),
    );
  }
}

class _WizardProgressHeader extends StatelessWidget {
  const _WizardProgressHeader({
    required this.currentStep,
    required this.onStepTap,
  });

  final int currentStep;
  final ValueChanged<int> onStepTap;

  static const List<String> _labels = ['Özet', 'Sinyaller', 'Tamamla'];

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    return Row(
      children: List.generate(3, (i) {
        final active = i == currentStep;
        final done = i < currentStep;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onStepTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? premium.champagneGold.withValues(alpha: 0.18)
                        : premium.glassSurface.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active
                          ? premium.champagneGold.withValues(alpha: 0.5)
                          : ext.borderSubtle,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (done) ...[
                        Icon(Icons.check_rounded,
                            size: 14, color: premium.champagneGold),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          _labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.meta(context).copyWith(
                            color: active ? ext.textPrimary : ext.textSecondary,
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PostCallWizardBottomBar extends StatelessWidget {
  const _PostCallWizardBottomBar({
    required this.stepIndex,
    required this.isSaving,
    required this.onSave,
    required this.onSaveContact,
    required this.customerLinked,
    this.onBack,
    this.onNext,
    this.saveError,
  });

  final int stepIndex;
  final bool isSaving;
  final VoidCallback onSave;
  final Future<void> Function() onSaveContact;
  final bool customerLinked;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String? saveError;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final ime = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        top: DesignTokens.space3,
        bottom: ime + DesignTokens.space3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (saveError != null &&
              saveError!.trim().isNotEmpty &&
              stepIndex == 2) ...[
            Text(
              saveError!,
              style: TextStyle(
                color: ext.danger,
                fontSize: 13,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space2),
          ],
          if (stepIndex < 2)
            Row(
              children: [
                if (onBack != null)
                  TextButton(
                    onPressed: onBack,
                    child: const Text('Geri'),
                  )
                else
                  const SizedBox(width: 8),
                const Spacer(),
                FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: premium.champagneGold,
                    foregroundColor: ext.onBrand,
                  ),
                  child: Text(
                    'Devam',
                    style: AppTypography.primaryButton(context)
                        .copyWith(color: ext.onBrand),
                  ),
                ),
              ],
            )
          else ...[
            if (!isSaving)
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.space2),
                child: Text(
                  customerLinked
                      ? 'Müşteri kartı ve çağrı günlüğü güncellenir.'
                      : 'Özet kalıcı çağrı kaydına yazılır.',
                  textAlign: TextAlign.center,
                  style: AppTypography.meta(context).copyWith(
                    color: ext.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: premium.champagneGold,
                foregroundColor: ext.onBrand,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: isSaving ? null : onSave,
              child: isSaving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ext.onBrand,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Kaydediliyor…',
                          style: AppTypography.primaryButton(context)
                              .copyWith(color: ext.onBrand),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            color: ext.onBrand, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Özeti kaydet',
                          style: AppTypography.primaryButton(context)
                              .copyWith(
                            color: ext.onBrand,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: DesignTokens.space2),
            OutlinedButton.icon(
              onPressed: () async {
                await onSaveContact();
              },
              icon: const Icon(Icons.contact_phone_rounded, size: 20),
              label: const Text('Rehbere kaydet'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ext.accent,
                side: BorderSide(color: ext.accent.withValues(alpha: 0.65)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Token optimizasyonu: kısa arama veya yanlış numara – AI analizi atlanır.
class _SkippedAnalysisCard extends StatelessWidget {
  const _SkippedAnalysisCard();

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_off_rounded,
                size: 56, color: ext.textSecondary.withValues(alpha: 0.85)),
            const SizedBox(height: 16),
            Text(
              'Derin analiz atlandı',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Çok kısa görüşme veya yanlış numara. Özet akışı açık; işlemciniz etkilenmez.',
              style: TextStyle(
                color: ext.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go(AppRouter.routeHome),
              icon: const Icon(Icons.home_rounded, size: 20),
              label: const Text('Ana sayfaya dön'),
              style: FilledButton.styleFrom(
                backgroundColor: premium.champagneGold,
                foregroundColor: ext.onBrand,
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
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Çağrı metni okunuyor…',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Niyet, bütçe, bölge ve tempo çıkarılıyor; birkaç saniye.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ext.textSecondary,
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

    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: ext.surfaceElevated.withValues(alpha: 0.55),
          border: Border.all(color: ext.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Özetten çıkan sinyaller',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: ext.textSecondary,
                    fontWeight: FontWeight.w700,
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
                      color: ext.textSecondary,
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
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: ext.foregroundMuted.withValues(alpha: 0.1),
        border: Border.all(color: ext.borderSubtle),
      ),
      child: Text(
        '$k: $v',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: ext.textPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ResultSummaryWithSentiment extends StatelessWidget {
  final CallExtraction extraction;
  final TextEditingController summaryController;

  const _ResultSummaryWithSentiment({
    required this.extraction,
    required this.summaryController,
  });

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    final emoji = _sentimentEmoji[extraction.sentiment] ?? '😐';
    final label = _sentimentLabel[extraction.sentiment] ?? '';
    final sub = _sentimentSubtitle[extraction.sentiment] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
        color: ext.surfaceElevated,
        border: Border.all(color: ext.borderSubtle.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: ext.shadowColor.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duygu tonu',
                      style: AppTypography.meta(context).copyWith(
                        color: ext.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: AppTypography.bodyStrong(context),
                    ),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: AppTypography.meta(context).copyWith(
                          color: ext.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: ext.borderSubtle),
          ),
          Text(
            'Özet metni',
            style: theme.textTheme.labelMedium?.copyWith(
              color: ext.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Taslak burada; dilediğiniz gibi düzenleyin.',
            style: AppTypography.meta(context).copyWith(
              color: ext.textTertiary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: summaryController,
            minLines: 4,
            maxLines: 10,
            style: AppTypography.body(context).copyWith(
              height: 1.4,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: ext.inputBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: ext.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: ext.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: ext.accent, width: 1.2),
              ),
              hintText: 'Kısa ve net; müşterinin ne istediği belli olsun.',
              hintStyle: AppTypography.body(context).copyWith(
                color: ext.textTertiary,
              ),
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
    final ext = AppThemeExtension.of(context);
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

    return LayoutBuilder(
      builder: (context, cons) {
        final maxW = cons.maxWidth;
        final useTwo = maxW > 420;
        final tileW = useTwo ? (maxW - 10) / 2 : maxW;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cards.map((e) {
            return SizedBox(
              width: tileW,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: ext.surfaceElevated.withValues(alpha: 0.65),
                  border:
                      Border.all(color: ext.borderSubtle.withValues(alpha: 0.7)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: ext.accent.withValues(alpha: 0.16),
                      ),
                      child: Icon(e.icon, color: ext.accent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: ext.textTertiary,
                              letterSpacing: 0.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.value,
                            style: AppTypography.body(context).copyWith(
                              fontWeight: FontWeight.w600,
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
      },
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
    final ext = AppThemeExtension.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
        color: ext.accent.withValues(alpha: 0.1),
        border: Border.all(
          color: ext.accent.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.navigation_rounded,
            color: ext.accent,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Önerilen sonraki adım',
                  style: AppTypography.bodyStrong(context).copyWith(
                    color: ext.accent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  suggestion,
                  style: AppTypography.body(context).copyWith(
                    height: 1.45,
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
