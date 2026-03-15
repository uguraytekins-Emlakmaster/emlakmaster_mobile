# Zekice Özellikler – Uygulama Özeti

Tüm öneriler uygulandı. Altyapı **kendini onarabilir** ve **uzun ömürlü** olacak şekilde tasarlandı.

---

## 1. Resilience altyapısı (kendini onaran sistem)

- **`lib/core/resilience/retry_policy.dart`**  
  Kritik işlemler için yeniden deneme: exponential backoff, geçici hatalarda otomatik retry, kalıcı hatalarda vazgeçme.

- **`lib/core/resilience/sync_status.dart`**  
  Senkron durumu: `isOnline`, `lastSyncAt`. Bağlantı değişince güncellenir; `recordSyncSuccess()` ile yazma başarılarında "Son senkron" güncellenir.

- **`lib/core/resilience/safe_operation.dart`**  
  `runWithResilience(action, ref)` ile Firestore (ve diğer) işlemleri: retry + başarıda sync durumu güncellemesi. Not kaydetme vb. buradan kullanılmalı.

- **Son senkron göstergesi**  
  `SyncStatusBanner`: Shell’lerin üstünde (consultant + admin). Çevrimdışı / "X dk önce" gösterir; tıklanınca açıklama SnackBar’da.

---

## 2. Ayarlar / Tema / Bildirim

- Tema: Açık / Koyu / Sistem; SharedPreferences’ta saklanır.
- Bildirimler: Açık/Kapat switch’i; tercih kaydedilir (push altyapısı ayrı eklenebilir).

---

## 3. Müşteri detay

- **Not ekle FAB**  
  Zaman çizelgesi üzerinde FAB → bottom sheet: şablon chip’leri (Teklif gönderildi, Randevu alındı, vb.) + metin alanı + Kaydet.  
  Kayıt: `runWithResilience` + `FirestoreService.saveNote`; başarıda haptic + SnackBar.

- **WhatsApp’ta aç**  
  `lib/core/utils/whatsapp_launcher.dart`: Türkiye numarası için `wa.me` URL + `url_launcher`.  
  Müşteri detayda "WhatsApp'ta aç" butonu (telefon varsa).

- **Magic Call müşteriye bağla**  
  Müşteri detaydan "Ara" → `routeCall` + `extra: { customerId }`.  
  CallScreen `customerId`/`phone` alır; arama bitince PostCallWizard’a `linkedCustomerId` gider; özet bu müşteriye yazılır.

---

## 4. Müşteri listesi / kart

- **Son temas chip’i**  
  `LastContactLabel`: "Az önce", "Bugün", "Dün", "X gün önce" + renk (yeşil/sarı/gri).  
  CustomerCard’da `lastInteractionAt` ile gösterilir.

- **Arama**  
  Zaten vardı; isim/telefon/e-posta ile client-side filtreleme.

---

## 5. Günlük özet / Danışman paneli

- **Bugün satırı**  
  Consultant dashboard’da "Bugün: X takip" + "Önerilen aksiyonlar listede" (resurrection sayısına göre).

- **Haftalık hedef**  
  `_WeeklyGoalCard`: "Bu hafta 0 / 15 çağrı" + progress bar. İleride haftalık çağrı sayısı bağlanabilir.

---

## 6. Cmd+K akıllı arama

- **Command Palette**  
  Yazarken: "Sayfalar" (Dashboard, Çağrı Merkezi, War Room, …) filtrelenir.  
  2+ karakterde: Firestore `customersStream()` ile müşteri araması; tıklanınca müşteri detaya gider.  
  DraggableScrollableSheet ile açılır.

---

## 7. Çağrı merkezi

- **CSV dışa aktar**  
  AppBar’da "Dışa aktar" ikonu. Görünen (filtrelenmiş) liste CSV’e dönüştürülür, **panoya kopyalanır** (Excel’e yapıştırma).  
  `lib/core/utils/csv_export.dart`: `callsToCsv(docs)` + UTF-8 BOM.

---

## 8. Haptic

- Not kaydedildiğinde `HapticFeedback.mediumImpact()`.  
  Tab değişimlerinde zaten `selectionClick` kullanılıyor.

---

## Bağımlılık

- **url_launcher: ^6.2.5** (WhatsApp için) — `pubspec.yaml`’a eklendi.  
  Proje kökünde `flutter pub get` çalıştırın (ve gerekirse Flutter SDK lockfile izinlerini düzeltin).

---

## Uzun ömürlülük

- **Retry:** Geçici ağ/veritabanı hatalarında otomatik yeniden deneme.
- **Sync durumu:** Kullanıcı çevrimdışı / son senkron bilgisini görür; güven artar.
- **Safe operation:** Yeni kritik yazmalar `runWithResilience` ile sarmalanabilir; böylece hem retry hem sync güncellemesi merkezi kalır.
- **Sabitler:** `AppConstants` (retry sayısı, timeout); tema/ayar anahtarları tek yerde.
- **Dil/UI:** Tüm kullanıcı metinleri Türkçe; hata mesajları sade.

Toplu işlem (müşteri listesinde çoklu seçim → takip listesine ekleme) UI olarak eklenmedi; resurrection/task entegrasyonu sonrası eklenebilir.
