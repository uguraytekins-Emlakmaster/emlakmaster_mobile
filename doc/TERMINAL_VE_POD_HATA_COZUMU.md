# Terminal ve Xcode Pod hataları — hızlı çözüm

## 1) “No pubspec.yaml” / `cd emlakmaster_mobile/macos` bulunamadı

Bu hatalar **yanlış klasörde** olduğunuz için oluşur. Terminalde çoğu zaman `~` veya `/Users/kullaniciadi` açılırsınız; Flutter komutları **proje kökünde** çalışmalıdır.

**Doğru proje kökü (bu makinede):**

```bash
cd /Users/uguraytekin/Projeler/EmlakMaster_Proje/emlakmaster_mobile
```

Sonra:

```bash
flutter clean
flutter pub get
```

**iOS Pod’ları** (Xcode’daki “sandbox is not in sync with Podfile.lock” için):

```bash
cd /Users/uguraytekin/Projeler/EmlakMaster_Proje/emlakmaster_mobile/ios
pod install --repo-update
```

**macOS Pod’ları** (sadece macOS hedefi için):

```bash
cd /Users/uguraytekin/Projeler/EmlakMaster_Proje/emlakmaster_mobile/macos
pod install --repo-update
```

> İpucu: `pwd` yazarak bulunduğunuz klasörü kontrol edin; `pubspec.yaml` görmüyorsanız bir üst dizine veya yukarıdaki tam yola gidin.

---

## 2) Xcode: “The sandbox is not in sync with the Podfile.lock”

**Neden:** `Podfile.lock` güncellendi (ör. `flutter pub get`, yeni plugin) ama `Pods/` klasörü / `Manifest.lock` eski kaldı.

1. Xcode’u kapatın.
2. Proje kökünden:
   ```bash
   cd ios && pod install --repo-update
   ```
   veya kalkan + pub: `scripts/pub_get_with_fix.sh` (iOS fixer `Podfile.lock` ≠ `Pods/Manifest.lock` ise `pod install` tetikler).
3. Projeyi **`.xcworkspace`** ile açın:  
   `ios/Runner.xcworkspace` (`.xcodeproj` değil).
4. Xcode’da tekrar Build (⌘B).

Gerekirse temiz kurulum:

```bash
cd /Users/uguraytekin/Projeler/EmlakMaster_Proje/emlakmaster_mobile/ios
rm -rf Pods Podfile.lock build
pod install --repo-update
```

**Tek komut (önerilen):** proje kökünde `scripts/ios_pod_repair.sh` — `flutter pub get` + `pod install` (varsayılan). Trunk tam tarama için `--repo-update`. Bozuk CDN / `JSON::ParserError` / `gRPC-Core.podspec.json` için: `--clean-cache` (isteğe bağlı `--repo-update`).

> **Not (Cursor / CI):** Ara ara CocoaPods CDN indirmesi yarım kalıp `unexpected end of input` ile `gRPC-Core` podspec’i bozulabilir. Bu durumda **`--clean-cache`** ve komutu **yerel Terminal.app**’te (veya Xcode dışı tam ortamda) çalıştırın; önbellek `~/Library/Caches/CocoaPods` altındadır. Cursor içinde `pod install` BoringSSL/gRPC aşamasında çok uzun sürebilir — **Mac’te doğrudan Terminal** kullanın.

---

## 3) “Communicating on a dead channel”

Genelde uygulama çöktüğünde veya hot restart kesildiğinde görülür. Pod’lar düzeldikten sonra `flutter run` ile yeniden çalıştırın; çoğu zaman ikincil bir uyarıdır.
