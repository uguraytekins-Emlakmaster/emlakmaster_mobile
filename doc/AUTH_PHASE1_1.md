# Phase 1.1 — Kimlik doğrulama (e-posta, Google, Apple)

## Desteklenen sağlayıcılar

| Sağlayıcı | Kod | Not |
|-----------|-----|-----|
| E-posta / şifre | `AuthService` | Giriş ve kayıt sonrası `UserBootstrapOrchestrator` |
| Google | `GoogleAuthService.signInWithGoogleTyped()` / `signInWithGoogleForFirebase()` | Web + iOS client ID: `GoogleOAuthConstants` |
| Apple | `AppleAuthService.signInWithAppleForFirebase()` | Yalnızca iOS/macOS; nonce + Firebase `OAuthProvider('apple.com')` |

Facebook: `AppConstants.showFacebookLogin` kapalıyken stub.

## Tip güvenli sonuç

- `AuthResult`: `AuthSuccess` | `AuthCancelled` | `AuthRequiresAction` | `AuthFailure`
- `AuthFailureKind`: `networkError`, `providerMisconfigured`, `userCancelled`, `invalidCredential`, `accountConflict`, `unknownError`
- Eşleme: `AuthResultMapper.fromFirebaseAuth` / `fromUnknown`
- İptal (Google hesap kapatma, Apple iptal) **throttling’e yazılmaz** (`auth_result_ui` + guard mantığı)

## Bootstrap sırası

1. Firebase Auth oturumu açılır.
2. `UserBootstrapOrchestrator.afterSuccessfulAuth` → `UserRepository.mergeProfileIfDocExists` (doc **varsa** boş `name`/`email` doldurur; doc yoksa yazı yok).
3. İlk `users/{uid}` oluşturma ve rol ataması **rol seçimi** / `ensureUserDocProvider` akışında kalır (`needsRoleSelectionProvider`).

## Yönlendirme (merkezi)

`GoRouter` + `needsRoleSelectionProvider` + `OnboardingStore` (`app_router.dart`). Giriş butonundan doğrudan `context.go` yok.

## Ortam / yapılandırma

- **Google:** `lib/core/config/google_oauth_constants.dart` — `webClientId`, `iosClientId`; Firebase Console’da Google provider.
- **Apple:** Firebase’de Apple provider; Apple Developer’da Sign in with Apple capability; Xcode → Signing & Capabilities → **Sign in with Apple**.
- **Ortak:** `AuthProviderConfig` — Apple’ın bu derlemede gösterilip gösterilmeyeceği.

## Testler

- `test/features/auth/auth_result_mapper_test.dart`
- `test/features/auth/auth_result_ui_test.dart`
