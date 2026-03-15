# Veri Gizliliği (Data Siloing) ve Çevrimdışı Çalışma

## 1. Veri İzolasyonu (Privacy-by-Design)

**Amaç:** Müşteri çalma ve veri sızıntısını önlemek. Danışman sadece kendi müşterilerini görür; yönetici her şeyi görür.

### Firestore Security Rules

- **customers:** Okuma/yazma sadece `assignedAgentId == request.auth.uid` ise veya kullanıcı **manager/admin/owner** rolündeyse.
- **calls, deals, call_summaries:** Aynı mantık; dokümandaki `agentId` danışmanın kendi uid’si veya kullanıcı yönetici olmalı.
- **agents:** Danışman sadece kendi `agentId` dokümanına yazabilir; yönetici hepsini yönetebilir.

### Yönetici rolü

Yönetici panelinde “her şeyi görme” için kullanıcının Firestore’da **users** koleksiyonunda bir dokümanı olmalı ve `role` alanı şunlardan biri olmalı:

- `manager`
- `admin`
- `owner`

Örnek: `users/{auth.uid}` → `{ "role": "manager", ... }`

### Uygulama tarafı

- Müşteri kaydederken `assignedAgentId` mutlaka gönderilir (`FirestoreService.saveCallExtractionToCustomer`).
- Çağrı/deal/call_summary oluştururken `agentId` = giriş yapan kullanıcının uid’si kullanılmalı.

---

## 2. Çevrimdışı Çalışma (Offline-First)

**Amaç:** Sahada veya internetin kesik olduğu yerlerde veri kaybı olmasın; internet gelince otomatik senkronize olsun.

### Firestore

- **Offline persistence** açık: `Settings(persistenceEnabled: true, cacheSizeBytes: CACHE_SIZE_UNLIMITED)`.
- Veriler cihazda önbellekte tutulur; bağlantı gelince Firestore otomatik senkronize eder.

### SyncManager

- `lib/core/services/sync_manager.dart`: Bağlantı durumunu takip eder.
- `SyncManager.onlineStream`: Çevrimiçi/çevrimdışı değişimlerini dinlemek için.
- İsteğe bağlı: Çevrimdışıyken “Veriler kaydedildi, bağlantı gelince senkronize edilecek” gibi bir banner gösterebilirsiniz.

### Kullanım

- Danışman bodrumda/sahada ilan veya müşteri girse bile veriler cihazda kalır; internet gelince Firestore ile eşitlenir. Ek bir “senkronize et” butonu gerekmez.

---

## 3. AI Token Optimizasyonu

**Amaç:** Çok kısa veya anlamsız çağrıları derinlemesine analize sokmamak; maliyet ve hız.

- **Min süre:** `AppConstants.minCallDurationSecForAnalysis` (varsayılan 5 saniye). Bu sürenin altındaki çağrılar tam AI analizine alınmaz.
- **Yanlış numara:** `callOutcome == 'wrong_number'` ise analiz atlanır.
- Çağrı ekranı kapanırken `durationSec` ve `outcome` özet ekranına iletilir; özet ekranı buna göre “AI analizi atlandı” veya tam sihirbazı gösterir.
