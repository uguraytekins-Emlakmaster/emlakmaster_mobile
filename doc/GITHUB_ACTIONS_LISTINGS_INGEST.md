# Emlak verileri — Cloudflare & GitHub Actions (B-Devam)

Mobil uygulama doğrudan sahibinden gibi sitelere **basit HTTP** ile gittiğinde sık sık **Cloudflare** (bot sayfası) alır. **Ücretli proxy** olmadan pratik yol: **GitHub Actions** + **Playwright** → HTML → **Firestore** `external_listings`.

- GitHub runner IP’leri bazen daha az engellenir; **garanti yok**.
- **Kota:** aylık ~**2000 dakika** (plana göre değişir). Zamanlama **3 saatte bir (UTC)** önerilir (`cron: 0 */3 * * *`); daha sık gerekiyorsa workflow’da saatlik cron’a çevirin.

## Önerilen sıra (otomatik script’ler)

Projede hazır script’ler var; **Firebase’den JSON indirmek** dışında adımlar komutla yapılabilir.

### A) GitHub secret (bir kez)

1. [Firebase Console](https://console.firebase.google.com/) → Project settings → Service accounts → **Generate new private key** → JSON indir (bunu sadece sen yapabilirsin).
2. Terminalde (repo kökü):

```bash
./scripts/github_listings_push_secret.sh ~/Downloads/firebase-adminsdk-XXXX.json
```

`gh` yüklü ve `gh auth login` yapılmış olmalı (`brew install gh`). Bu komut **`FIREBASE_SERVICE_ACCOUNT_JSON`** secret’ını bu repoya yükler.

İsteğe bağlı repo Variables:

```bash
./scripts/github_listings_set_variables.sh
# veya: MAX_LISTINGS=40 CITY_NAME=Diyarbakır ./scripts/github_listings_set_variables.sh
```

3. GitHub → **Actions** → **External listings ingest** → **Run workflow** → log’da `Parsed N satır` ve Firestore’da `ingestedBy: github_actions` doğrula.

### B) Sadece yerelde dene (GitHub’sız)

1. İndirdiğin JSON’u kopyala:

`tools/github_listings_ingest/.service_account.json` (dosya adı tam bu; **git’e gitmez**).

2. `tools/github_listings_ingest/env.local.example` → `.env.local` olarak kopyala, değerleri düzenle.
3. `./scripts/run_listings_ingest_local.sh`

### İsteğe bağlı repo Variables

| Ad | Örnek |
|----|--------|
| `CITY_NAME` | `Diyarbakır` |
| `DISTRICT_NAME` | Boş veya ilçe adı |
| `MAX_LISTINGS` | `30` — en fazla kaç ilan yazılacağı (1–100, script içinde sınırlı) |

Manuel koşuda il kodu **workflow_dispatch** `city_code` ile; `MAX_LISTINGS` yalnızca **Variables** ile.

## Mimari

1. `.github/workflows/external-listings-ingest.yml` — `workflow_dispatch` + `schedule`.
2. `tools/github_listings_ingest/ingest_sahibinden.py` — Playwright → parse → Firestore.
3. Uygulama sadece Firestore dinler.

> **Admin SDK** kuralları bypass eder; anahtarı **repoya koymayın**.

## Cloudflare tespiti

Script ham HTML’de kısa içerik / “Just a moment” / `cf-browser-verification` vb. arar; şüphede **GitHub `::warning::`** üretir. Yine de **0 ilan** çıkabilir; seçiciler site değişince güncellenmelidir.

## Trend (`trendPct`)

Ingest, **aynı dokümandaki önceki `priceValue`** ile yeni fiyatı karşılaştırır; mümkünse `trendPct` (yüzde) ve `trendBasis: prev_ingest_price` yazar. İlk yazımda veya fiyat çözülemediğinde alan güncellenmeyebilir.

## Plan B: CSV içe aktarma

Otomasyon çalışmazken:

```bash
cd tools/github_listings_ingest
pip install -r requirements.txt
export FIREBASE_SERVICE_ACCOUNT_JSON="$(cat /path/to/service-account.json)"
python import_csv.py sample_listings.csv
```

Başlıklar: `source,externalId,title,propertyType,priceText,priceValue,cityCode,cityName,districtName,link,imageUrl`

## Güvenlik

- Anahtarı yalnızca **GitHub Secret**’ta tutun; düzenli **rotate** edin.
- IAM: servis hesabına yalnızca gerekli rol (ör. **Cloud Datastore User** / Firestore uyumlu).
- Ekip erişimini GitHub **environment** + approval ile kısıtlayın (isteğe bağlı).

## Komut çalışmıyorsa

**Önce doğru klasöre gir:** `Projeler` kökünden değil, **`emlakmaster_mobile`** içinden çalıştırın. Adım adım: **`doc/LISTINGS_INGEST_QUICKSTART.md`**

## Tek komut (repoda yapılabilen her şey)

```bash
cd EmlakMaster_Proje/emlakmaster_mobile
bash run_listings_ingest_do_everything.sh
```

Sıra: `pytest` → Playwright kurulumu → `.env.local` oluşturma → `.service_account.json` varsa ingest → `gh` girişliyse secret sorusu.

VS Code / Cursor: **Tasks → “Listings ingest: tam kurulum scripti”**.

## Yerel test (ingest)

```bash
./scripts/run_listings_ingest_local.sh
```

Parse birim testleri (Firebase yok):

```bash
cd tools/github_listings_ingest
pip install -r requirements-dev.txt
python -m pytest tests/ -v
```

veya manuel:

```bash
cd tools/github_listings_ingest
pip install -r requirements.txt
playwright install chromium
# .service_account.json bu klasörde veya FIREBASE_SERVICE_ACCOUNT_FILE=...
export CITY_CODE=21
python ingest_sahibinden.py
```

## Yasal uyarı

Hedef sitelerin **kullanım şartları** ve **robots.txt** kurallarına uyun.
