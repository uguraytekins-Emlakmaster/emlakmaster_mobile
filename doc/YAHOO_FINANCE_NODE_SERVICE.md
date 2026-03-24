# Döviz: Yahoo Finance Node mini-servisi

Uygulama, isteğe bağlı olarak yerel veya ağa açık bir **Node.js** servisinden (`yahoo-finance2`) USD/TRY, EUR/TRY ve gram altın (TRY) okuyabilir.

## Neden

- Flutter tarafında doğrudan Yahoo’ya bağlanmak yerine tek bir küçük servis: sürüm güncellemesi ve hata ayıklama kolaylaşır.
- `YAHOO_FINANCE_SERVICE_URL` boşsa mevcut akış değişmez (TCMB → exchangerate.host).

## Servisi çalıştırma

```bash
cd tools/yahoo_finance_service
npm install
npm start
```

Ayrıntılar: `tools/yahoo_finance_service/README.md`.

## Flutter

```bash
dart run --dart-define=YAHOO_FINANCE_SERVICE_URL=http://127.0.0.1:8787/
```

API anahtarı kullanılıyorsa:

```bash
dart run --dart-define=YAHOO_FINANCE_SERVICE_API_KEY=...
```

## Veri kaynağı etiketi

UI’da `dataSource` alanında **`yahoo-node`** görünür (bu servis üzerinden gelen veri).

## Yasal / operasyonel not

Yahoo Finance verisi resmi değildir; kullanım koşulları ve rate limit geçerlidir. Üretim için risk değerlendirmesi yapın.
