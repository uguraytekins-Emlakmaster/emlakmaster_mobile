# Facebook ile Giriş Kurulumu

Facebook ile girişin çalışması için aşağıdaki adımlar tek seferde yapılmalıdır.

---

## Tek komut (uygulama tarafı)

Facebook’tan **App ID** ve **Client Token**’ı kopyaladıktan sonra proje klasöründe:

```bash
cd /Users/uguraytekin/Projeler/EmlakMaster_Proje/emlakmaster_mobile
./scripts/configure_facebook_app.sh
```

Script sırayla **App ID** ve **Client Token** sorar; yapıştırıp Enter’a bas. Ardından:

```bash
flutter clean && flutter pub get && flutter run
```

---

## 1. Facebook Developer Console

1. [developers.facebook.com](https://developers.facebook.com) → **My Apps** → **Create App** (veya mevcut uygulamanızı seçin).
2. **Consumer** veya **Business** türünde uygulama oluşturun.
3. **Settings** → **Basic** bölümünde:
   - **App ID** (sayı, örn. `1234567890123456`) → kopyalayın.
   - **App Secret**’e tıklayıp **Client Token** oluşturun / gösterin; bu değer **Client token** (uzun metin) → kopyalayın.
4. **Use cases** / **Products** kısmında **Facebook Login** ekleyin.
5. **Facebook Login** → **Settings**:
   - **Valid OAuth Redirect URIs**: Firebase / web kullanmıyorsanız boş bırakılabilir (mobil SDK için zorunlu değil).
   - **Client OAuth Login**: **Yes**.
   - **Embedded Browser OAuth Login**: isteğe bağlı **No** (uygulama içi tarayıcı yerine Facebook uygulaması açılır).

---

## 2. Firebase Console

1. [Firebase Console](https://console.firebase.google.com) → projeniz (örn. **emlak-master**) → **Authentication** → **Sign-in method**.
2. **Facebook** satırını açın → **Enable**.
3. **App ID** ve **App Secret** (Facebook Developer’daki **App Secret**, Client Token değil) girin → **Save**.

---

## 3. Uygulama Tarafında Kimlik Bilgilerini Yazma

Proje kökünden (emlakmaster_mobile) aşağıdaki script ile **App ID** ve **Client Token**’ı tek seferde Android ve iOS’a yazın:

```bash
export FACEBOOK_APP_ID="BURAYA_APP_ID"
export FACEBOOK_CLIENT_TOKEN="BURAYA_CLIENT_TOKEN"
./scripts/configure_facebook_app.sh
```

Veya doğrudan argüman ile:

```bash
./scripts/configure_facebook_app.sh "BURAYA_APP_ID" "BURAYA_CLIENT_TOKEN"
```

Script şunları günceller:

- **Android:** `android/app/src/main/res/values/strings.xml`, `android/app/build.gradle` (manifestPlaceholders).
- **iOS:** `ios/Runner/Info.plist` (FacebookAppID, FacebookClientToken, URL scheme `fb...`).

---

## 4. Manuel Güncelleme (script kullanmıyorsanız)

Aynı değerleri elle girecekseniz:

| Dosya | Anahtar / Yer | Değer |
|-------|----------------|-------|
| `android/app/src/main/res/values/strings.xml` | `facebook_app_id` | App ID (sayı) |
| | `facebook_client_token` | Client Token |
| | `facebook_login_protocol_scheme` | `fb` + App ID (örn. `fb1234567890123456`) |
| `android/app/build.gradle` | `defaultConfig.manifestPlaceholders.facebookAppId` | App ID |
| `ios/Runner/Info.plist` | `FacebookAppID` | App ID |
| | `FacebookClientToken` | Client Token |
| | `CFBundleURLTypes` → Facebook scheme | `fb` + App ID |

---

## 5. Kontrol Listesi

- [ ] Facebook Developer’da uygulama oluşturuldu, **App ID** ve **Client Token** alındı.
- [ ] Firebase Console → Authentication → **Facebook** etkin, **App ID** ve **App Secret** girildi.
- [ ] `./scripts/configure_facebook_app.sh` çalıştırıldı veya yukarıdaki dosyalar elle güncellendi.
- [ ] Uygulama yeniden derlendi (`flutter clean` sonrası `flutter run` veya release build).

Bu adımlar tamamsa Facebook ile giriş hatasız çalışır. Hata alırsanız ekrandaki hata mesajı ve **Hata kodu** satırını not alıp kontrol edin; genel giriş kontrolleri için **doc/FIREBASE_AUTH_CHECKLIST.md** dosyasına bakın.
