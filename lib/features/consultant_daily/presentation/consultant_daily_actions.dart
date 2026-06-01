import 'package:emlakmaster_mobile/core/navigation/main_shell_shortcut_provider.dart';
import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/utils/whatsapp_launcher.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/consultant_daily/presentation/utils/consultant_daily_types.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/providers/advisor_tasks_stream_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tüm görünür aksiyonlar tek yerde — dead button yok; her aksiyon gerçek bir
/// kabuk sekmesine, müşteri detayına veya sistem arama/mesaj akışına bağlanır.
abstract final class ConsultantDailyActions {
  ConsultantDailyActions._();

  static void open(WidgetRef ref, BuildContext context, ConsultantDailyEntry e) {
    switch (e.actionKind) {
      case DailyActionKind.openTasks:
        _goTab(ref, context, MainShellShortcut.openTasksTab);
        break;
      case DailyActionKind.openCustomer:
        goToCustomer(ref, context, e);
        break;
      case DailyActionKind.call:
        call(context, e);
        break;
      case DailyActionKind.message:
        message(context, e);
        break;
    }
  }

  static void goToCustomer(
    WidgetRef ref,
    BuildContext context,
    ConsultantDailyEntry e,
  ) {
    final id = e.customerId;
    if (id != null && id.isNotEmpty) {
      context.push('/customer/$id');
    } else {
      _goTab(ref, context, MainShellShortcut.openCustomersTab);
    }
  }

  static void goToTasks(WidgetRef ref, BuildContext context) =>
      _goTab(ref, context, MainShellShortcut.openTasksTab);

  static void _goTab(
    WidgetRef ref,
    BuildContext context,
    MainShellShortcut shortcut,
  ) {
    ref.read(mainShellShortcutProvider.notifier).enqueue(shortcut);
    context.go(AppRouter.routeHome);
  }

  static Future<void> call(BuildContext context, ConsultantDailyEntry e) async {
    final phone = e.phone ?? '';
    if (!OutboundPhoneDial.isLikelyCallablePhone(phone)) {
      _snack(context, 'Aranabilir numara kayıtlı değil.');
      return;
    }
    final ok = await OutboundPhoneDial.launchDial(phone);
    if (!ok && context.mounted) {
      _snack(context, 'Sistem telefon uygulaması açılamadı.');
    }
  }

  static Future<void> message(
    BuildContext context,
    ConsultantDailyEntry e,
  ) async {
    final phone = e.phone ?? '';
    if (phone.trim().isEmpty) {
      _snack(context, 'Mesaj için numara kayıtlı değil.');
      return;
    }
    final ok = await WhatsAppLauncher.openChat(phone);
    if (!ok && context.mounted) {
      _snack(context, 'WhatsApp açılamadı.');
    }
  }

  static void refresh(WidgetRef ref) {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isNotEmpty) {
      ref.invalidate(advisorTasksStreamProvider(uid));
    }
    ref.invalidate(customerListForAgentProvider);
    ref.invalidate(consultantCallsStreamProvider);
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<void> showDetailSheet(
    BuildContext context,
    WidgetRef ref,
    ConsultantDailyEntry e,
  ) {
    final ext = AppThemeExtension.of(context);
    final canCall = OutboundPhoneDial.isLikelyCallablePhone(e.phone ?? '');
    final hasPhone = (e.phone ?? '').trim().isNotEmpty;

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: ext.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ext.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  e.title,
                  style: TextStyle(
                    color: ext.textPrimary,
                    fontSize: DesignTokens.fontSizeLg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${e.typeLabel} · ${e.statusLabel} · ${e.timeLabel}',
                  style: TextStyle(
                    color: ext.textSecondary,
                    fontSize: DesignTokens.fontSizeSm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _DetailLine(label: 'Detay', value: e.detail),
                _DetailLine(label: 'Bağlam', value: e.context),
                if (e.isPartial)
                  const _DetailLine(
                    label: 'Kapsam',
                    value:
                        'Bu kayıt için sunucuda yeterli sinyal yok; baskı dürüstçe hesaplanamıyor.',
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    open(ref, context, e);
                  },
                  icon: Icon(_primaryIcon(e.actionKind), size: 18),
                  label: Text(e.actionLabel),
                ),
                if (e.customerId != null && hasPhone) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: canCall
                              ? () {
                                  Navigator.of(sheetContext).pop();
                                  call(context, e);
                                }
                              : null,
                          icon: const Icon(Icons.call_rounded, size: 18),
                          label: const Text('Ara'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            message(context, e);
                          },
                          icon: const Icon(Icons.chat_rounded, size: 18),
                          label: const Text('Mesaj'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static IconData _primaryIcon(DailyActionKind kind) {
    switch (kind) {
      case DailyActionKind.openTasks:
        return Icons.checklist_rounded;
      case DailyActionKind.openCustomer:
        return Icons.person_rounded;
      case DailyActionKind.call:
        return Icons.call_rounded;
      case DailyActionKind.message:
        return Icons.chat_rounded;
    }
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: ext.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: ext.textPrimary,
              fontSize: DesignTokens.fontSizeSm,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
