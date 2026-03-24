# Yahoo Finance mini-servis (Node.js)

Flutter `FinanceService` için `yahoo-finance2` ile USD/TRY, EUR/TRY ve gram altın (TRY) döndüren küçük HTTP API.

## Kurulum

```bash
cd tools/yahoo_finance_service
npm install
```

## Çalıştırma

```bash
npm start
# veya: PORT=8787 node server.mjs
```

- Sağlık: `GET http://127.0.0.1:8787/health`
- Kurlar: `GET http://127.0.0.1:8787/rates`

İsteğe bağlı ortam değişkenleri (`.env` yerine shell veya process manager ile):

| Değişken | Açıklama |
|----------|----------|
| `PORT` | Dinleme portu (varsayılan `8787`) |
| `API_KEY` | Doluysa istemci `X-API-Key` göndermeli |
| `CORS_ORIGIN` | CORS origin (varsayılan: tüm origin’ler) |

## Flutter bağlantısı

Uygulama `--dart-define` ile servis adresini alır:

```bash
dart run --dart-define=YAHOO_FINANCE_SERVICE_URL=http://127.0.0.1:8787/
```

API anahtarı kullanıyorsanız:

```bash
dart run \
  --dart-define=YAHOO_FINANCE_SERVICE_URL=http://127.0.0.1:8787/ \
  --dart-define=YAHOO_FINANCE_SERVICE_API_KEY=gizli-anahtar
```

URL tanımlıysa döviz akışı önce bu servisten okunur; başarısızsa TCMB → exchangerate.host sırası kullanılır.

## Uyarı

Yahoo Finance verisi gecikmeli / resmi olmayan bir kaynaktır. Üretimde kendi riskinizle kullanın; yoğun isteklerde engellenebilirsiniz.
