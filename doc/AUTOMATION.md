# Terminal ile otomasyon (tam yetki = bu komutlar)

Bu dosya, “benim yapamadığım” ile **terminalden gerçekten yapılabilen** işleri ayırır.

## Her zaman (CI / Cursor / yerel makine)

| Komut | Ne işe yarar |
|--------|----------------|
| `flutter test` | Tüm birim / widget testleri |
| `dart analyze` | Dart tarafı statik analiz |
| `flutter build ios --no-codesign` | iOS derlemesinin derleniyor olduğunu doğrular |
| `bash scripts/analyze_ios_build_warnings.sh` | **Xcode + Pods** derleme çıktısından uyarıları sayar ve özetler (birkaç dk sürebilir) |

## Cihaz USB ile bağlıyken (aynı makinede)

| Komut | Ne işe yarar |
|--------|----------------|
| `flutter devices` | Bağlı cihaz ID |
| `flutter run -d <DEVICE_ID>` | Uygulamayı kurar, debug bağlar — **otomatik başlatma** |
| `xcrun devicectl device process launch --device <ID> <bundleId>` | Sadece uygulamayı açar |

Bunlar **fiziksel dokunuşun yerine geçmez**; ama “uygulamayı çalıştır / yeniden kur” adımını terminalden yapar.

## Gerçekten “parmak” gerektiren şeyler

- Apple’ın **Face ID / şifre** ile onayladığı işlemler, **sistem izin** diyalogları (bazıları).
- **Görsel olarak** “bu buton doğru yerde mi?” kontrolü (insan gözü).

Bunlar için seçenekler:

1. **Sen** kısa bir checklist ile işaretlersin (`doc/QA_CHECKLIST.md`).
2. İleride projeye **`integration_test`** veya **Patrol** eklenirse, test senaryoları da `flutter test integration_test` ile terminalden koşturulabilir (yazılması gerekir).

## Xcode’daki 4000+ uyarı

- Bunların çoğu **Pods / Clang / eski API** uyarılarıdır; tek tek “elle” Xcode’da tıklamak şart değildir.
- Özet için: `bash scripts/analyze_ios_build_warnings.sh` (derleme logundan sayım ve dosya ipuçları).
- Uygulama Dart kodu için **asıl kaynak**: `dart analyze` (Flutter ekibi bunu önerir).

## Instruments (Time Profiler vb.)

- Arayüz: Xcode → Product → Profile.
- Komut satırı: `xcrun xctrace` (Xcode sürümüne göre şablonlar değişir). İlk kurulumda Apple dokümantasyonuna bakın; bu repoda varsayılan bir trace betiği yoktur.
