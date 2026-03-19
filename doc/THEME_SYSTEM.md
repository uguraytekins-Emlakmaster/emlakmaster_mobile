# Tema Sistemi — Production-Grade Refactor

## 1. Analiz raporu (mevcut durum)

### Tema state nerede tutuluyor
- **SettingsService** (`lib/core/services/settings_service.dart`): `getThemeModeIndex()` / `setThemeModeIndex(int)` ile SharedPreferences’ta kalıcılık. Key: `AppConstants.keyThemeMode`. Değer: **0 = system, 1 = light, 2 = dark**. Varsayılan: **2 (dark)**.
- **Riverpod** (`lib/core/providers/settings_provider.dart`):
  - `initialThemeModeIndexProvider`: Başlangıç değeri (main’de override edilir).
  - `themeModeIndexProvider`: StateNotifier ile index state; `setThemeModeIndex(index)` çağrılınca hem storage güncellenir hem state.
  - `themeModeProvider`: Index’ten türetilen `ThemeMode` (system/light/dark). `MaterialApp.themeMode` bu provider’dan beslenir.

### Root theme nasıl uygulanıyor
- **main.dart**: `MaterialApp.router(theme: AppTheme.light(), darkTheme: AppTheme.dark(), themeMode: ref.watch(themeModeProvider), ...)`. Builder içinde root arka plan `Theme.of(context).scaffoldBackgroundColor` ile dolduruluyor; RTL (Arapça) ve Shortcuts/Actions sarmalayıcıları var.
- **AppTheme** (`lib/core/theme/app_theme.dart`): İki statik metod — `light()` ve `dark()`. Her ikisi de `ThemeData` + **extensions: [AppThemeExtension.light()]** veya **AppThemeExtension.dark()** döndürüyor. Light tema artık inputDecorationTheme, elevatedButtonTheme, bottomNavigationBarTheme ile dark ile tam parite.

### Hardcoded renk kullanan ana dosyalar (düzeltilenler / kalanlar)
**Düzeltilen (token / theme kullanımına geçen):**
- `lib/core/theme/app_theme.dart` — light tema tamamlandı; extension eklendi.
- `lib/core/theme/app_theme_extension.dart` — **yeni**: semantic token’lar (background, surface, card, foreground, foregroundSecondary, foregroundMuted, border, input*, popover*, chartBackground, shadowColor, shimmerBase/Highlight).
- `lib/core/widgets/app_card.dart` — card/border/shadow → `AppThemeExtension.of(context)`.
- `lib/core/widgets/command_palette.dart` — arka plan, input, metin renkleri → extension.
- `lib/core/widgets/shimmer_placeholder.dart` — shimmer renkleri → extension.
- `lib/features/auth/presentation/widgets/auth_guard.dart` — scaffold ve metin/buton renkleri → `Theme.of(context).colorScheme` / scaffoldBackgroundColor.
- `lib/shared/widgets/empty_state.dart` — metin rengi → extension.foregroundSecondary.
- `lib/core/router/app_router.dart` — _RouteLoadingScreen, _ErrorFallbackScreen → theme.scaffoldBackgroundColor, colorScheme.onSurface, inputTextOnGold.
- `lib/screens/role_based_shell.dart` — _ShellLoading → theme.scaffoldBackgroundColor, colorScheme.onSurface.
- `lib/screens/placeholder_pages.dart` — ThemeSection / NotificationsSection border: `Colors.white10` → `DesignTokens.borderDark.withOpacity(0.5)`.
- `lib/features/listing_display/presentation/widgets/listing_display_settings_section.dart` — border → DesignTokens.
- `lib/features/war_room/presentation/pages/war_room_page.dart` — tab başlık rengi → colorScheme.onSurface.
- `lib/features/manager_command_center/presentation/pages/command_center_page.dart` — çağrı ikonu (on gold), hint rengi → inputTextOnGold, colorScheme.onSurface.
- `lib/screens/consultant_dashboard_page.dart` — Magic Call butonu foreground, Pipeline ikonu → inputTextOnGold.
- `lib/main.dart` — ErrorWidget metin rengi → DesignTokens.textPrimaryDark (error ekranı hâlâ koyu zemin; context yok).

