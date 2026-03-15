# Rainbow CRM / EmlakMaster – Vizyon ve Kalan İşler

## Ürün vizyonu (özet)

- Gayrimenkul danışmanları, ofis yöneticileri, brokerlar ve yatırımcılar için **Real Estate Operating System**.
- Çağrı merkezi, müşteri hafızası, ilan portföyü, pipeline, AI özet, raporlama, yatırımcı istihbaratı tek merkezde.
- Hedef: dünya çapında güvenilir, hızlı, akıllı, premium bir gayrimenkul CRM + yönetim katmanı.

---

## Tamamlanan (bu turda)

- **Design system:** `DesignTokens` (renk, spacing, radius, typography, elevation, animation).
- **Tema:** `AppTheme.dark()` / `light()` token tabanlı.
- **Roller:** 10 rol (Super Admin, Broker/Owner, Genel Yönetici, Ofis Müdürü, Team Lead, Danışman, Operasyon, Finans/Yatırım, Yatırımcı Portal, Demo); `AppRole`, `FeaturePermission` güncellendi.
- **Veri modelleri:** `CallEntity`, `CallDirection`, `CallOutcome`; `CallSummaryEntity`; `CustomerEntity`, `CustomerType`, `LifecycleStage` (shared/models).
- **Firestore sabitleri:** Spec’teki koleksiyon adları `AppConstants` içinde.
- **Shared widgets:** `SkeletonLoader`, `EmptyState`, `ErrorState`.
- **Executive dashboard:** Üstte `KpiBar` (çağrı, lead, sıcak, follow-up, aktif danışman/görüşme); “Çağrı Merkezi” butonu ile yönetici sayfasına geçiş.
- **Manager Command Center:** `CommandCenterPage` (tablo/kart/timeline seçici + boş state); route `/command-center`.
- **CRM Müşteriler:** `CustomerListPage` (arama çubuğu + boş state); `CustomerCard` (müşteri kartı + sıcaklık chip). Alt menü “Müşteriler” bu sayfayı açıyor.
- **Routing:** `routeCommandCenter` eklendi; shell’de Müşteriler sekmesi `CustomerListPage` kullanıyor.

---

## Kalan işler (teknik borç / sonraki adımlar)

### Faz 2 derinleştirme

1. **Dashboard KPI canlı veri:** `KpiBar` şu an sabit 0; Firestore `calls`, `analytics_daily` veya mevcut `agents`/`calls`/`deals` sayılarına bağlanmalı.
2. **Çağrı Merkezi veri:** `CommandCenterPage` gerçek çağrı listesi (Firestore `calls` + `call_summaries`), filtreler (danışman, tarih, sonuç, sıcaklık) ve tablo/kart/timeline görünümleri.
3. **CRM müşteri listesi:** `CustomerListPage` Firestore `customers` stream’i + arama/filtre + `CustomerCard` ile doldurulmalı; müşteri detay sayfası (timeline, notlar, çağrı özetleri) eklenmeli.
4. **Call screen state machine:** Spec’e uygun state’ler (idle, calling, active, keypad_open, muted, speaker_on, ending, ended, summary_transition); timer ve dispose güvenli.
5. **AI Call Summary:** State’ler (analyzing, analysis_ready, human_review, saving, saved, save_failed_retry); confidence, human edit, retry/save fallback.

### Faz 3

6. **Listings:** Detay sayfası, galeri, performans metrikleri, eşleşen müşteriler.
7. **Matching engine:** Müşteri–ilan eşleştirme, öneri skoru.
8. **Pipeline:** Kanban/liste, aşamalar, SLA, otomasyon kuralları.
9. **Tasks:** Manuel/AI önerili görev, müşteri/ilan bağlantısı, hatırlatma.
10. **Offers / Visits:** Teklif ve ziyaret CRUD, müşteri/ilan bağlantısı.

### Faz 4

11. **Investor Intelligence:** Yatırımcı dashboard, fırsat puanı, watchlist, alarmlar.
12. **Analytics & Reports:** Çağrı, danışman, pipeline, bölge raporları; PDF/Excel altyapısı.
13. **Notifications:** Push, in-app, görev hatırlatma, sıcak lead uyarısı.
14. **Audit & System health:** Audit log, sistem sağlık paneli, feature flags.

### Altyapı

15. **Auth:** E-posta/şifre, rolün `users` dokümanından okunması, rol bazlı landing.
16. **Firestore rules:** Tüm koleksiyonlar için rol bazlı kurallar; auth zorunlu.
17. **Offline / sync:** Offline queue, sync manager, stale indicator.
18. **Test:** Unit (repository, use case, permission), widget, integration iskeleti.

---

## Dosya değişiklikleri (bu tur)

| Dosya | Değişiklik |
|-------|------------|
| `lib/core/theme/design_tokens.dart` | Yeni: renk, spacing, radius, tipografi, animasyon token’ları |
| `lib/core/theme/app_theme.dart` | Token kullanacak şekilde güncellendi |
| `lib/features/auth/domain/entities/app_role.dart` | 10 rol (Broker, Genel Yönetici, Team Lead, Finans, Yatırımcı Portal vb.) |
| `lib/features/auth/domain/permissions/feature_permission.dart` | Yeni rollere göre yetkiler |
| `lib/core/constants/app_constants.dart` | Spec’teki tüm koleksiyon adları, appName: Rainbow CRM |
| `lib/shared/models/call_models.dart` | Yeni: CallEntity, CallDirection, CallOutcome |
| `lib/shared/models/call_summary_models.dart` | Yeni: CallSummaryEntity |
| `lib/shared/models/customer_models.dart` | Yeni: CustomerEntity, CustomerType, LifecycleStage |
| `lib/shared/widgets/skeleton_loader.dart` | Yeni: SkeletonLoader |
| `lib/shared/widgets/empty_state.dart` | Yeni: EmptyState |
| `lib/shared/widgets/error_state.dart` | Yeni: ErrorState |
| `lib/features/dashboard/presentation/widgets/kpi_bar.dart` | Yeni: KpiBar |
| `lib/features/manager_command_center/presentation/pages/command_center_page.dart` | Yeni: CommandCenterPage |
| `lib/features/crm_customers/presentation/pages/customer_list_page.dart` | Yeni: CustomerListPage |
| `lib/features/crm_customers/presentation/widgets/customer_card.dart` | Yeni: CustomerCard |
| `lib/core/router/app_router.dart` | routeCommandCenter, CommandCenterPage, CustomerListPage |
| `lib/screens/main_shell.dart` | Müşteriler sekmesi CustomerListPage |
| `lib/screens/dashboard_screen.dart` | KpiBar, “Çağrı Merkezi” butonu |

Bu yapı, vizyon dokümanındaki modüller ve Faz 2–4 için temel oluşturacak şekilde bırakıldı.
