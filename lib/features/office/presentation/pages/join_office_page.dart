import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/auth_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/widgets/auth_field_decoration.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_exception.dart';
import 'package:emlakmaster_mobile/features/office/presentation/utils/office_error_ui.dart';
import 'package:emlakmaster_mobile/features/office/services/office_setup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
class JoinOfficePage extends StatefulWidget {
  const JoinOfficePage({super.key});

  @override
  State<JoinOfficePage> createState() => _JoinOfficePageState();
}

class _JoinOfficePageState extends State<JoinOfficePage> {
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
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      await OfficeSetupService.joinOfficeWithInviteCode(
        user: user,
        rawCode: _codeController.text,
      );
      if (!mounted) return;
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
    return Scaffold(
      backgroundColor: ext.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Davet kodu'),
        foregroundColor: ext.foreground,
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
                  'Yöneticinizin paylaştığı kodu girin. Kod büyük/küçük harf duyarsızdır.',
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
                    label: 'Davet kodu',
                    hint: 'XXXXXXXX',
                    prefix: const Icon(Icons.tag_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 4) {
                      return 'Geçerli bir kod girin';
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
                      : const Text('Ofise katıl', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
