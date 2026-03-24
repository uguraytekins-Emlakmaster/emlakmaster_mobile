# Market Pulse — operasyon checklist (mükemmellik)

Kablo olmadan telefon testi ertelenebilir; aşağıdakiler masaüstü / CI ile yapılabilir.

## Günlük / haftalık

| Kontrol | Nerede |
|--------|--------|
| Ingest workflow yeşil | GitHub → Actions → **External listings ingest** |
| `external_listings` dolu | Firebase → Firestore |
| Parse testleri | `cd tools/github_listings_ingest && python3 -m pytest tests/ -v` |
| Flutter analiz | `flutter analyze` (proje kökü) |

## Uygulama içi (ilk açılışta)

- **Market Pulse** → liste doluysa altta **son senkron** satırı (`ingestedAt`) ve **üçüncü taraf uyarısı** görünür.
- Liste boşsa: boş durum metni + GitHub ingest dokümanı + cihazda doğrulama notu.

## Telefon / tablet (kablo olduğunda)

1. USB hata ayıklama açık.
2. `flutter run` veya yükleme paketi.
3. Dashboard → Market Pulse: kartlar, altın fiyat, son senkron.

## Sorun giderme

| Belirti | Aksiyon |
|---------|---------|
| Son senkron yok | Firestore kayıtlarında `ingestedAt` alanı yoksa (eski kayıtlar) bir kez ingest yeniden çalışsın. |
| Secret hatası | `doc/LISTINGS_INGEST_QUICKSTART.md` |
| 0 ilan | Cloudflare / seçici; `doc/GITHUB_ACTIONS_LISTINGS_INGEST.md` |
