# Yarım kalan / sıradaki işler

## Kod tarafı (isteğe bağlı)

| Konu | Not |
|------|-----|
| Harici ilan entegrasyonları (Rainbow) | Üretim mimarisi: `doc/EXTERNAL_LISTING_INTEGRATION_ARCHITECTURE.md` — Phase 1–3 |
| `withOpacity` → `withValues` | ~200+ bilgi seviyesi uyarı; toplu geçiş için Flutter sürümüne uygun helper |
| `integration_test` veya Patrol | Elle QA yerine otomatik ekran akışları |
| Xcode `xcrun xctrace` betiği | Performans trace’i tek komutla (şablon cihaza göre) |

## Elle QA (senin cihazında)

`doc/QA_CHECKLIST.md` içinde **A → E** kutucukları; özellikle:

1. **A** — Onboarding + giriş + çıkış  
2. **B** — 4 sekme + dashboard (Finance bar taşması düzeltildi — tekrar kontrol)  
3. **C** — Uçak modu / Firestore hata ekranı  
4. **D** — OOM / enerji  
5. **E** — Push capability  

## Shield

`./scripts/shield/shield.sh` — proje kökünde çalışır.  
`--quiet` modunda `set -e` ile yanlışlıkla çıkış kodu 1 olma hatası giderildi (log / “bitti” satırları `|| true`).

`./scripts/run_with_shield.sh …` — önce shield, sonra `flutter run` (cihaz/simülatör gerekir; etkileşimli süreç).
