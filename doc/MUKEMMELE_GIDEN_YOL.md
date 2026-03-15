# EmlakMaster – Mükemmele Giden Yol

Uygulama şu an işlevsel ve kullanılabilir; ama **mükemmel** (güvenilir, tam, profesyonel) olması için aşağıdaki eksiklerin giderilmesi gerekiyor. Öncelik sırasına göre düzenlendi.

---

## A. Kritik (güvenlik + güven – yayın öncesi şart)

| # | Eksik | Ne yapılmalı | Neden |
|---|--------|----------------|------|
| 1 | **Firestore kuralları** | Her koleksiyon için rol bazlı `read`/`write`: danışman sadece kendi müşteri/notlarına, yönetici hepsine. `users` dokümanında `role` zorunlu. | Veri başkasının eline geçmez; yetkisiz yazma engellenir. |
| 2 | **Gerçek agentId / demo kaldırma** | CallScreen ve PostCallWizard’da `demoAgent1` yerine giriş yapan kullanıcının `uid` kullanılsın. Çağrı kaydı ve özet doğru danışmana bağlansın. | Veriler gerçek kullanıcıya yazılır. |
| 3 | **Auth akışı netleştirme** | E-posta/şifre + Google zaten var; ilk girişte `users/{uid}` oluşturuluyor. Rol atamasının admin panel veya Firestore ile nasıl yapılacağı dokümante edilsin; gerekirse “Rol talebi” ekranı. | Doğru kişi doğru paneli görür. |

Bu üçü olmadan canlı ortamda güvenli ve doğru çalışması zor.

---

## B. Çekirdek iş akışı (günlük kullanımı tamamlar)

| # | Eksik | Ne yapılmalı | Neden |
|---|--------|----------------|------|
| 4 | **Arama ekranı (Call) state makinesi** | Net state’ler: idle → numara gir → calling → connected → muted/speaker → ending → summary’e geçiş. Timer doğru, dispose güvenli, gerçek arama entegrasyonu (telefon/SIP) ileride. | Arama akışı tutarlı; kullanıcı ne olduğunu anlar. |
| 5 | **AI çağrı özeti gerçek akış** | Şu an demo metin + simüle özet. Gerçekte: ses → (Whisper) metin → (LLM) yapılandırılmış özet → insan düzeltmesi → kaydet; hata/retry. | Çağrı sonrası değer üretir. |
| 6 | **Dashboard KPI tam canlı** | KpiBar’daki lead, sıcak, follow-up sayıları Firestore `analytics_daily` veya mevcut koleksiyonlardan hesaplansın. Haftalık hedef kartı gerçek haftalık çağrı sayısına bağlansın. | Yönetici tek bakışta doğru sayıyı görür. |
| 7 | **İlanlar detay** | İlan listesinden tıklanınca: detay sayfası, galeri, özet bilgi, (ileride) eşleşen müşteriler. | Portföy yönetimi anlam kazanır. |

Bunlar olmadan ürün “yarım” hisseder; günlük iş akışında tıkanma noktaları kalır.

---

## C. Modüller (ürünü büyütür)

| # | Eksik | Ne yapılmalı | Neden |
|---|--------|----------------|------|
| 8 | **Pipeline (Kanban)** | Deal/satış aşamaları, sürükle-bırak, aşama bazlı liste, basit SLA veya hatırlatma. | Satış süreci görünür; takip kolaylaşır. |
| 9 | **Görevler (Tasks)** | Müşteri/ilan bağlantılı görev, vade tarihi, “yapıldı” işaretleme, (ileride) hatırlatma/push. | Hiçbir takip kaçmaz. |
| 10 | **Teklif & ziyaret** | Teklif ve ziyaret CRUD, müşteri/ilan ile ilişkilendirme; müşteri timeline’da görünsün. | Müşteri hikayesi tamamlanır. |
| 11 | **Bildirimler** | Push (FCM) + uygulama içi: sıcak lead, görev hatırlatma, önemli güncellemeler. Ayarlardaki “Bildirimler” tercihi buraya bağlansın. | Kullanıcı zamanında geri döner. |
| 12 | **Toplu işlem** | Müşteri listesinde çoklu seçim → “Takip listesine ekle” (resurrection/task ile entegre). | Yönetici/danışman zaman kazanır. |

