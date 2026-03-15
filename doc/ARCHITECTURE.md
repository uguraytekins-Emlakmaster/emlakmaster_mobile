# EmlakMaster – Mimari Özet

## Faz 1 (Tamamlandı)

### Eklenen bağımlılıklar
- **flutter_riverpod** – State management
- **go_router** – Declarative routing
- **firebase_auth** – Kimlik doğrulama (anon + ileride e-posta/telefon)
- **equatable** – Value equality (entities/errors)
- **shared_preferences** – Tema/ayar önbelleği
- **connectivity_plus** – Ağ durumu (ileride offline queue)
- **logger** – Yapılandırılmış log

### Core katmanı
- `core/constants/app_constants.dart` – Koleksiyon adları, key’ler, timeout
- `core/config/app_config.dart` – Ortam (release/debug)
- `core/errors/app_exception.dart` – Tip güvenli hatalar (Network, Auth, Data, Permission, Validation, Timeout, Unknown)
- `core/errors/exception_mapper.dart` – Teknik hata → kullanıcı mesajı
- `core/result/result.dart` – Success/Failure sealed type
- `core/logging/app_logger.dart` – Merkezi logger
- `core/theme/app_theme.dart` – Light/dark premium tema
- `core/router/app_router.dart` – go_router tanımları, hata fallback ekranı

### Auth & roller
- `features/auth/domain/entities/app_role.dart` – Super Admin, Yönetici, Ofis Müdürü, Danışman, Operasyon, Misafir
- `features/auth/domain/permissions/feature_permission.dart` – Rol bazlı özellik yetkileri
- `features/auth/presentation/providers/auth_provider.dart` – currentRoleProvider (şu an demo: agent)

### Uygulama girişi
- `main.dart` – ProviderScope, MaterialApp.router, AppTheme, FlutterError.onError → AppLogger
- Firestore init sonrası **Anonymous Auth** ile otomatik giriş (Firestore kuralları için)
- Routing: `/` → MainShellPage, `/call` → CallScreen, `/call/summary` → PostCallWizardScreen
- Shell ve call/summary ekranları go_router (context.push / context.go / context.pop) kullanıyor

### Güvenlik
- `firestore.rules` – isSignedIn() ile korumalı koleksiyonlar; users, roles, agents, customers, calls, deals, listings, news, office_activity için kurallar
- **Not:** Firebase Console’da Anonymous Authentication’ı etkinleştirin.

### Kalite
- `analysis_options.yaml` – avoid_print, prefer_const_constructors, prefer_final_locals vb. kurallar

## Sonraki fazlar (kısa)
- **Faz 2:** Auth (e-posta/şifre, rol users dokümanından), Dashboard canlı veri, Customer CRM ekranı, Tasks/Notifications iskeleti
- **Faz 3:** Listings detay, Pipeline (Kanban), Raporlama, Map radar iyileştirme
- **Faz 4:** Gelişmiş AI, otomasyon kuralları, admin, Remote Config, performans geçişi
