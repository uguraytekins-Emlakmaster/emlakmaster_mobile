# Kendini Onaran Altyapı ve Yapılan Uygulamalar

## Yapılanlar (bu tur)

### 1. Gerçek agentId
- **CallScreen** ve **PostCallWizard** artık giriş yapan kullanıcının `uid`’sini kullanıyor (`demoAgent1` yalnızca uid yoksa yedek).
- Çağrı özeti ve agent istatistikleri doğru danışmana yazılıyor.

### 2. Resilience (kendini onaran yazmalar)
- **runWithResilience(ref, action)** kullanılan yerler:
  - CallScreen: `setAgentStatus` (görüşmede / müsait) – retry + sync durumu.
  - PostCallWizard: özet ve agent istatistikleri kaydı – retry + sync durumu.
  - Müşteri detay: not kaydetme.
- Geçici ağ hatalarında otomatik yeniden deneme; kalıcı hatalarda log ve kullanıcıya hata mesajı.

### 3. Call state makinesi
- **CallUIState**: `connecting` → `connected` → `ending`.
- UI metni: "Aranıyor..." → "Arama devam ediyor" → "Sonlandırılıyor...".
- Timer yalnızca `connected` iken ilerliyor; bitişte buton devre dışı ve loading gösterimi.

### 4. KPI ve haftalık hedef canlı
- **DashboardKpiSection**: Çağrı sayısı ve agent durumları zaten stream ile canlı.
- **Danışman paneli – Bu hafta**: `FirestoreService.agentWeeklyCallCountStream(agentId)` ile bu haftaki (Pazartesi 00:00’dan itibaren) kaydedilen çağrı özeti sayısı gösteriliyor.
- **Firestore composite index**: `call_summaries` için `assignedAgentId` (==) + `createdAt` (>=) sorgusu kullanılıyor. İlk çalıştırmada Firestore hata mesajında index oluşturma linki çıkar; tıklayıp index’i ekleyin.

### 5. İlan detay sayfası
- **Route**: `/listing/:id`.
- **ListingDetailPage**: Tek ilan için stream (görsel, başlık, fiyat, konum, oda, m², açıklama).
- İlan listesinde karta tıklanınca detay sayfasına gidiliyor.
- **FirestoreService.listingDocStream(id)** eklendi.

### 6. Global hata yakalama
- **main.dart**: `runZonedGuarded` ile yakalanmayan async hatalar `AppLogger.e` ile loglanıyor.
- `FlutterError.onError` ve `ErrorWidget.builder` zaten mevcut; widget hatalarında kullanıcıya anlamlı ekran gösteriliyor.

---

## Görevler (Tasks) modülü

- **Görevlerim** sekmesi danışman shell’e eklendi (alt menüde “Görevler”).
- Liste: danışmana ait görevler vade tarihine göre; yapıldı checkbox, gecikmiş görevler kırmızı çerçeve.
- **Görev ekle:** FAB → başlık, vade tarihi, opsiyonel müşteri ID; müşteri bağlıysa “Müşteriye git” linki.
- Firestore: `tasks` koleksiyonu, `advisorId` + `dueAt` sorgusu için gerekirse composite index (ilk çalıştırmada konsoldaki link ile oluşturulabilir).

---

## Champion sürüm (görsel ödül seviyesi)

- **Design tokens:** `primaryGlow`, `gradientPrimary`, `gradientCardBorder`, `cardChampion()`, `championCardRadius`, `championButtonHeight`.
- **Pipeline Kanban:** `/pipeline` – aşama sütunları (Lead → Kazanıldı/Kaybedildi), premium kartlar (glow, renkli aşama rozetleri), uzun bas ile aşama değiştir, FAB ile “Pipeline’a ekle”. Danışman özetinde “Pipeline” kartı ile erişim.
- **Teklif & Ziyaret:** Müşteri detayda “Teklif ekle” / “Ziyaret ekle” butonları; bottom sheet ile CRUD. Timeline kartları tipe göre vurgulu (teklif: yeşil, ziyaret: mavi, çağrı: info).
- **Bildirimler:** `/notifications` – in-app bildirim merkezi, champion boş durum. Danışman özetinde çan ikonu ile erişim. Firestore `notifications` (userId + createdAt index gerekebilir).
- **Toplu işlem:** Müşteri listesinde “Toplu işlem” → seçim modu, checkbox’lı kartlar, “Takip listesine ekle (N)” → seçilen her müşteri için Görevler’e “Takip et” görevi (3 gün sonra vade) eklenir.

---

## Sonraki adımlar (isteğe bağlı)

- ~~**FCM**~~ (yapıldı): firebase_messaging; izin, token, arka plan handler; token users/{uid}/fcmToken; ayar tercihine göre.
- **Teklif & ziyaret CRUD**: Müşteri timeline’da; ilan ile ilişki.
- ~~**Bildirimler**~~ (yapıldı: in-app merkez; FCM isteğe bağlı).
- ~~**Toplu işlem**~~ (yapıldı: çoklu seçim → takip listesine ekle).
- ~~**Testler**~~ (yapıldı): EmptyState widget testi eklendi; permission_test, unauthorized_screen_test, widget_test mevcut.
- ~~**Crashlytics**~~ (yapıldı): firebase_crashlytics; FlutterError ve zone hataları raporlanıyor.

---

## Firestore index (haftalık çağrı sayısı)

Sorgu: `call_summaries` koleksiyonu, `assignedAgentId` == X ve `createdAt` >= hafta başı.

Firebase Console’da index oluşturmak için: Uygulama ilk kez bu sorguyu çalıştırdığında Firestore hata mesajında çıkan linki kullanın. **Yapıldı:** Proje köküne `firestore.indexes.json` eklendi (call_summaries, tasks, pipeline_items, notifications). Index'leri yüklemek için proje kökünde: `npx firebase deploy --only firestore:indexes`. (CLI bazen "An unexpected error" verebilir; giriş ve proje seçimini kontrol edin; gerekirse Firebase Console → Firestore → Indexes üzerinden manuel ekleyin.)

---

## Geri kalan / Handoff

- **Index deploy:** Proje kökünde `npx firebase deploy --only firestore:indexes` komutunu kendi makinenizde çalıştırın. Hata alırsanız Firebase Console → Firestore → Indexes üzerinden index'leri manuel ekleyebilirsiniz.
- **Yapılmış özellikler (bu el):** Pipeline Kanban, Teklif/Ziyaret, Bildirimler merkezi, Toplu işlem, Champion tasarım; **FCM** (push + token Firestore), **Crashlytics**, **EmptyState testi**, **erişilebilirlik** (Semantics, cacheExtent).
- **Kalite:** İsterseniz `flutter analyze` ve `flutter test` ile projeyi yerel çalıştırarak kontrol edin (Flutter cache izinleri için gerekirse `sudo chown -R $(whoami) ~/flutter/bin/cache`).
- **FCM iOS:** Push almak için Xcode’da Runner → Signing & Capabilities → Push Notifications ekleyin. `flutter pub get` ve iOS için `cd ios && pod install` çalıştırın.
