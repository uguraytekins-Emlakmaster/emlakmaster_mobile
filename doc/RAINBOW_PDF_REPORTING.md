# Rainbow Analytics Center — PDF raporlama

Bu proje **Flutter**’dır; React Native `react-native-html-to-pdf` kullanılmaz. Aynı hedef — **sıfır ek maliyet**, **cihaz içi üretim** — [`pdf`](https://pub.dev/packages/pdf) + [`printing`](https://pub.dev/packages/printing) ile sağlanır.

## Akış

1. Kullanıcı **Rapor Oluştur** → `RainbowIntelService.buildFullReport` canlı veriyi toplar (ilan + skor + heatmap’ten Kayapınar/Bağlar).
2. `RainbowPdfBuilder.buildPrintPdf` tek geçişte **A4 PDF** üretir.
3. `Printing` / `PdfPreview` ile önizleme ve paylaşım.

## Tasarım (kurumsal)

- Beyaz zemin, siyah metin, altın aksan (`#C9A227` / `#BFA071`).
- Üst satır: solda **Rainbow Analytics Center**, sağda **Rainbow Gayrimenkul** + tarih.
- Filigran: **Rainbow Analytics Center** (düşük opaklık).
- Ana skor: ince **dairesel ilerleme** (vektörel yay); üç mini halka (ROI / Talep / m² bileşenleri).
- **İlçe analizi** tablosu: Kayapınar & Bağlar — canlı `analytics_daily/heatmap_*` veya varsayılan bölgeler.
- QR: ilan URL’si (`barcode` paketi, ücretsiz).

## Dosyalar

- `lib/features/analytics/data/pdf/rainbow_pdf_builder.dart` — düzen + grafik + tablo.
- `lib/features/analytics/domain/models/rainbow_intel_models.dart` — `DistrictSnapshotRow`, `districtSnapshots`.
- `lib/features/analytics/data/rainbow_intel_service.dart` — heatmap yükleme.

## Not

HTML/CSS string ile şablon yerine **Dart widget ağacı** kullanılır; çıktı yine **basılı kalitede PDF**dir ve tamamen **offline** üretilebilir.
