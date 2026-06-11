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

final DateFormat _timeFormat = DateFormat('HH:mm');
final DateFormat _dayTimeFormat = DateFormat('d MMM HH:mm', 'tr');

String _lastCallLabel(DateTime at, DateTime now) {
  final sameDay =
      at.year == now.year && at.month == now.month && at.day == now.day;
  return sameDay ? _timeFormat.format(at) : _dayTimeFormat.format(at);
}

/// Önemli bildirim pop-up'ı: kayıtsız numara hızlı kayıt.
///
/// Tasarım ilkesi: sakin, net, tek ana aksiyon. Süs yok, ölü buton yok.
/// "Hemen Kaydet" → kayıt sheet'i (numara önceden doldurulmuş); kayıt
/// sonrası çağrı geçmişi otomatik müşteriye bağlanır.
Future<void> showAxionCapturePopup(
  BuildContext context,
  WidgetRef ref,
  AxionUncapturedNumber number,
) async {
  AppFeedback.playNotification();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) =>
        _AxionCapturePopupDialog(number: number, hostRef: ref),
  );
}

class _AxionCapturePopupDialog extends StatelessWidget {
  const _AxionCapturePopupDialog({
    required this.number,
    required this.hostRef,
  });

  final AxionUncapturedNumber number;
  final WidgetRef hostRef;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeExtension.of(context);
    final now = DateTime.now();
    final contactName = (number.contactName ?? '').trim();
    final hasName = contactName.isNotEmpty;

    final metaParts = <String>[
      if (hasName) number.displayNumber,
      '${number.callCount} arama',
      if (number.missedCount > 0) '${number.missedCount} cevapsız',
      'son: ${_lastCallLabel(number.lastCallAt, now)}',
    ];

    return Dialog(
      backgroundColor: t.surface,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space5,
        vertical: DesignTokens.space6,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
        side: BorderSide(color: t.border.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: t.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    number.lastCallWasMissed
                        ? Icons.phone_missed_rounded
                        : Icons.phone_callback_rounded,
                    color: t.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kayıtsız numara',
                        style: TextStyle(
                          color: t.textSecondary,
                          fontSize: DesignTokens.fontSizeXs,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasName ? contactName : number.displayNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: DesignTokens.fontSizeLg,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Kapat',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: () => _snooze(context),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 22,
                    color: t.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space3),
            Text(
              metaParts.join(' · '),
              style: TextStyle(
                color: t.textSecondary,
                fontSize: DesignTokens.fontSizeSm,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Bu numara CRM\'de kayıtlı değil. Şimdi kaydedin; çağrı '
              'geçmişi otomatik olarak müşteriye bağlanır.',
              style: TextStyle(
                color: t.textTertiary,
                fontSize: DesignTokens.fontSizeXs,
                height: 1.45,
              ),
            ),
            const SizedBox(height: DesignTokens.space5),
            FilledButton.icon(
              onPressed: () => _save(context),
              style: FilledButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: t.onBrand,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusControl),
                ),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              label: const Text(
                'Hemen Kaydet',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _snooze(context),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      foregroundColor: t.textSecondary,
                    ),
                    child: const Text('Daha sonra'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => _dismiss(context),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      foregroundColor: t.textTertiary,
                    ),
                    child: const Text('Yoksay'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save(BuildContext dialogContext) {
    Navigator.of(dialogContext).pop();
    AppFeedback.selectionClick();
    showSaveContactSheet(
      dialogContext,
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
          AppLogger.e('AxionCapture linkCallsToCustomer', e, st);
        }
        await AxionCaptureDismissStore.instance.clear(number.normalizedKey);
        hostRef.invalidate(consultantCallsStreamProvider);
      },
    );
  }

  Future<void> _snooze(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    await AxionCaptureDismissStore.instance.snooze(number.normalizedKey);
    hostRef.invalidate(axionCapturePopupCandidateProvider);
  }

  Future<void> _dismiss(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    await AxionCaptureDismissStore.instance.dismiss(number.normalizedKey);
    hostRef.invalidate(axionCapturePopupCandidateProvider);
  }
}
