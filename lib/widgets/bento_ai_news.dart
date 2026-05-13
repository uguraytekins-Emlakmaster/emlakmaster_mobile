import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter/material.dart';

/// Firebase'de news yoksa kullanılacak sabit liste (Günün Fırsatı, Faiz Oranı vb.)
final List<Map<String, String>> _defaultNewsItems = [
  {
    'title': 'Günün Fırsatı',
    'body':
        'Bugün faiz oranlarında hafif bir geri çekilme var. Kredi bekleyen alıcı listenizi kontrol edip, uygun müşterilere otomatik bilgilendirme gönderebilirsiniz.'
  },
  {
    'title': 'Faiz Oranı Güncellemesi',
    'body':
        'Merkez Bankası kararı sonrası konut kredisi oranları güncellendi. Müşterilerinize yeni oranları iletmek için öneri listesini inceleyin.'
  },
  {
    'title': 'Piyasa Özeti',
    'body':
        'Diyarbakır bölgesinde 3+1 talep artışı devam ediyor. Bağlar ve Kayapınar ilçelerinde stoklarınızı güncel tutun.'
  },
  {
    'title': 'Fırsat İlanı',
    'body':
        'Portföyünüzde 30 günden uzun süredir ilanı açık kalan 2 emlak var. Fiyat revizyonu veya kampanya önerisi alabilirsiniz.'
  },
];

class BentoAiNews extends StatelessWidget {
  const BentoAiNews({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.newsStream(),
      builder: (context, snapshot) {
        final ext = AppThemeExtension.of(context);
        String title = 'Akıllı Gündem Özeti';
        String body;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final docs = snapshot.data!.docs;
          final index = DateTime.now().millisecondsSinceEpoch % docs.length;
          final d = docs[index].data();
          title = d['title'] as String? ?? 'Günün Fırsatı';
          body = d['body'] as String? ??
              d['text'] as String? ??
              _defaultNewsItems[0]['body']!;
        } else {
          final rnd = math.Random(DateTime.now().millisecond);
          final item = _defaultNewsItems[rnd.nextInt(_defaultNewsItems.length)];
          title = item['title']!;
          body = item['body']!;
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: ext.surfaceElevated.withValues(alpha: 0.92),
            border: Border.all(color: ext.border.withValues(alpha: 0.62)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ext.accent,
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: ext.onBrand,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.cardHeading(context).copyWith(
                        fontSize: DesignTokens.fontSizeMd,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: AppTypography.body(context).copyWith(
                        fontSize: DesignTokens.fontSizeSm,
                        height: 1.45,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: ext.accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  showPremiumModalBottomSheet<void>(
                    context: context,
                    useSafeArea: true,
                    builder: (ctx) {
                      final ext = AppThemeExtension.of(ctx);
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(
                          DesignTokens.space5,
                          DesignTokens.space2,
                          DesignTokens.space5,
                          DesignTokens.space6,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const PremiumBottomSheetHandle(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.bolt_outlined,
                                  size: DesignTokens.iconLg,
                                  color: ext.accent.withValues(alpha: 0.55),
                                ),
                                const SizedBox(width: DesignTokens.space3),
                                Expanded(
                                  child: PremiumSheetHeader(
                                    compact: true,
                                    title: title,
                                    subtitle: 'Piyasa özeti',
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Kapat',
                                  style: IconButton.styleFrom(
                                    foregroundColor: ext.textTertiary,
                                  ),
                                  onPressed: () => Navigator.pop(ctx),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: DesignTokens.space4),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.sizeOf(ctx).height * 0.45,
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  body,
                                  style: AppTypography.body(context).copyWith(
                                    fontSize: DesignTokens.fontSizeSm,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: DesignTokens.space5),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: FilledButton.styleFrom(
                                backgroundColor: ext.accent,
                                foregroundColor: ext.onBrand,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    DesignTokens.radiusControl,
                                  ),
                                ),
                              ),
                              child: const Text('Anladım'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: const Text(
                  'Önerileri Gör',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
