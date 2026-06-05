import 'package:emlakmaster_mobile/core/config/legal_links.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';

/// Hangi yasal belge gösterilecek.
enum LegalDocKind { privacy, terms }

/// Uygulama içi yasal belge görüntüleyici.
///
/// Mağaza (App Store / Play) gizlilik politikası ve kullanım şartlarının
/// uygulamadan erişilebilir olmasını ister. Harici URL barındırma zorunluluğunu
/// ortadan kaldırmak için belge metni uygulama içinde gösterilir. Harici bir URL
/// tanımlandıysa Ayarlar ekranı bunun yerine o URL'yi açar.
///
/// Not: Bu metin sağlam bir **temel** şablondur; yayından önce hukuk danışmanınca
/// gözden geçirilmesi önerilir. İçerik, uygulamanın gerçek veri işleme
/// uygulamalarına (Firebase kimlik doğrulama, Firestore CRM verisi, çağrı
/// üst verisi, bildirimler, analitik) göre yazılmıştır.
class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({super.key, required this.kind});

  final LegalDocKind kind;

  static const String _effectiveDate = 'Haziran 2026';

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final isPrivacy = kind == LegalDocKind.privacy;
    final title = isPrivacy ? 'Gizlilik Politikası' : 'Kullanım Şartları';
    final sections = isPrivacy ? _privacySections() : _termsSections();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: AppBackButton(onPressed: () => Navigator.of(context).maybePop()),
        title: Text(title),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space5,
            DesignTokens.space4,
            DesignTokens.space5,
            DesignTokens.space8,
          ),
          children: [
            Text(
              '${AppConstants.appName} · $title',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Yürürlük tarihi: $_effectiveDate',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ext.textTertiary,
                  ),
            ),
            const SizedBox(height: DesignTokens.space5),
            for (final s in sections) ...[
              Text(
                s.$1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: DesignTokens.space2),
              Text(
                s.$2,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ext.textSecondary,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: DesignTokens.space5),
            ],
            if (LegalLinks.hasSupportEmail)
              Text(
                'İletişim: ${LegalLinks.supportEmail}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ext.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  List<(String, String)> _privacySections() => const [
        (
          '1. Topladığımız Veriler',
          'Hesap bilgileri (ad, e-posta), kullandığınız müşteri ilişkileri yönetimi '
              '(CRM) verileri (müşteri/danışan kayıtları, notlar, görevler, satış '
              'aşamaları), çağrı üst verisi (numara, tarih, süre, sonuç etiketi) ve '
              'uygulamayı iyileştirmek için kullanım/analitik olayları. Çağrı '
              'içerikleri (ses kaydı) uygulama tarafından toplanmaz.',
        ),
        (
          '2. Verileri Nasıl Kullanırız',
          'Verileriniz; hizmeti sunmak, CRM ve çağrı akışlarınızı çalıştırmak, ofis '
              'içi yetkilendirme ve raporlama sağlamak, güvenliği korumak ve '
              'uygulamayı geliştirmek için işlenir. Verilerinizi reklam amacıyla '
              'üçüncü taraflara satmayız.',
        ),
        (
          '3. Veri Saklama Altyapısı',
          'Veriler Google Firebase (Authentication, Cloud Firestore, Cloud '
              'Messaging) altyapısında güvenli biçimde saklanır. Erişim, rol tabanlı '
              'yetkilendirme ve sunucu tarafı güvenlik kurallarıyla sınırlandırılır.',
        ),
        (
          '4. Veri Paylaşımı',
          'Bağlı olduğunuz ofis/şirket içindeki yöneticiler, yetkileri ölçüsünde '
              'ofise ait CRM ve çağrı kayıtlarını görebilir. Yasal yükümlülükler '
              'dışında verileriniz harici taraflarla paylaşılmaz.',
        ),
        (
          '5. Haklarınız (KVKK / GDPR)',
          'Kişisel verilerinize erişme, düzeltme ve silme hakkınız vardır. Ayarlar > '
              'Hesap Güvenliği > "Hesabı kalıcı sil" ile hesabınızı ve ilişkili '
              'verilerinizi silebilirsiniz. Silme talebi sunucu tarafında ilgili '
              'kayıtların temizlenmesini tetikler.',
        ),
        (
          '6. Bildirimler',
          'İzin verirseniz görev, çağrı ve mesaj hatırlatmaları için anlık bildirim '
              'gönderebiliriz. Bildirimleri ve "sessiz saatleri" Ayarlar > Bildirimler '
              'üzerinden istediğiniz zaman yönetebilirsiniz.',
        ),
        (
          '7. Değişiklikler',
          'Bu politikayı zaman zaman güncelleyebiliriz. Önemli değişikliklerde '
              'uygulama içinde bilgilendirme yapılır.',
        ),
      ];

  List<(String, String)> _termsSections() => const [
        (
          '1. Hizmetin Kapsamı',
          '${AppConstants.appName}, gayrimenkul danışmanları ve ofisleri için bir '
              'müşteri ilişkileri yönetimi (CRM) ve çağrı yönetimi uygulamasıdır. '
              'Hizmeti kullanarak bu şartları kabul etmiş olursunuz.',
        ),
        (
          '2. Hesap Sorumluluğu',
          'Hesap güvenliğinizden ve hesabınız altında gerçekleşen işlemlerden siz '
              'sorumlusunuz. Giriş bilgilerinizi gizli tutmalısınız.',
        ),
        (
          '3. Kabul Edilebilir Kullanım',
          'Uygulamayı yalnızca yasalara uygun ve yetkili olduğunuz veriler için '
              'kullanırsınız. Başkalarına ait verileri ilgili kişilerin rızası ve '
              'yasal dayanak olmadan işlemezsiniz.',
        ),
        (
          '4. Veri Sahipliği',
          'Girdiğiniz CRM ve çağrı verileri, bağlı olduğunuz ofis/şirkete ve size '
              'aittir. Biz bu verileri yalnızca hizmeti sunmak için işleriz.',
        ),
        (
          '5. Abonelik ve PRO',
          'Temel özellikler ücretsizdir. PRO katmanı ek içgörü ve sınırların '
              'kaldırılmasını sağlar. PRO geçişi, satış ekibimizle iletişim yoluyla '
              'yapılır; uygulama sahte satın alma veya aktivasyon göstermez.',
        ),
        (
          '6. Sorumluluk Sınırı',
          'Hizmet "olduğu gibi" sunulur. Yasaların izin verdiği ölçüde, dolaylı veya '
              'arızi zararlardan sorumlu tutulamayız. Verilerinizi düzenli yedeklemek '
              'sizin sorumluluğunuzdadır.',
        ),
        (
          '7. Fesih',
          'Hesabınızı dilediğiniz zaman Ayarlar üzerinden silebilirsiniz. Şartların '
              'ihlali halinde erişiminizi askıya alabiliriz.',
        ),
      ];
}