Bunlar “mükemmel” hissini güçlendirir; öncelik ihtiyaca göre verilebilir.

---

## D. Kalite & sürdürülebilirlik

| # | Eksik | Ne yapılmalı | Neden |
|---|--------|----------------|------|
| 13 | **Testler** | Kritik ekranlar ve yetki için widget testleri; repository/use case unit testleri; CI’da `flutter test`. Firebase için mock. | Her değişiklikte kırılma riski azalır. |
| 14 | **Hata izleme** | Firebase Crashlytics (veya benzeri); canlıda hata/exception toplama. | Sorunları hızlı görürsün. |
| 15 | **Performans** | Büyük listelerde lazy load / sayfalama; gereksiz rebuild kontrolü. | Ölçek büyüdükçe uygulama yavaşlamaz. |
| 16 | **Erişilebilirlik** | Semantik etiketler, kontrast, büyük dokunma alanları, ekran okuyucu uyumu. | Herkes kullanabilir. |

Bunlar uzun vadede “mükemmel” ve güvenilir kalmasını sağlar.

---

## E. İleri seviye (vizyon)

| # | Eksik | Ne yapılmalı | Neden |
|---|--------|----------------|------|
| 17 | **Raporlama & analitik** | Çağrı, danışman, pipeline, bölge raporları; PDF/Excel dışa aktarma (şu an sadece çağrı CSV var). | Yönetim karar alır. |
| 18 | **Yatırımcı istihbaratı** | Yatırımcı dashboard, fırsat puanı, watchlist, alarmlar. | Farklı kullanıcı segmenti tamamlanır. |
| 19 | **Matching engine** | Müşteri–ilan eşleştirme, öneri skoru, “Bu ilan bu müşteriye uygun” önerileri. | Satış hızlanır. |
| 20 | **Offline tam destek** | Kritik ekranlar ve yazmalar offline kuyruk + çevrimiçi olunca senkron (şu an Firestore persistence var; UI’da “bekleyen işlem” göstergesi güçlendirilebilir). | Sahada kesintisiz çalışma. |

---

## Önerilen sıra (mükemmele doğru adım adım)

1. **Firestore kuralları** (A.1) – Güvenlik temeli.
2. **Gerçek agentId** (A.2) – Veri bütünlüğü.
3. **Call screen state makinesi** (B.4) – Arama deneyimi.
4. **Dashboard KPI + haftalık hedef canlı** (B.6) – Yönetim ekranı anlamlı.
5. **İlanlar detay** (B.7) – Temel CRM tamamlanır.
6. **Görevler (Tasks)** (C.9) – Günlük takip.
7. **Bildirimler** (C.11) – Geri dönüş.
8. **Testler + Crashlytics** (D.13, D.14) – Kalite ve gözlem.

Sonrasında Pipeline, raporlama, matching, yatırımcı modülü ihtiyaca göre eklenebilir.

---

## Kısa özet

- **Kritik:** Firestore kuralları, demo agentId’nin kaldırılması, auth/rol netliği.
- **Çekirdek:** Call state, AI özet akışı, canlı KPI, ilan detay.
- **Modüller:** Pipeline, Tasks, teklif/ziyaret, bildirimler, toplu işlem.
- **Kalite:** Test, Crashlytics, performans, erişilebilirlik.
- **İleri:** Raporlama, yatırımcı, matching, offline tam destek.

Hangi numaradan (veya harf grubundan) başlamak istediğini söylersen, o başlığı adım adım koda indirgeyebiliriz.
