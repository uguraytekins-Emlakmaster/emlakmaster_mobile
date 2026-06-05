import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_types.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/client_portal_tokens.dart';
import 'package:flutter/material.dart';

Color accountToneColor(AppThemeExtension ext, AccountTone tone) {
  return switch (tone) {
    AccountTone.accent => ext.accent,
    AccountTone.info => ext.info,
    AccountTone.success => ext.success,
    AccountTone.warning => ext.warning,
    AccountTone.neutral => ext.textTertiary,
    AccountTone.danger => ext.danger,
  };
}

/// Kimlik kartı — gerçek avatar harfi + e-posta + rol. Uydurma alan yok.
class AccountIdentityCard extends StatelessWidget {
  const AccountIdentityCard({super.key, required this.snapshot});

  final AccountSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final primary = snapshot.signedIn
        ? (snapshot.email.isNotEmpty ? snapshot.email : 'Müşteri hesabı')
        : 'Giriş yapılmamış';
    final secondary = snapshot.signedIn
        ? (snapshot.greetingName.isNotEmpty
            ? '${snapshot.greetingName} · ${snapshot.roleLabel}'
            : '${snapshot.roleLabel} · oturum açık')
        : 'Oturum kapalı · keşfetmeye devam edebilirsiniz';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientPortalTokens.horizontal,
        ClientPortalTokens.chromeGap,
        ClientPortalTokens.horizontal,
        ClientPortalTokens.chromeGap,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ext.surface.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ext.border.withValues(alpha: 0.32)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: ext.accent.withValues(alpha: 0.18),
                child: Text(
                  snapshot.avatarLetter,
                  style: TextStyle(
                    color: ext.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      secondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hesap özet şeridi — yalnızca gerçek değerler; uydurma KPI yok.
class AccountSummaryStrip extends StatelessWidget {
  const AccountSummaryStrip({super.key, required this.summary});

  final AccountSummary summary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final cells = <(String, String, Color)>[
      (summary.profileReady ? 'Hazır' : '—', 'Profil',
          summary.profileReady ? ext.success : ext.textTertiary),
      (summary.contactReady ? 'Hazır' : '—', 'İletişim', ext.accent),
      (summary.requestReady ? 'Hazır' : '—', 'Talep', ext.info),
      (summary.messageReady ? 'Hazır' : '—', 'Mesaj', ext.success),
      (summary.savedFields.toString(), 'Kayıtlı', ext.warning),
    ].take(5).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientPortalTokens.horizontal,
        ClientPortalTokens.chromeGap / 2,
        ClientPortalTokens.horizontal,
        ClientPortalTokens.chromeGap,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ext.surface.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ext.border.withValues(alpha: 0.32)),
        ),
        child: SizedBox(
          height: ClientPortalTokens.summaryStripHeight,
          child: Row(
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: 28,
                    color: ext.border.withValues(alpha: 0.28),
                  ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cells[i].$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cells[i].$3,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cells[i].$2,
                        style: TextStyle(
                          color: ext.textTertiary,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Yatay filtre şeridi — AccountFilter (390/430 güvenli, yatay kaydırma).
class AccountFilterStrip extends StatelessWidget {
  const AccountFilterStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AccountFilter selected;
  final ValueChanged<AccountFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return SizedBox(
      height: ClientPortalTokens.filterStripHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: ClientPortalTokens.horizontal,
        ),
        itemCount: AccountFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final filter = AccountFilter.values[index];
          final isSelected = filter == selected;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(filter),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ext.accent.withValues(alpha: 0.16)
                      : ext.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? ext.accent.withValues(alpha: 0.45)
                        : ext.border.withValues(alpha: 0.32),
                  ),
                ),
                child: Text(
                  filter.label,
                  style: TextStyle(
                    color: isSelected ? ext.accent : ext.textSecondary,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Bölüm içi dürüst boş / kapsam notu kutusu.
class AccountInlineNote extends StatelessWidget {
  const AccountInlineNote({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientPortalTokens.horizontal,
        0,
        ClientPortalTokens.horizontal,
        ClientPortalTokens.chromeGap,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: ext.surface.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ext.border.withValues(alpha: 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: ext.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
