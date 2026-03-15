import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/resurrection_engine/presentation/providers/resurrection_queue_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Danışman paneli – Takip: sessiz lead listesi (7/14/30+ gün), yeniden kazanım kuyruğu.
class ConsultantResurrectionPage extends ConsumerWidget {
  const ConsultantResurrectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resurrectionAsync = ref.watch(resurrectionQueueProvider);
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark,
        foregroundColor: DesignTokens.textPrimaryDark,
        title: const Text('Takip listesi'),
        elevation: 0,
      ),
      body: resurrectionAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 64,
                    color: DesignTokens.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: DesignTokens.space4),
                  const Text(
                    'Şu an takip edilecek lead yok',
                    style: TextStyle(
                      color: DesignTokens.textSecondaryDark,
                      fontSize: DesignTokens.fontSizeMd,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      '7 gün ve üzeri sessiz kalan müşteriler burada listelenir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DesignTokens.textTertiaryDark,
                        fontSize: DesignTokens.fontSizeSm,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(DesignTokens.space4),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final e = items[index];
              final name = e.customerName ?? e.customerId;
              final days = e.daysSilent ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: DesignTokens.space2),
                padding: const EdgeInsets.all(DesignTokens.space4),
                decoration: BoxDecoration(
                  color: DesignTokens.surfaceDark,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: DesignTokens.borderDark),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DesignTokens.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: DesignTokens.primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: DesignTokens.textPrimaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '$days gün sessiz',
                    style: const TextStyle(
                      color: DesignTokens.textSecondaryDark,
                      fontSize: DesignTokens.fontSizeSm,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: DesignTokens.textTertiaryDark,
                  ),
                  onTap: () {},
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primary),
        ),
        error: (e, _) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: DesignTokens.danger,
              ),
              SizedBox(height: 16),
              Text(
                'Liste yüklenemedi.',
                style: TextStyle(color: DesignTokens.textSecondaryDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
