# Sürüm / dağıtım öncesi kontrol listesi

Otomatik (makinede):

```bash
cd emlakmaster_mobile
./scripts/dogrula_hepsi.sh
flutter build ios --release   # imza için Xcode gerekir
```

Manuel (telefon):

- [ ] Uygulamayı kapatıp aç: açılıyor, çökme yok
- [ ] E-posta/şifre giriş
- [ ] Google ile giriş
- [ ] Çıkış

App Store / TestFlight (senin Apple hesabın):

- [ ] Xcode: **Product → Archive** → Organizer → **Distribute App**
- [ ] Bundle ID üretim için değişecekse: Firebase + `GoogleService-Info.plist` / `google-services.json` güncelle

Notlar:

- Facebook native SDK kaldırıldı (sahte token ile iOS SIGABRT önlemi); tekrar açmak için `doc/FACEBOOK_SIGNIN_SETUP.md`
- iOS **UIScene** manifest + `SceneDelegate` eklendi (Flutter 3.41 / gelecek iOS sürümleri)
