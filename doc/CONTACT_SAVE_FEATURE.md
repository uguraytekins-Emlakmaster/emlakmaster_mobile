# Rehbere ve Uygulamaya Kaydet (Sesli Komut + Manuel)

Arama sonrası veya uygulama içi arama/müşteri ekranından kişiyi **rehbere (telefon rehberi)** ve **uygulamaya (EmlakMaster müşteri)** kaydetme. Sesli komut (AI yardımı) ve manuel giriş desteklenir.

## Üyelik seviyeleri

- **Normal üyelik:** Sesli komut (yapay zeka ile isim/telefon/not çıkarma) + manuel giriş ile hem rehbere hem uygulamaya kayıt yapılabilir.
- **Pro üyelik (danışman/yönetici):** Aynı rehber + uygulama kaydına ek olarak tam **AI Satış Asistanı** paneli (müşteri detayında) kullanılır.

## Tetikleme noktaları

1. **Çağrı özeti sihirbazı (PostCallWizard)**  
   Arama bittikten sonra "Rehbere ve uygulamaya kaydet (sesli / manuel)" butonu. Müşteriye bağlı aramada isim/telefon önceden doldurulur; aksi halde sesli veya manuel girilir.

2. **Müşteri listesi (CustomerCard)**  
   Her müşteri kartında rehber ikonu (contact_phone). Tıklanınca aynı sheet açılır; isim/telefon/e-posta önceden doldurulur.

## Akış

- **Sesli komut:** Mikrofon butonuna basılı tut → "Ahmet Yılmaz, telefon 532 123 45 67, not 3+1 Bağlar istiyor" gibi söyle → AI isim, telefon, not çıkarır ve forma yazar; kullanıcı gerekirse düzenleyip kaydeder.
- **Manuel:** İsim, telefon, e-posta, not alanlarını doldur.
- **Seçenekler:** "Rehbere kaydet" ve/veya "Uygulamaya kaydet" işaretlenir; her iki seçenek de açık olabilir.

## Teknik

- **Rehber:** `flutter_contacts` ile cihaz rehberine ekleme (izin: iOS `NSContactsUsageDescription`, Android `READ_CONTACTS` / `WRITE_CONTACTS`).
- **Özel izin akışı:** `permission_handler` ile izin durumu (granted / denied / permanentlyDenied). Kalıcı redde "Rehber izni kapalı" diyaloğu + **Ayarlara git** butonu; `ContactPermissionHelper.openSystemSettings()` uygulama ayarlarını açar.
- **Uygulama:** `FirestoreService.createCustomer()` ile `customers` koleksiyonuna yeni doküman.
- **Sesli çıkarma:** `extract_contact_from_voice()` (Türkçe; isim/telefon/not regex ve basit kurallar).

## Dosyalar

- `lib/features/contact_save/` — domain (ContactSaveRequest, extract_contact_from_voice), data (SaveContactService, **ContactPermissionHelper**), presentation (SaveContactSheet).
- `lib/features/calls/post_call_wizard.dart` — "Rehbere ve uygulamaya kaydet" butonu.
- `lib/features/crm_customers/presentation/widgets/customer_card.dart` — rehber ikonu.
- `lib/core/services/firestore_service.dart` — `createCustomer()`.

**Bağlam özeti:** `doc/GUNCELLEMELER_BAGLAMLAR.md`
