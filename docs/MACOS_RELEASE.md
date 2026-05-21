# macOS release dağıtımı

## Hızlı akış (geliştirme / kendi Mac)

```bash
flutter build macos --release
./scripts/package_macos_release.sh
open build/macos/Build/Products/Release/emlakmaster_mobile.app
```

DMG: `dist/macos/emlakmaster_mobile-<version>-<tarih>.dmg`

## Pre-release (CI ile aynı kontroller)

```bash
SKIP_BUILD=0 bash scripts/pre_release_check.sh   # test + analiz + release build
./scripts/package_macos_release.sh
```

## Dağıtım hazırlık kontrolü

```bash
./scripts/check_macos_distribution_ready.sh   # eksikleri listeler
./scripts/open_developer_id_setup.sh        # sertifika + Xcode
```

## Başka Mac’lere dağıtım (notarization)

Şu an Xcode **Apple Development** ile imzalıyor; Gatekeeper başka makinelerde **reddeder**.

1. [Apple Developer](https://developer.apple.com) → **Certificates** → **Developer ID Application**
2. Xcode → Runner → **Signing & Capabilities** → Release için Developer ID
3. Yeniden build:

   ```bash
   flutter build macos --release
   ```

4. Notarization (app-specific password: appleid.apple.com → App-Specific Passwords):

   ```bash
   export APPLE_ID="aytekinugi@gmail.com"
   export APPLE_TEAM_ID="FJ2A2DKJB9"
   export APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
   export MACOS_SIGN_IDENTITY="Developer ID Application: Ad Soyad (TEAMID)"

   NOTARIZE=1 ./scripts/package_macos_release.sh
   ```

   veya yalnızca notarize:

   ```bash
   ./scripts/notarize_macos_release.sh dist/macos/emlakmaster_mobile-….dmg
   ```

5. `spctl -a -vv` ile doğrulama:

   ```bash
   spctl -a -vv build/macos/Build/Products/Release/emlakmaster_mobile.app
   ```

Beklenen: `accepted` + `source=Notarized Developer ID`.

## Bundle boyutu

- Profile limit: `./scripts/check_macos_bundle_size.sh` (200 MB)
- Release örnek: ~140 MB
