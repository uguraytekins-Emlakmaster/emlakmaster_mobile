import 'dart:math' as math;

import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/resilience/safe_operation.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Duygu durumu: AI görüşme tonuna göre 5 seçenekten biri.
enum CallSentiment {
  veryPositive,   // 🤩 Çok Heyecanlı/Pozitif
  uncertain,      // 🤔 Kararsız/Düşünceli
  analytical,     // 🧐 Analitik/Sorgulayıcı
  lowInterest,   // 📉 Düşük İlgi
  urgent,         // ⚠️ Acelesi Var
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

String sentimentToStorage(CallSentiment s) {
  switch (s) {
    case CallSentiment.veryPositive: return 'very_positive';
    case CallSentiment.uncertain: return 'uncertain';
    case CallSentiment.analytical: return 'analytical';
    case CallSentiment.lowInterest: return 'low_interest';
    case CallSentiment.urgent: return 'urgent';
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
    CallSentiment.veryPositive: 'Müşteri 3+1 oturumluk, Bağlar/Kayapınar bölgesinde 5-8M TL bütçeyle 15 gün içinde taşınmak istiyor. Çok istekli.',
    CallSentiment.uncertain: 'Müşteri 3+1 düşünüyor, bütçe 5-8M TL. Bağlar/Kayapınar ilgi var ama henüz karar vermedi.',
    CallSentiment.analytical: 'Müşteri 3+1 için detaylı sorular sordu: metrekare, aidat, deprem. 5-8M TL, Bağlar/Kayapınar.',
    CallSentiment.lowInterest: 'Müşteri 3+1 ve 5-8M TL dedi ama acil değil; takip listesine alındı.',
    CallSentiment.urgent: 'Müşteri 15 gün içinde taşınmak istiyor, 3+1 Bağlar/Kayapınar 5-8M TL. Sıcak fırsat.',
  };

  final nextSteps = {
    CallSentiment.veryPositive: 'Müşteriye yarın sabah portföydeki 3+1 Bağlar dairesinin sunumunu gönder.',
    CallSentiment.uncertain: 'Bir hafta içinde tekrar arayıp kararını sor.',
    CallSentiment.analytical: 'Detaylı fiyat/kullanım özeti ve kıyaslama tablosu hazırla.',
    CallSentiment.lowInterest: 'Takip listesine ekle; 2 hafta sonra hatırlatma notu at.',
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
  });

  /// AI token optimizasyonu: kısa veya yanlış numara ise derin analiz atlanır.
  final int? callDurationSec;
  final String? callOutcome;

  /// Müşteri detaydan açılan aramada özet bu müşteriye bağlanır.
  final String? linkedCustomerId;

  @override
  ConsumerState<PostCallWizardScreen> createState() => _PostCallWizardScreenState();
}

class _PostCallWizardScreenState extends ConsumerState<PostCallWizardScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzing = true;
  CallExtraction? _extraction;
  bool _isSaving = false;
  String? _saveError;

  late AnimationController _progressController;

  static const String _demoConversation =
      'Müşteri 3+1 daire arıyor, oturumluk. Bütçe 5 ile 8 milyon lira arası. '
      'Bağlar ve Kayapınar bölgelerini istiyor. 15 gün içinde taşınmak istediğini söyledi.';

  bool get _skipFullAnalysis {
    final duration = widget.callDurationSec ?? 999;
    final outcome = widget.callOutcome ?? AppConstants.callOutcomeCompleted;
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
    if (_skipFullAnalysis) {
      _isAnalyzing = false;
      _extraction = null;
    } else {
      _progressController.forward();
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        setState(() {
          _isAnalyzing = false;
          _extraction = extractFromConversation(_demoConversation);
        });
      });
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _onSaveAndClose() async {
    if (_extraction == null || _isSaving) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    final agentId = ref.read(currentUserProvider).valueOrNull?.uid ?? 'demoAgent1';
    final customerId = widget.linkedCustomerId ?? 'demoCustomer1';
    try {
      await runWithResilience(
        ref: ref as Ref<Object?>,
        () async {
          await FirestoreService.saveCallExtractionToCustomer(
            customerId: customerId,
            assignedAgentId: agentId,
            customerIntent: _extraction!.customerIntent,
            budgetRange: _extraction!.budgetRange,
            preferredRegions: _extraction!.preferredRegions,
            urgency: _extraction!.urgency,
            nextStepSuggestion: _extraction!.nextStepSuggestion,
            sentiment: sentimentToStorage(_extraction!.sentiment),
            fullSummary: _extraction!.fullSummary,
          );
          await FirestoreService.incrementAgentStatsAfterSummary(
            agentId: agentId,
          );
        },
      );
      if (!mounted) return;
      AppLogger.i('Call summary saved');
      context.go(AppRouter.routeHome);
    } catch (e, st) {
      if (!mounted) return;
      AppLogger.e('PostCallWizard save failed', e, st);
      setState(() {
        _isSaving = false;
        _saveError =
            'Kayıt gönderilemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
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
                      Text(
                        'Çağrı Özeti Sihirbazı',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
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
                            _ResultSummaryWithSentiment(extraction: _extraction!),
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
                                style: const TextStyle(
                                  color: Color(0xFFE53935),
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
                                  backgroundColor: const Color(0xFF00FF41),
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
            const Icon(Icons.timer_off_rounded, size: 56, color: Colors.white54),
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
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go(AppRouter.routeHome),
              icon: const Icon(Icons.home_rounded, size: 20),
              label: const Text('Ana sayfaya dön'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00FF41),
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
        color: Colors.white.withOpacity(0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.transparent,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FF41)),
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

class _ResultSummaryWithSentiment extends StatelessWidget {
  final CallExtraction extraction;

  const _ResultSummaryWithSentiment({required this.extraction});

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
        color: Colors.white.withOpacity(0.08),
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
                Text(
                  extraction.fullSummary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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
      _BentoItem('Müşteri Niyeti', extraction.customerIntent, Icons.touch_app_rounded),
      _BentoItem('Bütçe Aralığı', extraction.budgetRange, Icons.account_balance_wallet_rounded),
      _BentoItem('Tercih Edilen Bölgeler', extraction.preferredRegions, Icons.location_on_rounded),
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
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF00FF41).withOpacity(0.2),
                  ),
                  child: Icon(e.icon, color: const Color(0xFF00FF41), size: 20),
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
        color: const Color(0xFF00FF41).withOpacity(0.12),
        border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: Color(0xFF00FF41),
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
                    color: const Color(0xFF00FF41),
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
