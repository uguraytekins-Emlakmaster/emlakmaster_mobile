import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/resilience/safe_operation.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showCustomerEditSheet(
  BuildContext context,
  WidgetRef ref, {
  required String customerId,
  required CustomerEntity entity,
}) {
  final nameController = TextEditingController(text: entity.fullName ?? '');
  final phoneController =
      TextEditingController(text: entity.primaryPhone ?? '');
  final emailController = TextEditingController(text: entity.email ?? '');
  var saving = false;

  showPremiumModalBottomSheet<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModal) {
        final ext = AppThemeExtension.of(ctx);
        return PremiumScrollableBottomSheetShell(
          title: 'Müşteri düzenle',
          subtitle: 'Ad, telefon ve e-posta',
          bottomActions: FilledButton(
            onPressed: saving
                ? null
                : () async {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    if (name.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: const Text('Ad ve telefon zorunludur.'),
                          backgroundColor: ext.danger,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    setModal(() => saving = true);
                    try {
                      final email = emailController.text.trim();
                      await runWithResilienceWidget(
                        () => FirebaseFirestore.instance
                            .collection(AppConstants.colCustomers)
                            .doc(customerId)
                            .set(
                          {
                            'fullName': name,
                            'primaryPhone': phone,
                            if (email.isNotEmpty) 'email': email,
                            'updatedAt': FieldValue.serverTimestamp(),
                          },
                          SetOptions(merge: true),
                        ),
                        ref: ref,
                      );
                      ref.invalidate(customerEntityByIdProvider(customerId));
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Müşteri güncellendi.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Kaydedilemedi: $e'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } finally {
                      if (ctx.mounted) setModal(() => saving = false);
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: ext.accent,
              foregroundColor: ext.onBrand,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: saving
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ext.onBrand,
                    ),
                  )
                : const Text('Kaydet'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Ad soyad'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: DesignTokens.space3),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Telefon'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: DesignTokens.space3),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta (opsiyonel)',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        );
      },
    ),
  );
}
