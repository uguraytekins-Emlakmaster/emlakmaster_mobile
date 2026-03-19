import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/facebook_auth_service.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/services/login_attempt_guard.dart';
import '../../../../core/theme/design_tokens.dart';
import '../widgets/auth_field_decoration.dart';

/// E-posta ile yeni hesap. Başarıda router → rol seçimi veya ana sayfa (mevcut akış).
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  static void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    final blocked = LoginAttemptGuard.assertCanAttempt();
    if (blocked != null) {
      setState(() => _errorMessage = blocked);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
      );
      if (!mounted) return;
      LoginAttemptGuard.clear();
      await AnalyticsService.instance.logSignUp();
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      LoginAttemptGuard.recordFailure();
      setState(() {
        _isLoading = false;
        _errorMessage = _registerErrorMessage(e);
      });
    }
  }

  static String _registerErrorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Bu e-posta ile zaten bir hesap var. Giriş yapın veya şifre sıfırlayın.';
        case 'invalid-email':
          return 'Geçerli bir e-posta adresi girin.';
        case 'weak-password':
          return 'Şifre çok zayıf. En az 8 karakter ve harf + rakam kullanın.';
        case 'operation-not-allowed':
          return 'E-posta ile kayıt şu an kapalı. Yönetici ile iletişime geçin.';
        case 'network-request-failed':
          return 'İnternet bağlantınızı kontrol edin.';
        case 'too-many-requests':
          return 'Çok fazla deneme. Biraz bekleyip tekrar deneyin.';
        default:
          return 'Kayıt tamamlanamadı (${e.code}). Tekrar deneyin.';
      }
    }
    return 'Kayıt tamamlanamadı. Bilgilerinizi kontrol edin.';
  }

  Future<void> _googleKayit() async {
    if (_isLoading) return;
    final blocked = LoginAttemptGuard.assertCanAttempt();
    if (blocked != null) {
      setState(() => _errorMessage = blocked);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      await GoogleAuthService.instance.signInWithGoogleForFirebase().timeout(
            const Duration(seconds: 90),
            onTimeout: () => throw FirebaseAuthException(
              code: 'timeout',
              message: 'Google oturumu zaman aşımına uğradı.',
            ),
          );
      if (!mounted) return;
      LoginAttemptGuard.clear();
      await AnalyticsService.instance.logSignUp(method: 'google');
      setState(() => _isLoading = false);
    } on GoogleSignInUserCanceled {
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      LoginAttemptGuard.recordFailure();
      setState(() {
        _isLoading = false;
        _errorMessage = _googleErr(e);
      });
    }
  }

  Future<void> _facebookKayit() async {
    if (_isLoading) return;
    final blocked = LoginAttemptGuard.assertCanAttempt();
    if (blocked != null) {
      setState(() => _errorMessage = blocked);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      await FacebookAuthService.instance
          .signInWithFacebookForFirebase()
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () => throw FirebaseAuthException(
              code: 'timeout',
              message: 'Facebook oturumu zaman aşımına uğradı.',
            ),
          );
      if (!mounted) return;
      LoginAttemptGuard.clear();
      await AnalyticsService.instance.logSignUp(method: 'facebook');
      setState(() => _isLoading = false);
    } on FacebookSignInUserCanceled {
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      LoginAttemptGuard.recordFailure();
      setState(() {
        _isLoading = false;
        _errorMessage = _facebookErr(e);
      });
    }
  }

  static String _googleErr(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return 'Bu e-posta başka bir yöntemle kayıtlı. E-posta ile giriş deneyin.';
        case 'invalid-credential':
          return e.message ?? 'Google oturumu doğrulanamadı.';
        case 'timeout':
          return e.message ?? 'Zaman aşımı. Tekrar deneyin.';
        case 'network-request-failed':
          return 'Ağ hatası. Bağlantınızı kontrol edin.';
        default:
          return 'Google ile devam edilemedi (${e.code}).';
      }
    }
    if (e is PlatformException) {
      final c = e.code.toLowerCase();
      if (c.contains('cancel')) return '';
      return 'Google hatası (${e.code}).';
    }
    return 'Google ile kayıt başarısız.';
  }

  static String _facebookErr(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return 'Bu e-posta başka bir yöntemle kayıtlı. O yöntemle giriş deneyin.';
        case 'invalid-credential':
          return e.message ?? 'Facebook oturumu doğrulanamadı.';
        case 'facebook-login-failed':
          return e.message ?? 'Facebook oturumu açılamadı.';
        case 'timeout':
          return e.message ?? 'Zaman aşımı. Tekrar deneyin.';
        case 'network-request-failed':
          return 'Ağ hatası. Bağlantınızı kontrol edin.';
        default:
          return 'Facebook ile devam edilemedi (${e.code}).';
      }
    }
    if (e is PlatformException) {
      final c = e.code.toLowerCase();
      if (c.contains('cancel')) return '';
      return 'Facebook hatası (${e.code}).';
    }
    return 'Facebook ile kayıt başarısız.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTap: _unfocus,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.contentPaddingHorizontal),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: DesignTokens.space2),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _isLoading ? null : () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20),
                        color: DesignTokens.textSecondaryDark,
                        style: IconButton.styleFrom(
                          backgroundColor: DesignTokens.surfaceDark,
                          padding: const EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusMd),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      'Hesap oluştur',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: DesignTokens.textPrimaryDark,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      'Bilgilerinizi girin; ardından rolünüzü seçerek panele geçin.',
                      style: TextStyle(
                        color: DesignTokens.textSecondaryDark.withOpacity(0.95),
                        fontSize: DesignTokens.fontSizeSm,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.space6),
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.space3),
                      decoration: BoxDecoration(
                        color: DesignTokens.antiqueGold.withOpacity(0.06),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusMd),
                        border: Border.all(
                            color: DesignTokens.antiqueGold.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 20,
                              color: DesignTokens.antiqueGold.withOpacity(
                                  0.9)), // ignore: prefer_const_constructors
                          const SizedBox(width: DesignTokens.space2),
                          const Expanded(
                            child: Text(
                              'Davet e-postanız kayıtlıysa rol ve ekip otomatik atanır.',
                              style: TextStyle(
                                color: DesignTokens.textSecondaryDark,
                                fontSize: DesignTokens.fontSizeSm - 1,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space6),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style:
                          const TextStyle(color: DesignTokens.textPrimaryDark),
                      cursorColor: DesignTokens.antiqueGold,
                      onTapOutside: (_) => _unfocus(),
                      decoration: AuthFieldDecoration.build(
                        label: 'Ad Soyad',
                        hint: 'Opsiyonel',
                        prefix: const Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (v.trim().length < 2) return 'En az 2 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      style:
                          const TextStyle(color: DesignTokens.textPrimaryDark),
                      cursorColor: DesignTokens.antiqueGold,
                      onTapOutside: (_) => _unfocus(),
                      decoration: AuthFieldDecoration.build(
                        label: 'E-posta',
                        hint: 'ornek@firma.com',
                        prefix: const Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'E-posta gerekli';
                        }
                        final t = v.trim();
                        if (!t.contains('@') || t.length < 5) {
                          return 'Geçerli bir e-posta girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style:
                          const TextStyle(color: DesignTokens.textPrimaryDark),
                      cursorColor: DesignTokens.antiqueGold,
                      onTapOutside: (_) => _unfocus(),
                      decoration: AuthFieldDecoration.build(
                        label: 'Şifre',
                        hint: 'En az 8 karakter',
                        prefix: const Icon(Icons.lock_outline_rounded),
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Şifre gerekli';
                        if (v.length < 8) return 'En az 8 karakter';
                        final hasLetter = RegExp(r'[A-Za-z]').hasMatch(v);
                        final hasDigit = RegExp(r'[0-9]').hasMatch(v);
                        if (!hasLetter || !hasDigit) {
                          return 'Harf ve rakam içermeli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      style:
                          const TextStyle(color: DesignTokens.textPrimaryDark),
                      cursorColor: DesignTokens.antiqueGold,
                      onTapOutside: (_) => _unfocus(),
                      decoration: AuthFieldDecoration.build(
                        label: 'Şifre tekrar',
                        prefix: const Icon(Icons.lock_person_outlined),
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Şifreyi tekrar girin';
                        }
                        if (v != _passwordController.text) {
                          return 'Şifreler eşleşmiyor';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                      const SizedBox(height: DesignTokens.space4),
                      Container(
                        padding: const EdgeInsets.all(DesignTokens.space3),
                        decoration: BoxDecoration(
                          color: DesignTokens.danger.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMd),
                          border: Border.all(
                              color: DesignTokens.danger.withOpacity(0.35)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded,
                                color: DesignTokens.danger.withOpacity(0.9),
                                size: 20),
                            const SizedBox(width: DesignTokens.space2),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: DesignTokens.textPrimaryDark,
                                  fontSize: DesignTokens.fontSizeSm,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: DesignTokens.space6),
                    Semantics(
                      label: 'Kayıt ol',
                      button: true,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: DesignTokens.antiqueGold,
                          foregroundColor: DesignTokens.inputTextOnGold,
                          padding: const EdgeInsets.symmetric(
                              vertical: DesignTokens.space4),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusMd),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: DesignTokens.inputTextOnGold,
                                ),
                              )
                            : const Text('Kayıt ol',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space5),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color:
                                    DesignTokens.borderDark.withOpacity(0.6))),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'veya',
                            style: TextStyle(
                              color: DesignTokens.textTertiaryDark,
                              fontSize: DesignTokens.fontSizeSm,
                            ),
                          ),
                        ),
                        Expanded(
                            child: Divider(
                                color:
                                    DesignTokens.borderDark.withOpacity(0.6))),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space5),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _googleKayit,
                      icon: const Icon(Icons.g_mobiledata,
                          size: 22, color: DesignTokens.textSecondaryDark),
                      label: const Text('Google ile devam et'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DesignTokens.textPrimaryDark,
                        side: const BorderSide(color: DesignTokens.borderDark),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMd),
                        ),
                      ),
                    ),
                    if (AppConstants.showFacebookLogin) ...[
                      const SizedBox(height: DesignTokens.space3),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _facebookKayit,
                        icon: const Icon(Icons.facebook_rounded,
                            size: 18, color: Color(0xFF1877F2)),
                        label: const Text('Facebook ile devam et'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DesignTokens.textPrimaryDark,
                          side: const BorderSide(color: DesignTokens.borderDark),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusMd),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: DesignTokens.space3),
                    const Text(
                      'Kayıt olarak hizmet şartlarını ve veri işleme bilgilendirmesini kabul etmiş olursunuz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DesignTokens.textTertiaryDark,
                        fontSize: DesignTokens.fontSizeSm - 2,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Zaten hesabınız var mı? ',
                          style: TextStyle(
                            color: DesignTokens.textSecondaryDark,
                            fontSize: DesignTokens.fontSizeMd,
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : () => context.pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: DesignTokens.antiqueGold,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Giriş yap',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
