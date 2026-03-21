# Market Pulse – Firebase Functions & FCM

## 0) Ücretsiz yol (önerilen, Blaze gerekmez)

Varsayılan uygulama davranışı: **cihazdan** HTML çekip Firestore’a yazar (`client_external_listings_sync_service.dart`).  
Ayrıntı: **`doc/MARKET_PULSE_FREE.md`** — `firestore.rules` deploy şart.

Aşağıdaki bölüm **isteğe bağlı** bulut Functions (Blaze) içindir.

## 1) “İlanları güncelle” (fetchListingsNow) — bulut callable (isteğe bağlı)

Uygulama `europe-west1` bölgesinde `fetchListingsNow` adlı **HTTPS callable** çağırır.

### Üretim (bulut)

1. **Blaze planı** gerekir (Spark’ta Cloud Build / Artifact Registry açılamaz → deploy olmaz).  
   [Firebase kullanım / faturalandırma](https://console.firebase.google.com/project/emlak-master/usage/details)

2. Terminal (proje: `emlakmaster_mobile`):

   ```bash
   chmod +x scripts/deploy_firebase_functions.sh
   ./scripts/deploy_firebase_functions.sh
   ```

   veya:

   ```bash
   cd functions && npm install && cd .. && firebase deploy --only functions --project emlak-master
   ```

3. `firebase login` ile oturum açık olmalı.

### Geliştirme (yerel emülatör, Blaze gerekmez)

Terminal 1:

```bash
chmod +x scripts/run_functions_emulator.sh
./scripts/run_functions_emulator.sh
```

Terminal 2 (aynı makinede):

```bash
flutter run --dart-define=USE_FUNCTIONS_EMULATOR=true
```

Bu, `lib/core/services/firebase_functions_bootstrap.dart` ile callable’ı `127.0.0.1:5001` emülatörüne yönlendirir.

---

## 2) Xcode: FCM / “no APNS Token”

- **Simülatörde** APNs token çoğu zaman gelmez; push beklemeyin (normal).
- **Gerçek cihaz** için: Xcode’da **Push Notifications** capability, bildirim izni, mümkünse ücretli Apple Developer + doğru provisioning.
- `AppDelegate` içinde `application.registerForRemoteNotifications()` çağrılır.
- Dart’ta `PushNotificationService`: iOS’ta APNs hazır olmadan `getToken()` çağrılmaz (gereksiz FCM log’u azaltır).

`Runner.entitlements` içinde `aps-environment` bilinçli olarak yorum satırı; ücretsiz Apple hesabında push profili oluşturulamayabilir. Ücretli hesapta push kullanacaksanız `development` / `production` ekleyin.

---

## 3) Veri akışı

- Callable `fetchAndWriteListings()` çalıştırır; sonuçlar Firestore `external_listings` koleksiyonuna yazılır.
- Şehir/ilçe: `app_settings/listing_display_settings` (`listing_display_settings` dokümanı).

---

## 4) Sorun giderme

| Belirti | Olası neden |
|--------|-------------|
| `not-found` callable | Fonksiyon deploy edilmemiş veya yanlış proje / bölge |
| Deploy “Blaze gerekli” | Spark → Blaze yükselt |
| Emülatör bağlanmıyor | `run_functions_emulator.sh` çalışıyor mu; `--dart-define=USE_FUNCTIONS_EMULATOR=true` verildi mi |
