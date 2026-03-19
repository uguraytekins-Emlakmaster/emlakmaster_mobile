# EmlakMaster Mobile

Flutter ile geliştirilmiş mobil uygulama (iOS, Android, macOS).

## Çalıştırma

**Önerilen (kalkan ile):**

```bash
./scripts/run_with_shield.sh              # kalkan + flutter run (varsayılan cihaz)
./scripts/run_with_shield.sh -d macos     # macOS
./scripts/run_with_shield.sh -d chrome    # Web
```

**Manuel:**

```bash
flutter pub get
flutter run
```

**Koruma kalkanı:** Bağımlılıklar ve üretilmiş dosyalar otomatik kontrol/düzeltilir.

```bash
./scripts/full_clean_and_prepare.sh  # tam temiz + pub get + shield + pod install (ilk kurulum / çökme sonrası)
./scripts/pub_get_with_fix.sh        # pub get + kalkan
./scripts/shield/shield.sh           # sadece kalkan
```

Detay: [scripts/shield/README.md](scripts/shield/README.md)

## Ortam (opsiyonel)

API anahtarı veya özel konfigürasyon kullanacaksanız `.env.example` dosyasını `.env` olarak kopyalayıp doldurun. Proje şu an Firebase `firebase_options.dart` ile çalışır; `.env` zorunlu değildir.

## Proje yapısı

- **`lib/screens/`** — Rol bazlı kabuklar (admin, danışman, müşteri), onboarding, liste/detay sayfaları, placeholder’lar. Router’dan doğrudan açılan tam sayfa ekranlar ve shell’ler burada.
- **`lib/features/`** — Özellik modülleri (auth, crm_customers, calls, pipeline, war_room, settings, vb.). Her modül kendi içinde `data/`, `domain/`, `presentation/` (pages, widgets, providers) yapısını kullanır.
- **`lib/core/`** — Tema (`theme/design_tokens.dart`), router, servisler, ortak widget’lar (`app_loading.dart`, `command_palette.dart`, shimmer, toaster), sabitler, l10n.
- **`lib/widgets/`** — Dashboard bento bileşenleri ve paylaşılan UI (bento_analytics, bento_ai_news, finance_bar, master_ticker, magic_call_button, vb.). Sayfa-bağımsız, tekrar kullanılabilir widget’lar.
- **Tema:** Renk ve spacing için `DesignTokens` kullanılır; doğrudan `Color(0xFF...)` yerine `DesignTokens.primary`, `DesignTokens.scaffoldDark` vb. tercih edilir.

## Gereksinimler

- Flutter SDK (environment: sdk ^3.5.0)
- iOS: Xcode, CocoaPods
- Android: Android Studio / SDK
