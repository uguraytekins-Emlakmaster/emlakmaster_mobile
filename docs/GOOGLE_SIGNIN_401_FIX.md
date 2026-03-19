# Google ile Giriş — 401 invalid_client / OAuth client was not found

Bu hata, Google Cloud Console'da **iOS** ve **Android** için OAuth 2.0 istemcisi tanımlı olmadığında veya paket adı/Bundle ID / SHA-1 uyuşmadığında oluşur.

**Hızlı adım:** Proje kökünden `./scripts/open_google_oauth_setup.sh` çalıştırın. Tarayıcı Credentials sayfasını açar; çıktıdaki değerleri kopyalayıp yapıştırmanız yeterli.

## 1. Google Cloud Console

1. [Google Cloud Console](https://console.cloud.google.com/) → proje **emlak-master** seçin.
2. **APIs & Services** → **Credentials** sayfasına gidin.

## 2. iOS için OAuth istemcisi

1. **+ CREATE CREDENTIALS** → **OAuth client ID**.
2. **Application type:** **iOS** seçin.
3. **Name:** örn. `EmlakMaster iOS`.
4. **Bundle ID:** tam olarak `com.example.emlakmasterMobile` yazın (GoogleService-Info.plist ve firebase_options ile aynı).
5. **Create** deyin. Çıkan **Client ID** ve **iOS URL scheme** (reversed client ID) not alın.
6. **Info.plist** içindeki `CFBundleURLSchemes` değerinin bu **iOS URL scheme** ile aynı olması gerekir. Yeni oluşturduğunuz iOS client farklı bir ID verirse, `ios/Runner/Info.plist` içinde ilgili dizi değerini bu yeni scheme ile güncelleyin.

## 3. Android için OAuth istemcisi

1. **+ CREATE CREDENTIALS** → **OAuth client ID**.
2. **Application type:** **Android** seçin.
3. **Name:** örn. `EmlakMaster Android`.
4. **Package name:** `com.example.emlakmaster_mobile` (android/app/build.gradle `applicationId` ile aynı).
5. **SHA-1 certificate fingerprint** ekleyin:
   - **Debug:** Terminalde (Java yüklüyse):  
     `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`  
     Çıktıdaki **SHA1** satırını kopyalayın.  
     Veya Android Studio: **Project** → **android** → sağ tık **Open Module Settings** → **Signing**; veya **Gradle** → **android** → **Tasks** → **android** → **signingReport** çalıştırıp SHA1 satırını alın.
   - **Release** kullanacaksanız, release keystore için de SHA-1 ekleyin.
6. **Create** deyin.

## 4. Firebase Console

- **Authentication** → **Sign-in method** → **Google** → **Enabled** olduğundan emin olun.
- Proje **emlak-master** ile aynı proje kullanılıyor olmalı.

## 5. Uygulama tarafı (mevcut durum)

- **Web client ID** tek kaynak: `lib/core/config/google_oauth_constants.dart` → `GoogleOAuthConstants.webClientId` (Dart) ve Android `res/values/strings.xml` → `default_web_client_id` (aynı değer).
- Giriş akışı: `GoogleAuthService` önce **sessiz oturum** (`signInSilently`) dener — daha önce Google ile giriş yapmış kullanıcılar çoğu kez hesap seçiciyi görmeden hızlı girer; gerekirse tam Google akışı açılır.
- Çıkışta `AuthService.signOut()` hem Firebase hem Google oturumunu kapatır (sonraki Google girişinde doğru hesap seçilebilir).
- iOS / macOS **Info.plist** `CFBundleURLSchemes`: `com.googleusercontent.apps.572835725773-93531b623c67ce9392c484`. Ayrı **iOS OAuth client** kullanıyorsanız bu scheme’i o client’ın reversed ID’si ile güncelleyin; **webClientId** yine **Web** istemci ID kalmalıdır.

## 6. Kontrol

- iOS ve Android için OAuth istemcilerini oluşturup SHA-1 (Android) ve Bundle ID (iOS) doğru girdikten sonra uygulamayı yeniden derleyip çalıştırın.
- Hâlâ 401 alırsanız: Console’da ilgili client’ı açıp Bundle ID / Package name / SHA-1’in projedeki değerlerle birebir aynı olduğunu kontrol edin.
