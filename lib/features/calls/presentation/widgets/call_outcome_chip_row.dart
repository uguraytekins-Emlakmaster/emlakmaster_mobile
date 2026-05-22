import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/domain/quick_call_outcome.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_outcome_style.dart';
import 'package:flutter/material.dart';

/// Tek dokunuşlu sonuç çipleri — yatay kaydırma, başparmak dostu.
class CallOutcomeChipRow extends StatelessWidget {
  const CallOutcomeChipRow({
    super.key,
    required this.selectedCode,
    required this.onSelected,
    this.onFastSave,
    this.saving = false,
  });

  final String? selectedCode;
  final ValueChanged<String> onSelected;
  final ValueChanged<String>? onFastSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: QuickCallOutcome.fastChips.length,
        separatorBuilder: (_, __) => const SizedBox(width: DesignTokens.space2),
        itemBuilder: (context, i) {
          final item = QuickCallOutcome.fastChips[i];
          final selected = selectedCode == item.code;
          final tone = CallOutcomeStyle.resolve(ext, item.labelTr);
          return Material(
            color: selected
                ? ext.accent.withValues(alpha: 0.18)
                : tone.fill,
            borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            child: InkWell(
              onTap: saving
                  ? null
                  : () {
                      AppFeedback.selectionClick();
                      onSelected(item.code);
                      onFastSave?.call(item.code);
                    },
              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space3,
                  vertical: DesignTokens.space2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                  border: Border.all(
                    color: selected
                        ? ext.accent.withValues(alpha: 0.5)
                        : tone.border,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.labelTr,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected ? ext.accent : tone.text,
                        fontWeight: FontWeight.w600,
                        fontSize: DesignTokens.fontSizeSm,
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
