import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/application/apply_quick_call_capture.dart';
import 'package:emlakmaster_mobile/features/calls/data/post_call_capture_draft.dart';
import 'package:emlakmaster_mobile/features/calls/domain/quick_call_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    try {
      await applyQuickCallCapture(
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
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çağrı kaydı güncellendi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt başarısız: $e'),
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
      color: ext.surfaceElevated,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom + ime),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ext.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Az önceki arama',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.draft.phone,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: ext.textSecondary,
                      letterSpacing: 0.4,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Görüşme cihazınızın telefonunda yapıldı; süre burada ölçülmez.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ext.textTertiary,
                      height: 1.35,
                    ),
              ),
              if (!widget.draft.crmSessionTracked) ...[
                const SizedBox(height: 10),
                Text(
                  'CRM çağrı oturumu açılamadı; kayıt yeni bir satır olarak eklenecek.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ext.textSecondary,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                'Sonuç',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: ext.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteCtrl,
                maxLines: 2,
                style: TextStyle(color: ext.textPrimary, fontSize: 14),
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
              const SizedBox(height: 14),
              Text(
                'Sıcaklık (opsiyonel)',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: ext.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
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
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Görev oluştur',
                  style: TextStyle(color: ext.textPrimary, fontSize: 14),
                ),
                subtitle: Text(
                  'Takip için görev satırı eklenir',
                  style: TextStyle(color: ext.textTertiary, fontSize: 12),
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
                  style: TextStyle(color: ext.textPrimary, fontSize: 14),
                ),
                trailing: _followUpAt != null
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () => setState(() => _followUpAt = null),
                      )
                    : null,
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _openWizard,
                      child: const Text('Detaylı sihirbaz'),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          : const Text('Kaydet'),
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
