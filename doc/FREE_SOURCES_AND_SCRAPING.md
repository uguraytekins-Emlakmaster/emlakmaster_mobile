# Ücretsiz veri kaynakları ve Cloudflare / kazıma notları

Bu doküman, **ücretli global API’ler yerine** yerel/halka açık kaynaklar ve **Cloudflare korumalı siteler** için mimari seçenekleri özetler. Maliyet hedefi: **$0** (kendi makineniz veya ücretsiz bulut kotası).

## Ekonomi (TCMB, yedek akışlar)

| Kaynak | Açıklama |
|--------|-----------|
| **TCMB `today.xml`** | Resmi günlük kurlar; HTTP ile çekilip XML parse edilir. Uygulama içinde `tcmb_public_rates.dart` / `FinanceService` bu akışı kullanır; başarısızlıkta yedek uç devreye girer. |
| **exchangerate.host (veya benzeri)** | Yedek: JSON, ücretsiz katman. |
| **yahoo-finance2** | Genelde Node.js tarafında; isterseniz ayrı küçük bir **ara script** ile JSON üretip uygulamaya verebilirsiniz (sunucu veya yerel cron). |

**Not:** “Anlık” hissi için arayüzde canlı etiket + sparkline kullanılır; veri TCMB’nin yayın sıklığına bağlıdır (resmi tablo günlük güncellenir).

## Emlak / Cloudflare engeli ($0 yaklaşımı)

Ücretli **rotating proxy** kullanmadan tipik seçenekler:

### 1. İstemci tarafı (kısmi)

- Tarayıcı veya uygulama, **kullanıcının kendi IP’si** ile istek yapar; bazı siteler bot tespitini gevşetebilir.
- Yasal / ToS uyumu ve kullanıcı gizliliği için net politika gerekir.

### 2. FlareSolverr (açık kaynak)

- Cloudflare challenge’larını **yerel veya kendi VPS’inizde** çözen bir yardımcı servis.
- Uygulama doğrudan hedef siteye değil, **FlareSolverr endpoint’ine** istek atar; dönen HTML/oturum bilgisi ile devam edilir.
- **Maliyet:** $0 (Oracle Cloud / Google Cloud free tier veya ev sunucusu).

### 3. SeleniumBase / Playwright / “headless browser”

- **SeleniumBase** (Python) veya benzeri ile gerçek tarayıcı oturumu; “Örnek yükle” benzeri akışlar otomatikleştirilebilir.
- Ağır ve bakım ister; genelde **batch / arka plan işi** olarak tasarlanır, mobil uygulama içine gömülmez.

### 4. Mimari öneri

```
[Mobil uygulama] → [Sizin backend veya yerel script] → FlareSolverr / headless
                                              ↓
                                    Normalize edilmiş JSON (emlak özeti)
```

- Hedef site ToS’sine uygunluk ve robots.txt **kullanıcı sorumluluğundadır**.
- Üretimde tercihen **resmi API / partner veri** ile desteklenmelidir.

## Market Pulse (emlak) — özet

Üretim için önerilen yol: **Cloud Functions** + **Firestore** + isteğe bağlı **ingest** (FlareSolverr / ücretli proxy worker). Telefon sadece **snapshot** dinler — pil dostu.

Ayrıntılı mimari: **`doc/MARKET_PULSE_SERVERLESS_ARCHITECTURE.md`**.

## İlgili kod

- `lib/core/services/tcmb_public_rates.dart` — TCMB XML
- `lib/core/services/finance_service.dart` — TCMB + yedek
- `lib/widgets/finance_bar.dart` — Ekonomi kartları (gradient, sparkline)
- `functions/index.js`, `functions/rollupMarketPulse.js` — sunucu rollup + ingest
- `lib/core/intelligence/background_intelligence_service.dart` — `intelligence_pipeline` bayrağı