**Kalan (ileride token’a taşınabilir):**
- `lib/features/contact_save/presentation/widgets/save_contact_sheet.dart` — çok sayıda Colors.white / white70 / black (modal/sheet).
- `lib/screens/listing_detail_page.dart` — hero/overlay metin ve ikonlar (beyaz tonları).
- `lib/features/calls/post_call_wizard.dart` — kart ve metin renkleri.
- `lib/features/calls/call_screen.dart` — arayüz yüzeyleri ve metin.
- `lib/widgets/bento_analytics.dart`, `bento_saha_radar.dart`, `bento_ai_news.dart`, `finance_bar.dart`, `master_ticker.dart`, `magic_call_button.dart` — çoğunlukla koyu palet sabit.
- `lib/features/ai_sales_assistant/presentation/widgets/ai_sales_assistant_panel.dart` — panel renkleri.
- `lib/features/crm_customers/presentation/pages/customer_detail_page.dart`, `customer_list_page.dart` — buton ve metin.
- `lib/features/auth/presentation/pages/role_selection_page.dart` — overlay metin.
- `lib/features/dashboard/presentation/widgets/welcome_patron_overlay.dart` — overlay metin.

### Light/dark/system bozukluğunun ana sebepleri
1. **Sabit DesignTokens**: Birçok widget doğrudan `DesignTokens.surfaceDark`, `textPrimaryDark`, `borderDark` kullanıyordu; tema light olsa bile bu renkler koyu kaldı.
2. **Light tema eksikti**: `AppTheme.light()` içinde inputDecorationTheme, elevatedButtonTheme, bottomNavigationBarTheme yoktu; Material varsayılanları ve kısmen dark token’lar karışıyordu.
3. **Colors.white / Colors.black**: Özellikle modallar, sheet’ler ve arama/çağrı ekranlarında sabit kullanım; tema değişince uyumsuzluk.
4. **System mode**: Kod tarafında zaten doğru — `ThemeMode.system` ve `themeModeProvider` kullanılıyor; Flutter `MediaQuery.platformBrightnessOf` ile sistemi izliyor. Sorun büyük ölçüde yukarıdaki sabit renklerden kaynaklanıyordu.

---

## 2. Refactor planı ve semantic token yapısı

### Merkezi tema yapısı
- **Tek ThemeData kaynağı**: `AppTheme.light()` ve `AppTheme.dark()`.
- **Semantic token’lar**: `ThemeExtension<AppThemeExtension>` ile `AppThemeExtension.light()` / `AppThemeExtension.dark()`. Bileşenler `AppThemeExtension.of(context)` ile erişir.
- **ThemeMode**: 0 = system, 1 = light, 2 = dark. MaterialApp.themeMode = ref.watch(themeModeProvider). System seçildiğinde cihaz teması Flutter tarafından otomatik izlenir.

### Semantic token listesi (AppThemeExtension)
| Token | Açıklama |
|-------|----------|
| background | Sayfa / scaffold arka planı |
| surface | Ana yüzey |
| surfaceElevated | Yükseltilmiş yüzey (kart üstü) |
| card | Kart arka planı |
| foreground | Ana metin |
| foregroundSecondary | İkincil metin |
| foregroundMuted | Placeholder / hint |
| border | Ana çizgi |
| borderSubdle | Hafif çizgi |
| inputBackground | Input/dropdown arka planı |
| inputForeground | Input metni |
| inputBorder | Input çerçevesi |
| popoverBackground | Modal/sheet/dropdown arka planı |
| popoverForeground | Popover metni |
| chartBackground | Grafik alanı |
| shadowColor | Gölge rengi |
| shimmerBase / shimmerHighlight | Shimmer placeholder |

### Kullanım kuralı
- Yeni bileşenler **doğrudan** `Colors.white`, `Colors.black`, `DesignTokens.textPrimaryDark` gibi sabitler kullanmamalı.
- Sayfa arka planı: `theme.scaffoldBackgroundColor` veya `ext.background`.
- Kart/yüzey: `ext.card` veya `ext.surface`.
- Metin: `ext.foreground`, `ext.foregroundSecondary`, `ext.foregroundMuted` veya `theme.colorScheme.onSurface` / `textTheme`.
- Buton (primary): `DesignTokens.primary` + `DesignTokens.inputTextOnGold` (zaten tema ile uyumlu).
- Border: `ext.border` veya `theme.dividerColor`.

