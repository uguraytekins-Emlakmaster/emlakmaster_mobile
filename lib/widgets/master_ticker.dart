import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter/material.dart';

class MasterTicker extends StatelessWidget {
  const MasterTicker({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return StreamBuilder<List<String>>(
      stream: FirestoreService.officeTickerStream,
      initialData: FirestoreService.defaultTickerItems,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <String>[];
        return Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardL),
            color: ext.surfaceElevated,
            border: Border.all(color: ext.borderSubtle),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DashboardLayoutTokens.radiusCardL),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  color: ext.accent,
                  child: Text(
                    'OFFICE TICKER',
                    style: TextStyle(
                      color: ext.onBrand,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Center(
                          child: Text(
                            items[index],
                            style: TextStyle(
                              color: ext.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
