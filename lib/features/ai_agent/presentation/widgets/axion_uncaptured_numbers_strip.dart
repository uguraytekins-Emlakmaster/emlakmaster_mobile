import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/contact_save/presentation/widgets/save_contact_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/axion_capture_dismiss_store.dart';
import '../../domain/axion_uncaptured_number.dart';
import '../providers/axion_agent_providers.dart';

final DateFormat _stripTimeFormat = DateFormat('HH:mm');
final DateFormat _stripDayFormat = DateFormat('d MMM', 'tr');

/// "Benim Günüm" — kayıtsız numara şeridi.
///
/// Çağrı geçmişinde olup CRM'de olmayan numaraları tek dokunuşla
/// kaydettirir. Boşken hiç çizilmez; sahte içerik yok.
class AxionUncapturedNumbersStrip extends ConsumerWidget {
  const AxionUncapturedNumbersStrip({super.key});

  static const int _maxVisible = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numbers = ref.watch(axionUncapturedNumbersProvider);
    if (numbers.isEmpty) return const SizedBox.shrink();

    final visibleToday =
        ref.watch(axionUncapturedStripVisibleProvider).valueOrNull ?? true;
    if (!visibleToday) return const SizedBox.shrink();

    final t = AppThemeExtension.of(context);
    final visible = numbers.take(_maxVisible).toList(growable: false);
    final hiddenCount = numbers.length - visible.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space2,
        DesignTokens.space4,
        DesignTokens.space4,
      ),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space4),
        decoration: BoxDecoration(
          color: t.surfaceElevated,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(color: t.warning.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_missed_rounded, size: 16, color: t.warning),
                const SizedBox(width: DesignTokens.space2),
                Expanded(
                  child: Text(
                    'Kayıtsız numaralar',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBase,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${numbers.length} numara',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXs,
                    color: t.textPassive,
                  ),
                ),
                const SizedBox(width: DesignTokens.space1),
                IconButton(
                  tooltip: 'Bugünlük kapat',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () async {
                    AppFeedback.selectionClick();
                    await AxionCaptureDismissStore.instance.hideStripForToday();
                    ref.invalidate(axionUncapturedStripVisibleProvider);
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: t.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space1),
            Text(
              'Aranan ama CRM\'de olmayan numaralar — tek dokunuşla kaydedin.',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXs,
                color: t.textTertiary,
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            for (final n in visible) _NumberRow(number: n),
            if (hiddenCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: DesignTokens.space1),
                child: Text(
                  '+$hiddenCount numara daha — Çağrılar sekmesinden ulaşabilirsiniz.',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXs,
                    color: t.textPassive,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NumberRow extends ConsumerWidget {
  const _NumberRow({required this.number});

  final AxionUncapturedNumber number;

  String _timeLabel(DateTime at, DateTime now) {
    final sameDay =
        at.year == now.year && at.month == now.month && at.day == now.day;
    return sameDay ? _stripTimeFormat.format(at) : _stripDayFormat.format(at);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppThemeExtension.of(context);
    final now = DateTime.now();
    final hasName = (number.contactName ?? '').trim().isNotEmpty;
    final meta = [
      if (hasName) number.displayNumber,
      '${number.callCount} arama',
      if (number.missedCount > 0) '${number.missedCount} cevapsız',
      _timeLabel(number.lastCallAt, now),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? number.contactName!.trim() : number.displayNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSm,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXs,
                    color: t.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
          FilledButton(
            onPressed: () => _save(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: t.onBrand,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
              ),
            ),
            child: const Text(
              'Kaydet',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _save(BuildContext context, WidgetRef ref) {
    AppFeedback.selectionClick();
    showSaveContactSheet(
      context,
      initialName: number.contactName,
      initialPhone: number.displayNumber,
      source: 'axion_agent_kayitsiz_numara',
      onSavedToApp: (customerId) async {
        try {
          await FirestoreService.linkCallsToCustomer(
            callDocIds: number.callDocIds,
            customerId: customerId,
          );
        } catch (e, st) {
          AppLogger.e('AxionUncapturedStrip linkCallsToCustomer', e, st);
        }
        ref.invalidate(consultantCallsStreamProvider);
      },
    );
  }
}
