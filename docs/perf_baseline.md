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
| 2026-05-19 | profile | macOS (ölçüm bekleniyor) | — | Asset bundle küçültme sonrası ilk baseline |
| YYYY-MM-DD | profile | macOS … | consultant / admin | |

### Startup milestone (`elapsed_ms` = main()’den itibaren)

| name | ms | Hedef (yönlendirici) |
|------|-----|----------------------|
| main_entered | | 0 |
| bootstrap_parallel_done | | &lt; 4500 |
| run_app | | &lt; 5000 |
| first_frame | | &lt; 5500 |
| role_shell_interactive | | ağa bağlı |
| role_shell_resolved | | ağa bağlı |

### İlk ekran (`screen_content_ready`)

| screen | ms | items |
|--------|-----|-------|
| consultant_dashboard / admin_dashboard | | |
| consultant_calls | | |
| customer_list | | |

### Ham log (yapıştırın)

```text
[Perf] startup_milestone name=main_entered elapsed_ms=...
...
```

## Yorum

- **Debug mod** kasıtlı yavaştır; karşılaştırma için yalnızca profile/release kullanın.
- `role_shell_*` süreleri Firestore / ağ gecikmesine bağlıdır; kod regresyonu için aynı Wi‑Fi ve hesapla tekrarlayın.
- Sekme geçişi jank için DevTools timeline + `docs/PERFORMANCE_PROFILING.md`.
