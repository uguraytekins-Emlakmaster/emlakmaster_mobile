import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/firebase/user_facing_firebase_message.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/services/auth_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/widgets/app_toaster.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Hesap güvenliği akışları: şifre değiştir, e-posta değiştir, hesabı sil.
/// Tümü gerçek Firebase Auth çağrıları kullanır; sahte başarı üretmez.
class AccountSecurityActions {
  AccountSecurityActions._();

  /// Şifre değiştirme: mevcut şifre ile reauth + yeni şifre.
  static Future<void> showChangePassword(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await _showFormSheet(
      context,
      title: l10n.t('acct_change_password_title'),
      subtitle: l10n.t('acct_change_password_sub'),
      icon: Icons.lock_reset_rounded,
      fields: [
        _FormField(
            key: 'current',
            label: l10n.t('acct_field_current_password'),
            obscure: true),
        _FormField(
            key: 'next',
            label: l10n.t('acct_field_new_password'),
            obscure: true),
        _FormField(
            key: 'confirm',
            label: l10n.t('acct_field_new_password_confirm'),
            obscure: true),
      ],
      submitLabel: l10n.t('acct_update_password_cta'),
      validate: (values) {
        if ((values['current'] ?? '').isEmpty) {
          return l10n.t('acct_err_current_password_required');
        }
        final next = values['next'] ?? '';
        if (next.length < 6) return l10n.t('acct_err_password_min');
        if (next != (values['confirm'] ?? '')) {
          return l10n.t('acct_err_passwords_mismatch');
        }
        return null;
      },
      action: (values) async {
        await AuthService.instance
            .reauthenticateWithPassword(values['current']!);
        await AuthService.instance.updatePassword(values['next']!);
      },
      successMessage: l10n.t('acct_password_updated'),
    );
  }

  /// E-posta değiştirme: reauth + yeni adrese doğrulama bağlantısı.
  static Future<void> showChangeEmail(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await _showFormSheet(
      context,
      title: l10n.t('acct_change_email_title'),
      subtitle: l10n.t('acct_change_email_sub'),
      icon: Icons.alternate_email_rounded,
      fields: [
        _FormField(
            key: 'current',
            label: l10n.t('acct_field_current_password'),
            obscure: true),
        _FormField(
            key: 'email',
            label: l10n.t('acct_field_new_email'),
            keyboard: TextInputType.emailAddress),
      ],
      submitLabel: l10n.t('acct_send_verification_cta'),
      validate: (values) {
        if ((values['current'] ?? '').isEmpty) {
          return l10n.t('acct_err_current_password_required');
        }
        final email = (values['email'] ?? '').trim();
        if (!email.contains('@') || !email.contains('.')) {
          return l10n.t('acct_err_email_invalid');
        }
        return null;
      },
      action: (values) async {
        await AuthService.instance
            .reauthenticateWithPassword(values['current']!);
        await AuthService.instance
            .sendEmailUpdateVerification(values['email']!.trim());
      },
      successMessage: l10n.t('acct_email_verification_sent'),
    );
  }

