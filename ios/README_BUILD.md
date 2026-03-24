# iOS build — “sandbox is not in sync with Podfile.lock”

Bu uyarı, **`Podfile.lock` ile `Pods/Manifest.lock` eşleşmiyor** demektir. Çözüm:

## 1) Xcode’u kapatın

## 2) Terminal’de (proje kökü) — **yerel Mac Terminal** önerilir

Cursor/IDE içinden `pod install` bazen CDN önbelleğinde takılır; **tam yetkili Terminal.app** kullanın.

```bash
cd /Users/uguraytekin/Projeler/EmlakMaster_Proje/emlakmaster_mobile
./scripts/ios_pod_repair.sh
```

- Varsayılan: `flutter pub get` + **`pod install`** (hızlı).
- Trunk tam yenileme: `./scripts/ios_pod_repair.sh --repo-update`
- `JSON::ParserError` / bozuk **gRPC** podspec: `./scripts/ios_pod_repair.sh --clean-cache`  
  (gerekirse: `--clean-cache --repo-update`)

## 3) Doğru dosyayı açın

- **Açın:** `ios/Runner.xcworkspace`
- **Açmayın:** `Runner.xcodeproj` (Pods entegrasyonu workspace ile gelir)

## 4) Xcode’da

**Product → Clean Build Folder** (⇧⌘K), ardından **Build** (⌘B).

---

**Not:** `pod install` bitince `ios/Pods/Manifest.lock` oluşur ve `Podfile.lock` ile aynı içeriğe sahip olmalıdır.
