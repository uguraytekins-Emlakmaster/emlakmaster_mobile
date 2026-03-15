# EmlakMaster Mobile

Flutter ile geliştirilmiş mobil uygulama (iOS, Android, macOS).

## Çalıştırma

```bash
flutter pub get
flutter run
```

**Koruma kalkanı (önerilen):** Bağımlılıklar ve üretilmiş dosyalar otomatik kontrol/düzeltilir:

```bash
./scripts/pub_get_with_fix.sh    # pub get + kalkan
./scripts/run_with_shield.sh     # kalkan + flutter run
./scripts/shield/shield.sh       # sadece kalkan
```

Detay: [scripts/shield/README.md](scripts/shield/README.md)

## Gereksinimler

- Flutter SDK (environment: sdk ^3.5.0)
- iOS: Xcode, CocoaPods
- Android: Android Studio / SDK
