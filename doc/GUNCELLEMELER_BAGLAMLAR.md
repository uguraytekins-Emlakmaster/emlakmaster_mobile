# EmlakMaster — Tüm Güncellemeler ve Bağlamları

Bu doküman, uygulamadaki güncellemeleri **bağlamlarıyla** (neden, nerede, hangi dosyalar) toplu olarak listeler. Detaylar için ilgili `doc/*.md` dosyalarına bakın.

---

## 0. Öncelik Turu (Şu An Ne Yapıldı)

| Yapılan | Bağlam |
|---------|--------|
| Testler | 28 test yeşil; CI için `flutter test` çalıştırılabilir. |
| Auth + rol | Zaten bağlı: currentRoleProvider → users/{uid}.role, ensureUserDoc ilk girişte doc oluşturur. |
| Firestore rules | users: sadece isOwner; açıklama eklendi. |
| KPI canlı | Bugünkü çağrı (todayCallsCountStream), açık görev (openTasksCountStream), Follow-up chip gerçek veri. |
| Müşteri listesi/detay | customersStream, arama, detay sayfası timeline + notlar zaten mevcut. |

---

## 1. Performans (No-Lag)

**Bağlam:** İlk açılışın hızlı, listelerin takılmadan kayması ve UI thread’in serbest kalması.

| Güncelleme | Bağlam / Neden | Dosyalar |
|------------|----------------|----------|
| Deferred init | Shell hemen görünsün; SyncManager, OnboardingStore, Hive ilk frame sonrası | `lib/main.dart` |
| Deferred sayfalar | War Room, Broker Command, Command Center sadece tıklanınca yüklensin | `lib/core/lazy/deferred_dashboard_pages.dart`, `lib/core/router/app_router.dart` |
| CachedNetworkImage + Shimmer | Ağ görselleri önbellekli; yüklenirken shimmer | Listing detay, ilan listesi, ofis logosu, `lib/widgets/` |
| Hive / AppCacheService | Hafif yerel cache; init post-frame | `lib/core/cache/app_cache_service.dart` |
| Riverpod `.select()` | Sadece izlenen alan değişince rebuild | Pipeline, bildirimler, görevler, danışman paneli |
| Portfolio match isolate | Ağır eşleştirme UI thread’de değil | `lib/features/smart_matching_engine/` (`compute_top_matched_listings_isolate.dart`, `portfolio_match_provider.dart`) |
| RepaintBoundary | Liste item’ları birbirini tetiklemesin | War room, müşteri listesi, ilan listesi |

**Detay:** `doc/PERFORMANCE.md`

---

## 2. Platform İzinleri

**Bağlam:** Tüm özelliklerin iOS, Android ve macOS’ta doğru izinlerle çalışması.

| Platform | İzinler (özet) | Özellik bağlamı |
|----------|----------------|-----------------|
| iOS | NSMicrophone, NSSpeechRecognition, NSContacts, NSPhotoLibrary, NSCamera, UIBackgroundModes | Sesli CRM, rehber kayıt, galeri/kamera, push |
| Android | RECORD_AUDIO, READ_CONTACTS, WRITE_CONTACTS, POST_NOTIFICATIONS, CAMERA, READ_MEDIA_IMAGES | Aynı özellikler |
| macOS | NSMicrophone, NSSpeechRecognition, NSPhotoLibrary, NSCamera, NSContacts (varsa) | Masaüstü sesli + rehber; Podfile 11.0 (speech_to_text) |

**Detay:** `doc/PLATFORM_PERMISSIONS.md`  
**Dosyalar:** `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`, `macos/Runner/Info.plist`, `macos/Podfile`

---

## 3. Rehber ve Uygulamaya Kaydet (Contact Save)

**Bağlam:** Arama sonrası veya müşteri ekranından kişiyi rehbere ve Firestore müşteri kaydına ekleme; sesli komut + manuel.

| Öğe | Bağlam | Dosyalar |
|-----|--------|----------|
| Sesli komut | İsim/telefon/not çıkarma (Türkçe) | `lib/features/contact_save/domain/extract_contact_from_voice.dart` |
| Rehbere yazma | flutter_contacts; izin gerekli | `lib/features/contact_save/data/save_contact_service.dart` |
| Uygulamaya kayıt | Firestore customers | `lib/core/services/firestore_service.dart` → `createCustomer()` |
| SaveContactSheet | Sesli + manuel; “Rehbere kaydet” / “Uygulamaya kaydet” seçenekleri | `lib/features/contact_save/presentation/widgets/save_contact_sheet.dart` |
| Tetikleyiciler | PostCallWizard butonu; CustomerCard rehber ikonu | `lib/features/calls/post_call_wizard.dart`, `lib/features/crm_customers/.../customer_card.dart` |

