import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';

/// Konuşma detayı — platformdan gelen mesajlar salt okunur; sahte gönderim alanı yok.
class MessageThreadPage extends StatelessWidget {
  const MessageThreadPage({
    super.key,
    required this.customerName,
    required this.listingRef,
    required this.platformLabel,
  });

  final String customerName;
  final String listingRef;
  final String platformLabel;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  const AppBackButton(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: ext.foreground,
                                fontWeight: FontWeight.w800,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (platformLabel.isNotEmpty)
                          Text(
                            platformLabel,
                            style: TextStyle(color: ext.foregroundMuted, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ext.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: ext.danger.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.block_rounded, color: ext.danger.withValues(alpha: 0.95), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bu sürümde uygulama içinden yanıt gönderilmiyor. '
                        'Mesajı yanıtlamak için ilgili platformu (ör. $platformLabel) web veya resmi uygulamasından devam edin.',
                        style: TextStyle(
                          color: ext.foreground,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _Bubble(
                    alignRight: false,
                    text:
                        'Merhaba, ${listingRef.contains('·') ? listingRef.split('·').first.trim() : 'ilan'} için görüşmek istiyorum. Müsait misiniz?',
                    time: '12:38',
                  ),
                  const _Bubble(
                    alignRight: true,
                    text: 'Merhaba, evet ilan güncel. Yarın öğleden sonra gösterebilirim.',
                    time: '12:40',
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Örnek önizleme — gerçek zamanlı senkron yakında',
                      style: TextStyle(color: ext.foregroundMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + MediaQuery.paddingOf(context).bottom),
              decoration: BoxDecoration(
                color: ext.surface,
                border: Border(top: BorderSide(color: ext.border.withValues(alpha: 0.5))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Yanıt kutusu devre dışı',
                      style: TextStyle(color: ext.foregroundMuted, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.lock_outline_rounded, color: ext.foregroundMuted, size: 20),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: null,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary.withValues(alpha: 0.35),
                      foregroundColor: ext.onBrand.withValues(alpha: 0.5),
                      disabledBackgroundColor: scheme.primary.withValues(alpha: 0.2),
                    ),
                    child: const Text('Gönder'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.alignRight,
    required this.text,
    required this.time,
  });

  final bool alignRight;
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: alignRight ? scheme.primary.withValues(alpha: 0.22) : ext.surfaceElevated,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(alignRight ? 18 : 4),
            bottomRight: Radius.circular(alignRight ? 4 : 18),
          ),
          border: Border.all(color: ext.border.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: ext.foreground,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: TextStyle(color: ext.foregroundMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