---

## 3. Yapılan uygulama özeti

- **app_theme_extension.dart**: Eklendi; light/dark semantic token seti ve `of(context)`.
- **app_theme.dart**: Dark theme’e `extensions: [AppThemeExtension.dark()]`; light theme’e aynı extension + inputDecorationTheme, elevatedButtonTheme, bottomNavigationBarTheme, colorScheme.surface ve `extensions: [AppThemeExtension.light()]`.
- **app_card, command_palette, shimmer_placeholder, auth_guard, empty_state, app_router, role_based_shell, placeholder_pages, listing_display_settings_section, war_room_page, command_center_page, consultant_dashboard_page, main (ErrorWidget metin)**: Tema/extension veya colorScheme ile güncellendi.

---

## 4. Kontrol listesi

- [x] Light mode: AppTheme.light() tam; extension light token’ları kullanılıyor.
- [x] Dark mode: AppTheme.dark() + extension dark token’ları.
- [x] System mode: themeModeProvider ThemeMode.system döndürüyor; Flutter cihaz temasını izliyor.
- [x] Tema değiştirince: MaterialApp themeMode değişir; extension ve colorScheme güncellenir; güncellenen bileşenler doğru renk alır.
- [ ] Tüm ekranlar: save_contact_sheet, listing_detail_page, call_screen, post_call_wizard, bento* ve CRM/dashboard widget’ları ileride token’a taşınabilir (isteğe bağlı sonraki adım).

---

## 5. Son rapor

**Çözülen problemler:**
- Light tema eksikliği giderildi; light ve dark tema paritesi sağlandı.
- Semantic token (AppThemeExtension) eklendi; merkezi tek kaynak.
- Ortak bileşenler (app_card, command_palette, auth_guard, empty_state, shimmer, router loading/error, role_based_shell, placeholder theme/notifications, listing_display_settings, war_room tab, command_center, consultant_dashboard) tema/extension kullanıyor.
- System mode zaten doğru çalışıyordu; sabit renkler kaldırıldıkça tüm ekranlar system’de de doğru görünecek.

**Değiştirilen dosyalar:**
- `lib/core/theme/app_theme_extension.dart` (yeni)
- `lib/core/theme/app_theme.dart`
- `lib/core/widgets/app_card.dart`
- `lib/core/widgets/command_palette.dart`
- `lib/core/widgets/shimmer_placeholder.dart`
- `lib/features/auth/presentation/widgets/auth_guard.dart`
- `lib/shared/widgets/empty_state.dart`
- `lib/core/router/app_router.dart`
- `lib/screens/role_based_shell.dart`
- `lib/screens/placeholder_pages.dart`
- `lib/features/listing_display/presentation/widgets/listing_display_settings_section.dart`
- `lib/features/war_room/presentation/pages/war_room_page.dart`
- `lib/features/manager_command_center/presentation/pages/command_center_page.dart`
- `lib/screens/consultant_dashboard_page.dart`
- `lib/main.dart`

**Riskli / ileride ele alınabilecek alanlar:**
- save_contact_sheet, listing_detail_page, post_call_wizard, call_screen: Çok sayıda sabit renk; istenirse adım adım `AppThemeExtension.of(context)` ve `theme.colorScheme` ile değiştirilebilir.
- Bento ve dashboard widget’ları: Görsel olarak koyu tasarım tercihli; light modda da token kullanılırsa tutarlı olur.
- ErrorWidget (main.dart): Kök seviyede context olmadığı için hâlâ koyu zemin + DesignTokens; kabul edilebilir.

**Tema seçici (Light / Dark / System):**
- Ayarlar veya placeholder ThemeSection’da index 0/1/2 ile seçiliyor; `setThemeModeIndex` çağrılıyor. Seçim kalıcı (SharedPreferences) ve uygulama yeniden başlatıldığında korunuyor.
