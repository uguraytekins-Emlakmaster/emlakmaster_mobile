import 'package:emlakmaster_mobile/core/providers/connectivity_provider.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Çevrimdışıyken üstte ince bilgi şeridi (mükerrer iş yok; sadece durum).
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityOnlineProvider);
    return online.when(
      data: (isOnline) {
        if (isOnline) return const SizedBox.shrink();
        final ext = AppThemeExtension.of(context);
        return Material(
          color: ext.surfaceElevated.withValues(alpha: 0.95),
          elevation: 1,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.cloud_off_rounded, size: 18, color: ext.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Çevrimdışısınız. Veriler cihazda saklanır; bağlantı gelince senkronize edilir.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: ext.textSecondary,
                            height: 1.3,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
