# Performans profili (DevTools)

Hızlı kontrol listesi — shell sekmesi veya büyük refactor sonrası.

## Soğuk açılış (ilk launch)

1. **Release/profile** ile ölçün; debug mod kasıtlı olarak yavaştır.
2. Baseline kaydı:
   - **macOS profile (tercih):** `./scripts/capture_startup_baseline.sh` → log `docs/perf_logs/startup_*_profile.log`
   - **Otomatik (imza yok / CI):** `./scripts/capture_startup_baseline_automated.sh` → `docs/perf_baseline.md` güncellenir
   - Eski log özeti: `./scripts/parse_perf_log.sh docs/perf_logs/….log`
3. Konsol kilometre taşları (profile’da da görünür):

   ```text
   [Perf] startup_milestone name=main_entered elapsed_ms=...
   [Perf] startup_milestone name=bootstrap_parallel_done elapsed_ms=...
   [Perf] startup_milestone name=run_app elapsed_ms=...
   [Perf] startup_milestone name=first_frame elapsed_ms=...
   [Perf] startup_milestone name=role_shell_interactive elapsed_ms=...
   [Perf] startup_milestone name=role_shell_resolved elapsed_ms=...
   [Perf] screen_content_ready screen=consultant_dashboard 412ms items=...
   ```

4. İlk ~0,5 sn: selamlama + arama / üst bar; kartlar **kademeli** gelir (`DeferredMountSection`).
5. Kabuk şeritleri (senkron, post-call) ~480 ms sonra (`StartupShellChrome`).
6. Pasif sekme Firestore dinlemez (`ShellLazyTab`).
7. Bootstrap: `userDocStreamHydrated` (önce `get`, sonra stream) + `ShellBootstrapSkeleton` — çift `_AuthShell` / “Panel hazırlanıyor” kaldırıldı.

`StartupMountSchedule` / `DeferredMountSection.*` — tüm mount gecikmeleri tek dosyada.

`main.dart`: `runApp` öncesi Firebase üst sınır ~4 sn, onboarding warmUp ~900 ms; tema diskten ilk kareden sonra.

**Firebase Analytics (profile/release):** `startup_milestone` (`milestone`, `duration_ms`) — konsol olmadan karşılaştırma için.

## Otomatik başlatma (macOS)

```bash
cd emlakmaster_mobile
chmod +x scripts/run_profile_perf.sh
./scripts/run_profile_perf.sh
```

Shield kullanıyorsanız `run_with_shield.sh` üzerinden profile modda açar.

## Hazırlık (manuel)

1. **Profile mode** ile çalıştır: `flutter run --profile` veya script yukarıdaki
2. DevTools → **Performance** → Record
3. Sekme değiştir: Özet → Mesajlar → Çağrılar → Müşteriler → Görevler → İlanlar

## Bakılacaklar

| Metrik | Hedef |
|--------|--------|
| Frame build | Çoğu kare **&lt; 16 ms** (60 fps) |
| Jank (kırmızı çubuk) | Sekme geçişinde **0–1** kısa spike |
| `screen_content_ready` (Analytics) | İlk içerik **&lt; 800 ms** (ağ koşuluna bağlı) |

## Konsol (debug + profile)

Debug ve **profile** build'de her ekran hazır olduğunda:

```text
[Perf] screen_content_ready screen=consultant_calls 412ms items=24
```

Xcode / VS Code **Debug Console** veya terminal çıktısında filtre: `Perf`

## Kayıtlı ekran adları

`consultant_dashboard`, `admin_dashboard`, `messages`, `tasks`, `listings`, `consultant_calls`, `customer_list`, `customer_detail`, `command_center`, `war_room`, `admin_reports`, `pipeline`, `notifications_center`, `follow_up`

## Sekme ön-yükleme

İlk kez bir sekmeye geçildiğinde `prefetchShellTab` ilgili Riverpod stream'lerini erken başlatır (stale-while-revalidate ile birlikte daha akıcı his).

## Bilinen iyi kalıplar

- Liste: `SliverList` / `ListView.builder`, satırda `ref.watch` yok
- Veri: `*DisplayProvider` (stale-while-revalidate)
- Dashboard widget: `StreamProvider` + tek `ref.watch`, iç içe `StreamBuilder` yok
- `lib/` içinde canlı `StreamBuilder` kullanılmaz

## Sorun görürsen

1. Performance timeline'da en uzun `build` widget'ını not et
2. `[Perf]` veya Firebase `screen_content_ready` süresine bak
3. `.cursor/rules/emlakmaster-performance.mdc` ile uyumu kontrol et

## Regresyon

```bash
flutter test
flutter analyze lib/core/performance lib/core/layout/adaptive_shell_scaffold.dart
```
