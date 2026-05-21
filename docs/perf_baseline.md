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
| 2026-05-21 | profile | macOS (profile) | — | run_profile_timed_capture 90s; giriş yapılmadı — role_shell/dashboard bekleniyor |

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

- **2026-05-21 otomatik satır:** `capture_startup_baseline_automated.sh` (test binding). `bootstrap_parallel_done` / `run_app` burada 0 ms — gerçek Firebase bootstrap yalnızca profile’da ölçülür.
- **2026-05-21 profile satır (kısmi):** macOS `--profile` soğuk açılış — `first_frame` **45 ms**, bootstrap **37 ms**. Giriş yapılmadığı için `role_shell_*` ve dashboard satırları boş; tam baseline için `./scripts/capture_startup_baseline.sh` ile giriş yapıp dashboard’a gelin.
- **İlk macOS imza hatası:** `No profiles for com.uguraytekin.emlakmastermobile` → bir kez `xcodebuild … -allowProvisioningUpdates build` (script başında not var); sonrasında `flutter build macos --profile` çalışır.
- **Debug mod** kasıtlı yavaştır; karşılaştırma için yalnızca profile/release kullanın.
- `role_shell_*` süreleri Firestore / ağ gecikmesine bağlıdır; kod regresyonu için aynı Wi‑Fi ve hesapla tekrarlayın.
- Sekme geçişi jank için DevTools timeline + `docs/PERFORMANCE_PROFILING.md`.
