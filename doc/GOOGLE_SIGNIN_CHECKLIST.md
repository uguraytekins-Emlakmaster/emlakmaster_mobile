# Google ile Giriş / Kayıt — Kontrol Listesi

Bu dosya, projedeki Google Sign-In ayarlarının tutarlılığını doğrular. Tüm satırlar uyumlu ise Google giriş ve kayıt çalışır.

**Firebase Console:** Authentication → Sign-in method → **Google = Açık** ✓ (kullanıcı doğruladı)

---

## 1. Dart (tek kaynak)

| Dosya | Değer | Beklenen |
|-------|--------|----------|
| `lib/core/config/google_oauth_constants.dart` | `webClientId` | Web OAuth client ID (Firebase/Google Cloud) |
| | `iosClientId` | iOS OAuth client ID (GoogleService-Info.plist ile aynı) |

- **webClientId:** `572835725773-m7hqe81ad42nnk5dv6k7gq0oup7pksj1.apps.googleusercontent.com`
- **iosClientId:** `572835725773-8s71g3li2ful895gppeb6bvlbck09hkd.apps.googleusercontent.com`

---

## 2. Android

| Dosya | Ayar | Değer |
|-------|------|--------|
| `android/app/build.gradle` | `applicationId` | `com.example.emlakmaster_mobile` |
| `android/app/src/main/res/values/strings.xml` | `default_web_client_id` | `webClientId` ile **aynı** |
| `android/app/google-services.json` | `package_name` | `com.example.emlakmaster_mobile` |
| | `oauth_client` (client_type 3) | Web client ID = `webClientId` |

Google Cloud Console’da **Android** OAuth 2.0 istemcisi: paket adı `com.example.emlakmaster_mobile`, **SHA-1** (debug/release) eklenmiş olmalı. Ayrıntı: **docs/GOOGLE_SIGNIN_401_FIX.md**.

---

## 3. iOS

| Dosya | Ayar | Değer |
|-------|------|--------|
| `ios/Runner/GoogleService-Info.plist` | `CLIENT_ID` | `iosClientId` ile **aynı** |
| | `REVERSED_CLIENT_ID` | URL scheme (com.googleusercontent.apps....) |
| | `BUNDLE_ID` | `com.example.emlakmasterMobile` |
| `ios/Runner/Info.plist` | `GIDClientID` | `iosClientId` ile **aynı** |
| | `CFBundleURLTypes` (Google) | `REVERSED_CLIENT_ID` ile **aynı** |

Google Cloud Console’da **iOS** OAuth 2.0 istemcisi: Bundle ID `com.example.emlakmasterMobile` olmalı.

---

## 4. macOS

| Dosya | Ayar | Değer |
|-------|------|--------|
| `macos/Runner/GoogleService-Info.plist` | `CLIENT_ID` | `iosClientId` ile **aynı** |
| | `REVERSED_CLIENT_ID` | URL scheme |
| `macos/Runner/Info.plist` | `GIDClientID` | `iosClientId` ile **aynı** |
| | `CFBundleURLTypes` (Google) | `REVERSED_CLIENT_ID` ile **aynı** |

Kod: `GoogleAuthService` iOS ve **macOS** için aynı `iosClientId` kullanır (idToken için gerekli).

---

## 5. Firebase Console

- **Authentication** → **Sign-in method** → **Google** → **Enabled** ✓
- Proje: **emlak-master**

---

## 6. Akış (kod)

- **Giriş:** `LoginPage` → “Google ile Giriş Yap” → `GoogleAuthService.signInWithGoogleForFirebase()` → Firebase `signInWithCredential`.
- **Kayıt:** `RegisterPage` → “Google ile devam et” → aynı servis → ilk girişte rol seçimi.
- **Çıkış:** `AuthService.signOut()` → Firebase + `GoogleAuthService.signOut()`.

---

## 7. Test ve build

- `flutter test test/core/config/google_oauth_constants_test.dart` → geçmeli.
- `flutter analyze` → hatasız.
- `flutter build apk --debug` / `flutter run` → derlenmeli.

Bu listeyi doldurduktan ve Firebase’de Google’ı açtıktan sonra cihaz/emülatörde “Google ile Giriş Yap” / “Google ile devam et” deneyebilirsin.
