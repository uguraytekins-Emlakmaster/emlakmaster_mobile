import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/design_tokens.dart';

/// Dürüstlük notu — eksik/kısmi veri varsa kullanıcıya açıkça söylenir.
///
/// Örnekler:
/// "Bütçe bilgisi eksik olduğu için öneri kısmi verilmiştir."
/// "Bu öneri mevcut kayıtlarla sınırlıdır."
/// "Bu çıktı kural tabanlı ücretsiz modda oluşturuldu."
class AxionAgentHonestyNote extends StatelessWidget {
  const AxionAgentHonestyNote({super.key, required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space3,
        vertical: DesignTokens.space2,
      ),
      decoration: BoxDecoration(
        color: t.infoSurface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: t.info),
          const SizedBox(width: DesignTokens.space2),
          Expanded(
            child: Text(
              note,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXs,
                color: t.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
