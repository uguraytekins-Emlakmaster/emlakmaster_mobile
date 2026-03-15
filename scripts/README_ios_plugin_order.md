# iOS: Firebase plugin sırası (koruma kalkanı)

## Sorun

`flutter pub get` veya `flutter clean` sonrası `ios/Runner/GeneratedPluginRegistrant.m` yeniden üretilir. Varsayılan sırada **Firebase Core**, Firestore/Auth’tan sonra kaydedildiği için uygulama açılışta **duplicate-app** crash’i verir.

## Otomatik koruma

- **Her iOS build’de** (Xcode veya `flutter run`) Runner target’ın ilk build phase’i olan **"Fix iOS plugin order"** çalışır.
- Bu script `GeneratedPluginRegistrant.m` içinde **FLTFirebaseCorePlugin** kaydını ilk sıraya alır (idempotent).
- Yani `flutter clean && flutter pub get` yapsanız bile bir sonraki build’de dosya otomatik düzelir; ekstra bir şey yapmanız gerekmez.

## Manuel çalıştırma

İsterseniz script’i elle de çalıştırabilirsiniz:

```bash
./scripts/fix_ios_plugin_order.sh
# veya belirli bir dosya için:
./scripts/fix_ios_plugin_order.sh ios/Runner/GeneratedPluginRegistrant.m
```

## Teknik

- Script: `scripts/fix_ios_plugin_order.sh`
- Xcode: Runner target → Build Phases → "Fix iOS plugin order (Firebase Core first)" (en üstte)
- Genel kalkan: `scripts/shield/shield.sh` da bu düzeltmeyi (02_ios_plugin_order) içerir. Tüm kalkan için bkz. `scripts/shield/README.md`.
