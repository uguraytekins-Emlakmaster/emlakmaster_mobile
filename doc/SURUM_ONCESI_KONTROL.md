# Sürüm / dağıtım öncesi kontrol listesi

**Mühendislik + Firebase + mağaza gizlilik:** `doc/PER_RELEASE_ENGINEERING_CHECKLIST.md` (kimlik script’i, iOS/macOS archive + Crashlytics, duman testi, App Privacy, Dependabot).

Otomatik (makinede):

```bash
cd emlakmaster_mobile
bash scripts/verify_firebase_identity.sh
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
