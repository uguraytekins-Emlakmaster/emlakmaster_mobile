# Performans baseline (elle doldurun)

Her büyük perf değişikliğinden sonra **profile** modda, uygulama **tamamen kapalıyken** bir kez ölçün.

```bash
chmod +x scripts/capture_startup_baseline.sh
./scripts/capture_startup_baseline.sh
```

Terminal filtresi: `[Perf]`

## Kayıt şablonu

| Tarih | Mod | Cihaz | Rol | Not |
|-------|-----|-------|-----|-----|
| 2026-05-21 | automated test | macOS (automated test) | — | CAPTURE_STARTUP_PERF; profile macOS için capture_startup_baseline.sh |
| YYYY-MM-DD | profile | macOS … | consultant / admin | |

### Startup milestone (`elapsed_ms` = main()'den itibaren)

| name | ms | Hedef (yönlendirici) |
|---|---|---|
| main_entered | 0 | 0 |
| bootstrap_parallel_done | 0 | < 4500 |
| run_app | 0 | < 5000 |
| first_frame | 113 | < 5500 |
| role_shell_interactive |  | ağa bağlı |
| role_shell_resolved |  | ağa bağlı |

### İlk ekran (`screen_content_ready`)

| screen | ms | items |
|--------|-----|-------|
| consultant_dashboard / admin_dashboard | | |
| consultant_calls | | |
| customer_list | | |

### Ham log (yapıştırın)

```text
[Perf] startup_milestone name=main_entered elapsed_ms=0
[Perf] startup_milestone name=bootstrap_parallel_done elapsed_ms=0
[Perf] startup_milestone name=run_app elapsed_ms=0
[Perf] startup_milestone name=first_frame elapsed_ms=113
```

## Yorum

- **2026-05-21 otomatik satır:** `capture_startup_baseline_automated.sh` (test binding). `role_shell_*` ve dashboard süreleri için Xcode’da giriş yapılı **profile** ölçümü gerekir (`capture_startup_baseline.sh`). Bu ortamda macOS build imza hatası: `No profiles for com.uguraytekin.emlakmastermobile`.
- **Debug mod** kasıtlı yavaştır; karşılaştırma için yalnızca profile/release kullanın.
- `role_shell_*` süreleri Firestore / ağ gecikmesine bağlıdır; kod regresyonu için aynı Wi‑Fi ve hesapla tekrarlayın.
- Sekme geçişi jank için DevTools timeline + `docs/PERFORMANCE_PROFILING.md`.
