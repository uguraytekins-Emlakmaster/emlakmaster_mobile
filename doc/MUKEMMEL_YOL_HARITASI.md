# EmlakMaster – Mükemmelleştirme Yol Haritası

Beraber ilerleyebileceğimiz öncelikli öneriler. Hangi başlıktan başlamak istediğinizi söylemeniz yeterli.

---

## 1. Hızlı kazanımlar (hem görünür hem mantıklı)

| Öneri | Ne yapacak | Etki |
|-------|------------|------|
| **Ayarlar sayfası** | `SettingsPlaceholderPage` yerine gerçek Ayarlar: tema (açık/koyu), bildirim aç/kapa, “Danışman paneli kullan” toggle (yöneticiler için), çıkış. | Kullanıcı kendini evinde hisseder. |
| **Müşteri listesi canlı veri** | `CustomerListPage` Firestore `customers` stream + arama. Şu an boş/placeholder. | CRM’in kalbi çalışır. |
| **Çağrı merkezi canlı liste** | `CommandCenterPage` Firestore `calls` + `call_summaries` ile gerçek liste, filtre (tarih, danışman, sonuç). | Yönetici ekranı anlamlı hale gelir. |

Bunlarla uygulama “gerçek veriyle çalışan” hissine kavuşur.

---

## 2. Kritik eksikler (güvenlik ve güven)

| Öneri | Ne yapacak | Etki |
|-------|------------|------|
| **Gerçek auth + rol** | Firebase Auth (e-posta/şifre veya mevcut Google) + Firestore `users/{uid}` içinde `role`. Şu an rol sabit/demo. | Doğru kişi doğru panele girer. |
| **Firestore kuralları** | Tüm koleksiyonlar için rol bazlı read/write kuralları; `users` dokümanında `role` alanı zorunlu. | Veri güvenliği sağlanır. |

Bunlar yayın öncesi mutlaka olmalı.

---

## 3. Deneyimi güçlendiren (tasarım + akış)

| Öneri | Ne yapacak | Etki |
|-------|------------|------|
| **Dashboard KPI tam canlı** | KpiBar zaten kısmen bağlı; eksik metrikleri (lead, sıcak, follow-up, aktif danışman) Firestore/analytics ile doldurmak. | Yönetici tek bakışta durumu görür. |
| **Müşteri detay sayfası** | Müşteri kartına tıklanınca: timeline (çağrı, not, ziyaret), not ekleme, hızlı arama butonu. | Danışman günlük işini uygulamada yapar. |
| **Call screen state makinesi** | Arama ekranında net state’ler: idle → calling → active → ending → summary; timer, mute, speaker. | Arama akışı tutarlı ve güvenilir olur. |
| **AI çağrı özeti akışı** | Analyzing → insan düzeltmesi → kaydet / retry; hata durumunda “Tekrar dene”. | Çağrı sonrası iş akışı tamamlanır. |

---

## 4. Orta vadede (modüller)

| Öneri | Ne yapacak | Etki |
|-------|------------|------|
| **İlanlar detay** | İlan kartı → detay sayfası, galeri, eşleşen müşteriler, kısa performans. | Portföy yönetimi anlam kazanır. |
| **Pipeline (Kanban)** | Deal aşamaları, sürükle-bırak, basit SLA/hatırlatma. | Satış süreci görünür olur. |
| **Görevler (Tasks)** | Müşteri/ilan bağlantılı görev, hatırlatma, “yapıldı” işaretleme. | Takip kaçmaz. |
| **Bildirimler** | Push / in-app: sıcak lead, görev hatırlatma, önemli güncellemeler. | Kullanıcı geri döner. |

---

## 5. Altyapı ve kalite

| Öneri | Ne yapacak | Etki |
|-------|------------|------|
| **Offline / sync** | SyncManager + offline queue, “son senkronizasyon” göstergesi. | Bağlantı kesilince veri kaybı azalır. |
| **Testler** | Kritik ekranlar ve yetki için widget/integration testleri; CI’da `flutter test`. | Her değişiklikte kırılma riski azalır. |
| **Hata izleme** | Örn. Firebase Crashlytics; canlıda hata toplama. | Sorunları hızlı görürsün. |

---

## Önerilen sıra (beraber ilerlemek için)

1. **Ayarlar sayfası** (kısa, görünür, kullanıcı hissi)
2. **Müşteri listesi canlı veri** (CRM’i gerçek yapar)
3. **Gerçek auth + rol** (güvenlik ve doğru panel)
4. **Çağrı merkezi canlı liste** (yönetici ekranı tamamlanır)
5. **Müşteri detay + timeline** (günlük iş akışı)

Sonrasında Call screen state, AI özet akışı, Pipeline, İlanlar detay vb. istediğiniz sırayla eklenebilir.

---

Hangi numaradan veya hangi başlıktan başlamak istediğinizi yazmanız yeterli; o adımı birlikte detaylandırıp koda dökebiliriz.
