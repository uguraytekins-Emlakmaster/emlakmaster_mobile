# Performans profili (DevTools)

Hızlı kontrol listesi — shell sekmesi veya büyük refactor sonrası.

## Hazırlık

1. Release/profile modda değil, **profile mode** ile çalıştır: `flutter run --profile`
2. DevTools → **Performance** → Record
3. Sekme değiştir: Özet → Mesajlar → Çağrılar → Müşteriler → Görevler → İlanlar

## Bakılacaklar

| Metrik | Hedef |
|--------|--------|
| Frame build | Çoğu kare **&lt; 16 ms** (60 fps) |
| Jank (kırmızı çubuk) | Sekme geçişinde **0–1** kısa spike |
| `screen_content_ready` (Analytics) | İlk içerik **&lt; 800 ms** (ağ koşuluna bağlı) |

Kayıtlı ekran adları: `consultant_dashboard`, `admin_dashboard`, `messages`, `tasks`, `listings`, `consultant_calls`, `customer_list`, `customer_detail`, `command_center`, `war_room`, `admin_reports`, `pipeline`, `notifications_center`.

## Bilinen iyi kalıplar

- Liste: `SliverList` / `ListView.builder`, satırda `ref.watch` yok
- Veri: `*DisplayProvider` (stale-while-revalidate)
- Dashboard widget: `StreamProvider` + tek `ref.watch`, iç içe `StreamBuilder` yok

## Sorun görürsen

1. Performance timeline’da en uzun `build` widget’ını not et
2. İlgili ekranda `ShellScreenReadyListener` süresine bak
3. `.cursor/rules/emlakmaster-performance.mdc` ile uyumu kontrol et
