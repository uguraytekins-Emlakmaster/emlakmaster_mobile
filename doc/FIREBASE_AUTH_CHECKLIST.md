# Firebase Console ve Giriş Kontrol Listesi

Giriş yapılamıyorsa aşağıdaki adımları sırayla kontrol edin. Hepsi uygunsa sorun büyük ihtimalle şifre/e-posta uyumsuzluğu veya ağdır.

---

## 1. Firebase Console → Authentication

- **Proje:** [Firebase Console](https://console.firebase.google.com) → **emlak-master**
- **Sol menü:** **Authentication** → **Sign-in method**

### 1.1 E-posta/Şifre

- **E-posta/Şifre** satırı **Etkin** olmalı.
- Kapalıysa: **E-posta/Şifre** → **Etkinleştir** → **Kaydet**
- Bu kapalıysa `operation-not-allowed` alırsınız; uygulama da bunu açıklayan mesaj gösterir.

### 1.2 Kullanıcı gerçekten kayıtlı mı?

- **Authentication** → **Users**
- Giriş yapmaya çalıştığınız **e-posta** listede var mı kontrol edin.
- Yoksa önce uygulama içinden **Kayıt ol** ile hesap oluşturun veya Console’dan **Add user** ile ekleyin.

### 1.3 Google ile giriş ✓

- **Google** satırı **Etkin** (kullanıcı doğruladı).
- Proje ayarları tüm platformlarda uyumlu: **doc/GOOGLE_SIGNIN_CHECKLIST.md**. Android (default_web_client_id, google-services.json), iOS ve macOS (GIDClientID, CFBundleURLSchemes) aynı Web/iOS client ID ile. Android’de 401 alırsan SHA-1: **docs/GOOGLE_SIGNIN_401_FIX.md**.

### 1.4 Facebook ile giriş

- **Facebook** satırı **Etkin** olmalı; Firebase’e **App ID** ve **App Secret** girilmeli.
- Uygulama tarafında **App ID** ve **Client Token** Android/iOS’ta tanımlı olmalı. Tek komut: **doc/FACEBOOK_SIGNIN_SETUP.md** ve `./scripts/configure_facebook_app.sh`.

---

## 2. Proje yapılandırması (uygulama tarafı)

### 2.1 Aynı proje kullanılıyor mu?

- **lib/firebase_options.dart** içinde `projectId: 'emlak-master'` olmalı.
- Web, Android, iOS, macOS için tanımlı `apiKey` ve `appId` bu projeye ait olmalı.

### 2.2 Android

- **google-services.json** (Android projesinde) bu Firebase projesinden indirilmiş olmalı.
- **android/app/src/main/res/values/strings.xml** → `default_web_client_id` = Web OAuth istemci ID (Google Sign-In için).

### 2.3 iOS

- **GoogleService-Info.plist** bu Firebase projesinden indirilmiş olmalı.
- **Info.plist** → `GIDClientID`, `CFBundleURLTypes` (Google Sign-In URL scheme) doğru olmalı.
- Facebook kullanıyorsanız: **FacebookAppID**, **FacebookClientToken** ve `fb...` URL scheme doğru olmalı (doc/FACEBOOK_SIGNIN_SETUP.md).

---

## 3. Firestore kuralları (giriş sonrası rol için)

- Giriş **Firebase Auth** ile yapılır; Firestore sadece giriş **sonrası** `users/{uid}` okumak için kullanılır.
- Giriş yapılamıyorsa sorun büyük ihtimalle **Auth** (yukarıdaki adımlar), Firestore değil.
- Yine de: **Firestore** → **Rules** → `users` için `allow read: if isSignedIn() && (request.auth.uid == userId || isManager());` benzeri kural olmalı (mevcut projede tanımlı).

---

## 4. Olası hata kodları ve anlamları

| Hata kodu | Ne yapmalı |
|-----------|------------|
| **operation-not-allowed** | Firebase Console → Authentication → Sign-in method → **E-posta/Şifre**’yi açın. |
| **user-not-found** / **wrong-password** / **invalid-credential** | E-posta veya şifre hatalı; şifrede baş/sonda boşluk olmasın. Hesap Authentication → Users’ta var mı kontrol edin. |
| **invalid-email** | Geçerli e-posta formatı girin. |
| **too-many-requests** | Bir süre bekleyip tekrar deneyin (Firebase veya uygulama tarafı sınır). |
| **network-request-failed** | İnternet bağlantısı ve firewall/VPN kontrolü. |
| **user-disabled** | Hesap devre dışı; yönetici ile iletişime geçin. |
| **invalid-api-key** / **app-not-authorized** | firebase_options / google-services / GoogleService-Info ile Console’daki proje aynı mı kontrol edin. |

---

## 5. Uygulama içi kontroller

- **Şifre:** Uygulama girişte e-posta ve şifreyi **trim** ediyor; yine de şifrede bilerek boşluk varsa kaldırıp deneyin.
- **Çok fazla deneme:** 12 başarısız denemeden sonra geçici engel var; mesajda belirtilen süre kadar bekleyin.
- **Hata kodu:** Giriş ekranında kırmızı kutuda **"Hata kodu: ..."** satırına bakın; yukarıdaki tabloyla eşleyin.

---

## 6. Özet kontrol sırası

1. Firebase Console → Authentication → **E-posta/Şifre** **Etkin** mi?
2. Bu e-posta **Authentication → Users** listesinde var mı?
3. Şifre doğru mu, başta/sonda boşluk yok mu?
4. İnternet bağlantısı var mı?
5. Uygulama aynı Firebase projesini mi kullanıyor? (firebase_options / google-services / plist)

Hepsi tamamsa ve hâlâ giriş yapılamıyorsa, ekrandaki **"Hata kodu: ..."** ifadesini not alıp destek ile paylaşın.
