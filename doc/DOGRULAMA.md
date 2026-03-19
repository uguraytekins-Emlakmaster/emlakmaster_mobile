# Doğrulama (test / hata önleme)

## Tek komut (önerilen)

```bash
./scripts/dogrula_hepsi.sh
```

- `flutter pub get` + **analyze** (tüm proje) + **test** + **macOS debug build** + Firestore rules **dry-run**  
- macOS build uzun sürerse: `DOGRULA_SKIP_MACOS=1 ./scripts/dogrula_hepsi.sh`

## Ne garanti edilir?

| Kontrol | Anlamı |
|---------|--------|
| `flutter analyze` | Statik analiz; çoğu derleme hatası önceden yakalanır. |
| `flutter test` | Birim + widget testleri (giriş koruması, OAuth id formatı, izinler vb.). |
| `flutter build macos` | Native/macOS derlemesi geçer. |
| Firestore rules dry-run | Kurallar Firebase tarafında derlenir. |

## Garanti edilemeyenler

- Gerçek cihazda Google/Firebase oturumu (manuel veya cihaz testi).  
- App Store / Play imzalama ve mağaza politikaları.  
- İnternet kesintisi, Firebase kota aşımı, üçüncü taraf API değişiklikleri.

**Sürüm öncesi:** `dogrula_hepsi.sh` + kısa manuel smoke (giriş, bir müşteri kaydı).
