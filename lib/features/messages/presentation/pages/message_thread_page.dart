import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/utils/whatsapp_launcher.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_navigation.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Harici platform önizlemesi — canlı ekip sohbeti için [TeamThreadPage] kullanılır.
class MessageThreadPage extends StatefulWidget {
  const MessageThreadPage({
    super.key,
    required this.customerName,
    required this.listingRef,
    required this.platformLabel,
    this.customerPhone,
  });

  final String customerName;
  final String listingRef;
  final String platformLabel;
  final String? customerPhone;

  @override
  State<MessageThreadPage> createState() => _MessageThreadPageState();
}

class _MessageThreadPageState extends State<MessageThreadPage> {
  final _composeController = TextEditingController(
    text: 'Merhaba, ilan hakkında bilgi almak istiyorum.',
  );

  @override
  void dispose() {
    _composeController.dispose();
    super.dispose();
  }

  Future<void> _copyDraft() async {
    await Clipboard.setData(ClipboardData(text: _composeController.text.trim()));
    if (!mounted) return;
    showPremiumActionFeedback(
      context,
      title: 'Metin kopyalandı',
      message:
          'Yanıtı ${widget.platformLabel.isNotEmpty ? widget.platformLabel : 'platform'} uygulamasına yapıştırabilirsiniz.',
      type: PremiumActionFeedbackType.success,
      useSheet: false,
    );
  }

  Future<void> _openWhatsAppIfPossible() async {
    final phone = widget.customerPhone?.trim() ?? '';
    final text = _composeController.text.trim();
    if (phone.isEmpty) {
      await _copyDraft();
      return;
    }
    final ok = await WhatsAppLauncher.openChat(phone, message: text);
    if (!mounted) return;
    if (!ok) {
      showPremiumActionFeedback(
        context,
        title: 'WhatsApp açılamadı',
        message: 'Numarayı kontrol edin veya metni panoya kopyalayıp manuel gönderin.',
        type: PremiumActionFeedbackType.warning,
        useSheet: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isWhatsApp = widget.platformLabel.toLowerCase().contains('whatsapp');

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
                  const PremiumNavLeading(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customerName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: ext.foreground,
                                fontWeight: FontWeight.w800,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.platformLabel.isNotEmpty)
                          Text(
                            widget.platformLabel,
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
                  color: ext.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: ext.accent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: ext.accent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ekip içi canlı sohbet Mesaj Merkezi kanallarından açılır. '
                        'Bu ekran harici platform önizlemesidir.',
                        style: TextStyle(
                          color: ext.foreground,
                          fontSize: 13,
                          height: 1.4,
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
                        'Merhaba, ${widget.listingRef.contains('·') ? widget.listingRef.split('·').first.trim() : 'ilan'} için görüşmek istiyorum. Müsait misiniz?',
                    time: 'Örnek',
                  ),
                  const _Bubble(
                    alignRight: true,
                    text: 'Merhaba, evet ilan güncel. Yarın öğleden sonra gösterebilirim.',
                    time: 'Örnek',
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                12 + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: ext.surface,
                border: Border(top: BorderSide(color: ext.border.withValues(alpha: 0.5))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _composeController,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Yanıt metnini yazın…',
                      filled: true,
                      fillColor: ext.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusControl),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _copyDraft,
                          child: const Text('Panoya kopyala'),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.space2),
                      Expanded(
                        child: FilledButton(
                          onPressed: isWhatsApp
                              ? _openWhatsAppIfPossible
                              : _copyDraft,
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: ext.onBrand,
                          ),
                          child: Text(isWhatsApp ? "WhatsApp'ta aç" : 'Metni hazırla'),
                        ),
                      ),
                    ],
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
