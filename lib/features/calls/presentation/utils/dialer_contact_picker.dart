import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/dialer_contact_directory.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_action_feedback.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';

/// Tuş takımından rehber kişisi seç — ilk telefon numarasını döner.
Future<String?> pickDialerContactPhone(BuildContext context) async {
  final loaded = await loadDialerContactDirectory();
  if (!context.mounted) return null;
  switch (loaded.perm) {
    case DialerContactsLoadResult.permanentlyDenied:
      await showPremiumActionFeedback(
        context,
        title: 'Rehber izni gerekli',
        message:
            'Numarayı rehberden seçmek için ayarlardan rehber erişimini açın.',
        type: PremiumActionFeedbackType.warning,
      );
      return null;
    case DialerContactsLoadResult.denied:
      await showPremiumActionFeedback(
        context,
        title: 'Rehber izni reddedildi',
        message:
            'İzin verirseniz kişi listesinden numara seçebilirsiniz; aksi halde tuş takımından girebilirsiniz.',
        type: PremiumActionFeedbackType.info,
      );
      return null;
    case DialerContactsLoadResult.granted:
      break;
  }

  final withPhone = loaded.contacts;

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
          final filtered = query.trim().isEmpty
              ? withPhone
              : filterDialerContacts(withPhone, query);

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
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: ext.accent.withValues(alpha: 0.12),
                        child: Text(
                          c.displayName.isNotEmpty
                              ? c.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(color: ext.accent),
                        ),
                      ),
                      title: Text(
                        c.displayName.isEmpty ? 'İsimsiz' : c.displayName,
                        style: AppTypography.bodyStrong(ctx),
                      ),
                      subtitle: Text(
                        c.phoneDisplay,
                        style: AppTypography.meta(ctx),
                      ),
                      onTap: () => Navigator.pop(ctx, c.phoneDigits),
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
