# Platform Gereksinimleri ve Uyumluluk

Bu belge EmlakMaster mobil uygulamasının desteklediği platformları ve minimum sürümleri tanımlar.

## Desteklenen platformlar

| Platform | Minimum sürüm | Notlar |
|----------|----------------|--------|
| **iOS**  | 13.0           | Podfile + Xcode deployment target. Info.plist GIDClientID, URL scheme, ITSAppUsesNonExemptEncryption. |
| **Android** | API 23 (Android 6) | minSdk 23, targetSdk 35. Google Sign-In için `default_web_client_id` (strings.xml). |
| **macOS** | (Flutter default) | Google Sign-In URL scheme + GIDClientID. Push/Crashlytics web hariç. |
| **Web**  | (Flutter default) | Firebase options mevcut; platform kontrolü `kIsWeb` / `defaultTargetPlatform` ile. |

## Yapılandırma özeti

- **Firebase:** `lib/firebase_options.dart` — web, macos, android, ios ayrı ayrı tanımlı.
- **Google Sign-In:** iOS/macOS için `GIDClientID` ve `CFBundleURLTypes`; Android için `res/values/strings.xml` → `default_web_client_id`.
- **Router / ilk ekran:** Tüm platformlarda aynı akış (onboarding → login/register → rol seçimi → ana sayfa). Beyaz ekran önlemi: kök koyu arka plan + router loading/error ekranları koyu.
- **Analiz:** `dart analyze` ve `flutter analyze` hatasız geçmeli; lint kuralları `analysis_options.yaml` içinde.

## Sonradan sorun çıkmaması için

- Bağımlılık eklerken/güncellerken: `flutter pub get` ve `dart analyze` çalıştırın.
- Yeni platform eklerken: `firebase_options.dart` ve ilgili platform klasörü (ios/android/macos) güncel olmalı.
- iOS/Android native değişiklikten sonra: `flutter clean` ve tekrar build önerilir.
