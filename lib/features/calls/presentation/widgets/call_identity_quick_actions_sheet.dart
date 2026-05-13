import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/utils/sms_launcher.dart';
import 'package:emlakmaster_mobile/core/utils/whatsapp_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Kimlik (numara / kişi) dokunuşunda: hızlı, premium aksiyon yüzeyi.
Future<void> showCallIdentityQuickActionsSheet(
  BuildContext context, {
  required String rawPhone,
  String? customerId,
  String? displayLabel,
  String? firestoreCallDocId,
}) async {
  final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return;

  HapticFeedback.lightImpact();
  final sheetExt = AppThemeExtension.of(context);
  final theme = Theme.of(context);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: sheetExt.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DesignTokens.radiusLg),
      ),
    ),
    builder: (ctx) {
      final ext = AppThemeExtension.of(ctx);
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(
          DesignTokens.space4,
          DesignTokens.space2,
          DesignTokens.space4,
          DesignTokens.space4 + bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              displayLabel?.trim().isNotEmpty == true
                  ? displayLabel!.trim()
                  : 'Hızlı işlemler',
              style: theme.textTheme.titleMedium?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: DesignTokens.space1),
            Text(
              rawPhone,
              style: theme.textTheme.bodySmall?.copyWith(
                color: ext.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            _SheetTile(
              icon: Icons.call_rounded,
              label: 'Ara',
              color: ext.success,
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await OutboundPhoneDial.launchDial(rawPhone);
                if (!ok && ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Arama başlatılamadı.')),
                  );
                }
              },
            ),
            _SheetTile(
              icon: Icons.sms_outlined,
              label: 'Mesaj yaz',
              color: ext.info,
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await SmsLauncher.openBulkSms([rawPhone]);
                if (!ok && ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Mesaj uygulaması açılamadı.')),
                  );
                }
              },
            ),
            _SheetTile(
              icon: Icons.chat_rounded,
              label: 'WhatsApp aç',
              color: const Color(0xFF25D366),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await WhatsAppLauncher.openChat(rawPhone);
                if (!ok && ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('WhatsApp açılamadı.')),
                  );
                }
              },
            ),
            if (customerId != null && customerId.trim().isNotEmpty)
              _SheetTile(
                icon: Icons.person_rounded,
                label: 'Müşteri kartını aç',
                color: ext.accent,
                onTap: () {
                  Navigator.pop(ctx);
                  ctx.push('/customer/${customerId.trim()}');
                },
              ),
            _SheetTile(
              icon: Icons.edit_note_rounded,
              label: 'Görüşme özeti / not',
              color: ext.textPrimary,
              onTap: () {
                Navigator.pop(ctx);
                final cid = customerId?.trim();
                ctx.push(
                  AppRouter.routeCallSummary,
                  extra: <String, dynamic>{
                    if (cid != null && cid.isNotEmpty) 'customerId': cid,
                    'phone': rawPhone,
                    if (firestoreCallDocId != null &&
                        firestoreCallDocId.trim().isNotEmpty)
                      'callSessionId': firestoreCallDocId.trim(),
                  },
                );
              },
            ),
            _SheetTile(
              icon: Icons.dialpad_rounded,
              label: 'Görüşme ekranı',
              color: ext.textSecondary,
              onTap: () {
                Navigator.pop(ctx);
                final cid = customerId?.trim();
                ctx.push(
                  AppRouter.routeCall,
                  extra: <String, dynamic>{
                    'phone': rawPhone,
                    if (cid != null && cid.isNotEmpty) 'customerId': cid,
                    'startedFromScreen': 'call_identity_sheet',
                  },
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Material(
        color: ext.card,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space4,
              vertical: DesignTokens.space3,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: ext.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
