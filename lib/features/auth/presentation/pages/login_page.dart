import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth_firestore_gate.dart';
import '../../../../core/services/auth_session_coordinator.dart';
import '../../../../core/services/firebase_core_bootstrap.dart';
import '../../../../core/services/logout_flow_tracer.dart';
import '../../../../core/services/login_attempt_guard.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/facebook_auth_service.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../domain/auth_result.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_result_ui.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../utils/auth_error_messages.dart';
import '../../../../core/services/login_entry_store.dart';
import '../../../../core/services/onboarding_store.dart';
import '../../domain/login_entry_persona.dart';
import '../widgets/auth_entry_hero.dart';
import '../widgets/auth_entry_persona_selector.dart';
import '../widgets/auth_field_decoration.dart';
import '../widgets/auth_page_shell.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';

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
  LoginEntryPersona? _persona;
  bool _personaReady = false;

  bool get _anyBusy => _busy != _BusyKind.none;

  /// Google girişinde "Dock'ta Safari/Chrome penceresine bakın" ipucu yalnızca
  /// harici tarayıcı penceresi açan masaüstü/web akışında geçerlidir.
  /// Android/iOS native hesap seçici kullanır → ipucu gizlenir.
  bool get _googleHintIsRelevant {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  /// Gerçek hata kodu (Firebase vb.); kullanıcı "bilgiler doğru" dediğinde teşhis için gösterilir.
  String? _errorDetail;
  String? _googleStatusHint;

  /// Giriş spinner'ı için güvenlik bekçisi: hiçbir giriş yöntemi sınırsız
  /// dönmemeli (anayasa: error-resilience — asla sonsuz yükleme). Auth/Firestore
  /// beklenenden uzun sürerse spinner sıfırlanır ve "tekrar dene" mesajı gösterilir.
  Timer? _busyWatchdog;
  static const Duration _busyWatchdogTimeout = Duration(seconds: 25);

  void _armBusyWatchdog() {
    _busyWatchdog?.cancel();
    _busyWatchdog = Timer(_busyWatchdogTimeout, () {
      if (!mounted || _busy == _BusyKind.none) return;
      setState(() {
        _busy = _BusyKind.none;
        _googleStatusHint = null;
        _errorMessage = AppLocalizations.of(context).t('auth_login_timeout');
      });
    });
  }

  void _cancelBusyWatchdog() {
    _busyWatchdog?.cancel();
    _busyWatchdog = null;
  }

  @override
  void initState() {
    super.initState();
    LogoutFlowTracer.step('LOGIN_RECOVERY', 'LoginPage.initState');
    _persona = LoginEntryStore.instance.personaSync;
    _personaReady = true;
    if (_persona == null) {
      unawaited(_loadPersona());
    }
    unawaited(
      FirebaseCoreBootstrap.instance.ensureReady().catchError((_) {}),
    );
  }

  Future<void> _loadPersona() async {
    final saved = await LoginEntryStore.instance.loadPersona();
    if (!mounted) return;
    setState(() {
      _persona = saved;
      _personaReady = true;
    });
  }

  Future<void> _onPersonaSelected(LoginEntryPersona persona) async {
    setState(() => _persona = persona);
    await LoginEntryStore.instance.setPersona(persona);
  }

  @override
  void dispose() {
    _busyWatchdog?.cancel();
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
    if (_persona == null) {
      setState(() => _errorMessage =
          AppLocalizations.of(context).t('auth_select_persona'));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final blocked = LoginAttemptGuard.assertCanAttempt();
    if (blocked != null) {
      setState(() => _errorMessage = blocked);
      return;
    }
    AppFeedback.mediumImpact();
    setState(() => _busy = _BusyKind.email);
    _armBusyWatchdog();
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
        _errorMessage = userFriendlyAuthError(AppLocalizations.of(context), e);
        _errorDetail = detail;
      });
    } finally {
      _cancelBusyWatchdog();
      if (mounted) setState(() => _busy = _BusyKind.none);
    }
  }

  void _openForgotPassword() {
    FocusManager.instance.primaryFocus?.unfocus();
    final email = _emailController.text.trim();
    showPremiumModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PremiumBottomSheetHandle(),
            _ForgotPasswordSheet(
              initialEmail: email,
              onDismiss: () {
                Navigator.of(sheetCtx).pop();
              },
            ),
          ],
        ),
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
      if (mounted) {
        await _navigateAfterAuthSuccess(r.credential);
      }
    } else if (r.shouldRecordLoginFailure) {
      LoginAttemptGuard.recordFailure();
    }
  }

  Future<void> _navigateAfterAuthSuccess(UserCredential cred) async {
    if (cred.user == null && FirebaseAuth.instance.currentUser == null) return;
    await _navigateAfterAuthSession();
  }

  Future<void> _navigateAfterAuthSession() async {
    if (Firebase.apps.isEmpty) {
      try {
        await FirebaseCoreBootstrap.instance.ensureReady();
      } catch (_) {
        return;
      }
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !mounted) return;

    await AuthFirestoreGate.ensureReadableUid(user.uid, forceRefresh: true);
    AuthSessionCoordinator.prepareForLogin(ref, user.uid);

    for (var i = 0; i < 30; i++) {
      if (ref.read(currentUserProvider).valueOrNull != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }

    if (!mounted) return;
    ref.read(AppRouter.goRouterProvider).refresh();

    final path = GoRouter.of(context).state.uri.path;
    if (path != AppRouter.routeLogin &&
        path != AppRouter.routeRegister &&
        path != AppRouter.routeOnboarding) {
      return;
    }

    final needsRole = ref.read(needsRoleSelectionProvider);
    final needsOffice = ref.read(needsOfficeSetupProvider);
    final needsRecovery = ref.read(needsOfficeRecoveryProvider);

    if (needsRole) {
      if (!OnboardingStore.instance.workspaceSetupCompletedSync) {
        context.go(AppRouter.routeWorkspaceSetup);
      } else {
        context.go(AppRouter.routeRoleSelection);
      }
      return;
    }
    if (needsOffice) {
      context.go(AppRouter.routeOfficeGate);
      return;
    }
    if (needsRecovery) {
      context.go(AppRouter.routeOfficeRecovery);
      return;
    }
    context.go(AppRouter.routeHome);
  }

  Future<void> _googleIleGiris() async {
    if (_busy != _BusyKind.none) return;
    if (_persona == null) {
      setState(() => _errorMessage =
          AppLocalizations.of(context).t('auth_select_persona'));
      return;
    }
    final blocked = LoginAttemptGuard.assertCanAttempt();
    if (blocked != null) {
      setState(() => _errorMessage = blocked);
      return;
    }
    AppFeedback.mediumImpact();
    setState(() {
      _errorMessage = null;
      _errorDetail = null;
      _googleStatusHint = AppLocalizations.of(context).t('auth_google_preparing');
      _busy = _BusyKind.google;
    });
    _armBusyWatchdog();
    unawaited(
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (!mounted || _busy != _BusyKind.google) return;
        setState(() => _googleStatusHint =
            AppLocalizations.of(context).t('auth_google_opening'));
      }),
    );
    try {
      final r = await GoogleAuthService.instance.signInWithGoogleTyped();
      if (!mounted) return;
      await _applyTypedAuthResult(r, analyticsMethod: 'google');
      setState(() {
        _errorMessage = r.loginBannerMessage ??
            (r is AuthCancelled
                ? AppLocalizations.of(context).t('auth_google_incomplete')
                : null);
        _errorDetail = switch (r) {
          AuthFailure(:final debugDetail) => debugDetail,
          AuthCancelled() => 'cancelled',
          _ => null,
        };
        _googleStatusHint = null;
      });
    } finally {
      _cancelBusyWatchdog();
      if (mounted) {
        setState(() {
          _busy = _BusyKind.none;
          if (_googleStatusHint != null && _errorMessage == null) {
            _googleStatusHint = null;
          }
        });
      }
    }
  }

  Future<void> _facebookIleGiris() async {
    if (_busy != _BusyKind.none) return;
    if (_persona == null) {
      setState(() => _errorMessage =
          AppLocalizations.of(context).t('auth_select_persona'));
      return;
    }
    final blocked = LoginAttemptGuard.assertCanAttempt();
    if (blocked != null) {
      setState(() => _errorMessage = blocked);
      return;
    }
    AppFeedback.mediumImpact();
    setState(() {
      _errorMessage = null;
      _errorDetail = null;
      _busy = _BusyKind.facebook;
    });
    _armBusyWatchdog();
    try {
      await FacebookAuthService.instance
          .signInWithFacebookForFirebase()
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () => throw FirebaseAuthException(
              code: 'timeout',
              message: AppLocalizations.of(context).t('auth_fb_timeout'),
            ),
          );
      if (!mounted) return;
      LoginAttemptGuard.clear();
      AnalyticsService.instance.logLogin(method: 'facebook');
    } catch (e) {
      if (!mounted) return;
      LoginAttemptGuard.recordFailure();
      final msg = _facebookSignInErrorMessage(AppLocalizations.of(context), e);
      setState(() {
        _errorMessage = msg.isEmpty ? null : msg;
      });
    } finally {
      _cancelBusyWatchdog();
      if (mounted) setState(() => _busy = _BusyKind.none);
    }
  }

  static String _facebookSignInErrorMessage(AppLocalizations l10n, Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return l10n.t('auth_fb_account_exists');
        case 'invalid-credential':
          return e.message ?? l10n.t('auth_fb_invalid_credential');
        case 'facebook-login-failed':
          return e.message ?? l10n.t('auth_fb_failed');
        case 'timeout':
          return e.message ?? l10n.t('auth_timeout_retry');
        case 'network-request-failed':
          return l10n.t('auth_no_internet');
        default:
          return l10n.tArgs('auth_fb_failed_code', [e.code]);
      }
    }
    if (e is PlatformException) {
      final c = e.code.toLowerCase();
      final m = '${e.message}'.toLowerCase();
      if (c.contains('cancel') || m.contains('cancel')) {
        return '';
      }
      if (c.contains('network') || m.contains('network')) {
        return l10n.t('auth_network_error');
      }
      return l10n.tArgs('auth_fb_failed_code2', [e.code]);
    }
    return l10n.t('auth_fb_failed_generic');
  }

  void _resetLocalInteractionState() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_busy == _BusyKind.none &&
        _errorMessage == null &&
        _googleStatusHint == null) {
      return;
    }
    if (!mounted) return;
    LogoutFlowTracer.step(
      'LOGIN_RECOVERY',
      'reset busy=$_busy errors=${_errorMessage != null}',
    );
    setState(() {
      _busy = _BusyKind.none;
      _errorMessage = null;
      _errorDetail = null;
      _googleStatusHint = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(
      currentUserProvider,
      (previous, next) {
        final hadUser = previous?.valueOrNull != null;
        final noUser = next.valueOrNull == null;
        if (hadUser && noUser) {
          _resetLocalInteractionState();
        }
      },
    );
    ref.listen<int>(
      authPresentationEpochProvider,
      (previous, next) {
        if (previous != next) {
          _resetLocalInteractionState();
        }
      },
    );
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    if (!_personaReady) {
      if (LogoutFlowTracer.isActive) {
        LogoutFlowTracer.step('LOGIN_RECOVERY', 'LoginPage waiting persona');
      }
      return AuthPageShell(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space8),
            child: CircularProgressIndicator(color: ext.accent),
          ),
        ),
      );
    }
    if (LogoutFlowTracer.isActive) {
      LogoutFlowTracer.step('LOGIN_RECOVERY', 'LoginPage interactive busy=$_busy');
    }
    return AuthPageShell(
      persona: _persona,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: DesignTokens.space2),
            AuthEntryHero(persona: _persona),
            const SizedBox(height: DesignTokens.space6),
            AuthEntryPersonaSelector(
              selected: _persona,
              onSelected: _onPersonaSelected,
            ),
            const SizedBox(height: DesignTokens.space8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              style: TextStyle(color: ext.textPrimary),
              cursorColor: ext.accent,
              onTapOutside: (_) => _unfocusKeyboard(),
              decoration: AuthFieldDecoration.build(
                context,
                label: l10n.t('label_email'),
                hint: l10n.t('auth_email_hint'),
                prefix: const Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.t('auth_email_required');
                }
                if (!v.contains('@')) {
                  return l10n.t('auth_email_invalid');
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: DesignTokens.space4),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: TextStyle(color: ext.textPrimary),
              cursorColor: ext.accent,
              onTapOutside: (_) => _unfocusKeyboard(),
              decoration: AuthFieldDecoration.build(
                context,
                label: l10n.t('auth_password_label'),
                prefix: const Icon(Icons.lock_outline_rounded),
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.t('auth_password_required');
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
                child: Text(l10n.t('auth_forgot_password')),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: DesignTokens.space4),
              Container(
                padding: const EdgeInsets.all(DesignTokens.space3),
                decoration: BoxDecoration(
                  color: ext.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: ext.danger.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: ext.danger.withValues(alpha: 0.9), size: 20),
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
                    if (_errorDetail != null && _errorDetail!.isNotEmpty) ...[
                      const SizedBox(height: DesignTokens.space2),
                      Text(
                        l10n.tArgs('auth_error_code', [_errorDetail!]),
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
              label: l10n.t('auth_login_cta'),
              child: FilledButton(
                onPressed: _anyBusy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: ext.accent,
                  foregroundColor: ext.onBrand,
                  padding:
                      const EdgeInsets.symmetric(vertical: DesignTokens.space4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
                child: _busy == _BusyKind.email
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: ext.onBrand),
                      )
                    : Text(l10n.t('auth_login_cta'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
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
                    ? l10n.t('auth_google_connecting')
                    : l10n.t('auth_login_google'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ext.textPrimary,
                side: BorderSide(color: ext.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
              ),
            ),
            if (_busy == _BusyKind.google && _googleStatusHint != null) ...[
              const SizedBox(height: DesignTokens.space2),
              Text(
                _googleStatusHint!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: DesignTokens.fontSizeSm,
                ),
              ),
              // "Tarayıcı/Dock" ipucu yalnızca harici tarayıcı penceresi
              // açılan masaüstünde (web/macOS/Windows/Linux) anlamlıdır.
              // Android/iOS'ta Google girişi native hesap seçici ile akar;
              // bu platformlarda Dock/Safari ipucu yanıltıcıdır → gizle.
              if (_googleHintIsRelevant) ...[
                const SizedBox(height: DesignTokens.space1),
                Text(
                  l10n.t('auth_google_browser_hint'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ext.textSecondary.withValues(alpha: 0.85),
                    fontSize: DesignTokens.fontSizeSm - 1,
                  ),
                ),
              ],
            ],
            if (AppConstants.showFacebookLogin) ...[
              const SizedBox(height: DesignTokens.space3),
              OutlinedButton.icon(
                onPressed: _anyBusy ? null : _facebookIleGiris,
                icon: const Icon(Icons.facebook_rounded,
                    size: 18, color: Color(0xFF1877F2)),
                label: Text(l10n.t('auth_login_facebook')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ext.textPrimary,
                  side: BorderSide(color: ext.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.space8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.t('auth_no_account'),
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
                  child: Text(
                    l10n.t('auth_register_cta'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, letterSpacing: 0.2),
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
    AppFeedback.mediumImpact();
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
        _errorMessage =
            _passwordResetUserFriendlyError(AppLocalizations.of(context), e);
      });
    }
  }

  /// Şifre sıfırlama için Firebase Auth hata kodlarını kullanıcı mesajına çevirir.
  static String _passwordResetUserFriendlyError(
      AppLocalizations l10n, dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return l10n.t('auth_reset_invalid_email');
        case 'user-not-found':
          return l10n.t('auth_reset_user_not_found');
        case 'too-many-requests':
          return l10n.t('auth_too_many_requests');
        case 'network-request-failed':
          return l10n.t('auth_check_internet_retry');
        case 'operation-not-allowed':
          return l10n.t('auth_reset_not_allowed');
        case 'invalid-recipient':
        case 'invalid-sender':
          return l10n.t('auth_reset_email_config');
        default:
          return l10n.tArgs('auth_reset_failed_code', [e.code]);
      }
    }
    final s = e.toString().toLowerCase();
    if (s.contains('user-not-found')) {
      return l10n.t('auth_reset_user_not_found');
    }
    if (s.contains('invalid-email')) return l10n.t('auth_reset_invalid_email2');
    if (s.contains('too-many-requests')) {
      return l10n.t('auth_too_many_requests');
    }
    if (s.contains('network')) return l10n.t('auth_check_internet');
    return l10n.t('auth_reset_failed_generic');
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      borderSide: BorderSide(color: ext.border),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      borderSide: BorderSide(color: ext.accent.withValues(alpha: 0.7)),
    );
    return Padding(
      padding: const EdgeInsets.only(
        left: DesignTokens.contentPaddingHorizontal,
        right: DesignTokens.contentPaddingHorizontal,
        top: DesignTokens.space3,
        bottom: DesignTokens.space6,
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
                    l10n.t('auth_reset_sent_title'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    l10n.t('auth_reset_sent_body'),
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
                      padding: const EdgeInsets.symmetric(
                          vertical: DesignTokens.space4),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                    ),
                    child: Text(l10n.t('action_ok'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
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
                      l10n.t('auth_forgot_password'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      l10n.t('auth_forgot_password_sub'),
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
                        labelText: l10n.t('label_email'),
                        hintText: l10n.t('auth_email_hint'),
                        labelStyle: TextStyle(color: ext.textTertiary),
                        hintStyle: TextStyle(color: ext.textPassive),
                        prefixIcon:
                            Icon(Icons.email_outlined, color: ext.textTertiary),
                        filled: true,
                        fillColor: ext.surface,
                        enabledBorder: inputBorder,
                        focusedBorder: focusBorder,
                        errorBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMd),
                          borderSide: BorderSide(color: ext.danger),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.t('auth_email_required');
                        }
                        if (!v.contains('@')) {
                          return l10n.t('auth_email_invalid');
                        }
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
                      label: l10n.t('auth_send_reset_link'),
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
                                    strokeWidth: 2, color: ext.onBrand),
                              )
                            : Text(l10n.t('auth_send_reset_link_short'),
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
