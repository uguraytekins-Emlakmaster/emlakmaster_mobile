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

  // Kategori tercihleri + sessiz saatler.
  bool _prefsLoading = true;
  bool _catTasks = true;
  bool _catCalls = true;
  bool _catMessages = true;
  bool _catMarketing = false;
  bool _catAgent = true;
  bool _quietEnabled = false;
  int _quietStartMin = AppConstants.defaultQuietHoursStartMin;
  int _quietEndMin = AppConstants.defaultQuietHoursEndMin;

  @override
  void initState() {
    super.initState();
    _loadSoundStyle();
    _loadPrefs();
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

  Future<void> _loadPrefs() async {
    final s = SettingsService.instance;
    final tasks = await s.getNotifCategoryTasks();
    final calls = await s.getNotifCategoryCalls();
    final messages = await s.getNotifCategoryMessages();
    final marketing = await s.getNotifCategoryMarketing();
    final agent = await s.getNotifCategoryAgent();
    final quietOn = await s.getQuietHoursEnabled();
    final quietStart = await s.getQuietHoursStartMin();
    final quietEnd = await s.getQuietHoursEndMin();
    if (!mounted) return;
    setState(() {
      _catTasks = tasks;
      _catCalls = calls;
      _catMessages = messages;
      _catMarketing = marketing;
      _catAgent = agent;
      _quietEnabled = quietOn;
      _quietStartMin = quietStart;
      _quietEndMin = quietEnd;
      _prefsLoading = false;
    });
  }

  String _fmtMin(int minuteOfDay) {
    final h = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
    final m = (minuteOfDay % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickQuietTime({required bool isStart}) async {
    final initialMin = isStart ? _quietStartMin : _quietEndMin;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialMin ~/ 60, minute: initialMin % 60),
    );
    if (picked == null) return;
    final value = picked.hour * 60 + picked.minute;
    if (isStart) {
      await SettingsService.instance.setQuietHoursStartMin(value);
      if (mounted) setState(() => _quietStartMin = value);
    } else {
      await SettingsService.instance.setQuietHoursEndMin(value);
      if (mounted) setState(() => _quietEndMin = value);
    }
  }

  Widget _catTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final ext = AppThemeExtension.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SwitchListTile(
      secondary: Icon(icon, color: ext.accent),
      title: Text(title, style: TextStyle(color: onSurface)),
      value: value,
      activeThumbColor: ext.accent,
      onChanged: onChanged,
    );
  }

  Widget _timeChip(String label, String value, VoidCallback onTap) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: theme.dividerColor),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: ext.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ],
      ),
    );
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
    final mainEnabled = asyncEnabled.valueOrNull ?? false;

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
      if (mainEnabled && !_prefsLoading) ...[
        Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.45)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            l10n.t('notif_categories_header'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: ext.textTertiary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.35,
            ),
          ),
        ),
        _catTile(
          icon: Icons.task_alt_rounded,
          title: l10n.t('notif_cat_tasks'),
          value: _catTasks,
          onChanged: (v) async {
            await SettingsService.instance.setNotifCategoryTasks(v);
            if (mounted) setState(() => _catTasks = v);
          },
        ),
        _catTile(
          icon: Icons.call_rounded,
          title: l10n.t('notif_cat_calls'),
          value: _catCalls,
          onChanged: (v) async {
            await SettingsService.instance.setNotifCategoryCalls(v);
            if (mounted) setState(() => _catCalls = v);
          },
        ),
        _catTile(
          icon: Icons.chat_bubble_rounded,
          title: l10n.t('notif_cat_messages'),
          value: _catMessages,
          onChanged: (v) async {
            await SettingsService.instance.setNotifCategoryMessages(v);
            if (mounted) setState(() => _catMessages = v);
          },
        ),
        _catTile(
          icon: Icons.campaign_rounded,
          title: l10n.t('notif_cat_marketing'),
          value: _catMarketing,
          onChanged: (v) async {
            await SettingsService.instance.setNotifCategoryMarketing(v);
            if (mounted) setState(() => _catMarketing = v);
          },
        ),
        _catTile(
          icon: Icons.auto_awesome_outlined,
          title: l10n.t('notif_cat_agent'),
          value: _catAgent,
          onChanged: (v) async {
            await SettingsService.instance.setNotifCategoryAgent(v);
            if (mounted) setState(() => _catAgent = v);
          },
        ),
        Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.45)),
        SwitchListTile(
          secondary: Icon(Icons.bedtime_rounded, color: ext.accent),
          title: Text(l10n.t('notif_quiet_hours'), style: TextStyle(color: onSurface)),
          subtitle: Text(
            l10n.t('notif_quiet_hours_sub'),
            style: TextStyle(color: onSurfaceVariant, fontSize: 12),
          ),
          value: _quietEnabled,
          activeThumbColor: ext.accent,
          onChanged: (v) async {
            await SettingsService.instance.setQuietHoursEnabled(v);
            if (mounted) setState(() => _quietEnabled = v);
          },
        ),
        if (_quietEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _timeChip(l10n.t('time_start'), _fmtMin(_quietStartMin),
                      () => _pickQuietTime(isStart: true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _timeChip(l10n.t('time_end'), _fmtMin(_quietEndMin),
                      () => _pickQuietTime(isStart: false)),
                ),
              ],
            ),
          ),
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
