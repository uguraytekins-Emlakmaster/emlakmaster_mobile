import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/consultant_customers_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_navigation.dart';
import 'package:flutter/material.dart';

class CustomerDetailWorkspaceSkeleton extends StatelessWidget {
  const CustomerDetailWorkspaceSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    Widget bar(double h, double w) => Container(
          height: h,
          width: w,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: ext.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsultantCustomersTokens.horizontal,
        16,
        ConsultantCustomersTokens.horizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yükleme sırasında da geri/ana sayfa erişilebilir kalsın (kabuk
          // kökünde kendini gizler); kullanıcı veri beklerken mahsur kalmaz.
          const PremiumHeaderNavBar(),
          bar(18, 160),
          bar(11, 220),
          const SizedBox(height: 10),
          bar(52, double.infinity),
          const SizedBox(height: 8),
          bar(36, double.infinity),
          const SizedBox(height: 10),
          for (var i = 0; i < 4; i++) bar(72, double.infinity),
        ],
      ),
    );
  }
}
