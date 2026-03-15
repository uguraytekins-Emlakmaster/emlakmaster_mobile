# Koruma kalkanı (Shield)

Proje genelinde **tüm dosyalara** ve **olumsuz senaryolara** karşı kendini onaran sistem. Amaç: sürekli sorun çıkmasın, bakım azalsın, proje kendi kendini onarsın.

## Ne yapar?

- **00** — Tüm `.sh` script'lerini çalıştırılabilir yapar (izin kaybı / taşıma sonrası).
- **01** — Flutter sağlığı: `pubspec.lock`, `.dart_tool`, `ios/Flutter/Generated.xcconfig`; eksikse `flutter pub get` (gerekirse `flutter clean`).
- **02** — iOS: `GeneratedPluginRegistrant.m` içinde Firebase Core'u ilk sıraya alır (duplicate-app crash önlemi).
- **03** — iOS: Pods senkron; `Pods` yoksa veya `Podfile` daha yeniyse `pod install`.
- **04** — Android: Kritik dosyalar ve `gradlew` izni.
- **05** — Dart: `dart fix --apply` ile güvenli analiz düzeltmeleri.
- **06** — Kritik dosya varlığı: `pubspec.yaml`, `lib/main.dart`; eksikse uyarı.
- **07** — Üretilmiş dosyalar: `.flutter-plugins`, `package_config.json`; yoksa `flutter pub get`.
- **08** — Opsiyonel: `.env` yoksa (`.env.example` varsa) bilgi mesajı.
- **09** — iOS: Firebase kullanılıyorsa `GoogleService-Info.plist` uyarısı.
- **10** — (Rezerve) İleride eklenebilecek hafif temizlik.

## Nasıl çalıştırılır?

```bash
# Tüm kalkanı çalıştır (proje kökünden veya herhangi bir yerden)
./scripts/shield/shield.sh

# Sessiz mod (sadece hata/uyarı)
./scripts/shield/shield.sh --quiet

# Tek fixer
./scripts/shield/shield.sh 02_ios_plugin_order
```

## Ne zaman otomatik çalışır?

1. **iOS build** — Xcode "Fix iOS plugin order" phase her build'de plugin sırasını düzeltir (sadece 02).
2. **Pub get + kalkan** — `./scripts/pub_get_with_fix.sh` = `flutter pub get` + tüm shield.
3. **Run / build wrapper** — `./scripts/run_with_shield.sh`, `./scripts/build_with_shield.sh` önce shield sonra flutter.
4. **Git** — Hooks kurulduysa: `post-merge` (pull sonrası shield), `pre-commit` (script izinleri). Kurulum: `./scripts/shield/install_git_hooks.sh`.

## Yeni fixer ekleme

`scripts/shield/fixers/` altına `11_adi.sh`, `12_adi.sh` ... ekleyin. Numara sırasına göre çalışır. İçinde `source "$(dirname "$0")/../config.sh"` ile `PROJECT_ROOT` kullanın.

## Kurallar

- Fixer'lar **idempotent** olmalı: birden fazla çalıştırmak zararsız.
- Kritik değişiklik yapmadan önce **uyarı** verin; gerekiyorsa **çıkış kodu 0** ile devam edin (shield durmasın).
- Yeni olumsuz senaryo düşündükçe yeni fixer ekleyebilirsiniz.
