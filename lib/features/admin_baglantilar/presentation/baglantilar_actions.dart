import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/providers/baglantilar_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/utils/baglantilar_types.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform_id.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/platform_setup_wizard_args.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/providers/connected_platforms_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class BaglantilarActions {
  BaglantilarActions._();

  // ——— Hızlı rotalar (yalnızca geçerli, mevcut rotalar) ———

  static void openSetupWizard(BuildContext context) {
    AppFeedback.selectionClick();
    context.push(
      AppRouter.routePlatformSetupWizard,
      extra: const PlatformSetupWizardArgs(),
    );
  }

  static void openImportHub(BuildContext context) {
    AppFeedback.selectionClick();
    context.push(AppRouter.routeImportHub);
  }

  static void openMyExternalListings(BuildContext context) {
    AppFeedback.lightImpact();
    context.push(AppRouter.routeMyExternalListings);
  }

  static void openOfficeAdmin(BuildContext context) {
    AppFeedback.selectionClick();
    context.push(AppRouter.routeOfficeAdmin);
  }

  static void openAudit(BuildContext context) {
    AppFeedback.selectionClick();
    context.push(AppRouter.routeAdminAudit);
  }

  // ——— Satır aksiyonları (yalnızca yetkiyle, dürüst rotalar) ———

  static void connect(
    BuildContext context, {
    required bool canManage,
    required IntegrationPlatformId platformId,
  }) {
    _guarded(context, canManage, () {
      AppFeedback.selectionClick();
      context.push(
        AppRouter.routePlatformSetupWizard,
        extra: PlatformSetupWizardArgs(initialPlatform: platformId),
      );
    });
  }

  static void configure(
    BuildContext context, {
    required bool canManage,
    required IntegrationPlatformId platformId,
  }) {
    _guarded(context, canManage, () {
      AppFeedback.selectionClick();
      context.push(
        AppRouter.routePlatformSetupWizard,
        extra: PlatformSetupWizardArgs(
          initialPlatform: platformId,
          editMode: true,
        ),
      );
    });
  }

  static Future<void> retry(
    BuildContext context,
    WidgetRef ref, {
    required bool canManage,
    required String platformName,
  }) async {
    if (!canManage) {
      _adminToast(context);
      return;
    }
    final officeId = ref.read(baglantilarOfficeIdProvider);
    ref.invalidate(platformSetupMapProvider(officeId));
    _toast(context, '$platformName için yenileme istendi.');
  }

  static void retryLoad(WidgetRef ref) {
    final officeId = ref.read(baglantilarOfficeIdProvider);
    ref.invalidate(platformSetupMapProvider(officeId));
  }

  /// Birincil dokunuş: içe aktarma destekliyse listelere, değilse kurulum/detay.
  static void openPrimary(
    BuildContext context, {
    required bool canManage,
    required BaglantiRowViewModel row,
  }) {
    if (row.canImport) {
      openMyExternalListings(context);
      return;
    }
    if (row.canConnect) {
      connect(context, canManage: canManage, platformId: row.platformId);
      return;
    }
    showDetailSheet(context, row);
  }

  // ——— Detay ———

  static void showDetailSheet(BuildContext context, BaglantiRowViewModel row) {
    AppFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.platformName,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _DetailLine(label: 'Sağlayıcı', value: row.providerLine),
                _DetailLine(label: 'Durum', value: row.statusLabel),
                if (row.detailLine.isNotEmpty)
                  _DetailLine(label: 'Detay', value: row.detailLine),
                if (row.capabilityPills.isNotEmpty)
                  _DetailLine(
                    label: 'Yetenekler',
                    value: row.capabilityPills.join(' · '),
                  ),
                if (row.needsAdmin)
                  const _DetailLine(
                    label: 'Erişim',
                    value: 'Yapılandırma için admin yetkisi gerekir',
                  ),
                const SizedBox(height: 12),
                Text(
                  'Canlı OAuth/otomatik senkron yalnızca doğrulandığında “Bağlı” '
                  'sayılır; önizleme kartları yalnızca arayüz örneğidir.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      openOfficeAdmin(context);
                    },
                    icon: const Icon(Icons.apartment_outlined, size: 18),
                    label: const Text('Ofis Masasına git'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ——— Yardımcılar ———

  static void _guarded(
    BuildContext context,
    bool canManage,
    VoidCallback action,
  ) {
    if (!canManage) {
      _adminToast(context);
      return;
    }
    action();
  }

  static void _adminToast(BuildContext context) {
    _toast(context, 'Bu işlem için admin yetkisi gerekiyor.');
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
