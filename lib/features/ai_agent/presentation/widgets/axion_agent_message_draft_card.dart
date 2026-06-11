import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/axion_agent_models.dart';
import 'axion_agent_card.dart';
import 'axion_agent_honesty_note.dart';

/// Mesaj taslağı kartı.
///
/// Otomatik gönderim YOK — yalnızca düzenle/kopyala ve (mevcut uygulama
/// akışı destekliyorsa) dış uygulama ile paylaş. Uyarı her zaman görünür.
class AxionAgentMessageDraftCard extends StatelessWidget {
  const AxionAgentMessageDraftCard({
    super.key,
    required this.draft,
    this.onEdit,
    this.onCopied,
    this.onSendViaExternalApp,
  });

  final AxionMessageDraft draft;
  final VoidCallback? onEdit;
  final VoidCallback? onCopied;

  /// Yalnızca mevcut uygulama akışı dış paylaşımı destekliyorsa verilmeli.
  final VoidCallback? onSendViaExternalApp;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeExtension.of(context);
    return AxionAgentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  draft.title,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBase,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space2,
                  vertical: DesignTokens.space1,
                ),
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Text(
                  draft.channel.label,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXs,
                    fontWeight: FontWeight.w600,
                    color: t.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space3),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.space3),
            decoration: BoxDecoration(
              color: t.inputBackground,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              border: Border.all(color: t.borderSubtle),
            ),
            child: Text(
              draft.body,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeSm,
                color: t.textPrimary,
                height: 1.45,
              ),
            ),
          ),
          if (draft.honestyNote != null) ...[
            const SizedBox(height: DesignTokens.space2),
            AxionAgentHonestyNote(note: draft.honestyNote!),
          ],
          const SizedBox(height: DesignTokens.space2),
          Text(
            draft.externalChannelWarning ?? 'Göndermeden önce kontrol edin.',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXs,
              fontWeight: FontWeight.w600,
              color: t.warning,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Wrap(
            spacing: DesignTokens.space2,
            children: [
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Düzenle'),
                ),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: draft.body));
                  onCopied?.call();
                },
                icon: const Icon(Icons.copy_outlined, size: 16),
                label: const Text('Kopyala'),
              ),
              if (onSendViaExternalApp != null)
                TextButton.icon(
                  onPressed: onSendViaExternalApp,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Uygulamada aç'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
