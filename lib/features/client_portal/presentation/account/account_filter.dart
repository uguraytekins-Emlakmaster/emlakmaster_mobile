import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_types.dart';

/// Saf, build-güvenli filtre. Kategori merceği (arama yok — hesap yüzeyi az
/// sayıda sabit satır içerir; metin araması fake karmaşıklık olur).
List<AccountEntry> filterAccountEntries(
  List<AccountEntry> source, {
  AccountFilter filter = AccountFilter.all,
}) {
  bool matches(AccountEntry e) => switch (filter) {
        AccountFilter.all => true,
        AccountFilter.account => e.section == AccountSection.account,
        AccountFilter.contact => e.section == AccountSection.contact,
        AccountFilter.channels => e.section == AccountSection.channels,
        AccountFilter.privacy => e.section == AccountSection.privacy,
        AccountFilter.partial => e.isPartial,
      };

  return source.where(matches).toList(growable: false);
}
