import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/design_tokens.dart';

/// Email/şifre ile giriş. Hata ve loading state.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() {
      _errorMessage = null;
    });
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      AnalyticsService.instance.logLogin(method: 'email');
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _userFriendlyAuthError(e);
      });
    }
  }

  static String _userFriendlyAuthError(dynamic e) {
    final s = e.toString().toLowerCase();
    if (s.contains('user-not-found') || s.contains('wrong-password')) {
      return 'E-posta veya şifre hatalı.';
    }
    if (s.contains('invalid-email')) return 'Geçersiz e-posta adresi.';
    if (s.contains('too-many-requests')) return 'Çok fazla deneme. Biraz bekleyip tekrar deneyin.';
    if (s.contains('network')) return 'İnternet bağlantısı yok.';
    return 'Giriş yapılamadı. Bilgilerinizi kontrol edin.';
  }

  Future<void> _googleIleGiris() async {
    if (_isLoading) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId:
            '572835725773-93531b623c67ce9392c484.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      AnalyticsService.instance.logLogin(method: 'google');
      setState(() => _isLoading = false);
      // Router authStateChanges ile otomatik ana sayfaya yönlendirir.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Google ile giriş başarısız. Tekrar deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'EmlakMaster',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: DesignTokens.primary,
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Giriş yapın',
                    style: TextStyle(
                      color: DesignTokens.textSecondaryDark,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'E-posta',
                      hintText: 'ornek@firma.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                      filled: true,
                      fillColor: DesignTokens.surfaceDark,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
                      if (!v.contains('@')) return 'Geçerli bir e-posta girin';
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                      filled: true,
                      fillColor: DesignTokens.surfaceDark,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Şifre gerekli';
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DesignTokens.danger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: DesignTokens.danger, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: DesignTokens.danger, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: DesignTokens.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('Giriş yap', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _googleIleGiris,
                    icon: const Icon(Icons.g_mobiledata, size: 22),
                    label: const Text('Google ile Giriş Yap'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignTokens.textPrimaryDark,
                      side: BorderSide(color: DesignTokens.textSecondaryDark.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
