import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/resilience/safe_operation.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/utils/customer_crm_refresh.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class CustomerDetailWorkspaceFlows {
  CustomerDetailWorkspaceFlows._();

  static const _noteTemplates = [
    'Teklif gönderildi.',
    'Randevu alındı.',
    'Geri arama bırakıldı.',
    'İlan gösterildi.',
  ];

  static void showAddNoteSheet(
    BuildContext context,
    WidgetRef ref,
    String customerId,
  ) {
    final ext = AppThemeExtension.of(context);
    final controller = TextEditingController();
    showPremiumModalBottomSheet<void>(
      context: context,
      builder: (ctx) => PremiumScrollableBottomSheetShell(
        title: 'Not ekle',
        subtitle: 'Şablon seçin veya doğrudan yazın',
        bottomActions: FilledButton.icon(
          onPressed: () async {
            final content = controller.text.trim();
            if (content.isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: const Text('Lütfen not içeriği girin.'),
                  backgroundColor: ext.danger,
                ),
              );
              return;
            }
            final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
            if (uid.isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: const Text('Giriş yapılmamış.'),
                  backgroundColor: ext.danger,
                ),
              );
              return;
            }
            try {
              await runWithResilienceWidget(
                () => FirestoreService.saveNote(
                  customerId: customerId,
                  content: content,
                  advisorId: uid,
                ),
                ref: ref,
              );
              AppFeedback.mediumImpact();
              invalidateCustomerCrmCascade(ref, customerId);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: const Text('Not kaydedildi.'),
                    backgroundColor: ext.accent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(
                    FirestoreService.userFacingErrorMessage(e),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          icon: const Icon(Icons.save_rounded),
          label: const Text('Kaydet'),
          style: FilledButton.styleFrom(
            backgroundColor: ext.accent,
            foregroundColor: ext.onBrand,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: DesignTokens.space2,
              runSpacing: DesignTokens.space2,
              children: _noteTemplates.map((t) {
                return ActionChip(
                  label: Text(t),
                  onPressed: () {
                    controller.text =
                        controller.text.isEmpty ? t : '${controller.text}\n$t';
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: DesignTokens.space4),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Not metni…',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
