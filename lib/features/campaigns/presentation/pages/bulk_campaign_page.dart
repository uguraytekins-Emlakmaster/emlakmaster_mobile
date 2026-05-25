import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/campaign_ai_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/emlak_app_bar.dart';
import '../../../../core/utils/sms_launcher.dart';
import '../../../../core/utils/whatsapp_launcher.dart';
import '../../../../core/widgets/app_toaster.dart';
import '../providers/bulk_campaign_providers.dart';

/// Toplu kampanya / filtre ekranı – müşteri segmentasyonu + AI metin önerisi iskeleti.
class BulkCampaignPage extends ConsumerWidget {
  const BulkCampaignPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segmentAsync = ref.watch(bulkCampaignSegmentProvider);
    final message = ref.watch(bulkCampaignMessageProvider);

    final count = segmentAsync.maybeWhen(
      data: (s) => s.activePhonesCount,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppThemeExtension.of(context).background,
      appBar: emlakAppBar(
        context,
        backgroundColor: Colors.transparent,
        title: Text(
          AppLocalizations.of(context).t('title_bulk_campaign'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SegmentHeader(totalCount: count),
              const SizedBox(height: DesignTokens.space4),
              const _SegmentFiltersCard(),
              const SizedBox(height: DesignTokens.space6),
              const _AiMessageHeader(),
              const SizedBox(height: DesignTokens.space3),
              _AiMessageComposer(initialValue: message),
              if (segmentAsync.isLoading) ...[
                const SizedBox(height: DesignTokens.space4),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(DesignTokens.space4),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
              if (segmentAsync.hasError) ...[
                const SizedBox(height: DesignTokens.space4),
                Text(
                  'Segment yüklenemedi. Bağlantıyı kontrol edip tekrar deneyin.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppThemeExtension.of(context).danger,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: segmentAsync.maybeWhen(
        data: (segment) => _BottomActionBar(
          enabled: count > 0 && message.trim().isNotEmpty,
          segment: segment,
          message: message,
        ),
        orElse: () => null,
      ),
    );
  }
}

class _SegmentHeader extends StatelessWidget {
  const _SegmentHeader({required this.totalCount});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.filter_alt_rounded, color: AppThemeExtension.of(context).accent, size: 22),
        const SizedBox(width: DesignTokens.space2),
        Text(
          AppLocalizations.of(context).t('segment_header'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppThemeExtension.of(context).textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        Row(
          children: [
            Icon(
              Icons.people_rounded,
              size: 16,
              color: totalCount > 0 ? AppThemeExtension.of(context).accent : AppThemeExtension.of(context).textTertiary,
            ),
            const SizedBox(width: DesignTokens.space1),
            Text(
              totalCount > 0
                  ? AppLocalizations.of(context).tArgs('segment_count', ['$totalCount'])
                  : AppLocalizations.of(context).t('segment_count_none'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: totalCount > 0
                        ? AppThemeExtension.of(context).textSecondary
                        : AppThemeExtension.of(context).textTertiary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SegmentFiltersCard extends ConsumerStatefulWidget {
  const _SegmentFiltersCard();

  @override
  ConsumerState<_SegmentFiltersCard> createState() => _SegmentFiltersCardState();
}

class _SegmentFiltersCardState extends ConsumerState<_SegmentFiltersCard> {
  RangeValues _budgetRange = const RangeValues(1, 10);
  double _minTemperature = 0.4;
  bool _activeCalls = true;
  bool _noInteractionRecently = false;
  String _regionText = '';

  @override
  void initState() {
    super.initState();
    final initial = ref.read(bulkCampaignFiltersProvider);
    _budgetRange = RangeValues(
      initial.minBudgetMillions,
      initial.maxBudgetMillions,
    );
    _minTemperature = initial.minLeadTemperature;
    _activeCalls = initial.requireRecentInteraction;
    _noInteractionRecently = initial.requireNoRecentInteraction;
    _regionText = initial.regionQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pushFilters();
    });
  }

  void _pushFilters() {
    if (!mounted) return;
    ref.read(bulkCampaignFiltersProvider.notifier).apply(
          BulkCampaignFilters(
            minBudgetMillions: _budgetRange.start,
            maxBudgetMillions: _budgetRange.end,
            minLeadTemperature: _minTemperature,
            requireRecentInteraction: _activeCalls,
            requireNoRecentInteraction: _noInteractionRecently,
            regionQuery: _regionText,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: AppThemeExtension.of(context).surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: AppThemeExtension.of(context).border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: DesignTokens.space2,
            runSpacing: DesignTokens.space2,
            children: [
              FilterChip(
                label: const Text('Sıcak lead (≥ 40 puan)'),
                selected: _minTemperature >= 0.4,
                onSelected: (v) {
                  setState(() {
                    _minTemperature = v ? 0.4 : 0.0;
                  });
                  _pushFilters();
                },
              ),
              FilterChip(
                label: const Text('Son 30 günde çağrı yapıldı'),
                selected: _activeCalls,
                onSelected: (v) {
                  setState(() => _activeCalls = v);
                  _pushFilters();
                },
              ),
              FilterChip(
                label: const Text('Son 45 gündür temas yok'),
                selected: _noInteractionRecently,
                onSelected: (v) {
                  setState(() => _noInteractionRecently = v);
                  _pushFilters();
                },
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space4),
          Text(
            'Bütçe aralığı (milyon TL)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppThemeExtension.of(context).textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Row(
            children: [
              Text(
                '${_budgetRange.start.toStringAsFixed(0)}M',
                style: TextStyle(
                  color: AppThemeExtension.of(context).textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: DesignTokens.space1),
              Text('–', style: TextStyle(color: AppThemeExtension.of(context).textTertiary)),
              const SizedBox(width: DesignTokens.space1),
              Text(
                '${_budgetRange.end.toStringAsFixed(0)}M',
                style: TextStyle(
                  color: AppThemeExtension.of(context).textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Örnek: 2M – 8M',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemeExtension.of(context).textTertiary,
                    ),
              ),
            ],
          ),
          RangeSlider(
            values: _budgetRange,
            max: 20,
            divisions: 20,
            labels: RangeLabels(
              '${_budgetRange.start.toStringAsFixed(0)}M',
              '${_budgetRange.end.toStringAsFixed(0)}M',
            ),
            onChanged: (values) {
              setState(() => _budgetRange = values);
              _pushFilters();
            },
          ),
          const SizedBox(height: DesignTokens.space4),
          Text(
            'Bölge / mahalle etiketi',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppThemeExtension.of(context).textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: DesignTokens.space2),
          TextField(
            decoration: InputDecoration(
              hintText: 'Örn: Bağdat Caddesi, Maslak, Küçükçekmece...',
              hintStyle: TextStyle(
                color: AppThemeExtension.of(context).textTertiary,
                fontSize: DesignTokens.fontSizeSm,
              ),
              filled: true,
              fillColor: AppThemeExtension.of(context).surface,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: AppThemeExtension.of(context).border),
                borderRadius: const BorderRadius.all(Radius.circular(DesignTokens.radiusMd)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppThemeExtension.of(context).border),
                borderRadius: const BorderRadius.all(Radius.circular(DesignTokens.radiusMd)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppThemeExtension.of(context).accent),
                borderRadius: const BorderRadius.all(Radius.circular(DesignTokens.radiusMd)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space3,
                vertical: DesignTokens.space3,
              ),
            ),
            style: TextStyle(color: AppThemeExtension.of(context).textPrimary),
            onChanged: (value) {
              setState(() => _regionText = value.trim());
              _pushFilters();
            },
          ),
          const SizedBox(height: DesignTokens.space3),
          Text(
            _buildSegmentSummary(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppThemeExtension.of(context).textTertiary,
                ),
          ),
        ],
      ),
    );
  }

  String _buildSegmentSummary() {
    final parts = <String>[];
    if (_minTemperature >= 0.4) {
      parts.add('En az orta-sıcak lead');
    }
    if (_activeCalls) {
      parts.add('Son 30 günde telefon teması olanlar');
    }
    if (_noInteractionRecently) {
      parts.add('Uzun süredir temas edilmeyenler');
    }
    if (_regionText.isNotEmpty) {
      parts.add('Bölge: $_regionText');
    }
    if (parts.isEmpty) {
      return 'Tüm CRM müşterileri hedefleniyor. Filtreleri daraltmak için yukarıdan seçim yapın.';
    }
    return 'Hedef segment: ${parts.join(' · ')}'
        ' · Bütçe: ${_budgetRange.start.toStringAsFixed(0)}M – ${_budgetRange.end.toStringAsFixed(0)}M (yaklaşık).';
  }
}

class _AiMessageHeader extends StatelessWidget {
  const _AiMessageHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.auto_awesome_rounded, color: AppThemeExtension.of(context).accent, size: 22),
        const SizedBox(width: DesignTokens.space2),
        Text(
          AppLocalizations.of(context).t('ai_message_header'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppThemeExtension.of(context).textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space3,
            vertical: DesignTokens.space1,
          ),
          decoration: BoxDecoration(
            color: AppThemeExtension.of(context).surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppThemeExtension.of(context).border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.science_rounded, size: 14, color: AppThemeExtension.of(context).textTertiary),
              const SizedBox(width: DesignTokens.space1),
              Text(
                'Beta · iskelet',
                style: TextStyle(
                  color: AppThemeExtension.of(context).textTertiary,
                  fontSize: DesignTokens.fontSizeXs,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AiMessageComposer extends ConsumerStatefulWidget {
  const _AiMessageComposer({required this.initialValue});

  final String initialValue;

  @override
  ConsumerState<_AiMessageComposer> createState() => _AiMessageComposerState();
}

class _AiMessageComposerState extends ConsumerState<_AiMessageComposer> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSuggestPressed() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final segment = ref.read(bulkCampaignSegmentProvider).valueOrNull;
      if (segment == null || segment.activePhonesCount == 0) {
        if (mounted) {
          AppToaster.warning(context, 'Önce filtrelerle bir hedef kitle oluştur.');
        }
        return;
      }
      final sample = segment.customers.take(5).map((c) {
        return {
          'fullName': c.fullName,
          'primaryPhone': c.primaryPhone,
          'budgetMin': c.budgetMin,
          'budgetMax': c.budgetMax,
          'regions': c.regionPreferences,
          'leadTemperature': c.leadTemperature,
          'lastInteractionAt': c.lastInteractionAt?.toIso8601String(),
        };
      }).toList();
      final suggestion = await CampaignAiService.suggestMessageForSegment(
        currentMessage: _controller.text,
        totalCustomers: segment.customers.length,
        phoneCount: segment.activePhonesCount,
        sampleCustomers: sample,
      );
      if (!mounted) return;
      setState(() {
        _controller.text = suggestion;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      });
      if (mounted) {
        ref.read(bulkCampaignMessageProvider.notifier).setMessage(suggestion);
        AppToaster.success(
          context,
          AppLocalizations.of(context).t('ai_suggest_ready'),
        );
      }
    } catch (e) {
      if (mounted) {
        AppToaster.error(
          context,
          AppLocalizations.of(context).tArgs('ai_suggest_error', [e.toString().split('\n').first]),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppThemeExtension.of(context).surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: AppThemeExtension.of(context).border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space4,
              DesignTokens.space4,
              DesignTokens.space4,
              DesignTokens.space2,
            ),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context).t('message_text'),
                  style: TextStyle(
                    color: AppThemeExtension.of(context).textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: DesignTokens.fontSizeSm,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _loading ? null : _onSuggestPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: AppThemeExtension.of(context).accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space3,
                      vertical: DesignTokens.space1,
                    ),
                  ),
                  icon: _loading
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppThemeExtension.of(context).accent,
                          ),
                        )
                      : const Icon(Icons.bolt_rounded, size: 18),
                  label: Text(
                    _loading
                        ? AppLocalizations.of(context).t('ai_suggesting')
                        : AppLocalizations.of(context).t('ai_suggest'),
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeXs,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppThemeExtension.of(context).border),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: Consumer(
              builder: (context, ref, _) {
                return TextField(
                  controller: _controller,
                  maxLines: 6,
                  minLines: 4,
                  onChanged: (value) => ref
                      .read(bulkCampaignMessageProvider.notifier)
                      .setMessage(value),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: AppLocalizations.of(context).t('message_hint'),
                    hintStyle: TextStyle(
                      color: AppThemeExtension.of(context).textTertiary,
                      fontSize: DesignTokens.fontSizeSm,
                    ),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppThemeExtension.of(context).textPrimary,
                    height: 1.4,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.enabled,
    required this.segment,
    required this.message,
  });

  final bool enabled;
  final BulkCampaignSegment segment;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space6,
        DesignTokens.space3,
        DesignTokens.space6,
        DesignTokens.space5,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.9) : Colors.white,
        border: Border(
          top: BorderSide(color: AppThemeExtension.of(context).border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: !enabled
                    ? null
                    : () async {
                        final phone =
                            segment.phones.isNotEmpty ? segment.phones.first : null;
                        if (phone == null) return;
                        final ok = await WhatsAppLauncher.openChat(
                          phone,
                          message: message,
                        );
                        if (!context.mounted) return;
                        if (!ok) {
                          AppToaster.warning(
                            context,
                            'WhatsApp açılamadı.',
                          );
                        }
                      },
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: Text(AppLocalizations.of(context).t('whatsapp')),
              ),
            ),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: !enabled
                    ? null
                    : () async {
                        final ok = await SmsLauncher.openBulkSms(
                          segment.phones,
                          body: message,
                        );
                        if (!context.mounted) return;
                        if (!ok) {
                          AppToaster.warning(
                            context,
                            'Mesaj uygulaması açılamadı.',
                          );
                        }
                      },
                icon: const Icon(Icons.sms_rounded, size: 18),
                label: Text(AppLocalizations.of(context).t('sms')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

