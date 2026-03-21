# Market Pulse – Harici ilan çekici (Cloud Functions)

Bu klasör, **sahibinden.com**, **emlakjet** ve **hepsi emlak** sitelerinden seçilen şehir/ilçe için son ilanları çeker ve Firestore `external_listings` koleksiyonuna yazar. Uygulama Market Pulse bölümünde bu veriyi anlık gösterir.

## Kurulum

```bash
cd functions
npm install
```

## Dağıtım

**Önemli:** Firebase projesi **Blaze (pay-as-you-go)** olmalı; Spark planda Cloud Functions deploy edilemez.

```bash
# Proje kökünden (emlakmaster_mobile)
./scripts/deploy_firebase_functions.sh
```

Alternatif:

```bash
cd functions && npm install && cd .. && firebase deploy --only functions --project emlak-master
```

Yerel emülatör (Blaze gerekmez, `USE_FUNCTIONS_EMULATOR=true` ile uygulama bağlanır):

```bash
./scripts/run_functions_emulator.sh
```

Ayrıntı: `doc/MARKET_PULSE_FIREBASE.md`.

## Fonksiyonlar

- **scheduledFetchListings**: Her 15 dakikada bir tetiklenir; ayarlardaki şehir/ilçe ile tüm kaynaklardan ilan çeker.
- **fetchListingsNow**: HTTP callable; manuel “şimdi çek” tetiklemesi (ileride uygulama içi butondan çağrılabilir).

## Ayarlar

İlanlar, Firestore `app_settings/listing_display_settings` dokümanındaki `cityCode`, `cityName`, `districtName` değerlerine göre filtrelenir. Ayarlar uygulama içi Ayarlar sayfasından yapılır.

## Notlar

- Site HTML yapıları zamanla değişebilir; selector’lar (`fetchers/*.js`) güncellenebilir.
- Sahibinden/emlakjet/hepsi emlak erişim politikalarına uygun kullanım sizin sorumluluğunuzdadır.
- İlk deploy sonrası Firestore’da `external_listings` için composite index (cityCode, postedAt) oluşturulur; gerekirse konsoldaki link ile index ekleyin.
