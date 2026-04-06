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
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce bir sonuç seçin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
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
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.taskCreated
                ? 'Çağrı kaydı ve takip görevi kaydedildi.'
                : 'Çağrı kaydı kaydedildi.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, st) {
      if (kDebugMode) {
        AppLogger.e('[quick_capture_sheet] save failed', e, st);
      }
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(FirestoreService.userFacingErrorMessage(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
              const SizedBox(height: DesignTokens.metricLabelGap),
              Text(
                'Görüşme cihazınızın telefonunda yapıldı; süre burada ölçülmez.',
                style: AppTypography.meta(context),
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
              Wrap(
                spacing: DesignTokens.space2,
                runSpacing: DesignTokens.space2,
                children: [
                  for (final o in QuickCallOutcome.choices)
                    ChoiceChip(
                      label: Text(o.labelTr),
                      selected: _outcomeCode == o.code,
                      onSelected: (_) => setState(() => _outcomeCode = o.code),
                      selectedColor: ext.accent.withValues(alpha: 0.22),
                      labelStyle: TextStyle(
                        color: _outcomeCode == o.code
                            ? ext.textPrimary
                            : ext.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: DesignTokens.fontSizeSm,
                      ),
                    ),
                ],
              ),
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
                      onPressed: _saving ? null : _save,
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
            ],
          ),
        ),
      ),
    );
  }
}
