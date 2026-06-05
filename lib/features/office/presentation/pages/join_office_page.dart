import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/auth_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/widgets/auth_field_decoration.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_exception.dart';
import 'package:emlakmaster_mobile/features/office/presentation/utils/office_error_ui.dart';
import 'package:emlakmaster_mobile/features/office/services/office_setup_service.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

class JoinOfficePage extends ConsumerStatefulWidget {
  const JoinOfficePage({super.key});

  @override
  ConsumerState<JoinOfficePage> createState() => _JoinOfficePageState();
}

class _JoinOfficePageState extends ConsumerState<JoinOfficePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    AppFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      await OfficeSetupService.joinOfficeWithInviteCode(
        user: user,
        rawCode: _codeController.text,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw OfficeException(
          OfficeErrorCode.network,
          'İşlem zaman aşımına uğradı. Bağlantınızı kontrol edip tekrar deneyin.',
        ),
      );
      if (!mounted) return;
      final uid = user.uid;
      // Tüm bağımlı provider'ları invalidate et — userDocStreamProvider
      // olmadan router redirect users.officeId == null görüp geri gönderiyordu.
      ref.invalidate(userDocStreamProvider(uid));
      ref.invalidate(primaryMembershipProvider);
      ref.invalidate(officeAccessStateProvider);
      ref.invalidate(currentOfficeProvider);
      ref.invalidate(currentRoleProvider);
      // Router'ın refreshListenable mekanizması needsOfficeSetup değişimini
      // algılar ve /office-join'den otomatik home'a yönlendirir. context.go
      // yalnızca güvenlik ağı olarak kalır.
      context.go(AppRouter.routeHome);
    } on OfficeException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.userMessage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = officeErrorUserMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ext.background,
      appBar: emlakAppBar(
        context,
        backgroundColor: ext.background,
        foregroundColor: ext.foreground,
        title: Text(l10n.t('office_invite_code')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.t('office_join_desc'),
                  style: TextStyle(
                    color: ext.foregroundSecondary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  style: TextStyle(
                    color: ext.foreground,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: ext.accent,
                  decoration: AuthFieldDecoration.build(context,
                    label: l10n.t('office_invite_code'),
                    hint: 'XXXXXXXX',
                    prefix: const Icon(Icons.tag_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 4) {
                      return l10n.t('office_code_invalid');
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: ext.danger.withValues(alpha: 0.95),
                      fontSize: 13,
                    ),
                  ),
                ],
                const Spacer(),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: ext.accent,
                    foregroundColor: ext.onBrand,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                  ),
                  child: _busy
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ext.onBrand,
                          ),
                        )
                      : Text(l10n.t('office_join_cta'), style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
