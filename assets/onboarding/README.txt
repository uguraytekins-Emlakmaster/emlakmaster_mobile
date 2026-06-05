EMLAK MASTER — TANITIM (ONBOARDING) EKRAN GÖRÜNTÜLERİ
=====================================================

Bu klasör, giriş öncesi tanıtım slaytlarında gösterilen GERÇEK ekran
görüntülerini içerir. Görseller tema duyarlıdır: her slayt için aydınlık ve
karanlık tema dosyası ayrı verilir. Dosya yoksa veya bozuksa uygulama otomatik
olarak kodla çizilen premium "mockup" görseline güvenli şekilde döner
(OnboardingSlideVisual → _OnboardingScreenshotFrame.errorBuilder). Yani PNG'ler
eklenmeden de uygulama derlenir ve sorunsuz çalışır.

GEREKEN DOSYALAR (tam adlar)
----------------------------
  welcome_light.png      welcome_dark.png       (Karşılama / giriş alanı)
  manager_light.png      manager_dark.png       (Yönetici paneli / komuta)
  consultant_light.png   consultant_dark.png    (Benim Günüm — YENİ Quick Nav'lı hali)
  calls_light.png        calls_dark.png         (Akıllı Görüşme / çağrılar)
  market_light.png       market_dark.png        (Piyasa & portföy / ilanlar)
  office_light.png       office_dark.png        (Ofis & mesajlar)

Not: "multi_platform" slaytı tek bir gerçek ekran olmadığından (çoklu cihaz
soyutlaması) ekran görüntüsü beklemez; kod kompozisyonu korunur.

ÇEKİM TALİMATI
--------------
1. Uygulamayı çalıştırın (kök: emlakmaster_mobile):
     scripts/run_with_shield.sh        (macOS)
   veya bir iPhone simülatöründe çalıştırın (önerilir; gerçek mobil çerçeve).
2. Aydınlık temada ilgili 6 ekrana tek tek gidin, tam ekran görüntü alın:
     - iOS Simulator: Cmd+S (Save Screen) → ~/Desktop
     - macOS app penceresi: Cmd+Shift+4 sonra Space ile pencere yakalama
3. Ayarlar → Görünüm → temayı KARANLIK yapıp aynı 6 ekranı tekrar yakalayın.
4. Dosyaları yukarıdaki tam adlarla bu klasöre (assets/onboarding/) koyun.
5. `flutter pub get` (veya scripts/pub_get_with_fix.sh) çalıştırın; pubspec'te
   `assets/onboarding/` zaten kayıtlıdır. Uygulamayı yeniden başlatın.

ÖNERİ (kalite)
--------------
- Dikey (portrait) tam ekran yakalayın; çerçeve BoxFit.cover ile üstten hizalar.
- Durum çubuğu temiz görünsün (bildirim yığını olmadan).
- Aynı cihaz/çözünürlükte tutarlı oran kullanın (ör. iPhone 15/16 simülatörü).

Arşiv / eski kaynaklar: assets/archive/onboarding/
