import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/domain/login_entry_persona.dart';
import 'package:flutter/material.dart';

/// Premium auth gövdesi: gradient, klavye inset, taşma yok, sürükleyerek klavye kapatma.
class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    super.key,
    required this.child,
    this.bottomBar,
    this.persona,
  });

  final Widget child;
  final Widget? bottomBar;
  final LoginEntryPersona? persona;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final accentTint = switch (persona) {
      LoginEntryPersona.manager => ext.brandPrimary,
      LoginEntryPersona.consultant => Color.lerp(ext.brandPrimary, ext.info, 0.45)!,
      null => ext.brandPrimary,
    };

    return Scaffold(
      backgroundColor: ext.background,
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ext.background,
              Color.lerp(ext.background, accentTint, persona == null ? 0.045 : 0.08)!,
            ],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        DesignTokens.space4,
                        DesignTokens.space4,
                        DesignTokens.space4,
                        DesignTokens.space4 + bottomInset,
                      ),
                      child: child,
                    ),
                  ),
                ),
                if (bottomBar != null) bottomBar!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
