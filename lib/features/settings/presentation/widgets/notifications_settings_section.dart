import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/feedback/app_sound.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/providers/settings_provider.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/settings/presentation/providers/feature_flags_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bildirimler + titreşim + ses efektleri.
class NotificationsSettingsSection extends ConsumerStatefulWidget {
  const NotificationsSettingsSection({super.key, this.embedInParentCard = false});

  final bool embedInParentCard;

  @override
  ConsumerState<NotificationsSettingsSection> createState() =>
      _NotificationsSettingsSectionState();
}

class _NotificationsSettingsSectionState
    extends ConsumerState<NotificationsSettingsSection> {
  String? _soundStyleId;
  bool _styleLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSoundStyle();
  }

  Future<void> _loadSoundStyle() async {
    final id = await SettingsService.instance.getNotificationSoundStyleId();
    if (mounted) {
      setState(() {
        _soundStyleId = id;
        _styleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = onSurface.withValues(alpha: 0.7);
    final flags = ref.watch(featureFlagsProvider).valueOrNull;
    final hapticOn = flags?[AppConstants.keyHapticFeedback] ?? true;
    final soundOn = flags?[AppConstants.keySoundEffects] ?? false;
    final asyncEnabled = ref.watch(notificationsEnabledProvider);

    final children = <Widget>[
      asyncEnabled.when(
        loading: () => ListTile(
          title: Text(l10n.t('notifications_main'), style: TextStyle(color: onSurface)),
          trailing: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ext.accent,
            ),
          ),
        ),
        error: (_, __) => ListTile(
          title: Text(l10n.t('notifications_main'), style: TextStyle(color: onSurface)),
          subtitle: Text(
            l10n.t('load_failed'),
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
        data: (enabled) => SwitchListTile(
          secondary: Icon(
            enabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_rounded,
            color: ext.accent,
          ),
          title: Text(l10n.t('notifications_main'), style: TextStyle(color: onSurface)),
          subtitle: Text(
            l10n.t('notifications_main_sub'),
            style: TextStyle(color: onSurfaceVariant, fontSize: 12),
          ),
          value: enabled,
          activeThumbColor: ext.accent,
          onChanged: (v) =>
              ref.read(notificationsEnabledProvider.notifier).setEnabled(v),
        ),
      ),
      Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.45)),
      SwitchListTile(
        secondary: Icon(Icons.vibration_rounded, color: ext.accent),
        title: Text(l10n.t('haptic_feedback'), style: TextStyle(color: onSurface)),
        subtitle: Text(
          l10n.t('haptic_feedback_sub'),
          style: TextStyle(color: onSurfaceVariant, fontSize: 12),
        ),
        value: hapticOn,
        activeThumbColor: ext.accent,
        onChanged: (v) async {
          await ref
              .read(featureFlagsProvider.notifier)
              .setFlag(AppConstants.keyHapticFeedback, v);
          AppFeedback.applyRuntimeFlags(haptic: v);
          if (v) await AppFeedback.lightImpact();
        },
      ),
      SwitchListTile(
        secondary: Icon(Icons.volume_up_rounded, color: ext.accent),
        title: Text(l10n.t('sound_effects'), style: TextStyle(color: onSurface)),
        subtitle: Text(
          l10n.t('sound_effects_sub'),
          style: TextStyle(color: onSurfaceVariant, fontSize: 12),
        ),
        value: soundOn,
        activeThumbColor: ext.accent,
        onChanged: (v) async {
          await ref
              .read(featureFlagsProvider.notifier)
              .setFlag(AppConstants.keySoundEffects, v);
          AppFeedback.applyRuntimeFlags(sound: v);
          if (v) {
            await AppFeedback.playSuccess();
          }
        },
      ),
      if (soundOn) ...[
        Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.45)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            l10n.t('notification_sound_style'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: ext.textTertiary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.35,
            ),
          ),
        ),
        if (_styleLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          ...AppNotificationSoundStyle.values.map((style) {
            final selected = (_soundStyleId ?? AppConstants.defaultNotificationSoundStyle) ==
                style.id;
            return ListTile(
              leading: Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? ext.accent : onSurfaceVariant,
                size: 22,
              ),
              title: Text(
                _styleLabel(l10n, style),
                style: TextStyle(
                  color: onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              subtitle: Text(
                _styleSub(l10n, style),
                style: TextStyle(color: onSurfaceVariant, fontSize: 11),
              ),
              trailing: IconButton(
                tooltip: l10n.t('sound_preview'),
                icon: Icon(Icons.play_circle_outline_rounded, color: ext.accent),
                onPressed: () => AppFeedback.previewNotificationStyle(style),
              ),
              onTap: () async {
                await SettingsService.instance
                    .setNotificationSoundStyleId(style.id);
                AppFeedback.applyRuntimeFlags(style: style);
                if (mounted) setState(() => _soundStyleId = style.id);
                await AppFeedback.previewNotificationStyle(style);
              },
            );
          }),
      ],
    ];

    if (widget.embedInParentCard) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    final isDark = theme.brightness == Brightness.dark;
    final surface =
        isDark ? ext.card : ext.surface;
    final border = isDark ? ext.border.withValues(alpha: 0.5) : ext.border;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  String _styleLabel(AppLocalizations l10n, AppNotificationSoundStyle style) {
    switch (style) {
      case AppNotificationSoundStyle.chime:
        return l10n.t('notification_sound_chime');
      case AppNotificationSoundStyle.sparkle:
        return l10n.t('notification_sound_sparkle');
      case AppNotificationSoundStyle.bell:
        return l10n.t('notification_sound_bell');
    }
  }

  String _styleSub(AppLocalizations l10n, AppNotificationSoundStyle style) {
    switch (style) {
      case AppNotificationSoundStyle.chime:
        return l10n.t('notification_sound_chime_sub');
      case AppNotificationSoundStyle.sparkle:
        return l10n.t('notification_sound_sparkle_sub');
      case AppNotificationSoundStyle.bell:
        return l10n.t('notification_sound_bell_sub');
    }
  }
}
