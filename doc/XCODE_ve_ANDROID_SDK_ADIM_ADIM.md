# Xcode ve Android SDK – Adım Adım Tam Rehber

---

# BÖLÜM A: XCODE (iOS için)

## A.1 Xcode’u indirme ve kurma

1. **App Store**’u açın (Mac’te sol üstten Apple menü → App Store veya Spotlight’ta “App Store” yazın).
2. Arama kutusuna **“Xcode”** yazın.
3. **Xcode** (Apple’ın uygulaması, mavi ikon) çıkacak → **Al** / **Get** (veya zaten yüklüyse **Aç** / **Open**) tıklayın.
4. Apple ID ile giriş yapmanız istenebilir. İndirme **birkaç GB** olduğu için zaman alır; bitene kadar bekleyin.
5. Kurulum bitince **Launchpad** veya **Applications** klasöründen **Xcode**’u açın.

---

## A.2 İlk açılış – lisans ve bileşenler

1. **Xcode**’u ilk kez açtığınızda **“Install additional required components?”** benzeri bir pencere çıkabilir → **Install** deyin.
2. **Lisans sözleşmesi** çıkarsa **Agree** (Kabul Et) tıklayın.
3. Gerekirse **şifrenizi** (Mac oturum şifresi) girin; kurulum tamamlansın.
4. Xcode tam açılana kadar bekleyin (ilk açılışta indeksleme yapabilir).

---

## A.3 Command Line Tools (Flutter için gerekli)

1. Xcode açıkken üst menüden **Xcode** → **Settings** (veya **Preferences**) tıklayın.
2. **Locations** sekmesine girin.
3. **Command Line Tools** satırında açılır menüden **Xcode sürümünüz** seçili olsun (örn. “Xcode 26.3”). Boşsa buradan seçin.
4. Pencereyi kapatın.

---

## A.4 iOS Simulator (sanal iPhone) yükleme

Flutter’ın “Unable to get list of installed Simulator runtimes” dememesi için en az bir iOS Simulator gerekir.

1. **Xcode**’u açın.
2. Üst menüden **Xcode** → **Settings** (veya **Preferences**) → **Platforms** sekmesine girin.  
   (Eski Xcode sürümlerinde bu bölüm **Components** veya **Downloads** adında olabilir.)
3. Sol tarafta **iOS** satırını görün. Yanında bir **simulator sürümü** (örn. “iOS 18.0” veya “iOS 17.5”) listeleniyorsa zaten yüklüdür.
4. **Hiç iOS sürümü yoksa** veya yanında **Get** / **Download** / **+** butonu varsa:
   - **Get** veya **Download** tıklayın.
   - İndirme büyük olabilir (birkaç GB); tamamlanana kadar bekleyin.
5. İndirme bitince listede **iOS …** “Installed” veya yeşil tik olarak görünür.
6. **Settings** penceresini kapatın.

---

## A.5 Simulator’ü test etme

1. Xcode üst menü: **Window** → **Devices and Simulators** (veya **Organizer** içinde Devices).
2. Üstte **Simulators** sekmesini seçin.
3. Sol listede en az bir **iPhone** modeli (örn. iPhone 15) görünüyorsa Simulator kurulmuştur.
4. İsterseniz bir simülatöre çift tıklayıp sanal iPhone’u açabilirsiniz; Flutter buna “cihaz” olarak bağlanır.

---

## A.6 Flutter ile kontrol

Terminalde:

```bash
flutter doctor -v
```

**Xcode** satırında yeşil tik ve “Xcode - develop for iOS and macOS” tamam görünmeli. Hâlâ uyarı varsa:

- Xcode’u bir kez açıp lisansı kabul ettiğinizden,
- **Settings → Locations** içinde Command Line Tools’un seçili olduğundan,
- **Settings → Platforms** içinde en az bir iOS sürümünün yüklü olduğundan emin olun.

---

## A.7 EmlakMaster’ı iOS’ta çalıştırma

```bash
cd /Users/uguraytekin/Projeler/EmlakMaster_Proje/emlakmaster_mobile
flutter pub get
cd ios && pod install && cd ..
flutter run -d ios
```

İlk seferde “Which device?” diye sorarsa listeden **iPhone Simulator**’ü seçin. Uygulama Simulator’de açılacaktır.

---

## A.8 iOS: "Unable to install ... Shutdown" (code 405) hatası

**Belirti:** Build başarılı olur ama `Error launching application on iPhone 16e` ve mesajda **"Unable to lookup in current state: Shutdown"** veya **code 405** geçer.

**Sebep:** Simulator kapalı (Shutdown). Flutter uygulamayı yüklerken cihazın açık ve "Booted" olması gerekir.

**Çözüm:**

