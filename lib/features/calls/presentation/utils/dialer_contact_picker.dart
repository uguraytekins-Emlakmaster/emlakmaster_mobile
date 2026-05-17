import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/contact_save/data/contact_permission_helper.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_action_feedback.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

/// Tuş takımından rehber kişisi seç — ilk telefon numarasını döner.
Future<String?> pickDialerContactPhone(BuildContext context) async {
  final perm =
      await ContactPermissionHelper.instance.requestContactPermission();
  if (!context.mounted) return null;
  switch (perm) {
    case ContactPermissionResult.permanentlyDenied:
      await showPremiumActionFeedback(
        context,
        title: 'Rehber izni gerekli',
        message:
            'Numarayı rehberden seçmek için ayarlardan rehber erişimini açın.',
        type: PremiumActionFeedbackType.warning,
      );
      return null;
    case ContactPermissionResult.denied:
      await showPremiumActionFeedback(
        context,
        title: 'Rehber izni reddedildi',
        message:
            'İzin verirseniz kişi listesinden numara seçebilirsiniz; aksi halde tuş takımından girebilirsiniz.',
        type: PremiumActionFeedbackType.info,
      );
      return null;
    case ContactPermissionResult.granted:
      break;
  }

  final contacts = await FlutterContacts.getAll(
    properties: {ContactProperty.phone},
  );
  if (!context.mounted) return null;

  final withPhone = contacts
      .where((c) => c.phones.isNotEmpty)
      .toList()
    ..sort(
      (a, b) => (a.displayName ?? '')
          .toLowerCase()
          .compareTo((b.displayName ?? '').toLowerCase()),
    );

  if (withPhone.isEmpty) {
    await showPremiumActionFeedback(
      context,
      title: 'Telefonlu kişi yok',
      message: 'Rehberinizde kayıtlı telefon numarası bulunamadı.',
      type: PremiumActionFeedbackType.info,
    );
    return null;
  }

  return showPremiumScrollableBottomSheet<String>(
    context: context,
    maxHeightFactor: 0.88,
    builder: (ctx) {
      final ext = AppThemeExtension.of(ctx);
      var query = '';
      return StatefulBuilder(
        builder: (ctx, setModal) {
          final q = query.trim().toLowerCase();
          final filtered = q.isEmpty
              ? withPhone
              : withPhone.where((c) {
                  final name = (c.displayName ?? '').toLowerCase();
                  final phones = c.phones
                      .map((p) => p.number.replaceAll(RegExp(r'\D'), ''))
                      .join(' ');
                  return name.contains(q) || phones.contains(q.replaceAll(RegExp(r'\D'), ''));
                }).toList();

          return PremiumScrollableBottomSheetShell(
            title: 'Rehberden seç',
            subtitle: '${withPhone.length} kişi',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'İsim veya numara ara',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: ext.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusControl),
                    ),
                  ),
                  onChanged: (v) => setModal(() => query = v),
                ),
                const SizedBox(height: DesignTokens.space3),
                if (filtered.isEmpty)
                  Text(
                    'Eşleşen kişi yok',
                    style: AppTypography.body(ctx).copyWith(
                      color: ext.textSecondary,
                    ),
                  )
                else
                  ...filtered.take(80).map((c) {
                    final phone = c.phones.first.number;
                    final digits = OutboundPhoneDial.digitsOnly(phone);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: ext.accent.withValues(alpha: 0.12),
                        child: Text(
                          (c.displayName ?? '').isNotEmpty
                              ? (c.displayName ?? '')[0].toUpperCase()
                              : '?',
                          style: TextStyle(color: ext.accent),
                        ),
                      ),
                      title: Text(
                        (c.displayName ?? '').isEmpty
                            ? 'İsimsiz'
                            : c.displayName!,
                        style: AppTypography.bodyStrong(ctx),
                      ),
                      subtitle: Text(
                        phone,
                        style: AppTypography.meta(ctx),
                      ),
                      onTap: () => Navigator.pop(ctx, digits),
                    );
                  }),
              ],
            ),
          );
        },
      );
    },
  );
}
