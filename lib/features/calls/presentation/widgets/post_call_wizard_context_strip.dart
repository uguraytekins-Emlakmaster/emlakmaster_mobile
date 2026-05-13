import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/crm_call_record_display.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sihirbazın üstünde sabit: kim, bağlantı, kaydın anlamı — formlardan uzak, sakin özet.
class PostCallWizardContextStrip extends ConsumerWidget {
  const PostCallWizardContextStrip({
    super.key,
    required this.linkedCustomerId,
    required this.phoneNumber,
    required this.callSessionId,
    required this.isHandoffCall,
  });

  final String? linkedCustomerId;
  final String? phoneNumber;
  final String? callSessionId;
  final bool isHandoffCall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final linked = linkedCustomerId != null && linkedCustomerId!.trim().isNotEmpty;
    final rawPhone = phoneNumber?.trim() ?? '';
    final formatted = rawPhone.isNotEmpty
        ? CrmCallRecordDisplay.formatPhone(rawPhone)
        : null;

    final customerAsync = linked
        ? ref.watch(customerEntityByIdProvider(linkedCustomerId!.trim()))
        : const AsyncValue.data(null);

    final title = customerAsync.when(
      data: (c) {
        final n = c?.fullName?.trim();
        if (n != null && n.isNotEmpty) return n;
        if (formatted != null) return formatted;
        return 'Çağrı özeti';
      },
      loading: () => 'Müşteri bilgisi…',
      error: (_, __) => formatted ?? 'Çağrı özeti',
    );

    final subtitle = linked
        ? 'Özet müşteri kartına ve çağrı kaydına yazılır.'
        : 'Özet çağrı kaydı olarak saklanır; istediğinizde müşteriye bağlayabilirsiniz.';

    final sessionNote = callSessionId != null && callSessionId!.trim().isNotEmpty
        ? 'Çağrı oturumu: ${CrmCallRecordDisplay.ellipsedMiddle(callSessionId!.trim(), head: 5)}'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space3,
        DesignTokens.space4,
        DesignTokens.space3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardPrimary),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ext.surfaceElevated.withValues(alpha: 0.95),
            ext.surface.withValues(alpha: 0.88),
          ],
        ),
        border: Border.all(color: ext.borderSubtle.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ext.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Icon(Icons.call_end_rounded, color: ext.accent, size: 22),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.cardHeading(context).copyWith(
                        fontSize: DesignTokens.fontSizeMd + 1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (linked && formatted != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        formatted,
                        style: AppTypography.bodyStrong(context).copyWith(
                          color: ext.textSecondary,
                        ),
                      ),
                    ],
                    if (!linked && formatted != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        formatted,
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
          const SizedBox(height: DesignTokens.space3),
          Wrap(
            spacing: DesignTokens.space2,
            runSpacing: DesignTokens.space2,
            children: [
              _SoftChip(
                icon: linked ? Icons.link_rounded : Icons.call_split_rounded,
                label: linked ? 'Müşteri kartına bağlı' : 'Bağımsız kayıt',
                emphasized: linked,
              ),
              if (isHandoffCall)
                const _SoftChip(
                  icon: Icons.phone_in_talk_rounded,
                  label: 'Sistem araması',
                  emphasized: false,
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            subtitle,
            style: AppTypography.meta(context).copyWith(
              color: ext.textSecondary,
              height: 1.4,
            ),
          ),
          if (sessionNote != null) ...[
            const SizedBox(height: DesignTokens.space1),
            Text(
              sessionNote,
              style: AppTypography.meta(context).copyWith(
                color: ext.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({
    required this.icon,
    required this.label,
    required this.emphasized,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final fg = emphasized ? ext.accent : ext.textSecondary;
    final bg = emphasized
        ? ext.accent.withValues(alpha: 0.12)
        : ext.foregroundMuted.withValues(alpha: 0.08);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: fg.withValues(alpha: emphasized ? 0.35 : 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.meta(context).copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