1. **Simulator'ü önce açın:** Spotlight (Cmd+Space) → "Simulator" yazıp Simulator uygulamasını açın; veya Xcode → Window → Devices and Simulators → Simulators → bir iPhone (örn. iPhone 16e) seçip açın.
2. Simulator penceresinde iOS tam açılana kadar (ana ekran görünene kadar) bekleyin.
3. Terminalde tekrar: `flutter run -d "iPhone 16e"` (cihaz adı farklıysa `flutter devices` ile ID'yi görüp `flutter run -d <id>` kullanın).

**Alternatif:** `open -a Simulator` ile Simulator'ü açın; iOS yüklendikten sonra `flutter run -d ios` çalıştırın.

---

# BÖLÜM B: ANDROID SDK (Android için)

## B.1 Android Studio indirme

1. Tarayıcıda şu adresi açın: **https://developer.android.com/studio**
2. Yeşil **“Download Android Studio”** butonuna tıklayın.
3. Sözleşmeyi kabul edin (checkbox işaretleyip indirmeyi başlatın).
4. İndirilen **.dmg** dosyasını açın ve **Android Studio**’yu **Applications** klasörüne sürükleyin.

---

## B.2 Android Studio ilk açılış – SDK kurulumu

1. **Applications**’tan **Android Studio**’yu çalıştırın.
2. **“Import Android Studio Settings…”** veya **“Do not import settings”** çıkarsa → **Do not import settings** → OK.
3. **Welcome** ekranında **Next** ile devam edin.
4. **Install Type** ekranında **Standard** seçili olsun → **Next**.
5. **UI Theme** (tema) isterse istediğinizi seçin → **Next**.
6. **Verify Settings** ekranında kurulacaklar listelenir:
   - **Android SDK**
   - **Android SDK Platform**
   - **Android Virtual Device** (emülatör)
   Bunları olduğu gibi bırakın → **Finish**.
7. **“Downloading Components”** penceresi açılır; tüm bileşenlerin inmesini bekleyin (internet hızına göre 10–30 dakika sürebilir).
8. **Finish** görününce tıklayın. Android Studio ana ekranı açılır.

---

## B.3 SDK konumunu not alma (gerekirse)

Flutter daha sonra “Unable to locate Android SDK” derse bu yolu kullanacaksınız.

1. Android Studio’da **Android Studio** menü → **Settings** (Mac’te **Preferences**).
2. Sol menüden **Languages & Frameworks** → **Android SDK** tıklayın.
3. Üstte **“Android SDK Location”** yazan yerdeki yolu kopyalayın. Genelde:
   - **/Users/uguraytekin/Library/Android/sdk**
   Bu yolu bir yere not edin.

---

## B.4 Flutter’a Android SDK yolunu verme

Terminalde:

```bash
flutter doctor
```

**Android toolchain** kırmızıysa ve **“Unable to locate Android SDK”** yazıyorsa:

```bash
flutter config --android-sdk /Users/uguraytekin/Library/Android/sdk
```

(SDK’yı farklı yere kurduysanız, B.3’te not ettiğiniz yolu buraya yazın.)

Sonra tekrar:

```bash
flutter doctor
```

Android toolchain yeşil olana kadar bu adımı kullanın.

---

## B.5 Android lisanslarını kabul etme

Terminalde:

```bash
flutter doctor --android-licenses
```

Her soruda **y** yazıp **Enter**’a basın. Tüm lisanslar kabul edilene kadar devam edin.

---

## B.6 Emülatör (sanal cihaz) oluşturma (isteğe bağlı)

1. Android Studio’da **More Actions** veya **Tools** → **Device Manager** açın.
2. **Create Device** tıklayın.
3. Bir telefon modeli seçin (örn. **Pixel 6**) → **Next**.
4. Bir **system image** (örn. “Tiramisu” API 33) seçin. Yanında **Download** yazıyorsa önce indirin, sonra **Next**.
5. **Finish** deyin. Cihaz listeye eklenir.

---

## B.7 EmlakMaster’ı Android’de çalıştırma

- **Emülatör kullanacaksanız:** Önce Device Manager’dan emülatörü **Play** ile başlatın.
- Terminalde:

```bash
cd /Users/uguraytekin/Projeler/EmlakMaster_Proje/emlakmaster_mobile
flutter pub get
flutter run -d android
```

Cihaz/emülatör listesi için: `flutter devices`. Birden fazla cihaz varsa `flutter run -d <cihaz_id>` ile seçebilirsiniz.

---

# Özet

| Ne yapıyorsunuz   | Nerede / Ne yapın |
|-------------------|-------------------|
| Xcode indir       | App Store → “Xcode” ara → Al / Aç |
| Xcode lisans      | İlk açılışta Install / Agree |
| Command Line Tools| Xcode → Settings → Locations → Command Line Tools seçin |
| iOS Simulator     | Xcode → Settings → Platforms → iOS → Get/Download |
| Android Studio    | developer.android.com/studio → Download |
| Android SDK       | Android Studio ilk açılışta Standard kurulum, Finish’e kadar bekleyin |
| SDK yolu          | Android Studio → Settings → Android SDK → yolu kopyalayın |
| Flutter’a SDK     | `flutter config --android-sdk /Users/uguraytekin/Library/Android/sdk` |
| Android lisans    | `flutter doctor --android-licenses` → hepsinde `y` |

Bu adımları tamamladıktan sonra hem **Xcode** hem **Android SDK** Flutter ile uyumlu olur; `flutter run -d ios` ve `flutter run -d android` komutlarını kullanabilirsiniz.
