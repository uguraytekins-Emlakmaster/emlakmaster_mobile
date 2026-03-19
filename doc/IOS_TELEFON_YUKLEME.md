# iPhone’a kabloyla yükleme

## Hızlı komut (temiz derleme dahil)

Proje kökünde:

```bash
./scripts/iphone_kablo_yukle.sh
```

Temizlik atlamak için: `./scripts/iphone_kablo_yukle.sh --quick`

Terminal `flutter run` imzada takılırsa script **Xcode’u açar**; aşağıdaki hesap / imza adımlarını bir kez yapın.

## 1. Xcode’da Apple hesabını yenile (zorunlu)

Hata: *Unable to log in with account … login details were rejected.*

1. **Xcode** → **Settings** (veya **Preferences**) → **Accounts**
2. Sol altta **+** → **Apple ID** ile `aytekinugi@gmail.com` ekle **veya** mevcut hesabı seç → **Sign in again** / şifreyi güncelle
3. İki adımlı doğrulama açıksa Apple’ın istediği kodu gir

Hata: *No Account for Team "Q885JNUR54"* veya *No profiles for 'com.example.emlakmasterMobile' were found*

- **Xcode** → **Settings** → **Accounts** → sol altta **+** → **Apple ID** ile giriş (genelde `aytekinugi@gmail.com`)
- Hesabı seç → sağda **Teams** altında **Apple Development** takımının göründüğünü doğrula
- Ardından aşağıdaki **Signing** adımını yapıp **Product → Build** çalıştır

## 2. İmzayı bir kez Xcode’da doğrula (önerilir)

1. `open ios/Runner.xcworkspace`
2. Sol üstten **Runner** projesi → **Runner** target → **Signing & Capabilities**
3. **Team:** kişisel takımını seç (Apple Development hesabınız; projede `DEVELOPMENT_TEAM` ile eşleşmeli)
4. Üst menüden **Product → Build** (ilk build profil oluşturur)

## 3. Telefona yükle

Kabloyu takılı tut, sonra terminalde:

```bash
cd /path/to/emlakmaster_mobile
flutter devices   # iPhone görünmeli
flutter run --release -d <iPhone_ID>
```

veya:

```bash
./scripts/iphone_kablo_yukle.sh
```

**Not:** `com.example.emlakmasterMobile` Firebase ile kayıtlı; bundle ID’yi değiştirirsen `GoogleService-Info.plist` / Firebase’i de güncellemen gerekir.
