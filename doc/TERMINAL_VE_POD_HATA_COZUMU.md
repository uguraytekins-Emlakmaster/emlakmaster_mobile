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

1. Xcode’u kapatın.
2. Yukarıdaki gibi **`ios`** klasöründe `pod install` çalıştırın.
3. Projeyi **`.xcworkspace`** ile açın:  
   `ios/Runner.xcworkspace` (`.xcodeproj` değil).
4. Xcode’da tekrar Build (⌘B).

Gerekirse temiz kurulum:

```bash
cd /Users/uguraytekin/Projeler/EmlakMaster_Proje/emlakmaster_mobile/ios
rm -rf Pods Podfile.lock build
pod install --repo-update
```

---

## 3) “Communicating on a dead channel”

Genelde uygulama çöktüğünde veya hot restart kesildiğinde görülür. Pod’lar düzeldikten sonra `flutter run` ile yeniden çalıştırın; çoğu zaman ikincil bir uyarıdır.
