# Performans profili (DevTools)

Hızlı kontrol listesi — shell sekmesi veya büyük refactor sonrası.

## Soğuk açılış (ilk launch)

1. **Release/profile** ile ölçün; debug mod kasıtlı olarak yavaştır.
2. İlk ~0,5 sn: selamlama + arama / üst bar; kartlar **kademeli** gelir (`DeferredMountSection`).
3. Kabuk şeritleri (senkron, post-call) ~480 ms sonra (`StartupShellChrome`).
4. Pasif sekme Firestore dinlemez (`ShellLazyTab`).
5. Bootstrap: `userDocStreamHydrated` (önce `get`, sonra stream) + `ShellBootstrapSkeleton` — çift `_AuthShell` / “Panel hazırlanıyor” kaldırıldı.

`StartupMountSchedule` / `DeferredMountSection.*` — tüm mount gecikmeleri tek dosyada.

`main.dart`: `runApp` öncesi Firebase üst sınır ~4 sn, onboarding warmUp ~900 ms; tema diskten ilk kareden sonra.

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

## Debug konsol (geliştirme)

Debug build'de her ekran hazır olduğunda:

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
