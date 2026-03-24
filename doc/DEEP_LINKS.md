# Derin bağlantılar — Bölge özeti (`/region-insight/:regionId`)

## Bağımlılık

- Paket: **`app_links`** (`pubspec.yaml`). Kurulum: proje kökünde `flutter pub get` veya altyapıya uygun olarak `scripts/pub_get_with_fix.sh` (pub get + shield).

## Uygulama içi

- `AppRouter.regionInsightPath('kayapinar')` → `/region-insight/kayapinar`
- `extra: RegionHeatmapScore` ile tam skor taşınır; **extra yoksa** `resolveRegionHeatmapForRoute` varsayılan Diyarbakır üçlüsünden eşleştirir.

## Özel URL şeması (`app_links` + platform kayıtları)

Şema: **`emlakmaster`**

Örnekler (Android / iOS / macOS):

| URI | Açıklama |
|-----|----------|
| `emlakmaster:///region-insight/kayapinar` | Üçlü slash, path doğrudan |
| `emlakmaster://app/region-insight/kayapinar` | `app` host + path |
| `emlakmaster://region-insight/kayapinar` | `region-insight` host + segment |

HTTPS (ileride evrensel bağlantı için):

- `https://<alan>/region-insight/kayapinar` — path `/region-insight/...` ile çözülür.

## Oturum yok

1. Rota `PendingDeepLinkStore` içine yazılır (`AppRouter.redirect` + `RegionDeepLinkBootstrap`).
2. Kullanıcı giriş yaptıktan sonra `consumePendingAfterAuth` ile `router.go(pending)` çalışır.

## Test

```bash
flutter test test/core/deep_linking/region_insight_uri_test.dart
```

## Android test (adb)

```bash
adb shell am start -a android.intent.action.VIEW -d "emlakmaster://app/region-insight/kayapinar"
```