  /// Şifre sıfırlama e-postası (mevcut hesap adresine).
  static Future<void> sendPasswordReset(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      await AuthService.instance.sendPasswordResetForCurrentUser();
      if (context.mounted) {
        AppToaster.success(context, l10n.t('acct_password_reset_sent'));
      }
    } catch (e) {
      if (context.mounted) {
        AppToaster.error(
            context, userFacingErrorMessage(e, context: 'password_reset'));
      }
    }
  }

  /// Hesabı kalıcı sil: güçlü onay + reauth (şifre hesapları) + Auth silme +
  /// en iyi çaba Firestore temizliği. Mağaza (Apple) zorunluluğu.
  static Future<void> showDeleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final ext = AppThemeExtension.of(ctx);
        return AlertDialog(
          backgroundColor: ext.surfaceElevated,
          title: Text(l10n.t('acct_delete_confirm_title')),
          content: Text(l10n.t('acct_delete_confirm_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.t('action_dismiss')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ext.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.t('action_continue')),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final isPassword = AuthService.instance.isPasswordProvider;
    if (isPassword) {
      await _showFormSheet(
        context,
        title: l10n.t('acct_delete_title'),
        subtitle: l10n.t('acct_delete_sub'),
        icon: Icons.delete_forever_rounded,
        danger: true,
        fields: [
          _FormField(
              key: 'current',
              label: l10n.t('acct_field_current_password'),
              obscure: true),
        ],
        submitLabel: l10n.t('acct_delete_cta'),
        validate: (values) => (values['current'] ?? '').isEmpty
            ? l10n.t('acct_err_password_required')
            : null,
        action: (values) async {
          await AuthService.instance
              .reauthenticateWithPassword(values['current']!);
          await _purgeUserDocsBestEffort();
          await AuthService.instance.deleteCurrentUser();
        },
        successMessage: l10n.t('acct_deleted'),
      );
    } else {
      // OAuth (Google/Facebook) hesapları: parola yok. Doğrudan silmeyi dene;
      // Firebase yakın zamanlı giriş isterse dürüstçe yönlendir.
      try {
        await _purgeUserDocsBestEffort();
        await AuthService.instance.deleteCurrentUser();
        if (context.mounted) {
          AppToaster.success(context, l10n.t('acct_deleted'));
        }
      } on FirebaseAuthException catch (e) {
        if (!context.mounted) return;
        if (e.code == 'requires-recent-login') {
          AppToaster.warning(
            context,
            l10n.t('acct_delete_requires_recent_login'),
          );
        } else {
          AppToaster.error(
              context, userFacingErrorMessage(e, context: 'account_delete'));
        }
      } catch (e) {
        if (context.mounted) {
          AppToaster.error(
              context, userFacingErrorMessage(e, context: 'account_delete'));
        }
      }
    }
  }

  /// En iyi çaba: kullanıcı dokümanı ve ofis üyeliklerini siler. Kurallar engellerse
  /// sessizce geçilir — Auth hesabının silinmesi mağaza zorunluluğunu karşılar.
  /// Çağrı/müşteri/görev gibi büyük veri kümeleri sunucu (Cloud Function onDelete)
  /// tarafından temizlenmelidir.
  static Future<void> _purgeUserDocsBestEffort() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;
    final fs = FirebaseFirestore.instance;
    try {
      final memberships = await fs
          .collection(AppConstants.colOfficeMemberships)
          .where('userId', isEqualTo: uid)
          .get();
      for (final doc in memberships.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}
    try {
      await fs.collection(AppConstants.colUsers).doc(uid).delete();
    } catch (_) {}
  }

  // ---------- Ortak form sheet ----------

  static Future<void> _showFormSheet(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<_FormField> fields,
    required String submitLabel,
    required String? Function(Map<String, String>) validate,
    required Future<void> Function(Map<String, String>) action,
    required String successMessage,
    bool danger = false,
  }) async {
    await showPremiumModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => _AccountFormSheet(
        title: title,
        subtitle: subtitle,
        icon: icon,
        fields: fields,
        submitLabel: submitLabel,
        validate: validate,
        action: action,
        successMessage: successMessage,
        danger: danger,
      ),
    );
  }
}

class _FormField {
  const _FormField({
    required this.key,
    required this.label,
    this.obscure = false,
    this.keyboard = TextInputType.text,
  });
  final String key;
  final String label;
  final bool obscure;
  final TextInputType keyboard;
}

class _AccountFormSheet extends StatefulWidget {
  const _AccountFormSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.fields,
    required this.submitLabel,
    required this.validate,
    required this.action,
    required this.successMessage,
    required this.danger,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<_FormField> fields;
  final String submitLabel;
  final String? Function(Map<String, String>) validate;
  final Future<void> Function(Map<String, String>) action;
  final String successMessage;
  final bool danger;

  @override
  State<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<_AccountFormSheet> {
  late final Map<String, TextEditingController> _controllers = {
    for (final f in widget.fields) f.key: TextEditingController(),
  };
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final values = {
      for (final entry in _controllers.entries) entry.key: entry.value.text,
    };
    final validationError = widget.validate(values);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.action(values);
      if (!mounted) return;
      Navigator.pop(context);
      AppToaster.success(context, widget.successMessage);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = userFacingErrorMessage(e, context: 'account_security');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    final accent = widget.danger ? ext.danger : ext.accent;

    // Klavye insets, SafeArea ve maks. yükseklik shell tarafından sağlanır
    // (showPremiumScrollableBottomSheet); burada yalnızca kaydırılabilir gövde.
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PremiumBottomSheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space5,
                  DesignTokens.space2,
                  DesignTokens.space4,
                  DesignTokens.space3,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(widget.icon,
                        size: DesignTokens.iconLg,
                        color: accent.withValues(alpha: 0.6)),
                    const SizedBox(width: DesignTokens.space3),
                    Expanded(
                      child: PremiumSheetHeader(
                        compact: true,
                        title: widget.title,
                        subtitle: widget.subtitle,
                      ),
                    ),
                    IconButton(
                      tooltip: AppLocalizations.of(context).t('action_close'),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space5),
                child: Column(
                  children: [
                    for (final f in widget.fields) ...[
                      TextField(
                        controller: _controllers[f.key],
                        obscureText: f.obscure,
                        keyboardType: f.keyboard,
                        enabled: !_submitting,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: f.label,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space3),
                    ],
                    if (_error != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _error!,
                          style: TextStyle(
                              color: ext.danger, fontSize: 12.5, height: 1.35),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space3),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                widget.submitLabel,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}
