# Sürüm öncesi — mühendislik / Firebase / mağaza (kısa)

Yasal veya mağaza onayı yerine geçmez; teknik ve süreç hatırlatmasıdır.

## 1. Repo ve kimlik (otomatik)

Proje kökünde:

```bash
bash scripts/verify_firebase_identity.sh
```

CI’da da çalışır (`.github/workflows/ci.yml`). Hata varsa push etme.

## 2. iOS — imza, archive, Crashlytics

1. `open ios/Runner.xcworkspace`
2. **Signing & Capabilities:** `com.uguraytekin.emlakmastermobile`, doğru **Team**
3. **Product → Archive** (Release)
4. Organizer’da arşivi aç → **Build** logunda **Firebase Crashlytics** `run` satırının çalıştığını doğrula
5. Firebase Console → **Crashlytics** / **dSYMs:** bu sürüm için sembol işlendi mi (bir süre sonra)

## 3. macOS — bundle değişikliğinden sonra imza

Yeni bundle id için Apple’ın **Mac Development** profilini ilk kez oluşturması gerekir:

1. `open macos/Runner.xcworkspace`
2. **Runner** → **Signing & Capabilities** → **Team** seçili, **Automatically manage signing** açık olsun
3. **Product → Build** (Release veya Debug); hata olursa Xcode önerilen “Fix Issue” / hesap yenileme
4. Ardından: **Product → Archive** (dağıtım hedefin varsa) veya `flutter build macos --release` (aynı hesap / takım ile)

Crashlytics: Release archive sonrası Firebase’de macOS uygulaması için (projede iOS ile aynı `GOOGLE_APP_ID` kullanılıyorsa) olayların ve dSYM’lerin düştüğünü kontrol et.

## 4. Duman testi (cihaz / sürüm adayı)

- [ ] Uygulama açılışı (çökme yok)
- [ ] E-posta / şifre giriş
- [ ] **Google ile giriş** (iOS’ta test edildiysen bir kez **macOS** da)
- [ ] Çıkış
- [ ] Kritik bir iş akışı (ör. ana liste veya günlük kullandığın bir ekran)

## 5. App Store Connect — Gizlilik (Privacy)

- [ ] **App Privacy** sorularında toplanan veri türleri (ör. Crashlytics, Analytics, Auth, iletişim) güncel mi?
- [ ] Üçüncü taraf SDK’lar (Firebase vb.) için doğru kategoriler seçildi mi?
- [ ] Metinler hukuk / iş ekibinle uyumlu mu (bu dosya hukuki tavsiye değildir).

## 6. Bağımlılıklar

- GitHub **Dependabot** PR’larını (`pub`) haftalık gözden geçir; breaking change’leri `CHANGELOG` / sürüm notu ile eşle.
- İstersen yerelde: `flutter pub outdated`

## 7. Firebase / Google Console (manuel)

- Google Cloud **Credentials:** iOS OAuth Bundle ID = `com.uguraytekin.emlakmastermobile`
- **Firebase** proje ayarları: iOS (ve macOS kullanımı) uygulama kimliği ile yüklenen plist’ler tutarlı mı?

## 8. FlutterFire’ı yeniden üretmek (yedek akış)

Yeni Firebase uygulaması veya `GOOGLE_APP_ID` değişirse `scripts/terminal_firebase_kurulum.sh` içindeki `flutterfire configure` örneğini güncelleyip çalıştır; ardından plist/json ve `lib/firebase_options.dart` diff’ini gözden geçir.
