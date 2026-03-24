# Gerçek cihaz testi (Android & iOS)

## Ön koşullar

- Flutter SDK güncel; `flutter doctor -v` yeşil.
- **Android**: USB hata ayıklama açık, cihaz `adb devices` ile görünür.
- **iOS**: Xcode; ücretsiz Apple hesabı ile **Signing & Capabilities**’te **Sign In with Apple** olmamalı (bu projede kaldırıldı). Gerekirse Xcode’da Development Team seçin.

## Debug günlükleri

- **Navigasyon**: `AppLogger.nav` — `NavigatorObserver` (debug).
- **Riverpod**: `DebugRiverpodObserver` — adlandırılmış provider güncellemeleri + hatalar (yalnızca `kDebugMode`).
- **HTTP**: `traceHttpCall` — TCMB / exchangerate örnekleri (süre; hassas veri loglanmaz).
- **Hatalar**: `runZonedGuarded`, `FlutterError.onError`, `PlatformDispatcher.instance.onError`, Crashlytics (Firebase yüklüyse).

## Önerilen komutlar

```bash
cd emlakmaster_mobile

# Bağımlılıklar
flutter pub get

# Analiz
flutter analyze

# Gerçek cihaz / emülatör (debug)
flutter run

# Android release APK (cihaza yükleme testi)
flutter build apk --release

# iOS — imzasız derleme doğrulaması (debug veya release)
flutter build ios --debug --no-codesign
# veya
flutter build ios --release --no-codesign
```

## Performans incelemesi

- Flutter DevTools → **Performance** (jank), **CPU Profiler**.
- Ağır listeler için `ListView.builder` / `ListView.separated` tercih edin; sabit kısa formlar için `ListView` kabul edilebilir.

## Riskler

- Ücretsiz Apple hesabı: belirli capability’ler ve dağıtım kısıtları devam eder; provisioning Xcode’da çözülmelidir.
- Aşırı debug log’u düşük cihazlarda hafif gecikme yaratabilir; release build’de Riverpod observer ve çoğu API süre log’u kapalıdır.
