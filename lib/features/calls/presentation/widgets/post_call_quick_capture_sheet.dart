import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/navigation/app_back_dispatcher.dart';
import 'package:emlakmaster_mobile/core/navigation/discard_changes_dialog.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/application/apply_quick_call_capture.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_capture_draft.dart';
import 'package:emlakmaster_mobile/features/calls/domain/quick_call_outcome.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/post_call_capture_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_outcome_chip_row.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/callback_enqueue_sheet.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_quick_note_snippets.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/calls_surface_ack.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

Future<void> showPostCallQuickCaptureSheet({
  required BuildContext context,
  required PostCallCaptureDraft draft,
}) async {
  await showPremiumScrollableBottomSheet<void>(
    context: context,
    maxHeightFactor: 0.92,
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
  bool _saved = false;
  bool _showAdvanced = false;
  String? _lastSaveButtonLogKey;
  String? _completedMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(postCallCaptureProvider.notifier).markCaptureInProgress();
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _appendQuickNoteSnippet(String snippet) {
    final line = snippet.trim();
    if (line.isEmpty) return;
    AppFeedback.selectionClick();
    final t = _noteCtrl.text.trim();
    setState(() {
      _noteCtrl.text = t.isEmpty ? line : '$t · $line';
      _noteCtrl.selection =
          TextSelection.collapsed(offset: _noteCtrl.text.length);
    });
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
      _saved = true;
      AppFeedback.mediumImpact();
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
      var ackLine = result.taskCreated
          ? 'Sonuç kaydedildi · takip eklendi'
          : 'Sonuç kaydedildi';
      final w = warn?.trim();
      if (w != null && w.isNotEmpty && w.length <= 72) {
        ackLine = '$ackLine · $w';
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final overlayCtx = messenger.context;
        if (!overlayCtx.mounted) return;
        showCallsSurfaceAck(
          overlayCtx,
          ackLine,
          icon: Icons.check_circle_rounded,
          duration: const Duration(milliseconds: 1700),
        );
        AppLogger.forensic('quick_capture_sheet: inline ack shown');
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

  Future<void> _onFastOutcome(String code) async {
    if (_saving) return;
    setState(() {
      _outcomeCode = code;
      if (code == QuickCallOutcome.callbackScheduled) {
        _followUpAt = DateTime.now().add(const Duration(minutes: 15));
        _createTask = true;
      }
    });
    await _save();
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

  bool get _captureDirty =>
      !_saved &&
      !_saving &&
      (_outcomeCode != null ||
          _noteCtrl.text.trim().isNotEmpty ||
          _createTask ||
          _followUpAt != null ||
          (_heatBand != null && _heatBand!.isNotEmpty));

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
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

    return PopScope(
      canPop: !_captureDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          if (!_saved && !_saving) {
            ref.read(postCallCaptureProvider.notifier).markCaptureAbandoned();
          }
          return;
        }
        if (!_captureDirty) return;
        final leave = await showDiscardChangesDialog(context);
        if (!mounted || leave != true) return;
        ref.read(postCallCaptureProvider.notifier).markCaptureAbandoned();
        AppBackDispatcher.popRoute(context);
      },
      child: PremiumScrollableBottomSheetShell(
        header: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.call_received_rounded,
              size: DesignTokens.iconLg,
              color: ext.accent.withValues(alpha: 0.5),
            ),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: PremiumSheetHeader(
                compact: true,
                title: 'Az önceki arama',
                subtitle: widget.draft.phone,
              ),
            ),
          ],
        ),
        bottomActions: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _openWizard,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusControl,
                        ),
                      ),
                      side: BorderSide(color: ext.borderSubtle),
                    ),
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
                    style: FilledButton.styleFrom(
                      backgroundColor: ext.accent,
                      foregroundColor: ext.onBrand,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusControl,
                        ),
                      ),
                    ),
                    child: _saving
                        ? SizedBox(
                            height: DesignTokens.iconMd,
                            width: DesignTokens.iconMd,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ext.onBrand,
                            ),
                          )
                        : Text(
                            _outcomeCode == null
                                ? 'Kaydet'
                                : 'Sonucu kaydet',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                      Icon(
                        Icons.bolt_rounded,
                        color: ext.accent,
                        size: DesignTokens.iconMd,
                      ),
                      const SizedBox(width: DesignTokens.space2),
                      Text(
                        'Çağrı zaten kayıtlı',
                        style: AppTypography.cardHeading(context)
                            .copyWith(fontSize: DesignTokens.fontSizeMd),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    'Bu adımda çağrıya yalnızca detay eklersiniz: sonuç, kısa not ve gerekirse takip görevi.',
                    style: AppTypography.body(context),
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    'Çağrı cihazınızın telefonunda yapıldı; süre burada ölçülmez.',
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
            const SizedBox(height: DesignTokens.space4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Hızlı not',
                style: AppTypography.cardHeading(context)
                    .copyWith(color: ext.textSecondary, fontSize: 14),
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Wrap(
              spacing: DesignTokens.space2,
              runSpacing: DesignTokens.space2,
              children: [
                for (final s in CallQuickNoteSnippets.labels)
                  Material(
                    color: ext.card,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusPill),
                    child: InkWell(
                      onTap: () => _appendQuickNoteSnippet(s),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusPill),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.space3,
                          vertical: DesignTokens.space1 + 2,
                        ),
                        child: Text(
                          s,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: ext.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: DesignTokens.fontSizeSm,
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.space4),
            Text(
              'Sonuç — dokunun, kaydedilsin',
              style: AppTypography.cardHeading(context)
                  .copyWith(color: ext.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: DesignTokens.space2),
            CallOutcomeChipRow(
              selectedCode: _outcomeCode,
              saving: _saving,
              onSelected: (c) => setState(() => _outcomeCode = c),
              onFastSave: _onFastOutcome,
            ),
            const SizedBox(height: DesignTokens.space2),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                child: Text(
                  _showAdvanced ? 'Gelişmiş alanları gizle' : 'Not / takip / sıcaklık',
                  style: TextStyle(color: ext.textSecondary, fontSize: 13),
                ),
              ),
            ),
            if (_outcomeCode == QuickCallOutcome.callbackScheduled) ...[
              const SizedBox(height: DesignTokens.space2),
              Consumer(
                builder: (context, ref, _) => Wrap(
                  spacing: DesignTokens.space2,
                  children: [
                    ActionChip(
                      label: const Text('Kuyruğa ekle'),
                      onPressed: () => showCallbackEnqueueSheet(
                        context,
                        ref,
                        phone: widget.draft.phone,
                        customerId: widget.draft.customerId,
                        source: 'post_call_capture',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_showAdvanced) ...[
            const SizedBox(height: DesignTokens.space3),
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
            const SizedBox(height: DesignTokens.space2),
            Row(
              children: [
                for (final h in const [
                  ('cold', 'Soğuk'),
                  ('warm', 'Ilık'),
                  ('hot', 'Sıcak'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: DesignTokens.space2),
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
              leading: Icon(
                Icons.event_rounded,
                color: ext.textSecondary,
                size: DesignTokens.iconMd,
              ),
              title: Text(
                _followUpAt == null
                    ? 'Takip tarihi seç (opsiyonel)'
                    : 'Takip: ${_followUpAt!.day}.${_followUpAt!.month}.${_followUpAt!.year}',
                style: AppTypography.bodyStrong(context),
              ),
              trailing: _followUpAt != null
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        size: DesignTokens.iconMd,
                      ),
                      onPressed: () => setState(() => _followUpAt = null),
                    )
                  : null,
              onTap: _pickDate,
            ),
            ],
            const SizedBox(height: DesignTokens.space2),
          ],
        ),
      ),
    );
  }
}
