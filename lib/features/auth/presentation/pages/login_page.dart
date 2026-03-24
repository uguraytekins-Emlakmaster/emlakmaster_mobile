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
import '../../domain/auth_result.dart';
import '../utils/auth_result_ui.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../utils/auth_error_messages.dart';
import '../widgets/auth_field_decoration.dart';
import '../widgets/auth_page_shell.dart';
enum _BusyKind { none, email, google, facebook }

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
  _BusyKind _busy = _BusyKind.none;
  String? _errorMessage;

  bool get _anyBusy => _busy != _BusyKind.none;

  /// Gerçek hata kodu (Firebase vb.); kullanıcı "bilgiler doğru" dediğinde teşhis için gösterilir.
  String? _errorDetail;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy != _BusyKind.none) return;
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
    setState(() => _busy = _BusyKind.email);
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
        _errorMessage = userFriendlyAuthError(e);
        _errorDetail = detail;
      });
    } finally {
      if (mounted) setState(() => _busy = _BusyKind.none);
    }
  }

  void _openForgotPassword() {
    FocusManager.instance.primaryFocus?.unfocus();
    final email = _emailController.text.trim();
    final ext = AppThemeExtension.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ext.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
      ),
      builder: (sheetCtx) => _ForgotPasswordSheet(
        initialEmail: email,
        onDismiss: () {
          Navigator.of(sheetCtx).pop();
          // Başarı metni sheet içinde (_sent); ek SnackBar yok — kapanınca mesaj kaybolmaz.
        },
      ),
    );
  }

  static void _unfocusKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _applyTypedAuthResult(
    AuthResult r, {
    required String analyticsMethod,
  }) async {
    if (r is AuthSuccess) {
      LoginAttemptGuard.clear();
      await AnalyticsService.instance.logLogin(method: analyticsMethod);
    } else if (r.shouldRecordLoginFailure) {
      LoginAttemptGuard.recordFailure();
    }
  }

  Future<void> _googleIleGiris() async {
    if (_busy != _BusyKind.none) return;
    final blocked = LoginAttemptGuard.assertCanAttempt();
    if (blocked != null) {
      setState(() => _errorMessage = blocked);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _errorMessage = null;
      _errorDetail = null;
      _busy = _BusyKind.google;
    });
    try {
      final r = await GoogleAuthService.instance.signInWithGoogleTyped();
      if (!mounted) return;
      await _applyTypedAuthResult(r, analyticsMethod: 'google');
      setState(() {
        _errorMessage = r.loginBannerMessage;
        _errorDetail = r is AuthFailure ? r.debugDetail : null;
      });
    } finally {
      if (mounted) setState(() => _busy = _BusyKind.none);
    }
  }

  Future<void> _facebookIleGiris() async {
    if (_busy != _BusyKind.none) return;
    final blocked = LoginAttemptGuard.assertCanAttempt();
    if (blocked != null) {
      setState(() => _errorMessage = blocked);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _errorMessage = null;
      _errorDetail = null;
      _busy = _BusyKind.facebook;
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
    } catch (e) {
      if (!mounted) return;
      LoginAttemptGuard.recordFailure();
      final msg = _facebookSignInErrorMessage(e);
      setState(() {
        _errorMessage = msg.isEmpty ? null : msg;
      });
    } finally {
      if (mounted) setState(() => _busy = _BusyKind.none);
    }
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
    final ext = AppThemeExtension.of(context);
    return AuthPageShell(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: DesignTokens.space4),
            Text(
              'Rainbow CRM',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: ext.brandPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    fontSize: 28,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Profesyonel gayrimenkul operasyonu',
              style: TextStyle(
                color: ext.foregroundSecondary,
                fontSize: DesignTokens.fontSizeMd,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      style:
                          TextStyle(color: ext.textPrimary),
                      cursorColor: ext.accent,
                      onTapOutside: (_) => _unfocusKeyboard(),
                      decoration: AuthFieldDecoration.build(context,
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
                          TextStyle(color: ext.textPrimary),
                      cursorColor: ext.accent,
                      onTapOutside: (_) => _unfocusKeyboard(),
                      decoration: AuthFieldDecoration.build(context,
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
                        onPressed: _anyBusy ? null : _openForgotPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: ext.accent,
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
                          color: ext.danger.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMd),
                          border: Border.all(
                              color: ext.danger.withValues(alpha: 0.35)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    color: ext.danger.withValues(alpha: 0.9),
                                    size: 20),
                                const SizedBox(width: DesignTokens.space2),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                        color: ext.textPrimary,
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
                                style: TextStyle(
                                  color: ext.textSecondary,
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
                        onPressed: _anyBusy ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: ext.accent,
                          foregroundColor: ext.onBrand,
                          padding: const EdgeInsets.symmetric(
                              vertical: DesignTokens.space4),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusMd),
                          ),
                        ),
                        child: _busy == _BusyKind.email
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: ext.onBrand),
                              )
                            : const Text('Giriş yap',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    OutlinedButton.icon(
                      onPressed: _anyBusy ? null : _googleIleGiris,
                      icon: _busy == _BusyKind.google
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ext.textSecondary,
                              ),
                            )
                          : Icon(Icons.g_mobiledata,
                              size: 22, color: ext.textSecondary),
                      label: Text(
                        _busy == _BusyKind.google
                            ? 'Google ile bağlanılıyor…'
                            : 'Google ile Giriş Yap',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ext.textPrimary,
                        side: BorderSide(color: ext.border),
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
                        onPressed: _anyBusy ? null : _facebookIleGiris,
                        icon: const Icon(Icons.facebook_rounded,
                            size: 18, color: Color(0xFF1877F2)),
                        label: const Text('Facebook ile Giriş Yap'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ext.textPrimary,
                          side: BorderSide(color: ext.border),
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
                        Text(
                          'Hesabınız yok mu?',
                          style: TextStyle(
                            color: ext.textSecondary,
                            fontSize: DesignTokens.fontSizeMd,
                          ),
                        ),
                        TextButton(
                          onPressed: _anyBusy
                              ? null
                              : () => context.push(AppRouter.routeRegister),
                          style: TextButton.styleFrom(
                            foregroundColor: ext.accent,
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
    );
  }
}

/// Şifremi unuttum: e-posta gir, sıfırlama bağlantısı gönder.
class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet(
      {required this.initialEmail, required this.onDismiss});

  final String initialEmail;
  /// Başarı ekranında «Tamam» sonrası: sheet kapanır + isteğe bağlı SnackBar.
  final VoidCallback onDismiss;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _sent = false;

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
      setState(() {
        _isLoading = false;
        _sent = true;
      });
      FocusManager.instance.primaryFocus?.unfocus();
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
    final ext = AppThemeExtension.of(context);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      borderSide: BorderSide(color: ext.border),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      borderSide: BorderSide(color: ext.accent.withValues(alpha: 0.7)),
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
        child: _sent
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.mark_email_read_outlined,
                      size: 52, color: ext.success.withValues(alpha: 0.95)),
                  const SizedBox(height: DesignTokens.space4),
                  Text(
                    'Bağlantı gönderildi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    'Gelen kutunuzu ve spam klasörünü kontrol edin. E-posta birkaç dakika sürebilir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ext.textSecondary,
                      fontSize: DesignTokens.fontSizeSm,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space6),
                  FilledButton(
                    onPressed: widget.onDismiss,
                    style: FilledButton.styleFrom(
                      backgroundColor: ext.accent,
                      foregroundColor: ext.onBrand,
                      padding: const EdgeInsets.symmetric(vertical: DesignTokens.space4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                    ),
                    child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              )
            : Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Şifremi unuttum',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: DesignTokens.space2),
              Text(
                'Kayıtlı e-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.',
                style: TextStyle(
                    color: ext.textSecondary,
                    fontSize: DesignTokens.fontSizeSm),
              ),
              const SizedBox(height: DesignTokens.space6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: TextStyle(color: ext.textPrimary),
                cursorColor: ext.accent,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  hintText: 'ornek@firma.com',
                  labelStyle:
                      TextStyle(color: ext.textTertiary),
                  hintStyle:
                      TextStyle(color: ext.textTertiary),
                  prefixIcon: Icon(Icons.email_outlined,
                      color: ext.textTertiary),
                  filled: true,
                  fillColor: ext.surface,
                  enabledBorder: inputBorder,
                  focusedBorder: focusBorder,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    borderSide: BorderSide(color: ext.danger),
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
                      color: ext.danger.withValues(alpha: 0.95),
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
                    backgroundColor: ext.accent,
                    foregroundColor: ext.onBrand,
                    padding: const EdgeInsets.symmetric(
                        vertical: DesignTokens.space4),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ext.onBrand),
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
