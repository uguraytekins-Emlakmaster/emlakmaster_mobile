# AI maliyet kapısı (AI Gate) — mimari ve denetim

Bu belge, istemci tarafındaki **uzak model çağrılarını** sınırlamak ve sezgisel/şablon yollarını önceliklendirmek için referanstır. Sunucu (Cloud Functions) tarafında ayrı kota ve yetkilendirme önerilir.

---

## 1. AI yüzeyi denetimi (sınıflandırma)

| Akış | Sınıf | Not |
|------|--------|-----|
| Post-call zenginleştirme (`enrichPostCallSummary`) | **MUST USE AI (koşullu)** | Anlamlı özet/transkript için değerli; kapı + heuristic zorunlu. |
| Post-call heuristic (`computeHeuristicPostCallAiEnrichment`) | **HEURISTIC** | Varsayılan yol; her zaman yerel. |
| Toplu kampanya metni (`generateBulkCampaignMessage`) | **OPTIONAL / yüksek değer** | Kullanıcı butonu; kapı + şablon yedeği. |
| `BackgroundIntelligenceService` / client rollup | **HEURISTIC + CACHE** | Model yok; Firestore yazımı; [AppLifecyclePowerService] ile arka planda kısıtlı. |
| `RainbowIntelService` / skor motoru | **HEURISTIC** | İzole skor; harici API yer tutucu. |
| AI Satış Asistanı paneli (çağrı ekranı) | **HEURISTIC** | Sıcaklık + eşleştirme skorları; uzak model yok. |
| `BentoAiNews` | **HEURISTIC / içerik** | Firestore veya statik şablon; model yok. |
| `extractFromConversation` (demo) | **HEURISTIC** | Rastgele şablon; prod’da model değil. |
| Sesli CRM / STT | **HARİCİ STT** | Maliyet ayrı; metin geldikten sonra AI Gate post-call ile bağlanır. |
| İlan içe aktarma CF (`enqueueUrlImport` vb.) | **İŞ HATTI** | AI değil; kuyruk. |
| Transcript pipeline (`HeuristicTranscriptAiPipeline`) | **HEURISTIC** | Uzak model yok. |

---

## 2. Önerilen AI Gate mimarisi

**Katman sırası:** heuristic → (isteğe bağlı) önbellek → **AiGate** → uzak model.

**Kod konumu:**

- `lib/core/ai/ai_gate.dart` — merkezi karar ve dedupe zaman damgaları.
- `lib/core/ai/heuristic_campaign_message.dart` — kampanya şablonu.
- `PostCallAiEnrichmentService` — `allowRemoteModel`; uzak başarıda `AiGate.markPostCallRemoteSuccess`.
- `CampaignAiService` — kapı + şablon düşüşü + başarıda `markCampaignRemoteSuccess`.
- `post_call_wizard.dart` — `feature_call_summary` + `AiGate.allowPostCallRemote` ile uzak çağrı izni.

---

## 3. Sezgisel öncelik (örnekler)

- Tüm **müşteri sıcaklığı / lead / eşleştirme** skorları: mevcut motorlar.
- **Kampanya metni**: önce şablon; uzak yalnız kapı açıkken.
- **Günlük özet / dashboard** istemci tohumları: zaten kural/rollup; sunucu tarafı ayrıca kotlanmalı.

---

## 4. Önbellek planı

| Veri | Anahtar / kural | Geçersiz kılma |
|------|------------------|----------------|
| Post-call uzak başarı | `AiGate` içi hash (özet+transkript) | 3 dk içinde aynı içerik → yeni uzak çağrı yok |
| Kampanya önerisi | segment + mesaj hash | 45 sn cooldown; önceki metin `cachedCampaignSuggestion` |
| Rainbow intel | `rainbow_intel_cache` (mevcut) | İlçe/TTL ile |

İstemci bellek önbelleği yeniden başlatmada sıfırlanır; kalıcı dedupe için Firestore `lastAiEnrichmentHash` alanı ileride eklenebilir.

---

## 5. Geri dönüş UX

| Durum | Davranış |
|--------|-----------|
| Uzak post-call kapalı (`feature_call_summary` false) | Heuristic zenginleştirme Firestore’a yazılır; alanlar dolu kalır. |
| Kapı: kısa süre / kısa metin | Uzak atlanır; heuristic. |
| CF hata / zaman aşımı | Mevcut: heuristic (post-call); kampanyada şablon. |
| Kampanya cooldown | Önbellekteki son öneri veya şablon metin. |

---

## 6. Maliyet riski yüksek noktalar

1. **Cloud Functions** kötü yapılandırılmış veya kotasız — sunucu tarafında rate limit zorunlu.
2. **Post-call** aynı görüşme tekrar kaydedilirse — istemci dedupe + sunucu idempotency önerilir.
3. **Kampanya** hızlı ardışık tıklama — 45 sn cooldown + cache.
4. **Gelecekte** ekran açılışına bağlı otomatik model — **yasak**; her zaman kullanıcı veya net iş olayı tetiklemeli.

---

## 7. Kod değişiklikleri (ilk geçiş)

- `lib/core/ai/ai_gate.dart` (yeni)
- `lib/core/ai/heuristic_campaign_message.dart` (yeni)
- `lib/features/calls/data/post_call_ai_enrichment_service.dart`
- `lib/features/calls/post_call_wizard.dart`
- `lib/core/services/campaign_ai_service.dart`
- `lib/features/campaigns/presentation/pages/bulk_campaign_page.dart`

---

---

## 8. Sunucu tarafı koruma (Cloud Functions)

**Dosyalar:** `functions/aiRemoteGuard.js`, `functions/aiCallables.js`, `functions/index.js` export.

| Özellik | Uygulama |
|--------|-----------|
| Kill switch | `app_settings/ai_remote_control` — `remoteAiDisabled: true` veya `killSwitch: true` → `failed-precondition` |
| Kota | `users/{uid}/_ai_remote_quota/daily` — günlük sayaçlar; varsayılan env: `AI_POSTCALL_DAILY_LIMIT=30`, `AI_CAMPAIGN_DAILY_LIMIT=20`; isteğe bağlı `maxPostCallPerDay` / `maxCampaignPerDay` aynı dokümanda |
| Idempotency | `ai_idempotency_cache/{sha256}` — 48 saat TTL; aynı kanonik payload → önbellekten yanıt (LLM tekrarı yok) |
| Log | `functions.logger` ile JSON satırı: `remote_ai_disabled`, `idempotent_cache_hit`, `quota_blocked`, `remote_ai_ok` |
| İstemci | `resource-exhausted` / `failed-precondition` → mevcut Dart yolu heuristic’e düşer |

**Bölge:** `europe-west1` — Flutter `PostCallAiEnrichmentService` bu bölgeye hizalandı.

**Firestore kuralları:** `ai_idempotency_cache` ve `users/.../_ai_remote_quota` istemci yazımı/okuması kapalı (yalnız Admin SDK).

*Son güncelleme: release öncesi maliyet kontrolü geçişi.*
