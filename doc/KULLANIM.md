# Uygulamayı Sorunsuz Kullanmak

Bu sayfa, uygulamayı açıp günlük kullanım için **tek seferde** yapmanız gerekenleri özetler. Bunlar tamamlandıysa sadece uygulamayı açıp kullanabilirsiniz.

---

## Tek seferlik (kurulum / yönetici)

1. **Firebase Console**
   - [Firebase Console](https://console.firebase.google.com) → proje **emlak-master**
   - **Authentication → Sign-in method:** **E-posta/Şifre** ve (isteğe bağlı) **Google** açık olsun.
   - **Firestore:** Kurallar güncellendiyse: `firebase deploy --only firestore:rules` (veya `scripts/deploy_firestore_rules.sh`).

2. **Google ile giriş (isteğe bağlı)**
   - iOS/Android için OAuth client’lar ve Web client ID zaten projede yapılandırıldı. Ekstra bir şey yapmanız gerekmez; sadece Console’da Google provider’ın açık olduğundan emin olun.

3. **Cihazda uygulama**
   - **iOS:** İlk açılışta “Güvenilmez Geliştirici” uyarısı çıkarsa: Ayarlar → Genel → VPN ve Cihaz Yönetimi → geliştirici uygulamasına güvenin.
   - **Android:** Gerekli izinleri (bildirim, kamera, mikrofon vb.) uygulama ilk kullanımda isteyecektir; onaylayın.

---

## Günlük kullanım

- Uygulamayı açın → İlk açılışta tanıtım (onboarding) bir kez gösterilir, **Başla** ile geçilir; bir daha çıkmaz.
- Giriş yapın (e-posta/şifre veya Google) → Rol seçimi (ilk kez) veya doğrudan panele gidersiniz.
- Şifremi unuttum: E-posta girin; sıfırlama bağlantısı (ve spam klasörü) kontrol edin.
- Sorun olursa: [AUTH_AND_ROLES.md](AUTH_AND_ROLES.md) ve [PLATFORMS.md](PLATFORMS.md) dosyalarına bakın.

Bu adımlar tamamsa **uygulamayı sorunsuz kullanmak** için ekstra bir işlem gerekmez.
