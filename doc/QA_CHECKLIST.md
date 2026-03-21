# EmlakMaster Mobile — QA kontrol listesi

## Otomatik (terminal — sen veya CI)

```bash
cd emlakmaster_mobile
flutter test
dart analyze
flutter build ios --no-codesign
```

Xcode + Pods uyarı özetini görmek için (uzun sürebilir):

```bash
bash scripts/analyze_ios_build_warnings.sh
```

Ayrıntı: `doc/AUTOMATION.md`.

### Repoda son tamamlananlar (otomasyon / kod)

- [x] `FinanceBar`: dar ekranda yatay taşma (RenderFlex overflow) giderildi — chip’ler `Expanded` ile eşit bölünüyor.
- [x] `FinanceService` + EUR/TRY formülü + birim test; `fetchListingsNow` tek uçuş kilidi; Market Pulse animasyon yükü azaltıldı.
- [x] `doc/AUTOMATION.md`, `scripts/analyze_ios_build_warnings.sh`, iOS LaunchScreen koyu arka plan.

---

## A — Açılış ve hesap

- [ ] İlk kurulumda onboarding tamamlanır, tekrar açılışta atlanır.
- [ ] E-posta/şifre girişi; hatalı şifrede anlamlı mesaj.
- [ ] Kayıt akışı (varsa) ve çıkış.

## B — Ana kabuk (danışman)

- [ ] 4 sekme: Ana sayfa, İlanlar, Müşteriler, Profil — geçişler akıcı.
- [ ] Dashboard: Finance bar, Market Pulse (yetki varsa), güncelle butonu çift tıklamada tek istek.

## C — Ağ ve hata

- [ ] Uçak modu: boş/hata durumunda “tekrar dene” veya anlamlı mesaj.
- [ ] Firestore izin hatasında sonsuz yükleme yok (hata ekranı).

## D — Performans (fiziksel cihaz)

- [ ] Ana ekranda 1–2 dk kullanımda OOM (bellek öldürme) olmamalı.
- [ ] Xcode Energy “High” kısa süreli olabilir; sürekli kilitlenme yok.
- [ ] (İsteğe bağlı) Xcode Instruments ile Time Profiler — `doc/AUTOMATION.md`.

## E — Push (isteğe bağlı)

- [ ] Xcode: Push Notifications capability.
- [ ] İlk izin sonrası FCM token uyarısı azalmalı (APNs).
