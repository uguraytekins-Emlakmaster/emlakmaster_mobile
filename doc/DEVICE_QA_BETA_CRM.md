# Beta — gerçek cihaz QA matrisi (CRM / çağrı / AI / broker)

Bu doküman **yeni özellik değil**, lansman öncesi **cihazda doğrulama** ve hata yakalama içindir. Öncelik: gerçek kullanım, ağ kesintisi, izinler ve Firestore hataları.

---

## Ön koşullar

- [ ] `flutter doctor -v` temiz; hedef cihazda debug ve mümkünse **release** build.
- [ ] Test hesabı: broker/yönetici rolü + en az bir danışman akışı.
- [ ] Log: Xcode / `adb logcat` veya `flutter run` konsolu; `AppLogger` + Crashlytics (varsa).

---

## 1. Müşteri oluşturma

| # | Kontrol | Beklenen |
|---|---------|----------|
| 1.1 | Yeni müşteri formu, zorunlu alanlar boş kayıt | Doğrulama / kullanıcı mesajı |
| 1.2 | Geçerli veri ile kayıt | Liste ve detayda görünür |
| 1.3 | Hızlı ardışık iki kayıt (çift dokunuş) | Tek kayıt veya idempotent davranış; çökme yok |
| 1.4 | Uzun not / özel karakter | Kayıt ve geri okuma doğru |

---

## 2. Müşteri detay — zeka / zaman çizelgesi

| # | Kontrol | Beklenen |
|---|---------|----------|
| 2.1 | Özet / transkript / içgörü şeritleri | Yükleme → veri veya anlamlı boş/hata metni |
| 2.2 | Firestore hata veya boş doküman | Kısa Türkçe hata; sessiz `SizedBox.shrink` yok |
| 2.3 | Kaydırma + geri dönüş (liste → detay) | State bozulmaz, flicker kabul edilebilir düzeyde |

---

## 3. Görev oluşturma / tamamlama

| # | Kontrol | Beklenen |
|---|---------|----------|
| 3.1 | Akıllı görevden veya manuel görev oluşturma | Görev listesinde görünür |
| 3.2 | Tamamlama | Durum güncellenir; Snackbar hata mesajı kullanıcı dostu (`userFacingErrorMessage`) |
| 3.3 | Ağ kesintisi sırasında tamamlama | Anlamlı hata; uygulama çökmez |

---

## 4. Çağrı sonrası özet kaydı

| # | Kontrol | Beklenen |
|---|---------|----------|
| 4.1 | Özet metni + kaydet | `saveCallExtractionToCustomer` + not; ana sayfaya dönüş |
| 4.2 | Müşteri bağlantısı yok | Açık mesaj; kayıt yapılmaz |
| 4.3 | Boş özet, sadece transkript | Mod `transcript_only` ile zenginleştirme yolu (log: debug) |

---

## 5. STT → transkript handoff

| # | Kontrol | Beklenen |
|---|---------|----------|
| 5.1 | PTT ile metin, kullanıcı transkripti **elle değiştirmedi** | `mergeSpeechToTextHandoffIfPresent` yolu |
| 5.2 | Kullanıcı transkripti düzenledi | `mergePayloadIfPresent` (manuel) |
| 5.3 | Handoff Firestore hatası | `AppLogger.w` + kullanıcı akışı devam (kayıt atlanır) |

---

## 6. AI zenginleştirme — kayıt + gösterim

| # | Kontrol | Beklenen |
|---|---------|----------|
| 6.1 | `summary_only` / `summary_plus_transcript` / `transcript_only` | Firestore’da `mergePostCallAiEnrichment`; müşteri detayda görünür |
| 6.2 | Zenginleştirme API / merge hatası | `Post-call AI enrichment merge failed` log; CRM özeti yine kayıtlı kalmalı |
| 6.3 | Uzun transkript | Kesilme / zaman aşımı: hata loglanır, uygulama ayakta |

---

## 7. Broker dashboard — operasyon özeti

| # | Kontrol | Beklenen |
|---|---------|----------|
| 7.1 | Yönetici rolü | `BrokerDashboardIntelligenceSummaryCard` satırları veya hata satırı |
| 7.2 | Misafir / danışman | Boş özet (rol guard) |
| 7.3 | Alt akışlardan biri hata | Kart hata durumu; tek satır metin |

---

## 8. Uyarılar / eskalasyon / hatırlatıcı / akıllı görev

| # | Kontrol | Beklenen |
|---|---------|----------|
| 8.1 | Ofis uyarıları + eskalasyon + hatırlatıcı + öneri birlikte | Özet metinleri tutarlı; çökme yok |
| 8.2 | Sadece boş listeler | “Son tarama: … yok” benzeri anlamlı metin |

---

## 9. Çevrimdışı / izin / Firestore

| # | Kontrol | Beklenen |
|---|---------|----------|
| 9.1 | Uçak modu aç-kapa | Cached UI mümkün; yazma başarısız → mesaj |
| 9.2 | Mikrofon izni reddi (PTT) | Graceful; ayarlara yönlendirme varsa test |
| 9.3 | Firestore permission denied / unavailable | Kullanıcıya dönük mesaj; `AppLogger.e` ile iz sürmek |

---

## Yüksek riskli akışlar (neden)

1. **Post-call kayıt + arka plan AI merge** — İki aşama (senkron Firestore + `Future.microtask` zenginleştirme); yavaş ağda yarış veya kullanıcı hemen çıkış; cihazda zamanlama farkı.
2. **STT handoff + kullanıcı düzenleme bayrağı** — `_transcriptUserEditedOnce` yanlış dalda yanlış merge; gerçek cihazda PTT gecikmesi farklı.
3. **Broker özet kartı** — Beş `AsyncValue` birleşimi; biri hata/loading → birleşik durum; düşük bellekte rebuild fırtınası.
4. **Çevrimdışı yazma** — Offline persistence açık olsa bile çakışma ve kuyruk; kullanıcı “kaydettim” sanır.
5. **Müşteri detay akışları** — Çoklu stream + zeka şeritleri; ilk açılışta boş → dolu geçişi ve hata kenarları.

---

## Önerilen test sırası

1. **Birinci** — Kimlik + rol: giriş, broker/yönetici dashboard özet kartı (7.x), müşteri listesi → detay (2.x) — iskelet doğrulaması.
2. **İkinci** — Para akışı: müşteri oluştur (1.x) → çağrı sonrası sihirbaz (4.x, 5.x, 6.x) → detayda zenginleştirilmiş veri (2.x, 6.x).
3. **Üçüncü** — Dayanıklılık: görev 3.x, offline/izin 9.x, kasıtlı hata (Firestore kuralı veya uçak modu).

---

## Debug yardımcıları (kod)

- `post_call_wizard`: `kDebugMode` — zenginleştirme modu + transkript uzunluğu + handoff var/yok.
- `broker_dashboard_intelligence_summary_provider`: `kDebugMode` — kaynak listelerinin sayıları + `hasAny`.

Release davranışı ve UX değişmez.
