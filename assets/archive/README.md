# Asset arşivi (Flutter bundle dışı)

Bu klasördeki dosyalar **pubspec.yaml** içinde tanımlı değildir; uygulama APK/IPA boyutuna dahil edilmez.

| Alt klasör | İçerik |
|------------|--------|
| `branding/` | İkon varyantları, SVG kaynaklar, önizlemeler, yedek PNG’ler |
| `onboarding/` | Tanıtım ekran görüntüleri ve kaynak PNG’ler |

**Uygulamada kullanılan branding**

- `assets/branding/emlak_master_app_icon_MASTER.png` — UI amblemi, launcher (Android/macOS/web)
- `assets/branding/emlak_master_app_icon_IOS_STORE_OPAQUE.png` — iOS App Store ikonu

Tanıtım slaytları kod mock’ları ile çizilir (`kOnboardingLegacyAssetPaths` boş). PNG kullanmak için slayta `assetPath` ekleyip dosyayı `assets/branding/` veya yeni bir `assets/onboarding/` girdisi ile pubspec’e alın.

İkon yeniden üretimi: `dart run tool/compose_ios_store_opaque_icon.dart`
