import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/utils/sms_launcher.dart';
import 'package:emlakmaster_mobile/core/utils/whatsapp_launcher.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_quick_note_snippets.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/calls_surface_ack.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/crm_call_record_display.dart';
import 'package:emlakmaster_mobile/features/contact_save/presentation/widgets/save_contact_sheet.dart';
import 'package:emlakmaster_mobile/screens/consultant_shell_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

/// Kimlik (numara / kişi) dokunuşunda: hızlı, premium aksiyon yüzeyi.
Future<void> showCallIdentityQuickActionsSheet(
  BuildContext context, {
  required String rawPhone,
  String? customerId,
  String? displayLabel,
  String? firestoreCallDocId,
  VoidCallback? onCallListMutated,
  VoidCallback? onOpenCustomerDirectory,
}) async {
  final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return;

  final anchor = context;

  AppFeedback.lightImpact();
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
      final cid = customerId?.trim();
      final hasCustomer = cid != null && cid.isNotEmpty;
      final label = displayLabel?.trim();
      final initialName = (label != null &&
              label.isNotEmpty &&
              label != CrmCallRecordDisplay.formatPhone(rawPhone))
          ? label
          : null;
      final initialPhone = CrmCallRecordDisplay.formatPhone(rawPhone);

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
              label?.isNotEmpty == true ? label! : 'Hızlı işlemler',
              style: theme.textTheme.titleMedium?.copyWith(
                color: ext.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: DesignTokens.space1),
            Text(
              rawPhone,
              style: theme.textTheme.bodySmall?.copyWith(
                color: ext.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hasCustomer) ...[
              const SizedBox(height: DesignTokens.space2),
              Text(
                'Müşteri kartına bağlı — özet ve geçmiş için kartı açın.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: ext.textTertiary,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
            if (firestoreCallDocId != null &&
                firestoreCallDocId.trim().isNotEmpty) ...[
              const SizedBox(height: DesignTokens.space3),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hızlı not',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: ext.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.04,
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.space2),
              Wrap(
                spacing: DesignTokens.space2,
                runSpacing: DesignTokens.space2,
                children: [
                  for (final snippet in CallQuickNoteSnippets.labels)
                    Material(
                      color: ext.card,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusPill),
                      child: InkWell(
                        onTap: () async {
                          AppFeedback.selectionClick();
                          final id = firestoreCallDocId.trim();
                          await FirestoreService.appendQuickCaptureNoteSnippet(
                            callId: id,
                            snippet: snippet,
                          );
                          if (!anchor.mounted) return;
                          AppFeedback.mediumImpact();
                          onCallListMutated?.call();
                          showCallsSurfaceAck(
                            anchor,
                            'Not eklendi',
                            icon: Icons.check_rounded,
                          );
                        },
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusPill),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.space3,
                            vertical: DesignTokens.space1 + 2,
                          ),
                          child: Text(
                            snippet,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: DesignTokens.fontSizeSm,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (!hasCustomer) ...[
              const SizedBox(height: DesignTokens.space3),
              _SheetTile(
                icon: Icons.link_rounded,
                label: 'Müşteriye bağla',
                color: ext.accent,
                onTap: () {
                  Navigator.pop(ctx);
                  AppFeedback.lightImpact();
                  final openDir = onOpenCustomerDirectory;
                  if (openDir != null) {
                    openDir();
                  } else if (ConsultantShellNav.maybeOf(anchor) != null) {
                    ConsultantShellNav.goToCustomersTab(anchor);
                    if (anchor.mounted) {
                      showCallsSurfaceAck(
                        anchor,
                        'Müşteri listesinde ara',
                        icon: Icons.people_alt_rounded,
                      );
                    }
                  } else if (anchor.mounted) {
                    showCallsSurfaceAck(
                      anchor,
                      'Müşteri kartından veya CRM listenizden eşleştirin',
                      icon: Icons.info_outline_rounded,
                    );
                  }
                },
              ),
              Center(
                child: TextButton(
                  onPressed: () {
                    AppFeedback.selectionClick();
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    'Bağlamayı şimdilik ertele',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: ext.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.space4),
            _SheetTile(
              icon: Icons.call_rounded,
              label: 'Ara',
              color: ext.success,
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await OutboundPhoneDial.launchDial(rawPhone);
                if (!ok && anchor.mounted) {
                  ScaffoldMessenger.of(anchor).showSnackBar(
                    const SnackBar(content: Text('Arama başlatılamadı.')),
                  );
                } else if (ok && anchor.mounted) {
                  showCallsSurfaceAck(
                    anchor,
                    'Arama başlatıldı',
                    icon: Icons.call_rounded,
                  );
                }
              },
            ),
            _SheetTile(
              icon: Icons.sms_rounded,
              label: 'Mesaj yaz',
              color: ext.info,
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await SmsLauncher.openBulkSms([rawPhone]);
                if (!ok && anchor.mounted) {
                  ScaffoldMessenger.of(anchor).showSnackBar(
                    const SnackBar(content: Text('Mesaj uygulaması açılamadı.')),
                  );
                } else if (ok && anchor.mounted) {
                  showCallsSurfaceAck(
                    anchor,
                    'SMS akışı hazırlandı',
                    icon: Icons.sms_rounded,
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
                if (!ok && anchor.mounted) {
                  ScaffoldMessenger.of(anchor).showSnackBar(
                    const SnackBar(content: Text('WhatsApp açılamadı.')),
                  );
                } else if (ok && anchor.mounted) {
                  showCallsSurfaceAck(
                    anchor,
                    'WhatsApp açıldı',
                    icon: Icons.chat_rounded,
                  );
                }
              },
            ),
            if (hasCustomer)
              _SheetTile(
                icon: Icons.open_in_new_rounded,
                label: 'Kartı aç',
                color: ext.accent,
                onTap: () {
                  Navigator.pop(ctx);
                  AppFeedback.lightImpact();
                  ctx.push('/customer/$cid');
                },
              ),
            if (!hasCustomer)
              _SheetTile(
                icon: Icons.person_add_alt_1_rounded,
                label: 'Portföye kaydet',
                color: ext.accent,
                onTap: () {
                  Navigator.pop(ctx);
                  showSaveContactSheet(
                    anchor,
                    initialName: initialName,
                    initialPhone: initialPhone,
                    source: 'calls_quick_identity',
                  );
                },
              ),
            _SheetTile(
              icon: Icons.edit_note_rounded,
              label: 'Görüşme özeti / not',
              color: ext.textPrimary,
              onTap: () {
                Navigator.pop(ctx);
                final trimmed = customerId?.trim();
                ctx.push(
                  AppRouter.routeCallSummary,
                  extra: <String, dynamic>{
                    if (trimmed != null && trimmed.isNotEmpty)
                      'customerId': trimmed,
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
                final trimmed = customerId?.trim();
                ctx.push(
                  AppRouter.routeCall,
                  extra: <String, dynamic>{
                    'phone': rawPhone,
                    if (trimmed != null && trimmed.isNotEmpty)
                      'customerId': trimmed,
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 22, color: ext.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
