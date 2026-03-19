import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/login_attempt_guard.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/facebook_auth_service.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../utils/auth_error_messages.dart';
import '../widgets/auth_field_decoration.dart';

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

  /// Gerçek hata kodu (Firebase vb.); kullanıcı "bilgiler doğru" dediğinde teşhis için gösterilir.
  String? _errorDetail;

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
      _errorDetail = null;
    });
    if (!_formKey.currentState!.validate()) return;
    final blocked = LoginAttemptGuard.assertCanAttempt();
    if (blocked != null) {
      setState(() => _errorMessage = blocked);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    try {
      await AuthService.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      LoginAttemptGuard.clear();
      AnalyticsService.instance.logLogin(method: 'email');
      setState(() => _isLoading = false);
    } catch (e, st) {
      if (!mounted) return;
      LoginAttemptGuard.recordFailure();
      if (kDebugMode) {
        debugPrint('Login error: $e');
        debugPrint('Stack: $st');
        if (e is FirebaseAuthException) {
          debugPrint('Firebase code: ${e.code} message: ${e.message}');
        }
      }
      final detail = e is FirebaseAuthException
          ? '${e.code}${e.message != null && e.message!.isNotEmpty ? ': ${e.message}' : ''}'
          : '${e.runtimeType}: ${e.toString().length > 80 ? '${e.toString().substring(0, 80)}…' : e}';
      setState(() {
        _isLoading = false;
        _errorMessage = userFriendlyAuthError(e);
        _errorDetail = detail;
      });
    }
  }

  void _openForgotPassword() {
    FocusManager.instance.primaryFocus?.unfocus();
    final email = _emailController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
      ),
      builder: (sheetCtx) => _ForgotPasswordSheet(
        initialEmail: email,
        onResetSent: () {
          Navigator.of(sheetCtx).pop();
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Şifre sıfırlama bağlantısı istendi. Gelen kutunuzu ve spam klasörünü kontrol edin.',
              ),
              backgroundColor: DesignTokens.success,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 5),
            ),
          );
        },
      ),
    );
  }

  static void _unfocusKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _googleIleGiris() async {
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
              message:
                  'Google girişi zaman aşımına uğradı. Ağı kontrol edip tekrar deneyin.',
            ),
          );
      if (!mounted) return;
      LoginAttemptGuard.clear();
      AnalyticsService.instance.logLogin(method: 'google');
      setState(() => _isLoading = false);
    } on GoogleSignInUserCanceled {
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      LoginAttemptGuard.recordFailure();
      final msg = _googleSignInErrorMessage(e);
      setState(() {
        _isLoading = false;
        _errorMessage = msg.isEmpty ? null : msg;
      });
    }
  }

  Future<void> _facebookIleGiris() async {
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
              message:
                  'Facebook girişi zaman aşımına uğradı. Ağı kontrol edip tekrar deneyin.',
            ),
          );
      if (!mounted) return;
      LoginAttemptGuard.clear();
      AnalyticsService.instance.logLogin(method: 'facebook');
      setState(() => _isLoading = false);
    } on FacebookSignInUserCanceled {
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      LoginAttemptGuard.recordFailure();
      final msg = _facebookSignInErrorMessage(e);
      setState(() {
        _isLoading = false;
        _errorMessage = msg.isEmpty ? null : msg;
      });
    }
  }

  static String _googleSignInErrorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return 'Bu e-posta zaten e-posta/şifre veya başka bir yöntemle kayıtlı. O yöntemle giriş yapın.';
        case 'invalid-credential':
          return e.message ??
              'Google oturumu doğrulanamadı. Uygulamayı güncelleyin veya yönetici ile iletişime geçin.';
        case 'user-disabled':
          return 'Bu hesap devre dışı bırakıldı.';
        case 'timeout':
          return e.message ?? 'Bağlantı zaman aşımı. Tekrar deneyin.';
        case 'network-request-failed':
          return 'İnternet bağlantısı yok veya zayıf.';
        default:
          return 'Google ile giriş yapılamadı (${e.code}). Tekrar deneyin.';
      }
    }
    if (e is PlatformException) {
      final c = e.code.toLowerCase();
      final m = '${e.message}'.toLowerCase();
      if (c.contains('canceled') ||
          c.contains('cancelled') ||
          m.contains('cancel')) {
        return '';
      }
      if (c == 'sign_in_failed' ||
          m.contains('12500') ||
          m.contains('developer_error') ||
          m.contains('10:')) {
        return 'Android: Firebase Console’da SHA-1 parmak izini ve paket adını doğrulayın. '
            'Ayrıntı: docs/GOOGLE_SIGNIN_401_FIX.md';
      }
      if (c.contains('network') || m.contains('network')) {
        return 'Ağ hatası. Bağlantınızı kontrol edin.';
      }
      return 'Google girişi başarısız (${e.code}). Tekrar deneyin.';
    }
    return 'Google ile giriş başarısız. Tekrar deneyin.';
  }

  static String _facebookSignInErrorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return 'Bu e-posta başka bir yöntemle kayıtlı. O yöntemle giriş yapın.';
        case 'invalid-credential':
          return e.message ?? 'Facebook oturumu doğrulanamadı.';
        case 'facebook-login-failed':
          return e.message ?? 'Facebook ile giriş yapılamadı.';
        case 'timeout':
          return e.message ?? 'Bağlantı zaman aşımı. Tekrar deneyin.';
        case 'network-request-failed':
          return 'İnternet bağlantısı yok veya zayıf.';
        default:
          return 'Facebook ile giriş yapılamadı (${e.code}). Tekrar deneyin.';
      }
    }
    if (e is PlatformException) {
      final c = e.code.toLowerCase();
      final m = '${e.message}'.toLowerCase();
      if (c.contains('cancel') || m.contains('cancel')) {
        return '';
      }
      if (c.contains('network') || m.contains('network')) {
        return 'Ağ hatası. Bağlantınızı kontrol edin.';
      }
      return 'Facebook girişi başarısız (${e.code}). Tekrar deneyin.';
    }
    return 'Facebook ile giriş başarısız. Tekrar deneyin.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTap: _unfocusKeyboard,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.contentPaddingHorizontal),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: DesignTokens.space6),
                    Text(
                      'EmlakMaster',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: DesignTokens.antiqueGold,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    const Text(
                      'Giriş yapın',
                      style: TextStyle(
                        color: DesignTokens.textSecondaryDark,
                        fontSize: DesignTokens.fontSizeMd,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.space10),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      style:
                          const TextStyle(color: DesignTokens.textPrimaryDark),
                      cursorColor: DesignTokens.antiqueGold,
                      onTapOutside: (_) => _unfocusKeyboard(),
                      decoration: AuthFieldDecoration.build(
                        label: 'E-posta',
                        hint: 'ornek@firma.com',
                        prefix: const Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'E-posta gerekli';
                        }
                        if (!v.contains('@')) {
                          return 'Geçerli bir e-posta girin';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style:
                          const TextStyle(color: DesignTokens.textPrimaryDark),
                      cursorColor: DesignTokens.antiqueGold,
                      onTapOutside: (_) => _unfocusKeyboard(),
                      decoration: AuthFieldDecoration.build(
                        label: 'Şifre',
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
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _openForgotPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: DesignTokens.antiqueGold,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('Şifremi unuttum'),
                      ),
                    ),
                    if (_errorMessage != null) ...[
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                        fontSize: DesignTokens.fontSizeSm),
                                  ),
                                ),
                              ],
                            ),
                            if (_errorDetail != null &&
                                _errorDetail!.isNotEmpty) ...[
                              const SizedBox(height: DesignTokens.space2),
                              Text(
                                'Hata kodu: $_errorDetail',
                                style: const TextStyle(
                                  color: DesignTokens.textSecondaryDark,
                                  fontSize: DesignTokens.fontSizeSm - 2,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: DesignTokens.space6),
                    Semantics(
                      button: true,
                      label: 'Giriş yap',
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
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: DesignTokens.inputTextOnGold),
                              )
                            : const Text('Giriş yap',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _googleIleGiris,
                      icon: const Icon(Icons.g_mobiledata,
                          size: 22, color: DesignTokens.textSecondaryDark),
                      label: const Text('Google ile Giriş Yap'),
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
                        onPressed: _isLoading ? null : _facebookIleGiris,
                        icon: const Icon(Icons.facebook_rounded,
                            size: 18, color: Color(0xFF1877F2)),
                        label: const Text('Facebook ile Giriş Yap'),
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
                    const SizedBox(height: DesignTokens.space8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Hesabınız yok mu?',
                          style: TextStyle(
                            color: DesignTokens.textSecondaryDark,
                            fontSize: DesignTokens.fontSizeMd,
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => context.push(AppRouter.routeRegister),
                          style: TextButton.styleFrom(
                            foregroundColor: DesignTokens.antiqueGold,
                            padding: const EdgeInsets.only(left: 4, right: 8),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Kayıt ol',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2),
                          ),
                        ),
                      ],
                    ),
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

/// Şifremi unuttum: e-posta gir, sıfırlama bağlantısı gönder.
class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet(
      {required this.initialEmail, required this.onResetSent});

  final String initialEmail;
  final VoidCallback onResetSent;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (_isLoading) return;
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      await AuthService.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      if (!mounted) return;
      setState(() => _isLoading = false);
      FocusManager.instance.primaryFocus?.unfocus();
      widget.onResetSent();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _passwordResetUserFriendlyError(e);
      });
    }
  }

  /// Şifre sıfırlama için Firebase Auth hata kodlarını kullanıcı mesajına çevirir.
  static String _passwordResetUserFriendlyError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Geçerli bir e-posta adresi girin.';
        case 'user-not-found':
          return 'Bu e-posta adresiyle kayıtlı hesap bulunamadı.';
        case 'too-many-requests':
          return 'Çok fazla deneme. Biraz bekleyip tekrar deneyin.';
        case 'network-request-failed':
          return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
        case 'operation-not-allowed':
          return 'Şifre sıfırlama şu an etkin değil. Lütfen yönetici ile iletişime geçin.';
        case 'invalid-recipient':
        case 'invalid-sender':
          return 'E-posta yapılandırması hatalı. Lütfen yönetici ile iletişime geçin.';
        default:
          return 'Bağlantı gönderilemedi (${e.code}). E-posta adresinizi kontrol edin veya daha sonra tekrar deneyin.';
      }
    }
    final s = e.toString().toLowerCase();
    if (s.contains('user-not-found')) {
      return 'Bu e-posta adresiyle kayıtlı hesap bulunamadı.';
    }
    if (s.contains('invalid-email')) return 'Geçersiz e-posta adresi.';
    if (s.contains('too-many-requests')) {
      return 'Çok fazla deneme. Biraz bekleyip tekrar deneyin.';
    }
    if (s.contains('network')) return 'İnternet bağlantınızı kontrol edin.';
    return 'Bağlantı gönderilemedi. E-posta adresinizi kontrol edin veya daha sonra tekrar deneyin.';
  }

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      borderSide: const BorderSide(color: DesignTokens.borderDark),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      borderSide: BorderSide(color: DesignTokens.antiqueGold.withOpacity(0.7)),
    );
    return Padding(
      padding: EdgeInsets.only(
        left: DesignTokens.contentPaddingHorizontal,
        right: DesignTokens.contentPaddingHorizontal,
        top: DesignTokens.space6,
        bottom: MediaQuery.of(context).viewInsets.bottom + DesignTokens.space6,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Şifremi unuttum',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: DesignTokens.textPrimaryDark,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: DesignTokens.space2),
              const Text(
                'Kayıtlı e-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.',
                style: TextStyle(
                    color: DesignTokens.textSecondaryDark,
                    fontSize: DesignTokens.fontSizeSm),
              ),
              const SizedBox(height: DesignTokens.space6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: const TextStyle(color: DesignTokens.textPrimaryDark),
                cursorColor: DesignTokens.antiqueGold,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  hintText: 'ornek@firma.com',
                  labelStyle:
                      const TextStyle(color: DesignTokens.textTertiaryDark),
                  hintStyle:
                      const TextStyle(color: DesignTokens.textTertiaryDark),
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: DesignTokens.textTertiaryDark),
                  filled: true,
                  fillColor: DesignTokens.surfaceDark,
                  enabledBorder: inputBorder,
                  focusedBorder: focusBorder,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    borderSide: const BorderSide(color: DesignTokens.danger),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
                  if (!v.contains('@')) return 'Geçerli bir e-posta girin';
                  return null;
                },
                onFieldSubmitted: (_) => _sendReset(),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: DesignTokens.space3),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                      color: DesignTokens.danger.withOpacity(0.95),
                      fontSize: DesignTokens.fontSizeSm),
                ),
              ],
              const SizedBox(height: DesignTokens.space6),
              Semantics(
                button: true,
                label: 'Şifre sıfırlama bağlantısı gönder',
                child: FilledButton(
                  onPressed: _isLoading ? null : _sendReset,
                  style: FilledButton.styleFrom(
                    backgroundColor: DesignTokens.antiqueGold,
                    foregroundColor: DesignTokens.inputTextOnGold,
                    padding: const EdgeInsets.symmetric(
                        vertical: DesignTokens.space4),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: DesignTokens.inputTextOnGold),
                        )
                      : const Text('Sıfırlama bağlantısı gönder',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
