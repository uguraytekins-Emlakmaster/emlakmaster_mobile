import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/application/apply_quick_call_capture.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_capture_draft.dart';
import 'package:emlakmaster_mobile/features/calls/domain/quick_call_outcome.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';

Future<void> showPostCallQuickCaptureSheet({
  required BuildContext context,
  required PostCallCaptureDraft draft,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PostCallQuickCaptureBody(draft: draft),
  );
}

class _PostCallQuickCaptureBody extends ConsumerStatefulWidget {
  const _PostCallQuickCaptureBody({required this.draft});

  final PostCallCaptureDraft draft;

  @override
  ConsumerState<_PostCallQuickCaptureBody> createState() =>
      _PostCallQuickCaptureBodyState();
}

class _PostCallQuickCaptureBodyState
    extends ConsumerState<_PostCallQuickCaptureBody> {
  String? _outcomeCode;
  final _noteCtrl = TextEditingController();
  bool _createTask = false;
  DateTime? _followUpAt;
  String? _heatBand;
  bool _saving = false;
  String? _lastSaveButtonLogKey;
  String? _completedMessage;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _followUpAt ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null && mounted) {
      setState(() => _followUpAt = DateTime(d.year, d.month, d.day, 10));
    }
  }

  Future<void> _save() async {
    final code = _outcomeCode;
    AppLogger.forensic(
      'quick_capture_sheet: _save entered saving=$_saving outcome=${code ?? '-'}',
    );
    if (code == null) {
      AppLogger.forensic(
        'quick_capture_sheet: EARLY_RETURN no outcome selected',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce bir sonuç seçin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    AppLogger.forensic(
      'quick_capture_sheet: saving state set true',
    );
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      AppLogger.forensic(
        'quick_capture_sheet: Kaydet pressed code=$code task=$_createTask',
      );
      if (kDebugMode) {
        AppLogger.d(
          '[quick_capture_sheet] save tap code=$code heat=${_heatBand ?? '-'} '
          'task=$_createTask due=${_followUpAt?.toIso8601String() ?? '-'}',
        );
      }
      final result = await applyQuickCallCapture(
        ref: ref,
        context: context,
        draft: widget.draft,
        outcomeCode: code,
        note: _noteCtrl.text,
        followUpReminderAt: _followUpAt,
        createFollowUpTask: _createTask,
        heatBand: _heatBand,
      );
      AppLogger.forensic('quick_capture_sheet: engine returned ok');
      if (!mounted) {
        AppLogger.forensic(
          'quick_capture_sheet: unmounted after save (no sheet pop)',
        );
        return;
      }
      HapticFeedback.mediumImpact();
      var okMessage = result.taskCreated
          ? 'Çağrı kaydı ve takip görevi kaydedildi.'
          : 'Çağrı kaydı kaydedildi.';
      final warn = result.enrichmentWarningTr;
      if (warn != null && warn.trim().isNotEmpty) {
        okMessage = '$okMessage\n\n$warn';
      }
      var closed = false;
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
        closed = true;
        AppLogger.forensic(
          'quick_capture_sheet: rootNavigator.pop done',
        );
      } else if (navigator.canPop()) {
        navigator.pop();
        closed = true;
        AppLogger.forensic(
          'quick_capture_sheet: local Navigator.pop done',
        );
      } else {
        AppLogger.forensic(
          'quick_capture_sheet: no navigator pop target, showing completed state',
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ex = AppThemeExtension.of(context);
        messenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: ex.surface.withValues(alpha: 0.9),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: ex.border.withValues(alpha: 0.5)),
            ),
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: ex.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    okMessage,
                    style: AppTypography.bodyStrong(context)
                        .copyWith(color: ex.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
        AppLogger.forensic(
            'quick_capture_sheet: SnackBar scheduled post-frame');
      });
      if (!closed && mounted) {
        setState(() {
          _completedMessage = okMessage;
        });
      }
      AppLogger.forensic('quick_capture_sheet: FINAL completion reached');
    } catch (e, st) {
      AppLogger.forensic(
        'quick_capture_sheet: FINAL error ${e.runtimeType}',
      );
      AppLogger.e('[quick_capture_sheet] save failed', e, st);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(FirestoreService.userFacingErrorMessage(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _onSavePressed() async {
    AppLogger.forensic(
      'quick_capture_sheet: onPressed first line '
      'saving=$_saving outcome=${_outcomeCode ?? '-'} '
      'session=${widget.draft.callSessionId} '
      'customer=${widget.draft.customerId ?? '-'} '
      'task=$_createTask followUp=${_followUpAt?.toIso8601String() ?? '-'}',
    );
    if (_saving) {
      AppLogger.forensic(
        'quick_capture_sheet: EARLY_RETURN blocked because saving=true',
      );
      return;
    }
    await _save();
  }

  void _openWizard() {
    Navigator.of(context).pop();
    context.push(
      AppRouter.routeCallSummary,
      extra: {
        'outcome': AppConstants.callOutcomeSystemHandoff,
        'durationSec': null,
        if (widget.draft.customerId != null &&
            widget.draft.customerId!.isNotEmpty)
          'customerId': widget.draft.customerId,
        'phone': widget.draft.phone,
        'callSessionId': widget.draft.callSessionId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final ime = MediaQuery.viewInsetsOf(context).bottom;
    final saveOnPressed = _saving ? null : _onSavePressed;
    final buttonLogKey = [
      saveOnPressed == null ? 'disabled' : 'enabled',
      'saving=$_saving',
      'outcome=${_outcomeCode ?? '-'}',
      'task=$_createTask',
      'crmTracked=${widget.draft.crmSessionTracked}',
    ].join('|');
    if (_lastSaveButtonLogKey != buttonLogKey) {
      _lastSaveButtonLogKey = buttonLogKey;
      AppLogger.forensic(
        'quick_capture_sheet: button wiring $buttonLogKey',
      );
    }

    return Material(
      color: ext.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(DesignTokens.radiusSheet),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          DesignTokens.space5,
          DesignTokens.space3,
          DesignTokens.space5,
          DesignTokens.space5 + bottom + ime,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PremiumBottomSheetHandle(),
              Text(
                'Az önceki arama',
                style: AppTypography.pageHeading(context)
                    .copyWith(fontSize: DesignTokens.fontSizeXl),
              ),
              const SizedBox(height: DesignTokens.titleSubtitleGap),
              Text(
                widget.draft.phone,
                style: AppTypography.bodyStrong(context)
                    .copyWith(color: ext.textSecondary),
              ),
              const SizedBox(height: DesignTokens.space3),
              Container(
                padding: const EdgeInsets.all(DesignTokens.space4),
                decoration: BoxDecoration(
                  color: ext.surfaceElevated,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  border: Border.all(color: ext.border.withValues(alpha: 0.45)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bolt_rounded, color: ext.accent, size: 18),
                        const SizedBox(width: DesignTokens.space2),
                        Text(
                          'Cagri zaten kayitli',
                          style: AppTypography.cardHeading(context)
                              .copyWith(fontSize: DesignTokens.fontSizeMd),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      'Bu adimda cagriya sadece detay eklersin: sonuc, kisa not ve gerekirse takip gorevi.',
                      style: AppTypography.body(context),
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      'Görüşme cihazınızın telefonunda yapıldı; süre burada ölçülmez.',
                      style: AppTypography.meta(context),
                    ),
                  ],
                ),
              ),
              if (!widget.draft.crmSessionTracked) ...[
                const SizedBox(height: DesignTokens.space3),
                Text(
                  'CRM çağrı oturumu açılamadı; kayıt yeni bir satır olarak eklenecek.',
                  style: AppTypography.body(context),
                ),
              ],
              const SizedBox(height: DesignTokens.space5),
              Text(
                'Sonuç',
                style: AppTypography.cardHeading(context)
                    .copyWith(color: ext.textSecondary),
              ),
              const SizedBox(height: DesignTokens.sectionTitleGap),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width =
                      (constraints.maxWidth - DesignTokens.space2) / 2;
                  return Wrap(
                    spacing: DesignTokens.space2,
                    runSpacing: DesignTokens.space2,
                    children: [
                      for (final o in QuickCallOutcome.choices)
                        SizedBox(
                          width: width,
                          child: _OutcomeOptionCard(
                            item: o,
                            selected: _outcomeCode == o.code,
                            onTap: () => setState(() => _outcomeCode = o.code),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (_outcomeCode != null) ...[
                const SizedBox(height: DesignTokens.space3),
                Text(
                  _outcomeHint(_outcomeCode!),
                  style: AppTypography.body(context),
                ),
              ],
              const SizedBox(height: DesignTokens.space4),
              TextField(
                controller: _noteCtrl,
                maxLines: 2,
                style: AppTypography.bodyStrong(context)
                    .copyWith(color: ext.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Kısa not (opsiyonel)',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: ext.surface.withValues(alpha: 0.6),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusControl),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.space4),
              Text(
                'Sıcaklık (opsiyonel)',
                style: AppTypography.cardHeading(context)
                    .copyWith(color: ext.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final h in const [
                    ('cold', 'Soğuk'),
                    ('warm', 'Ilık'),
                    ('hot', 'Sıcak'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(h.$2),
                        selected: _heatBand == h.$1,
                        onSelected: (_) => setState(
                            () => _heatBand = _heatBand == h.$1 ? null : h.$1),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: DesignTokens.space4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Görev oluştur',
                  style: AppTypography.bodyStrong(context),
                ),
                subtitle: Text(
                  'Takip için görev satırı eklenir',
                  style: AppTypography.meta(context),
                ),
                value: _createTask,
                onChanged: (v) => setState(() => _createTask = v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.event_rounded, color: ext.accent, size: 22),
                title: Text(
                  _followUpAt == null
                      ? 'Takip tarihi seç (opsiyonel)'
                      : 'Takip: ${_followUpAt!.day}.${_followUpAt!.month}.${_followUpAt!.year}',
                  style: AppTypography.bodyStrong(context),
                ),
                trailing: _followUpAt != null
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () => setState(() => _followUpAt = null),
                      )
                    : null,
                onTap: _pickDate,
              ),
              const SizedBox(height: DesignTokens.space3),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _openWizard,
                      child: Text(
                        'Detaylı sihirbaz',
                        style: AppTypography.secondaryButton(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space3),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: saveOnPressed,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Kaydet',
                              style: AppTypography.primaryButton(context),
                            ),
                    ),
                  ),
                ],
              ),
              if (_completedMessage != null) ...[
                const SizedBox(height: DesignTokens.space3),
                Container(
                  padding: const EdgeInsets.all(DesignTokens.space3),
                  decoration: BoxDecoration(
                    color: ext.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    border: Border.all(
                      color: ext.success.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    _completedMessage!,
                    style: AppTypography.bodyStrong(context)
                        .copyWith(color: ext.success),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _outcomeHint(String code) {
  switch (code) {
    case QuickCallOutcome.reached:
      return 'Müşteriyle temas kuruldu. Kısa not ve sıcaklık seçimiyle kaydı tamamlayabilirsin.';
    case QuickCallOutcome.noAnswer:
      return 'Müşteriye ulaşılamadı. İstersen hemen bir takip görevi planlayabilirsin.';
    case QuickCallOutcome.busy:
      return 'Müşteri meşguldü. Uygun bir takip tarihi seçmek iyi olur.';
    case QuickCallOutcome.callbackScheduled:
      return 'Geri dönüş planlandı. Takip tarihi ekleyerek akışı netleştirebilirsin.';
    case QuickCallOutcome.appointmentSet:
      return 'Randevu oluşturuldu. Bu kayıt müşteri akışını güçlendirecek.';
    case QuickCallOutcome.offerSent:
      return 'Teklif paylaşıldı. Not düşerek satış bağlamını koruyabilirsin.';
    default:
      return 'Çağrı sonucunu kaydettiğinde CRM akışı hemen güncellenir.';
  }
}

IconData _outcomeIcon(String code) {
  switch (code) {
    case QuickCallOutcome.reached:
      return Icons.check_circle_rounded;
    case QuickCallOutcome.noAnswer:
      return Icons.phone_missed_rounded;
    case QuickCallOutcome.busy:
      return Icons.do_not_disturb_on_total_silence_rounded;
    case QuickCallOutcome.callbackScheduled:
      return Icons.schedule_rounded;
    case QuickCallOutcome.appointmentSet:
      return Icons.event_available_rounded;
    case QuickCallOutcome.offerSent:
      return Icons.description_rounded;
    default:
      return Icons.call_rounded;
  }
}

class _OutcomeOptionCard extends StatelessWidget {
  const _OutcomeOptionCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final QuickCallOutcomeItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color:
          selected ? ext.accent.withValues(alpha: 0.14) : ext.surfaceElevated,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.space3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(
              color: selected
                  ? ext.accent.withValues(alpha: 0.45)
                  : ext.border.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _outcomeIcon(item.code),
                size: 18,
                color: selected ? ext.accent : ext.textSecondary,
              ),
              const SizedBox(width: DesignTokens.space2),
              Expanded(
                child: Text(
                  item.labelTr,
                  style: AppTypography.bodyStrong(context).copyWith(
                    color: selected ? ext.textPrimary : ext.textSecondary,
                    fontSize: DesignTokens.fontSizeBase,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
