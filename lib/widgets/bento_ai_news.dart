import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter/material.dart';
/// Firebase'de news yoksa kullanılacak sabit liste (Günün Fırsatı, Faiz Oranı vb.)
final List<Map<String, String>> _defaultNewsItems = [
  {'title': 'Günün Fırsatı', 'body': 'Bugün faiz oranlarında hafif bir geri çekilme var. Kredi bekleyen alıcı listenizi kontrol edip, uygun müşterilere otomatik bilgilendirme gönderebilirsiniz.'},
  {'title': 'Faiz Oranı Güncellemesi', 'body': 'Merkez Bankası kararı sonrası konut kredisi oranları güncellendi. Müşterilerinize yeni oranları iletmek için öneri listesini inceleyin.'},
  {'title': 'Piyasa Özeti', 'body': 'Diyarbakır bölgesinde 3+1 talep artışı devam ediyor. Bağlar ve Kayapınar ilçelerinde stoklarınızı güncel tutun.'},
  {'title': 'Fırsat İlanı', 'body': 'Portföyünüzde 30 günden uzun süredir ilanı açık kalan 2 emlak var. Fiyat revizyonu veya kampanya önerisi alabilirsiniz.'},
];

class BentoAiNews extends StatelessWidget {
  const BentoAiNews({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.newsStream(),
      builder: (context, snapshot) {
        String title = 'AI News Insight';
        String body;
        if (snapshot.hasData &&
            snapshot.data!.docs.isNotEmpty) {
          final docs = snapshot.data!.docs;
          final index = DateTime.now().millisecondsSinceEpoch % docs.length;
          final d = docs[index].data();
          title = d['title'] as String? ?? 'Günün Fırsatı';
          body = d['body'] as String? ?? d['text'] as String? ?? _defaultNewsItems[0]['body']!;
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
            color: Colors.white.withValues(alpha: 0.04),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppThemeExtension.of(context).accent,
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        height: 1.4,
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
                  foregroundColor: AppThemeExtension.of(context).accent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: AppThemeExtension.of(context).surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (ctx) => SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.bolt_rounded, color: AppThemeExtension.of(context).accent, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.sizeOf(ctx).height * 0.45,
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  body,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppThemeExtension.of(context).accent,
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('Anladım'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