**Detay:** `doc/CONTACT_SAVE_FEATURE.md`

---

## 4. Özel Rehber İzin Akışı

**Bağlam:** İzin reddedildiğinde veya kalıcı red (permanently denied) durumunda kullanıcıyı ayarlara yönlendirme.

| Öğe | Bağlam | Dosyalar |
|-----|--------|----------|
| permission_handler | İzin durumu (granted/denied/permanentlyDenied) ve “Ayarlara git” | `pubspec.yaml`, `lib/features/contact_save/data/contact_permission_helper.dart` |
| ContactPermissionHelper | İstek + durum kontrolü + openSystemSettings() | `contact_permission_helper.dart` |
| SaveToDeviceResult | success / denied / permanentlyDenied; UI buna göre davranır | `save_contact_service.dart` |
| “Ayarlara git” diyaloğu | Kalıcı red ise “Rehber izni kapalı” + Ayarlara git butonu | `save_contact_sheet.dart` → `_showContactPermissionSettingsDialog()` |

**Akış:** Rehbere kaydet tıklanır → izin istenir → red (veya kalıcı red) → kalıcı red ise diyalog + Ayarlara git → `openAppSettings()` (permission_handler).

---

## 5. Stabilite ve Veri

**Bağlam:** Overflow, API hataları ve platforma özel çökme risklerini azaltma.

| Güncelleme | Bağlam | Dosyalar |
|------------|--------|----------|
| Finance bar overflow | Küçük font/padding ve constraint | `lib/widgets/finance_bar.dart` |
| FinanceService | Null-safe JSON; hata durumunda cache/varsayılan oran | `lib/core/services/finance_service.dart` |
| PushNotificationService | getToken() macOS/web’de çağrılmaz (APNS hatası önlenir) | `lib/core/services/push_notification_service.dart` |
| macOS Podfile | platform :osx 11.0 (speech_to_text uyumu) | `macos/Podfile` |

---

## 6. Bağımlılık Özeti (Bu Güncellemelere Ait)

| Paket | Bağlam |
|-------|--------|
| `flutter_contacts` | Rehbere ekleme |
| `permission_handler` | Rehber izin durumu + Ayarlara git |
| `cached_network_image`, `shimmer` | Görsel performans |
| `hive`, `hive_flutter` | AppCacheService |
| `speech_to_text` | Sesli komut (contact save + Hands-Free CRM) |

---

## 7. KPI Canlı Veri

| Öğe | Bağlam | Dosyalar |
|-----|--------|----------|
| Bugünkü çağrı | createdAt >= bugün 00:00 | `FirestoreService.todayCallsCountStream()` |
| Açık görev (Follow-up) | tasks where done == false | `FirestoreService.openTasksCountStream()` |
| Agents | status, missedCalls | `FirestoreService.agentsStream()` |
| Dashboard KPI | Yukarıdaki stream'lerle KpiBar | `dashboard_kpi_section.dart` |

## 8. Hızlı Dosya Referansları

- **Performans:** `main.dart`, `deferred_dashboard_pages.dart`, `app_cache_service.dart`, `portfolio_match_provider.dart`, `compute_top_matched_listings_isolate.dart`
- **İzinler:** `ContactPermissionHelper`, `SaveContactService.saveToDevice` → `SaveToDeviceResult`
- **Contact Save UI:** `SaveContactSheet`, `PostCallWizard`, `CustomerCard`
- **Stabilite:** `finance_bar.dart`, `finance_service.dart`, `push_notification_service.dart`
- **KPI:** `firestore_service.dart` (todayCallsCountStream, openTasksCountStream), `dashboard_kpi_section.dart`, `kpi_bar.dart`
- **Auth/Rol:** `auth_provider.dart`, `user_repository.dart`, `firestore.rules` (users)

Tüm güncellemeler bu bağlamlarla uyumlu; yeni özellik eklerken ilgili `doc/*.md` ve bu özet güncellenmeli.
