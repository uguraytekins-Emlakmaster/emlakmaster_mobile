# EmlakMaster — Platform İzinleri ve Özellik Durumu

Tüm özelliklerin iOS, Android ve macOS’ta açık olması için gerekli izinler tanımlanmıştır.

## iOS (`ios/Runner/Info.plist`)

| İzin / Anahtar | Açıklama | Özellik |
|----------------|----------|---------|
| `NSPhotoLibraryUsageDescription` | Galeri erişimi | Ofis logosu (image_picker) |
| `NSCameraUsageDescription` | Kamera | Logo fotoğrafı (image_picker) |
| `NSMicrophoneUsageDescription` | Mikrofon | Sesli not, Hands-Free CRM (speech_to_text) |
| `NSSpeechRecognitionUsageDescription` | Konuşma tanıma | Ses → metin (speech_to_text) |
| `UIBackgroundModes`: fetch, remote-notification | Arka plan | Push bildirimleri (firebase_messaging) |

**url_launcher:** Harici 360° / link açmak için ek plist gerekmez (standart https).

---

## Android (`android/app/src/main/AndroidManifest.xml`)

| İzin | Açıklama | Özellik |
|------|----------|---------|
| `INTERNET` | Ağ | Firebase, API, CachedNetworkImage, url_launcher |
| `POST_NOTIFICATIONS` | Bildirimler | FCM, in-app bildirimler |
| `RECORD_AUDIO` | Mikrofon | Sesli not, Hands-Free CRM (speech_to_text) |
| `CAMERA` | Kamera | Logo fotoğrafı (image_picker) |
| `READ_EXTERNAL_STORAGE` (maxSdkVersion 32) | Depolama (eski) | Galeri (image_picker) |
| `READ_MEDIA_IMAGES` | Medya (Android 13+) | Galeri (image_picker) |

---

## macOS (`macos/Runner/Info.plist`)

| İzin / Anahtar | Açıklama | Özellik |
|----------------|----------|---------|
| `CFBundleURLTypes` (Google Sign-In) | OAuth URL scheme | Google giriş |
| `NSMicrophoneUsageDescription` | Mikrofon | Sesli not (speech_to_text) |
| `NSSpeechRecognitionUsageDescription` | Konuşma tanıma | Ses → metin |
| `NSPhotoLibraryUsageDescription` | Galeri | Ofis logosu |
| `NSCameraUsageDescription` | Kamera | Logo fotoğrafı |

---

## Özellik ↔ Platform Özeti

| Özellik | iOS | Android | macOS |
|---------|-----|---------|-------|
| Firebase (Auth, Firestore, FCM, Crashlytics, Analytics) | ✅ | ✅ | ✅ (Firebase config ile) |
| Google Sign-In | ✅ | ✅ | ✅ (URL scheme tanımlı) |
| Görsel: CachedNetworkImage, image_picker | ✅ | ✅ | ✅ |
| Sesli not / Hands-Free CRM (speech_to_text) | ✅ | ✅ | ✅ |
| Push bildirimleri | ✅ (UIBackgroundModes) | ✅ (POST_NOTIFICATIONS) | — |
| url_launcher (360° link, harici sayfa) | ✅ | ✅ | ✅ |
| Hive (yerel cache) | ✅ | ✅ | ✅ |

Yeni bir native özellik (örn. konum, bluetooth) eklendiğinde ilgili platformun manifest/plist dosyasına izin eklenmeli.
