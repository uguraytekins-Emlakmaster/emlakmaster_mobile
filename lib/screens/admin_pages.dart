import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:emlakmaster_mobile/widgets/finance_bar.dart';
import 'package:emlakmaster_mobile/widgets/master_ticker.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';

export 'admin_reports_page.dart';

/// Yönetici paneli – Ekonomi & Piyasa: kur, altın, piyasa nabzı, ticker.
class AdminEconomyPage extends StatelessWidget {
  const AdminEconomyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = AppThemeExtension.of(context);
    final fg = ext.textPrimary;
    return PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: emlakAppBar(
          context,
          backgroundColor: Colors.transparent,
          foregroundColor: theme.appBarTheme.foregroundColor ?? fg,
          title: const Text('Piyasa Nabzı'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(DesignTokens.space6),
          children: [
            const MasterTicker(),
            const SizedBox(height: DesignTokens.space6),
            const FinanceBar(),
            const SizedBox(height: DesignTokens.space6),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: DesignTokens.space2),
              child: Text(
                'Kur, altın ve seçili endeksler canlı akar; ayrıntılar İçgörüler alanında derlenir.',
                style: AppTypography.body(context).copyWith(
                  fontSize: DesignTokens.fontSizeSm,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
