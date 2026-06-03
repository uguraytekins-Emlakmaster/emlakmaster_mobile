/// Yasal & destek bağlantıları — mağaza (App Store / Play) için zorunlu.
///
/// Değerler boş bırakıldığında ilgili satır Ayarlar > "Yasal & Destek" altında
/// **gösterilmez** (asla ölü/çalışmayan link gösterilmez). Yayından önce gerçek
/// URL ve destek e-postasını doldurun.
abstract final class LegalLinks {
  LegalLinks._();

  /// Gizlilik Politikası tam URL'si (https://...). Mağaza zorunluluğu.
  static const String privacyPolicyUrl =
      String.fromEnvironment('EM_PRIVACY_URL');

  /// Kullanım Şartları tam URL'si (https://...).
  static const String termsOfServiceUrl =
      String.fromEnvironment('EM_TERMS_URL');

  /// Destek / yardım e-postası (mailto için, yalnızca adres — "mailto:" eklemeyin).
  /// Varsayılan gerçek adrestir; istenirse build'de `--dart-define=EM_SUPPORT_EMAIL=...`
  /// ile geçersiz kılınabilir.
  static const String supportEmail = String.fromEnvironment(
    'EM_SUPPORT_EMAIL',
    defaultValue: 'uguraytekin@protonmail.com',
  );

  /// Opsiyonel: web sitesi / yardım merkezi URL'si.
  static const String supportWebsiteUrl =
      String.fromEnvironment('EM_SUPPORT_URL');

  static bool get hasPrivacyPolicy => privacyPolicyUrl.trim().isNotEmpty;
  static bool get hasTermsOfService => termsOfServiceUrl.trim().isNotEmpty;
  static bool get hasSupportEmail => supportEmail.trim().isNotEmpty;
  static bool get hasSupportWebsite => supportWebsiteUrl.trim().isNotEmpty;

  /// "Yasal & Destek" bölümünün gösterilmesi için en az bir bağlantı gerekir
  /// (lisanslar her zaman gösterilir, bu yüzden bölüm de her zaman görünür).
  static bool get hasAnyLink =>
      hasPrivacyPolicy ||
      hasTermsOfService ||
      hasSupportEmail ||
      hasSupportWebsite;
}
