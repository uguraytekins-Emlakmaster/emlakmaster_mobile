# Ayarlar ve İlk Giriş Rol Seçimi

## İlk giriş: Nasıl giriş yapmak istiyorsunuz?

İlk kez giriş yapan kullanıcıda Firestore'da `users/{uid}` dokümanı yoksa **rol seçim ekranı** gösterilir. Kullanıcı aşağıdaki giriş türlerinden birini seçer; seçim Firestore'a yazılır ve panele yansır.

### Seçenekler

| Rol | Açıklama |
|-----|----------|
| **Broker / Sahibi** | Şirket sahibi, tüm yetkiler |
| **Gayrimenkul Yatırım Uzmanı** | Finans / Yatırım, portföy takibi (finance_investor, investor_portal) |
| **Ofis Müdürü** | Yönetici, ekip ve çağrı merkezi |
| **Team Lead** | Ekip lideri |
| **Danışman** | Müşteri ve ilan yönetimi |
| **Operasyon Personeli** | Çağrı merkezi, operasyon |
| **Genel Yönetici** | Üst düzey yönetim |
| **Yatırımcı Portal** | Yatırımcı paneli |
| **Süper Admin** | Sadece ilk kullanıcı görür; kurulum yöneticisi |

- **Teknik:** `RoleSelectionPage`, `needsRoleSelectionProvider`, route `/role-selection`. Doc yokken otomatik `ensureUserDoc` çağrılmaz; kullanıcı seçim yapar ve `UserRepository.setUserDoc` ile doc oluşturulur.

---

## Ayarlar: Kategoriler ve özellik bayrakları

Tüm özellikler **Ayarlar** ekranından açılıp kapatılabilir veya ilgili detay sayfasından düzenlenir. Değerler SharedPreferences'ta saklanır; isteğe bağlı ileride Firestore ile senkronize edilebilir.

### Kategoriler

1. **Hesap & Giriş** — Profil, rol, yönetici yetkisi al, panel tercihi (yönetici / danışman), test için rol değiştir.
2. **Görünüm** — Tema (sistem / açık / koyu), kompakt dashboard.
3. **Bildirimler** — Bildirimler anahtarı, push bildirimleri.
4. **Çağrı & CRM** — Sesli CRM (Magic Call), rehbere/uygulamaya kaydet, çağrı özeti (AI).
5. **İlanlar & Eşleştirme** — İlan kaynakları ve ofis (mevcut bölüm), Market Pulse, portföy eşleştirme.
6. **War Room & Raporlar** — KPI çubuğu, War Room, Çağrı Merkezi, günlük özet, pipeline, yatırımcı istihbaratı, görevler, bildirim merkezi.
7. **Ses & Erişilebilirlik** — Titreşim (haptic), ses efektleri.
8. **Gizlilik & Veri** — Analytics, hata raporlama (Crashlytics).
9. **Hesap** — Çıkış yap.

### Özellik bayrakları (AppConstants / SettingsService)

- `keyFeatureVoiceCrm`, `keyFeatureContactSave`, `keyFeatureCallSummary`
- `keyFeatureWarRoom`, `keyFeatureMarketPulse`, `keyFeatureDailyBrief`, `keyFeaturePipeline`, `keyFeatureCommandCenter`, `keyFeatureInvestorIntelligence`
- `keyFeatureKpiBar`, `keyFeaturePortfolioMatch`, `keyFeatureTasks`, `keyFeatureNotificationsCenter`
- `keyFeatureAnalytics`, `keyFeatureCrashlytics`, `keyFeaturePushNotifications`
- `keyCompactDashboard`, `keyHapticFeedback`, `keySoundEffects`

Varsayılan: çoğu **açık** (true); kompakt dashboard ve ses efektleri **kapalı** (false).

### Kullanım

- **featureFlagsProvider** (Riverpod): Tüm bayraklar tek StateNotifier'da; ayar ekranı ve uygulama buradan okur. `setFlag(key, value)` ile güncelleme.
- Ekranlar ilgili bayrağı okuyup özelliği gösterip gizleyebilir (örn. War Room kapalıysa menüde gizle).

### Dosyalar

- `lib/features/auth/presentation/pages/role_selection_page.dart` — İlk giriş rol seçimi.
- `lib/features/settings/` — domain (`app_setting_item.dart`), presentation (`settings_page.dart`, `feature_flags_provider.dart`).
- `lib/core/constants/app_constants.dart` — Özellik anahtarları.
- `lib/core/services/settings_service.dart` — getFeatureFlag / setFeatureFlag ve kısayollar.

---

## Öneriler (ileride eklenebilir)

- **Dil / yerel** — Uygulama dili (TR / EN) ve bölge formatları.
- **Varsayılan görünüm** — Dashboard’da açılış sekmesi (özetim / müşteriler / ilanlar).
- **Çağrı kaydı** — Otomatik kayıt açık/kapalı ve yasal uyarı metni.
- **Veri saklama** — Önbellek temizleme, veri dışa aktarma.
- **Geliştirici** — API base URL, mock modu (debug).
- **Firestore senkronu** — Ayarların `app_settings` veya `users/{uid}/preferences` ile senkronize edilmesi.
