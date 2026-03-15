# EmlakMaster – Android ve iOS Kurulum Rehberi

Bu rehber, projeyi **Android** ve **iOS**’ta çalıştırmak için bilgisayarınızda yapmanız gereken adımları anlatır. Proje tarafı (Flutter kodu, Android/iOS yapılandırması) zaten hazır; sadece **Android SDK** ve **Xcode** kurulumu sizin yapacağınız işlemler.

---

## 1. Android için

### 1.1 Android Studio ve SDK kurulumu

1. **Android Studio** indirin:  
   https://developer.android.com/studio  
   “Download Android Studio” ile indirip kurun.

2. **İlk açılışta** kurulum sihirbazı çıkar:
   - “Standard” kurulumu seçin.
   - **Android SDK**, SDK Platform-Tools ve emulator bileşenleri kurulacak.
   - Kurulum bitene kadar bekleyin.

3. **SDK konumunu not alın** (ileride gerekebilir):
   - Android Studio → **Settings / Preferences** → **Languages & Frameworks** → **Android SDK**
   - “Android SDK Location” (örn. `~/Library/Android/sdk`).

### 1.2 Flutter’a SDK yolunu gösterme (gerekirse)

Terminalde:

```bash
flutter doctor
```

“Android toolchain” hâlâ kırmızıysa ve “Unable to locate Android SDK” diyorsa:

```bash
flutter config --android-sdk /Users/uguraytekin/Library/Android/sdk
```

(Yol farklıysa Android Studio’daki “Android SDK Location” değerini yazın.)

### 1.3 Lisansları kabul etme

```bash
flutter doctor --android-licenses
```

Tüm sorularda `y` yazıp Enter’a basın.

### 1.4 Emülatör veya cihaz

- **Emülatör:** Android Studio → **Device Manager** → “Create Device” ile bir sanal cihaz oluşturun.
- **Fiziksel cihaz:** USB ile bağlayıp “USB hata ayıklama”yı açın; `flutter devices` ile görünmeli.

### 1.5 Projeyi Android’de çalıştırma

```bash
cd /Users/uguraytekin/Projeler/EmlakMaster_Proje/emlakmaster_mobile
flutter pub get
flutter run -d android
```

İlk seferde build uzun sürebilir. Cihaz/emülatör listesi için: `flutter devices`.

---

## 2. iOS için

### 2.1 Xcode

- **Xcode** App Store’dan yükleyin (zaten yüklüyse güncel tutun).
- Bir kez **Xcode’u açıp** lisansı kabul edin ve “Additional Components” varsa yükleyin.

### 2.2 Simulator runtimes (flutter doctor uyarısı için)

“Unable to get list of installed Simulator runtimes” uyarısı varsa:

1. **Xcode** açın.
2. **Xcode** menü → **Settings** (veya **Preferences**) → **Platforms** (veya **Components**).
3. **iOS** platformunda bir **Simulator** sürümü (örn. en güncel iOS) yüklü değilse “Get” / “Install” ile yükleyin.

### 2.3 Projeyi iOS’ta çalıştırma

**Gerçek cihaz** veya **Simulator** gerekir (yalnızca macOS’ta çalışır).

```bash
cd /Users/uguraytekin/Projeler/EmlakMaster_Proje/emlakmaster_mobile
flutter pub get
cd ios && pod install && cd ..
flutter run -d ios
```

Cihaz seçimi: `flutter devices` ile “iPhone” veya “ios” etiketli cihazı görün; belirli cihaz için `flutter run -d <device-id>` kullanın.

**Not:** Gerçek iPhone’da çalıştırmak için Apple Developer hesabı ve Xcode’da “Signing & Capabilities” ayarı gerekir.

---

## 3. Firebase (Android / iOS)

Projede **Firebase** (Auth, Firestore) kullanılıyor. Şu an aynı Firebase projesi (emlak-master) için genel ayarlar kodda tanımlı; tam ve kalıcı yapılandırma için:

1. **FlutterFire CLI** kurun:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Proje klasöründe:
   ```bash
   cd /Users/uguraytekin/Projeler/EmlakMaster_Proje/emlakmaster_mobile
   flutterfire configure
   ```
   Bu komut:
   - Firebase projenizi seçmenizi ister,
   - Android ve iOS uygulamalarını (gerekirse) oluşturur,
   - `lib/firebase_options.dart`, `android/app/google-services.json` ve `ios/Runner/GoogleService-Info.plist` dosyalarını günceller.

Bunu yapmadan da **web** ile aynı proje bilgileri kullanıldığı için Auth/Firestore çoğu senaryoda çalışabilir; tam uyum ve ileride push bildirimleri için `flutterfire configure` önerilir.

---

## 4. Özet komutlar

| Platform   | Komut |
|-----------|--------|
| macOS     | `flutter run -d macos` |
| Android   | `flutter run -d android` |
| iOS       | `cd ios && pod install && cd ..` sonra `flutter run -d ios` |

Tüm cihazları görmek: `flutter devices`  
Kurulum kontrolü: `flutter doctor -v`

---

## 5. Projede yapılan Android / iOS değişiklikleri

- **Android:** `minSdk 21`, uygulama adı “EmlakMaster”, `INTERNET` izni, `usesCleartextTraffic` (geliştirme için).
- **iOS:** Uygulama görünen adı “EmlakMaster”, minimum iOS 13.0.
- **Firebase:** `firebase_options.dart` içinde Android ve iOS platformları eklendi (aynı proje); isteğe bağlı `flutterfire configure` ile tam yapılandırma.

Bu adımları tamamladıktan sonra hem Android hem iOS’ta `flutter run -d android` ve `flutter run -d ios` ile uygulamayı çalıştırabilirsiniz.
