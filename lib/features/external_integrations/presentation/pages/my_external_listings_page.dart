import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/widgets/my_external_listings_inner.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Tam ekran «Benim ilanlarım» (router’dan açılır).
class MyExternalListingsPage extends StatelessWidget {
  const MyExternalListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  if (context.canPop()) const AppBackButton(),
                  Expanded(
                    child: Text(
                      l10n.t('my_external_listings_title'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: ext.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: MyExternalListingsInner(),
            ),
          ],
        ),
      ),
    );
  }
}
