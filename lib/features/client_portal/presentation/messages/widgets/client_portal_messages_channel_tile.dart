import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/premium/premium_theme_extension.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/messages/client_portal_messages_tokens.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/messages/client_portal_messages_types.dart';
import 'package:flutter/material.dart';

/// Premium iletişim kanalı kartı — concierge ritmi, dürüst meta etiketler.
class ClientMessagesChannelTile extends StatelessWidget {
  const ClientMessagesChannelTile({
    super.key,
    required this.spec,
    required this.onTap,
  });

  final ClientMessagesChannelSpec spec;
  final VoidCallback onTap;

  bool get _primary => spec.tier == ClientMessagesChannelTier.primary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final premium = PremiumThemeExtension.of(context);
    final tone = spec.accent ?? ext.accent;
    final minHeight = _primary
        ? ClientPortalMessagesTokens.primaryChannelMinHeight
        : ClientPortalMessagesTokens.standardChannelMinHeight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientPortalMessagesTokens.horizontal,
        0,
        ClientPortalMessagesTokens.horizontal,
        9,
      ),
      child: Material(
        color: ext.surface.withValues(alpha: _primary ? 0.62 : 0.52),
        borderRadius:
            BorderRadius.circular(ClientPortalMessagesTokens.surfaceRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(ClientPortalMessagesTokens.surfaceRadius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(ClientPortalMessagesTokens.surfaceRadius),
              border: Border.all(
                color: _primary
                    ? tone.withValues(alpha: 0.34)
                    : ext.border.withValues(alpha: 0.24),
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _primary ? 14 : 12,
                  _primary ? 13 : 11,
                  12,
                  _primary ? 13 : 11,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_primary)
                      Container(
                        width: 2,
                        height: ClientPortalMessagesTokens.channelIconSize + 6,
                        margin: const EdgeInsets.only(right: 10, top: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          color: tone.withValues(alpha: 0.75),
                        ),
                      ),
                    Container(
                      width: ClientPortalMessagesTokens.channelIconSize,
                      height: ClientPortalMessagesTokens.channelIconSize,
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: _primary ? 0.16 : 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: tone.withValues(alpha: _primary ? 0.34 : 0.24),
                        ),
                      ),
                      child: Icon(
                        spec.icon,
                        color: tone.withValues(alpha: 0.95),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  spec.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: ext.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize:
                                        ClientPortalMessagesTokens.channelTitleSize,
                                    letterSpacing: -0.15,
                                  ),
                                ),
                              ),
                              if (_primary)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: premium.champagneGold
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: premium.champagneGold
                                          .withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: Text(
                                    'Önerilen',
                                    style: TextStyle(
                                      color: premium.champagneGold
                                          .withValues(alpha: 0.92),
                                      fontSize:
                                          ClientPortalMessagesTokens.channelChipSize,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            spec.purpose,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tone.withValues(alpha: 0.88),
                              fontSize: ClientPortalMessagesTokens.channelMetaSize + 0.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            spec.nextStep,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ext.textSecondary,
                              fontSize: ClientPortalMessagesTokens.channelMetaSize + 0.5,
                              height: 1.28,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              for (final label in spec.meta)
                                _MetaChip(label: label, tone: tone, primary: _primary),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 17,
                      color: ext.textTertiary.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.tone,
    required this.primary,
  });

  final String label;
  final Color tone;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: primary
            ? tone.withValues(alpha: 0.1)
            : ext.surfaceElevated.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: primary
              ? tone.withValues(alpha: 0.24)
              : ext.border.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: primary ? tone.withValues(alpha: 0.9) : ext.textTertiary,
          fontSize: ClientPortalMessagesTokens.channelChipSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
