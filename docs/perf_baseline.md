# Performans baseline

## Hızlı komutlar

| Amaç | Komut |
|------|--------|
| CI / PR regresyon | `./scripts/verify_startup_perf.sh` |
| Otomatik milestone (imza yok) | `./scripts/capture_startup_baseline_automated.sh` |
| macOS profile soğuk açılış | `./scripts/capture_startup_baseline.sh` |
| Tam baseline (imza + giriş + dashboard) | `./scripts/capture_startup_baseline_full.sh` |
| Süre sınırlı profile (agent) | `CAPTURE_DURATION_SEC=120 ./scripts/run_profile_timed_capture.sh` |
| Eşik kontrolü (log) | `python3 scripts/check_perf_thresholds.py docs/perf_logs/….log --mode profile` |
| Bundle boyutu | `./scripts/check_macos_bundle_size.sh` |

Eşikler: `scripts/perf_thresholds.json`

Terminal filtresi: `[Perf]`

## Kayıt şablonu

| Tarih | Mod | Cihaz | Rol | Not |
|-------|-----|-------|-----|-----|
| 2026-05-21 | automated test | macOS (automated test) | — | CAPTURE_STARTUP_PERF; profile macOS için capture_startup_baseline.sh |
| 2026-05-21 | profile | macOS (profile) | — | run_profile_timed_capture 90s; giriş yapılmadı — role_shell/dashboard bekleniyor |
| YYYY-MM-DD | profile (tam) | macOS … | consultant / admin | capture_startup_baseline_full.sh — giriş + dashboard |

### Startup milestone (`elapsed_ms` = main()'den itibaren)

| name | ms | Hedef (yönlendirici) |
|---|---|---|
| main_entered | 0 | 0 |
| bootstrap_parallel_done | 37 | < 4500 |
| run_app | 37 | < 5000 |
| first_frame | 45 | < 5500 |
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
flutter: [Perf] startup_milestone name=main_entered elapsed_ms=0
flutter: [Perf] startup_milestone name=bootstrap_parallel_done elapsed_ms=37
flutter: [Perf] startup_milestone name=run_app elapsed_ms=37
flutter: [Perf] startup_milestone name=first_frame elapsed_ms=45
```

## Yorum

- **Otomatik satır:** test binding; `bootstrap`/`run_app` burada 0 ms olabilir — gerçek Firebase yalnızca profile’da.
- **Profile (kısmi):** soğuk açılış `first_frame` **45 ms**; tam kayıt için `capture_startup_baseline_full.sh` ile giriş + dashboard.
- **CI:** `verify_startup_perf.sh` — `first_frame` ≤ 250 ms (automated).
- **İmza:** `ensure_macos_profile_signing.sh` veya Xcode Team + `-allowProvisioningUpdates`.
- **Debug mod** karşılaştırma için kullanılmaz; yalnızca profile/release.
- Sekme jank: `docs/PERFORMANCE_PROFILING.md`.
