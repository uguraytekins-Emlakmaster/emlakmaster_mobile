import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/platform/io_platform_stub.dart'
    if (dart.library.io) 'dart:io' as io;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:emlakmaster_mobile/core/utils/csv_export.dart';
import 'package:emlakmaster_mobile/core/utils/sms_launcher.dart';
import 'package:emlakmaster_mobile/core/utils/whatsapp_launcher.dart';
import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/device_call_log_sync_service.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/domain/local_call_sync_ui_state.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/local_call_records_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_sync_status_icon.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

/// Danışmanın tüm çağrıları (gelen/giden), numaralar, toplu veri export ve toplu SMS.
class ConsultantCallsPage extends ConsumerStatefulWidget {
  const ConsultantCallsPage({super.key});

  @override
  ConsumerState<ConsultantCallsPage> createState() =>
      _ConsultantCallsPageState();
}

class _ConsultantCallsPageState extends ConsumerState<ConsultantCallsPage> {
  final Set<String> _selectedIds = {};
  bool _isSyncingDeviceCalls = false;

  /// WhatsApp sırayla aç: kuyruk ve şu anki indeks (açılan bir sonraki).
  List<String>? _whatsappQueue;
  int _whatsappIndex = 0;
  String _whatsappMessage = '';
  static const Map<String, String> _outcomeLabels = {
    'connected': 'Bağlandı',
    'missed': 'Cevapsız',
    'no_answer': 'Cevap yok',
    'busy': 'Meşgul',
    'failed': 'Başarısız',
  };

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];

  void _retryCallsLoad() {
    HapticFeedback.lightImpact();
    ref.invalidate(consultantCallsStreamProvider);
    ref.invalidate(localCallRecordsStreamProvider);
    if (mounted) {
      setState(() {
        _selectedIds.clear();
      });
    }
  }

  void _selectAll(bool select) {
    setState(() {
      if (select) {
        for (final d in _docs) {
          _selectedIds.add(d.id);
        }
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _selectedDocs() {
    final idSet = _selectedIds.toSet();
    return _docs.where((d) => idSet.contains(d.id)).toList();
  }

  List<String> _phonesFromDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> list) {
    final phones = <String>[];
    for (final d in list) {
      final data = d.data();
      final p =
          data['phoneNumber'] as String? ?? data['phone'] as String? ?? '';
      if (p.trim().isNotEmpty) phones.add(p.trim());
    }
    return phones;
  }

  void _copyCsvToClipboard() {
    final list = _selectedIds.isEmpty ? _docs : _selectedDocs();
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dışa aktarılacak çağrı yok.')),
      );
      return;
    }
    final csv = callsToCsvWithPhones(list);
    Clipboard.setData(ClipboardData(text: csv));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'CSV panoya kopyalandı (${list.length} satır). Excel\'e yapıştırabilirsiniz.'),
          duration: const Duration(seconds: 2),
        ),
      );
      AnalyticsService.instance.logEvent(AnalyticsEvents.callsExportCsv, {
        AnalyticsEvents.paramCount: list.length,
      });
    }
  }

  Future<void> _openBulkSms() async {
    final list = _selectedIds.isEmpty ? _docs : _selectedDocs();
    final phones = _phonesFromDocs(list);
    if (phones.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('SMS göndermek için en az bir geçerli numara seçin.')),
        );
      }
      return;
    }
    final ok = await SmsLauncher.openBulkSms(phones);
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS uygulaması açılamadı.')),
      );
    } else if (mounted && ok) {
      AnalyticsService.instance.logEvent(AnalyticsEvents.callsBulkSms, {
        AnalyticsEvents.paramCount: phones.length,
      });
    }
  }

  /// Toplu WhatsApp: seçili numaraları sırayla WhatsApp’ta açar (opsiyonel mesaj ile).
  Future<void> _openWhatsAppBulk() async {
    final list = _selectedIds.isEmpty ? _docs : _selectedDocs();
    final phones = _phonesFromDocs(list);
    if (phones.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('WhatsApp için en az bir geçerli numara seçin.')),
        );
      }
      return;
    }
    final controller = TextEditingController(text: _whatsappMessage);
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final dTheme = Theme.of(ctx);
        final dIsDark = dTheme.brightness == Brightness.dark;
        final dSurface = dIsDark
            ? AppThemeExtension.of(context).surface
            : AppThemeExtension.of(context).surface;
        final dBg = dIsDark
            ? AppThemeExtension.of(context).background
            : AppThemeExtension.of(context).background;
        final dFg = dIsDark
            ? AppThemeExtension.of(context).textPrimary
            : AppThemeExtension.of(context).textPrimary;
        final dSecondary = dIsDark
            ? AppThemeExtension.of(context).textSecondary
            : AppThemeExtension.of(context).textSecondary;
        return AlertDialog(
          backgroundColor: dSurface,
          title: Text('WhatsApp ile aç', style: TextStyle(color: dFg)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${phones.length} kişi. İsteğe bağlı mesaj yazın; sohbet açıldığında kutuya doldurulur.',
                  style: AppTypography.body(ctx).copyWith(color: dSecondary),
                ),
                const SizedBox(height: DesignTokens.space3),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Merhaba, ...',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                    filled: true,
                    fillColor: dBg,
                  ),
                  style: AppTypography.bodyStrong(ctx).copyWith(color: dFg),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(foregroundColor: dSecondary),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              style: FilledButton.styleFrom(
                  backgroundColor: AppThemeExtension.of(context).accent),
              child: const Text('İlkini aç'),
            ),
          ],
        );
      },
    );
    if (message == null || !mounted) return;
    _whatsappMessage = message;
    setState(() {
      _whatsappQueue = phones;
      _whatsappIndex = 0;
    });
    final opened = await WhatsAppLauncher.openChat(phones.first,
        message: _whatsappMessage.trim().isEmpty ? null : _whatsappMessage);
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('WhatsApp açılamadı. Uygulama yüklü mü kontrol edin.')),
      );
    }
    setState(() => _whatsappIndex = 1);
    if (_whatsappIndex >= _whatsappQueue!.length) {
      setState(() {
        _whatsappQueue = null;
        _whatsappIndex = 0;
      });
    }
    AnalyticsService.instance.logEvent(AnalyticsEvents.callsBulkWhatsappStart, {
      AnalyticsEvents.paramCount: phones.length,
    });
  }

  Future<void> _openNextWhatsApp() async {
    final queue = _whatsappQueue;
    if (queue == null || _whatsappIndex >= queue.length) {
      setState(() {
        _whatsappQueue = null;
        _whatsappIndex = 0;
      });
      return;
    }
    final phone = queue[_whatsappIndex];
    final message = _whatsappMessage.trim().isEmpty ? null : _whatsappMessage;
    await WhatsAppLauncher.openChat(phone, message: message);
    if (!mounted) return;
    setState(() => _whatsappIndex = _whatsappIndex + 1);
    if (_whatsappIndex >= queue.length) {
      setState(() {
        _whatsappQueue = null;
        _whatsappIndex = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp listesi tamamlandı.')),
      );
    }
  }

  void _clearWhatsAppQueue() {
    setState(() {
      _whatsappQueue = null;
      _whatsappIndex = 0;
    });
  }

  String _syncSubtitleHint(LocalCallSyncUiState s) {
    return switch (s) {
      LocalCallSyncUiState.pending => 'Senkron bekleniyor',
      LocalCallSyncUiState.syncing => 'Senkronize ediliyor',
      LocalCallSyncUiState.synced => 'Buluta kayıtlı',
      LocalCallSyncUiState.failedRetry => 'Tekrar denenecek',
      LocalCallSyncUiState.failedPermanent => 'Senkron başarısız (süre aşımı)',
    };
  }

  Widget _buildIosInfoBanner(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space6,
        DesignTokens.space2,
        DesignTokens.space6,
        DesignTokens.space3,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ext.surfaceElevated,
          borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
          border: Border.all(color: ext.border.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: ext.accent.withValues(alpha: 0.85)),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Text(
                  'iOS: Yalnızca uygulama içi (Magic Call) aramaları görünür. Sistem çağrı günlüğü Apple kısıtlaması nedeniyle eklenmez.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ext.textSecondary,
                        height: 1.35,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _syncDeviceCallLog() async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    if (uid == null || uid.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş yapılı değil.')),
        );
      }
      return;
    }
    if (!io.Platform.isAndroid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Telefon çağrı günlüğü sadece Android\'de desteklenir. iOS\'ta uygulama içi aramalar listelenir.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    setState(() => _isSyncingDeviceCalls = true);
    final result =
        await DeviceCallLogSyncService.instance.syncCallLogToFirestore(uid);
    if (!mounted) return;
    setState(() => _isSyncingDeviceCalls = false);
    AnalyticsService.instance.logEvent(AnalyticsEvents.callsDeviceSyncResult, {
      AnalyticsEvents.paramResult: result.name,
    });
    switch (result) {
      case DeviceCallLogSyncResult.success:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telefon çağrıları senkronize edildi.')),
        );
        break;
      case DeviceCallLogSyncResult.permissionDenied:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çağrı günlüğü izni verilmedi.')),
        );
        break;
      case DeviceCallLogSyncResult.permissionPermanentlyDenied:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Çağrı günlüğü izni kapalı. Ayarlardan açabilirsiniz.'),
            action: SnackBarAction(
              label: 'Ayarlar',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        break;
      case DeviceCallLogSyncResult.notSupported:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bu cihazda çağrı günlüğü desteklenmiyor.')),
        );
        break;
      case DeviceCallLogSyncResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Senkronizasyon sırasında hata oluştu.')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? AppThemeExtension.of(context).background
        : AppThemeExtension.of(context).background;
    final fg = isDark
        ? AppThemeExtension.of(context).textPrimary
        : AppThemeExtension.of(context).textPrimary;
    final surface = isDark
        ? AppThemeExtension.of(context).surface
        : AppThemeExtension.of(context).surface;
    final textSecondary = isDark
        ? AppThemeExtension.of(context).textSecondary
        : AppThemeExtension.of(context).textSecondary;
    final callsAsync = ref.watch(consultantCallsStreamProvider);
    ref.listen(consultantCallsStreamProvider, (prev, next) {
      next.whenOrNull(
        data: (docs) {
          AppLogger.i('[consultant_calls] resolved docs=${docs.length}');
        },
        error: (e, st) {
          AppLogger.e('[consultant_calls] load error', e, st);
        },
      );
    });

    final queue = _whatsappQueue;
    final hasQueue =
        queue != null && queue.isNotEmpty && _whatsappIndex < queue.length;

    return Scaffold(
      backgroundColor: bg,
      appBar: emlakAppBar(
        context,
        title: const Text('Tüm Çağrılar'),
        backgroundColor: theme.appBarTheme.backgroundColor ?? bg,
        foregroundColor: theme.appBarTheme.foregroundColor ?? fg,
        actions: [
          if (io.Platform.isAndroid)
            IconButton(
              icon: _isSyncingDeviceCalls
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppThemeExtension.of(context).accent),
                    )
                  : const Icon(Icons.phone_android_rounded),
              tooltip: 'Telefon çağrılarını senkronize et',
              onPressed: _isSyncingDeviceCalls ? null : _syncDeviceCallLog,
            ),
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'CSV\'yi panoya kopyala',
            onPressed: _copyCsvToClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.sms_rounded),
            tooltip: 'Toplu SMS',
            onPressed: _openBulkSms,
          ),
          IconButton(
            icon: const Icon(Icons.chat_rounded),
            tooltip: 'WhatsApp ile aç',
            onPressed: _openWhatsAppBulk,
          ),
        ],
      ),
      body: callsAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                  color: AppThemeExtension.of(context).accent),
              const SizedBox(height: DesignTokens.space4),
              Text(
                'Çağrılar hazırlanıyor...',
                style: AppTypography.body(context),
              ),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    color: textSecondary, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Çağrılar yüklenemedi.',
                  style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('$e',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _retryCallsLoad,
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
        data: (docs) {
          _docs = docs;
          final locals =
              ref.watch(localCallRecordsStreamProvider).valueOrNull ?? [];
          final docIds = docs.map((d) => d.id).toSet();
          final byFirestoreId = <String, LocalCallRecord>{};
          for (final r in locals) {
            final fid = r.firestoreDocumentId;
            if (fid != null && fid.isNotEmpty) {
              byFirestoreId[fid] = r;
            }
          }
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final localStandalone = <LocalCallRecord>[];
          for (final r in locals) {
            final fid = r.firestoreDocumentId;
            if (fid != null && docIds.contains(fid)) continue;
            if (deriveLocalCallSyncUiState(r, nowMs: nowMs) ==
                LocalCallSyncUiState.synced) {
              continue;
            }
            localStandalone.add(r);
          }
          localStandalone.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (_docs.isEmpty && localStandalone.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (io.Platform.isIOS) _buildIosInfoBanner(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space6),
                    child: EmptyState(
                      premiumVisual: true,
                      grouped: true,
                      anchorAboveCenter: true,
                      icon: Icons.call_rounded,
                      title:
                          AppLocalizations.of(context).t('empty_calls_title'),
                      subtitle:
                          AppLocalizations.of(context).t('empty_calls_sub'),
                      actionLabel:
                          AppLocalizations.of(context).t('empty_calls_cta'),
                      onAction: () => context.push(
                        AppRouter.routeCall,
                        extra: const {
                          'startedFromScreen': 'consultant_calls',
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          final totalCount = localStandalone.length + _docs.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (io.Platform.isIOS) _buildIosInfoBanner(context),
              Material(
                color: surface,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.space6,
                    DesignTokens.space3,
                    DesignTokens.space6,
                    DesignTokens.space2,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$totalCount kayıt',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _selectAll(true),
                        style: TextButton.styleFrom(
                            foregroundColor:
                                AppThemeExtension.of(context).accent),
                        child: const Text('Tümünü seç'),
                      ),
                      TextButton(
                        onPressed: () => _selectAll(false),
                        style: TextButton.styleFrom(
                            foregroundColor: textSecondary),
                        child: const Text('Seçimi kaldır'),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(DesignTokens.space2),
                  itemCount: totalCount,
                  cacheExtent: 300,
                  itemBuilder: (context, index) {
                    if (index < localStandalone.length) {
                      final r = localStandalone[index];
                      final dt =
                          DateTime.fromMillisecondsSinceEpoch(r.createdAt);
                      final dateStr =
                          '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                      final outcomeStr = r.outcome ?? '—';
                      final syncHint = _syncSubtitleHint(
                        deriveLocalCallSyncUiState(r, nowMs: nowMs),
                      );
                      return Card(
                        margin:
                            const EdgeInsets.only(bottom: DesignTokens.space2),
                        color: surface,
                        child: CheckboxListTile(
                          value: false,
                          onChanged: null,
                          title: Row(
                            children: [
                              Icon(
                                Icons.cloud_off_outlined,
                                size: 18,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r.phoneNumber,
                                  style: TextStyle(
                                    color: fg,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              CallSyncStatusIcon(
                                record: r,
                                onManualRetry: deriveLocalCallSyncUiState(r,
                                            nowMs: nowMs) ==
                                        LocalCallSyncUiState.failedPermanent
                                    ? () =>
                                        unawaited(retryLocalCallRecordSync(r))
                                    : null,
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$dateStr · Yerel · $outcomeStr · $syncHint',
                              style:
                                  TextStyle(color: textSecondary, fontSize: 12),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          activeColor: AppThemeExtension.of(context).accent,
                        ),
                      );
                    }
                    final doc = _docs[index - localStandalone.length];
                    final data = doc.data();
                    final id = doc.id;
                    final direction = data['direction'] as String? ??
                        data['callDirection'] as String? ??
                        '';
                    final isIncoming = direction == 'incoming';
                    final phone = data['phoneNumber'] as String? ??
                        data['phone'] as String? ??
                        '—';
                    final duration = data['durationSec'] as num?;
                    final durationStr =
                        duration != null ? '${duration.toInt()} sn' : '—';
                    final outcomeRaw = data['outcome'] as String? ??
                        data['callOutcome'] as String?;
                    final outcomeStr = outcomeRaw != null
                        ? (_outcomeLabels[outcomeRaw] ?? outcomeRaw)
                        : '—';
                    final createdAt = data['createdAt'];
                    String dateStr = '—';
                    if (createdAt is Timestamp) {
                      final dt = createdAt.toDate();
                      dateStr =
                          '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                    }
                    final selected = _selectedIds.contains(id);
                    final hasPhone = (data['phoneNumber'] as String? ??
                            data['phone'] as String?)
                        .toString()
                        .trim()
                        .isNotEmpty;
                    final match = byFirestoreId[id];
                    final firestoreSubtitle = match != null
                        ? '$dateStr · $durationStr · $outcomeStr · ${_syncSubtitleHint(deriveLocalCallSyncUiState(match, nowMs: nowMs))}'
                        : '$dateStr · $durationStr · $outcomeStr · Sunucu';

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: DesignTokens.space2),
                      color: surface,
                      child: CheckboxListTile(
                        value: selected,
                        onChanged:
                            hasPhone ? (_) => _toggleSelection(id) : null,
                        title: Row(
                          children: [
                            Icon(
                              isIncoming
                                  ? Icons.call_received_rounded
                                  : Icons.call_made_rounded,
                              size: 18,
                              color: isIncoming
                                  ? AppThemeExtension.of(context).success
                                  : AppThemeExtension.of(context).info,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                phone,
                                style: TextStyle(
                                  color: fg,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (match != null)
                              CallSyncStatusIcon(
                                record: match,
                                onManualRetry: deriveLocalCallSyncUiState(match,
                                            nowMs: nowMs) ==
                                        LocalCallSyncUiState.failedPermanent
                                    ? () => unawaited(
                                        retryLocalCallRecordSync(match))
                                    : null,
                              )
                            else
                              const ServerOnlyCallSourceIcon(),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            firestoreSubtitle,
                            style:
                                TextStyle(color: textSecondary, fontSize: 12),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        activeColor: AppThemeExtension.of(context).accent,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: hasQueue
          ? Material(
              color: surface,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space4,
                      vertical: DesignTokens.space2),
                  child: Row(
                    children: [
                      Icon(Icons.chat_rounded,
                          color: AppThemeExtension.of(context).accent,
                          size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sıradakini aç (${_whatsappIndex + 1}/${queue.length})',
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _openNextWhatsApp,
                        style: TextButton.styleFrom(
                            foregroundColor:
                                AppThemeExtension.of(context).accent),
                        child: const Text('Sıradakini aç'),
                      ),
                      TextButton(
                        onPressed: _clearWhatsAppQueue,
                        style: TextButton.styleFrom(
                            foregroundColor: textSecondary),
                        child: const Text('Bitir'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
