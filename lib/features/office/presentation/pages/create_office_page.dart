import 'package:emlakmaster_mobile/core/config/dev_mode_config.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/auth_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/widgets/auth_field_decoration.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_exception.dart';
import 'package:emlakmaster_mobile/features/office/presentation/utils/office_error_ui.dart';
import 'package:emlakmaster_mobile/features/office/services/office_setup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
class CreateOfficePage extends ConsumerStatefulWidget {
  const CreateOfficePage({super.key});

  @override
  ConsumerState<CreateOfficePage> createState() => _CreateOfficePageState();
}

class _CreateOfficePageState extends ConsumerState<CreateOfficePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _error = null);
    if (isDevMode) {
      _formKey.currentState?.save();
    } else {
      if (!_formKey.currentState!.validate()) return;
    }
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      await OfficeSetupService.createOfficeAsOwner(
        user: user,
        officeName: _nameController.text,
      );
      if (!mounted) return;
      ref.invalidate(primaryMembershipProvider);
      ref.invalidate(officeAccessStateProvider);
      ref.invalidate(currentOfficeProvider);
      if (OfficeSetupService.usedDevFallbackOnLastCreate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geçici olarak yerel modda devam ediliyor'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
        title: const Text('Ofis oluştur'),
          foregroundColor: ext.foreground,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Ofis adı',
                        style: TextStyle(
                          color: ext.foregroundSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: ext.foreground),
                        cursorColor: ext.accent,
                        decoration: AuthFieldDecoration.build(context,
                          label: 'Ofis adı',
                          hint: 'Örn. Rainbow Gayrimenkul Merkez',
                          prefix: const Icon(Icons.business_outlined),
                        ),
                        validator: (v) {
                          if (isDevMode) return null;
                          if (v == null || v.trim().length < 2) {
                            return 'En az 2 karakter girin';
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
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: FilledButton(
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
                    : const Text('Ofisi oluştur', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
