# Market Pulse – ücretsiz (Blaze / Cloud Functions olmadan)

## Nasıl çalışıyor?

“**İlanları güncelle**” **cihazdan** (iOS / Android / macOS) sitelere HTTP ile gider, HTML’den ilan çıkarmaya çalışır ve **`external_listings`** koleksiyonuna yazar.

### Önemli: Çoğu zaman 0 ilan normaldir

- **Sahibinden / Hepsi Emlak** sık sık **Cloudflare** (“Just a moment…”) ile korunur; uygulama JavaScript doğrulaması yapamaz → ham HTML’de ilan linki olmaz.
- **Emlakjet** sayfası **Next.js** ile listeyi tarayıcıda doldurur; ilk HTML’de ilan satırı olmayabilir.

Bu yüzden **canlı otomatik çekme** güvenilir değildir; **ücretsiz Spark** ile tam çözüm genelde **Cloud Functions + tarayıcı otomasyonu** veya **manuel / API** verisidir.

Uygulamada **«Örnek yükle»** ile Firestore’a **örnek ilanlar** (`source: demo`) yazılır; Market Pulse ekranı dolar.

## Nasıl çalışıyor? (teknik)

“**İlanları güncelle**” ve “**Örnek yükle**” **Cloud Functions veya Blaze gerektirmez** (istemci yazımı + kurallar).

- **Flutter Web**: Hedef siteler CORS nedeniyle tarayıcıdan çağrılamaz; mobil/masaüstü uygulama kullanın.
- **Firestore kotası**: Spark planında günlük okuma/yazma limitleri vardır; çok sık tetiklemeyin.
- **Yasal / kullanım**: Sitelerin kullanım koşullarına uygunluk sizin sorumluluğunuzdadır.

## Bir kerelik: güvenlik kuralları

İstemci yazımı için `firestore.rules` güncellendi. **Projeye bir kez deploy edin** (Spark’ta ücretsiz):

```bash
cd emlakmaster_mobile
./scripts/deploy_firestore_rules.sh
```

veya:

```bash
firebase deploy --only firestore:rules --project emlak-master
```

Deploy edilmezse `permission-denied` alırsınız.

## İsteğe bağlı: bulut zamanlayıcı

`functions/` içindeki Node betikleri ve zamanlanmış çalıştırma **hâlâ** Blaze gerektirir. Ücretsiz yolda:

- Kullanıcılar uygulamadan manuel günceller, veya
- İleride kendi sunucunuz / GitHub Actions / başka ücretsiz tetikleyici ile aynı mantığı çalıştırırsınız (service account ile Admin SDK).

## Teknik

- Kod: `lib/features/external_listings/data/client_external_listings_sync_service.dart`
- Alan `clientFetched: true` ile kurallarda doğrulanır.
