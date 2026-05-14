import 'package:emlakmaster_mobile/core/copy/product_labels.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/platform/io_platform_stub.dart'
    if (dart.library.io) 'dart:io' as io;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:emlakmaster_mobile/core/utils/csv_export.dart';
import 'package:emlakmaster_mobile/core/utils/sms_launcher.dart';
import 'package:emlakmaster_mobile/core/utils/whatsapp_launcher.dart';
import 'package:emlakmaster_mobile/core/analytics/analytics_events.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/device_call_log_sync_service.dart';
import 'package:emlakmaster_mobile/features/calls/domain/quick_call_outcome.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/calls/data/local_call_record.dart';
import 'package:emlakmaster_mobile/features/calls/domain/local_call_sync_ui_state.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/firestore_agent_display_names_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/local_call_records_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/crm_call_record_display.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_sync_status_icon.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/crm_call_operating_card.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/crm_call_record_list_item.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_identity_quick_actions_sheet.dart';
import 'package:emlakmaster_mobile/screens/consultant_shell_nav.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_surface_card_rhythm.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_card_memory_hints.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_surface_quick_filter.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_surface_contextual_insight.dart';
import 'package:emlakmaster_mobile/features/contact_save/presentation/widgets/save_contact_sheet.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/calls_surface_ack.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/widgets/call_callback_work_mode_cue.dart';
import 'package:emlakmaster_mobile/core/phone/outbound_phone_dial.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/domain/crm_call_record_helpers.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
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
  CallSurfaceQuickFilter _quickFilter = CallSurfaceQuickFilter.all;

  /// WhatsApp sırayla aç: kuyruk ve şu anki indeks (açılan bir sonraki).
  List<String>? _whatsappQueue;
  int _whatsappIndex = 0;
  String _whatsappMessage = '';
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];

  void _openCustomerDirectoryForLinking() {
    ConsultantShellNav.goToCustomersTab(context);
  }

  void _selectAll(
    bool select, [
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>? firestoreVisible,
  ]) {
    setState(() {
      if (select) {
        final target = firestoreVisible ?? _docs;
        for (final d in target) {
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
        HapticFeedback.selectionClick();
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
        const SnackBar(content: Text('Dışarı alınacak görüşme yok.')),
      );
      return;
    }
    final csv = callsToCsvWithPhones(list);
    Clipboard.setData(ClipboardData(text: csv));
    if (mounted) {
      showCallsSurfaceAck(
        context,
        'CSV panoya hazır · ${list.length} satır',
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
              content: Text('SMS için en az bir geçerli numara seçin.')),
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
      showCallsSurfaceAck(context, 'SMS akışı başlatıldı');
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
          title: Text('WhatsApp akışını aç', style: TextStyle(color: dFg)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${phones.length} kişi seçildi. Dilerseniz bir mesaj hazırlayın; sohbet açıldığında kutuya yerleşir.',
                  style: AppTypography.body(ctx).copyWith(color: dSecondary),
                ),
                const SizedBox(height: DesignTokens.space3),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Merhaba, size uygun bir ilan paylaşabilirim...',
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
              child: const Text('İlk sohbeti aç'),
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
            content: Text(
                'WhatsApp açılamadı. Uygulamanın yüklü olduğundan emin olun.')),
      );
    } else if (mounted) {
      showCallsSurfaceAck(context, 'Mesaj akışı başlatıldı');
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
        const SnackBar(content: Text('WhatsApp akışı tamamlandı.')),
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
      LocalCallSyncUiState.pending => 'Aktarım sırası bekleniyor',
      LocalCallSyncUiState.syncing => 'Buluta aktarılıyor',
      LocalCallSyncUiState.synced => 'Bulutta hazır',
      LocalCallSyncUiState.failedRetry => 'Kısa süre sonra yeniden denenecek',
      LocalCallSyncUiState.failedPermanent =>
        'Buluta aktarılamadı · Yeniden dene',
    };
  }

  Widget _buildIosInfoBanner(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space2 + 2,
        DesignTokens.space4,
        DesignTokens.space2 + 2,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ext.infoSurface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(color: ext.border.withValues(alpha: 0.52)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space3,
            DesignTokens.space4,
            DesignTokens.space4,
            DesignTokens.space3,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  margin: const EdgeInsets.only(right: DesignTokens.space3),
                  decoration: BoxDecoration(
                    color: ext.accent.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: ext.info,
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      'Ürün notu',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: ext.accent.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space1),
                    Text(
                      'iOS’ta yalnızca uygulama içi görüşmeler',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.22,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space1 + 2),
                    Text(
                      'Apple kısıtları nedeniyle sistem arama geçmişi bu listede yer almaz; CRM’deki kayıtlar uygulama üzerinden yapılan görüşmelerdir.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ext.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.48,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _consultantIntelligenceRow(
    BuildContext context,
    CallSurfaceListStats stats,
    AppThemeExtension ext,
    Color fg,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        0,
        DesignTokens.space4,
        DesignTokens.space2,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ext.infoSurface.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: ext.border.withValues(alpha: 0.42)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space3 + 2,
            vertical: DesignTokens.space2 + 2,
          ),
          child: Text(
            'Bugün ${stats.today} kayıt · '
            'Tamamlanması gereken ${stats.pendingCapture} · '
            'Cevapsız ${stats.unanswered}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
          ),
        ),
      ),
    );
  }

  Widget _consultantQuickFilterStrip(AppThemeExtension ext) {
    Widget chip(CallSurfaceQuickFilter f, String label) {
      final sel = _quickFilter == f;
      return Padding(
        padding: const EdgeInsets.only(right: DesignTokens.space2),
        child: FilterChip(
          selected: sel,
          showCheckmark: true,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          side: BorderSide(
            color: sel
                ? ext.accent.withValues(alpha: 0.26)
                : ext.border.withValues(alpha: 0.38),
          ),
          label: Text(label),
          onSelected: (_) => setState(() => _quickFilter = f),
          selectedColor: ext.accent.withValues(alpha: 0.11),
          checkmarkColor: ext.accent,
          labelStyle: TextStyle(
            color: sel ? ext.textPrimary : ext.textSecondary,
            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12.5,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        0,
        DesignTokens.space4,
        DesignTokens.space2,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip(CallSurfaceQuickFilter.all, 'Tümü'),
            chip(CallSurfaceQuickFilter.today, 'Bugün'),
            chip(CallSurfaceQuickFilter.unanswered, 'Cevapsız'),
            chip(CallSurfaceQuickFilter.callback, 'Geri aranacak'),
            chip(CallSurfaceQuickFilter.reached, 'Ulaşılan'),
            chip(CallSurfaceQuickFilter.hot, 'Sıcak'),
            chip(CallSurfaceQuickFilter.fresh, 'Yeni'),
          ],
        ),
      ),
    );
  }

  Widget _consultantSelectionCommandBar(
    BuildContext context,
    AppThemeExtension ext,
    Color fg,
  ) {
    final n = _selectedIds.length;
    return Material(
      color: ext.card,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: ext.border.withValues(alpha: 0.38)),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space1 + 2,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Text(
                '$n seçili',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _openBulkSms,
                icon: const Icon(Icons.sms_rounded),
                tooltip: 'Toplu SMS',
              ),
              const SizedBox(width: DesignTokens.space2),
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _openWhatsAppBulk,
                icon: const Icon(Icons.chat_rounded),
                tooltip: 'WhatsApp akışı',
              ),
              const SizedBox(width: DesignTokens.space2),
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _copyCsvToClipboard,
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'CSV panoya',
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
          const SnackBar(content: Text('Oturum açık değil.')),
        );
      }
      return;
    }
    if (!io.Platform.isAndroid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Telefon arama geçmişi yalnızca Android\'de desteklenir. iOS\'ta yalnızca uygulama içi görüşmeler listelenir.'),
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
          const SnackBar(content: Text('Telefon görüşmeleri içeri alındı.')),
        );
        break;
      case DeviceCallLogSyncResult.permissionDenied:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arama geçmişi izni verilmedi.')),
        );
        break;
      case DeviceCallLogSyncResult.permissionPermanentlyDenied:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Arama geçmişi izni kapalı. İsterseniz ayarlardan açabilirsiniz.'),
            action: SnackBarAction(
              label: 'İzin ayarları',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        break;
      case DeviceCallLogSyncResult.notSupported:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bu cihaz arama geçmişini desteklemiyor.')),
        );
        break;
      case DeviceCallLogSyncResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aktarım sırasında bir sorun oluştu.')),
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
    final ext = AppThemeExtension.of(context);
    final callsAsync = ref.watch(consultantCallsStreamProvider);
    final currentUid =
        ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''));
    final customers = ref.watch(customerListForAgentProvider).valueOrNull ??
        const <CustomerEntity>[];
    final customerById = {for (final c in customers) c.id: c};
    final agentNames =
        ref.watch(firestoreAgentDisplayNamesProvider).valueOrNull ??
            const <String, String>{};
    if (kDebugMode && callsAsync.isLoading) {
      AppLogger.d('[consultant_calls] loading...');
    }
    if (kDebugMode && callsAsync.hasError) {
      AppLogger.w(
        '[consultant_calls] error',
        callsAsync.error,
        callsAsync.stackTrace,
      );
    }

    final queue = _whatsappQueue;
    final hasQueue =
        queue != null && queue.isNotEmpty && _whatsappIndex < queue.length;

    return Scaffold(
      backgroundColor: bg,
      appBar: emlakAppBar(
        context,
        title: Text(
          ProductLabels.myCalls,
          style: AppTypography.pageHeading(context).copyWith(
            fontSize: DesignTokens.fontSizeXl,
            letterSpacing: -0.32,
            height: 1.06,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? bg,
        foregroundColor: theme.appBarTheme.foregroundColor ?? fg,
        actions: [
          if (io.Platform.isAndroid)
            IconButton(
              style: IconButton.styleFrom(
                minimumSize: const Size(44, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor:
                    theme.appBarTheme.actionsIconTheme?.color ?? ext.accent,
              ),
              icon: _isSyncingDeviceCalls
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ext.accent),
                    )
                  : const Icon(Icons.phone_android_rounded),
              tooltip: 'Telefon görüşmelerini içeri al',
              onPressed: _isSyncingDeviceCalls ? null : _syncDeviceCallLog,
            ),
          IconButton(
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor:
                  theme.appBarTheme.actionsIconTheme?.color ?? ext.accent,
            ),
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'CSV\'yi panoya al',
            onPressed: _copyCsvToClipboard,
          ),
          IconButton(
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor:
                  theme.appBarTheme.actionsIconTheme?.color ?? ext.accent,
            ),
            icon: const Icon(Icons.sms_rounded),
            tooltip: 'Toplu SMS gönder',
            onPressed: _openBulkSms,
          ),
          IconButton(
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor:
                  theme.appBarTheme.actionsIconTheme?.color ?? ext.accent,
            ),
            icon: const Icon(Icons.chat_rounded),
            tooltip: 'WhatsApp akışını aç',
            onPressed: _openWhatsAppBulk,
          ),
        ],
      ),
      body: callsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
              color: AppThemeExtension.of(context).accent),
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
                  style: AppTypography.cardHeading(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(FirestoreService.userFacingErrorMessage(e),
                    style: AppTypography.body(context)
                        .copyWith(color: textSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: DesignTokens.space4),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(consultantCallsStreamProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
        data: (docs) {
          _docs = docs;
          if (kDebugMode) {
            AppLogger.d('[consultant_calls] loaded docs=${docs.length}');
          }
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
                      outlinedActionLabel: 'Portföye kaydet',
                      onOutlinedAction: () => showSaveContactSheet(
                        context,
                        source: 'consultant_calls_empty',
                      ),
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
          final filteredDocs = _docs
              .where(
                (d) => CallSurfaceQuickFilterLogic.matchesFirestoreDoc(
                  d,
                  _quickFilter,
                ),
              )
              .toList();
          final filteredLocals = localStandalone
              .where(
                (r) => CallSurfaceQuickFilterLogic.matchesLocalRecord(
                  r,
                  _quickFilter,
                ),
              )
              .toList();
          final visibleTotal =
              filteredLocals.length + filteredDocs.length;
          final stats = CallSurfaceListStats.blendedConsultant(
            docs: _docs,
            locals: localStandalone,
          );
          if (visibleTotal == 0 && totalCount > 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (io.Platform.isIOS) _buildIosInfoBanner(context),
                _consultantIntelligenceRow(
                    context, stats, ext, fg, textSecondary),
                _consultantQuickFilterStrip(ext),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.space6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_alt_off_rounded,
                              size: 44, color: textSecondary),
                          const SizedBox(height: DesignTokens.space3),
                          Text(
                            'Bu filtreye uygun görüşme yok',
                            textAlign: TextAlign.center,
                            style: AppTypography.cardHeading(context),
                          ),
                          const SizedBox(height: DesignTokens.space2),
                          FilledButton.tonal(
                            onPressed: () => setState(() =>
                                _quickFilter = CallSurfaceQuickFilter.all),
                            child: const Text('Filtreyi sıfırla'),
                          ),
                          const SizedBox(height: DesignTokens.space2),
                          OutlinedButton.icon(
                            onPressed: () => context.push(
                              AppRouter.routeCall,
                              extra: const {
                                'startedFromScreen': 'consultant_calls_filter_empty',
                              },
                            ),
                            icon: const Icon(Icons.call_made_rounded, size: 18),
                            label: const Text('Yeni arama başlat'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (io.Platform.isIOS) _buildIosInfoBanner(context),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: surface,
                  border: Border(
                    bottom: BorderSide(
                      color: ext.border.withValues(alpha: isDark ? 0.38 : 0.44),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.space4,
                    DesignTokens.space3,
                    DesignTokens.space4,
                    DesignTokens.space2 + 2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: _quickFilter == CallSurfaceQuickFilter.all
                                    ? '$totalCount'
                                    : '$visibleTotal',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w700,
                                  fontSize: DesignTokens.fontSizeMd,
                                  height: 1.12,
                                ),
                              ),
                              TextSpan(
                                text: _quickFilter == CallSurfaceQuickFilter.all
                                    ? ' görüşme'
                                    : ' görüşme · filtreli',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _selectAll(true, filteredDocs),
                        style: TextButton.styleFrom(
                          foregroundColor: ext.accent,
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.space2 + 2,
                            vertical: DesignTokens.space1,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Hepsini seç'),
                      ),
                      TextButton(
                        onPressed: () => _selectAll(false),
                        style: TextButton.styleFrom(
                          foregroundColor: textSecondary,
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.space2 + 2,
                            vertical: DesignTokens.space1,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Seçimi kaldır'),
                      ),
                    ],
                  ),
                ),
              ),
              _consultantIntelligenceRow(
                  context, stats, ext, fg, textSecondary),
              _consultantQuickFilterStrip(ext),
              if (_quickFilter == CallSurfaceQuickFilter.callback &&
                  visibleTotal > 0)
                CallCallbackWorkModeCue(count: visibleTotal),
              if (_selectedIds.isNotEmpty)
                _consultantSelectionCommandBar(
                    context, ext, fg),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.space4,
                    DesignTokens.space2 + 2,
                    DesignTokens.space4,
                    DesignTokens.space5,
                  ),
                  itemCount: visibleTotal,
                  cacheExtent: 300,
                  itemBuilder: (context, index) {
                    if (index < filteredLocals.length) {
                      final r = filteredLocals[index];
                      final dt =
                          DateTime.fromMillisecondsSinceEpoch(r.createdAt);
                      final dateStr =
                          '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                      final outcomeStr = r.outcome ?? '—';
                      final syncHint = _syncSubtitleHint(
                        deriveLocalCallSyncUiState(r, nowMs: nowMs),
                      );
                      final custName =
                          r.customerId != null && r.customerId!.isNotEmpty
                              ? customerById[r.customerId!]?.fullName
                              : null;
                      final formattedPhone =
                          CrmCallRecordDisplay.formatPhone(r.phoneNumber);
                      final localTitle = CrmCallRecordDisplay.primaryTitle(
                        customerFullName: custName,
                        rawPhone: r.phoneNumber,
                      );
                      final phoneUnder =
                          CrmCallRecordDisplay.shouldShowPhoneUnderTitle(
                        title: localTitle,
                        formattedPhone: formattedPhone,
                      )
                              ? formattedPhone
                              : null;
                      final localFoot = CrmCallRecordDisplay.technicalFootnote(
                        firestoreDocId: r.firestoreDocumentId,
                        customerId: r.customerId,
                      );
                      final localIdentityHint =
                          ((r.customerId?.isEmpty) ?? true) &&
                                  custName == null
                              ? 'Yeni kişi · Müşteri kartına bağlı değil'
                              : null;
                      final localInsight =
                          CallSurfaceContextualInsight.forLocalDraft(
                        outcome: r.outcome,
                        hasCallablePhone: OutboundPhoneDial.isLikelyCallablePhone(
                            r.phoneNumber),
                        hasNote: (r.notes?.trim().isNotEmpty ?? false),
                      );
                      final localRhythm =
                          CallSurfaceCardRhythmLogic.forLocalDraft(r);
                      final localRail =
                          CallSurfacePriorityMarkers.railForLocal(r);
                      final localMemory = CallCardMemoryHints.forLocal(
                        createdAtMs: r.createdAt,
                        notes: r.notes,
                        outcome: r.outcome,
                        followUpReminderAtMs: r.followUpReminderAtMs,
                      );
                      return Slidable(
                        key: ValueKey('sl_local_${r.id}'),
                        startActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.22,
                          children: [
                            SlidableAction(
                              onPressed: (_) async {
                                if (OutboundPhoneDial.isLikelyCallablePhone(
                                    r.phoneNumber)) {
                                  final ok = await OutboundPhoneDial.launchDial(
                                      r.phoneNumber);
                                  if (context.mounted && ok) {
                                    HapticFeedback.mediumImpact();
                                  }
                                }
                              },
                              backgroundColor:
                                  AppThemeExtension.of(context).success,
                              foregroundColor: Colors.white,
                              icon: Icons.call_rounded,
                              label: 'Ara',
                            ),
                          ],
                        ),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.24,
                          children: [
                            SlidableAction(
                              onPressed: (_) {
                                showCallIdentityQuickActionsSheet(
                                  context,
                                  rawPhone: r.phoneNumber,
                                  customerId: r.customerId,
                                  displayLabel: localTitle,
                                  firestoreCallDocId: r.firestoreDocumentId,
                                  onCallListMutated: () => ref.invalidate(
                                      consultantCallsStreamProvider),
                                  onOpenCustomerDirectory:
                                      _openCustomerDirectoryForLinking,
                                );
                              },
                              backgroundColor:
                                  AppThemeExtension.of(context).accent,
                              foregroundColor: Colors.white,
                              icon: Icons.bolt_rounded,
                              label: 'İşlem',
                            ),
                          ],
                        ),
                        child: _LocalCallRecordCard(
                          title: localTitle,
                          phoneSubtitle: phoneUnder,
                          dateStr: dateStr,
                          outcome: QuickCallOutcome.labelTr(outcomeStr),
                          syncHint: syncHint,
                          note: r.notes,
                          technicalFootnote: localFoot,
                          identityFootnote: localIdentityHint,
                          contextualInsight: localInsight,
                          cardRhythm: localRhythm,
                          showPriorityRail: localRail,
                          memoryHint: localMemory,
                          rawPhone: r.phoneNumber,
                          customerId: r.customerId,
                          firestoreDocId: r.firestoreDocumentId,
                          onCallListMutated: () => ref.invalidate(
                              consultantCallsStreamProvider),
                          onOpenCustomerDirectory:
                              _openCustomerDirectoryForLinking,
                          syncIcon: CallSyncStatusIcon(
                            record: r,
                            onManualRetry:
                                deriveLocalCallSyncUiState(r, nowMs: nowMs) ==
                                        LocalCallSyncUiState.failedPermanent
                                    ? () => unawaited(
                                        retryLocalCallRecordSync(r))
                                    : null,
                          ),
                        ),
                      );
                    }
                    final doc =
                        filteredDocs[index - filteredLocals.length];
                    final data = doc.data();
                    final id = doc.id;
                    final direction = data['direction'] as String? ??
                        data['callDirection'] as String? ??
                        '';
                    final isIncoming = direction == 'incoming';
                    final rawPhone = data['phoneNumber'] as String? ??
                        data['phone'] as String? ??
                        '';
                    final hasPhoneDigits =
                        rawPhone.replaceAll(RegExp(r'\D'), '').isNotEmpty;
                    final phone = hasPhoneDigits
                        ? CrmCallRecordDisplay.formatPhone(rawPhone)
                        : '—';
                    final duration = data['durationSec'] as num?;
                    final durationStr =
                        duration != null ? '${duration.toInt()} sn' : '—';
                    final outcomeRaw = data['outcome'] as String? ??
                        data['callOutcome'] as String?;
                    final outcomeStr = outcomeRaw != null
                        ? (CrmCallRecordHelpers
                                .kOutcomeCodeLabelsTr[outcomeRaw] ??
                            outcomeRaw)
                        : '—';
                    final createdAt = data['createdAt'];
                    String dateStr = '—';
                    if (createdAt is Timestamp) {
                      final dt = createdAt.toDate();
                      dateStr =
                          '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                    }
                    final selected = _selectedIds.contains(id);
                    final hasPhone = rawPhone.trim().isNotEmpty;
                    final contactName =
                        CrmCallRecordDisplay.contactNameFromCallData(data);
                    final match = byFirestoreId[id];
                    final customerId = (data['customerId'] as String?)?.trim();
                    final customerName =
                        customerId != null && customerId.isNotEmpty
                            ? customerById[customerId]?.fullName
                            : null;
                    final note =
                        CrmCallRecordDisplay.notePreviewFromFirestoreData(
                      data,
                      maxLen: 160,
                    );
                    final advisorId = (data['advisorId'] as String?)?.trim() ??
                        (data['agentId'] as String?)?.trim() ??
                        '';
                    final advisorPart = CrmCallRecordDisplay.advisorContext(
                      advisorAgentId: advisorId,
                      currentUid: currentUid,
                      agentNames: agentNames,
                    );
                    final contextLine = CrmCallRecordDisplay.contextLine(
                      advisorPart: advisorPart,
                      dateTime: dateStr,
                      duration: durationStr,
                    );
                    final completionLabel =
                        CrmCallRecordHelpers.captureStatusTr(data);
                    final resolvedCustomerName = customerName?.trim();
                    final rowTitle = CrmCallRecordDisplay.primaryTitle(
                      customerFullName: (resolvedCustomerName != null &&
                              resolvedCustomerName.isNotEmpty)
                          ? resolvedCustomerName
                          : null,
                      contactDisplayName: contactName,
                      rawPhone: rawPhone.isEmpty ? null : rawPhone,
                    );
                    final phoneUnder =
                        CrmCallRecordDisplay.shouldShowPhoneUnderTitle(
                      title: rowTitle,
                      formattedPhone: phone,
                    )
                            ? phone
                            : null;
                    final technicalMeta =
                        CrmCallRecordDisplay.technicalFootnote(
                      firestoreDocId: id,
                      customerId: customerId,
                    );
                    final identityHint =
                        (customerId == null || customerId.isEmpty) &&
                                (contactName?.trim().isEmpty ?? true) &&
                                (resolvedCustomerName == null ||
                                    resolvedCustomerName.isEmpty)
                            ? 'Yeni kişi · Müşteri kartına bağlı değil'
                            : null;

                    final fsInsight = CallSurfaceContextualInsight.forFirestoreData(
                      data,
                      notePreview: note,
                      hasCallablePhone: hasPhone &&
                          OutboundPhoneDial.isLikelyCallablePhone(rawPhone),
                    );
                    final cardRhythm =
                        CallSurfaceCardRhythmLogic.forFirestore(data);
                    final showPriorityRail =
                        CallSurfacePriorityMarkers.railForFirestore(data);
                    final memoryHint = CallCardMemoryHints.forFirestore(
                      data,
                      notePreview: note,
                    );

                    return Slidable(
                      key: ValueKey('sl_fs_$id'),
                      startActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.22,
                        children: [
                          SlidableAction(
                            onPressed: (_) async {
                              if (OutboundPhoneDial.isLikelyCallablePhone(
                                  rawPhone)) {
                                final ok =
                                    await OutboundPhoneDial.launchDial(rawPhone);
                                if (context.mounted && ok) {
                                  HapticFeedback.mediumImpact();
                                }
                              }
                            },
                            backgroundColor:
                                AppThemeExtension.of(context).success,
                            foregroundColor: Colors.white,
                            icon: Icons.call_rounded,
                            label: 'Ara',
                          ),
                        ],
                      ),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.24,
                        children: [
                          SlidableAction(
                            onPressed: (_) {
                              if (!hasPhone) return;
                              showCallIdentityQuickActionsSheet(
                                context,
                                rawPhone: rawPhone,
                                customerId: customerId,
                                displayLabel: rowTitle,
                                firestoreCallDocId: id,
                                onCallListMutated: () => ref.invalidate(
                                    consultantCallsStreamProvider),
                                onOpenCustomerDirectory:
                                    _openCustomerDirectoryForLinking,
                              );
                            },
                            backgroundColor:
                                AppThemeExtension.of(context).accent,
                            foregroundColor: Colors.white,
                            icon: Icons.bolt_rounded,
                            label: 'İşlem',
                          ),
                        ],
                      ),
                      child: _FirestoreCallRecordCard(
                        selected: selected,
                        enabled: hasPhone,
                        onSelect: hasPhone ? () => _toggleSelection(id) : null,
                        title: rowTitle,
                        phoneSubtitle: phoneUnder,
                        outcome: outcomeStr,
                        contextLine: contextLine,
                        stateLabel: completionLabel,
                        note: note,
                        technicalMeta: technicalMeta,
                        identityFootnote: identityHint,
                        contextualInsight: fsInsight,
                        cardRhythm: cardRhythm,
                        showPriorityRail: showPriorityRail,
                        memoryHint: memoryHint,
                        rawPhone: rawPhone,
                        customerId: customerId,
                        firestoreDocId: id,
                        onCallListMutated: () => ref.invalidate(
                            consultantCallsStreamProvider),
                        onOpenCustomerDirectory: _openCustomerDirectoryForLinking,
                        leadingIcon: isIncoming
                            ? Icons.call_received_rounded
                            : Icons.call_made_rounded,
                        leadingColor: isIncoming
                            ? AppThemeExtension.of(context).success
                            : AppThemeExtension.of(context).info,
                        trailing: match != null
                            ? CallSyncStatusIcon(
                                record: match,
                                onManualRetry:
                                    deriveLocalCallSyncUiState(match,
                                                nowMs: nowMs) ==
                                            LocalCallSyncUiState
                                                .failedPermanent
                                        ? () => unawaited(
                                            retryLocalCallRecordSync(match))
                                        : null,
                              )
                            : const ServerOnlyCallSourceIcon(),
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
                          'Sıradaki sohbeti aç (${_whatsappIndex + 1}/${queue.length})',
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
                        child: const Text('Akışı kapat'),
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

class _LocalCallRecordCard extends StatelessWidget {
  const _LocalCallRecordCard({
    required this.title,
    this.phoneSubtitle,
    required this.dateStr,
    required this.outcome,
    required this.syncHint,
    required this.note,
    this.technicalFootnote,
    this.identityFootnote,
    this.contextualInsight,
    required this.cardRhythm,
    required this.showPriorityRail,
    this.memoryHint,
    required this.rawPhone,
    this.customerId,
    this.firestoreDocId,
    this.onCallListMutated,
    this.onOpenCustomerDirectory,
    required this.syncIcon,
  });

  final String title;
  final String? phoneSubtitle;
  final String dateStr;
  final String outcome;
  final String syncHint;
  final String? note;
  final String? technicalFootnote;
  final String? identityFootnote;
  final String? contextualInsight;
  final CallSurfaceCardRhythm cardRhythm;
  final bool showPriorityRail;
  final String? memoryHint;
  final String rawPhone;
  final String? customerId;
  final String? firestoreDocId;
  final VoidCallback? onCallListMutated;
  final VoidCallback? onOpenCustomerDirectory;
  final Widget syncIcon;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final contextLine = CrmCallRecordDisplay.contextLine(
      advisorPart: 'Bu cihaz',
      dateTime: dateStr,
    );
    final callable = OutboundPhoneDial.isLikelyCallablePhone(rawPhone);
    final cid = customerId?.trim();
    return CrmCallOperatingCard(
      rhythm: cardRhythm,
      showPriorityRail: showPriorityRail,
      child: CrmCallRecordListItem(
        title: title,
        phoneSubtitle: phoneSubtitle,
        outcomeLabel: outcome,
        captureLabel: syncHint,
        contextLine: contextLine,
        notePreview: note,
        technicalFootnote: technicalFootnote,
        identityFootnote: identityFootnote,
        contextualInsight: contextualInsight,
        memoryHint: memoryHint,
        onOpenCustomerCard: cid != null && cid.isNotEmpty
            ? () => context.push('/customer/$cid')
            : null,
        onIdentityTap: callable
            ? () => showCallIdentityQuickActionsSheet(
                  context,
                  rawPhone: rawPhone,
                  customerId: customerId,
                  displayLabel: title,
                  firestoreCallDocId: firestoreDocId,
                  onCallListMutated: onCallListMutated,
                  onOpenCustomerDirectory: onOpenCustomerDirectory,
                )
            : null,
        onIdentityLongPress: callable
            ? () {
                unawaited(OutboundPhoneDial.launchDial(rawPhone));
              }
            : null,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ext.textSecondary.withValues(alpha: 0.075),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm + 2),
            border: Border.all(
              color: ext.border.withValues(alpha: 0.38),
            ),
          ),
          child: Icon(Icons.phone_in_talk_rounded,
              color: ext.textSecondary, size: 20),
        ),
        trailing: syncIcon,
      ),
    );
  }
}

class _FirestoreCallRecordCard extends StatelessWidget {
  const _FirestoreCallRecordCard({
    required this.selected,
    required this.enabled,
    required this.onSelect,
    required this.title,
    this.phoneSubtitle,
    required this.outcome,
    required this.contextLine,
    required this.stateLabel,
    required this.note,
    this.technicalMeta,
    this.identityFootnote,
    this.contextualInsight,
    required this.cardRhythm,
    required this.showPriorityRail,
    this.memoryHint,
    required this.rawPhone,
    this.customerId,
    this.firestoreDocId,
    this.onCallListMutated,
    this.onOpenCustomerDirectory,
    required this.leadingIcon,
    required this.leadingColor,
    required this.trailing,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback? onSelect;
  final String title;
  final String? phoneSubtitle;
  final String outcome;
  final String contextLine;
  final String stateLabel;
  final String? note;
  final String? technicalMeta;
  final String? identityFootnote;
  final String? contextualInsight;
  final CallSurfaceCardRhythm cardRhythm;
  final bool showPriorityRail;
  final String? memoryHint;
  final String rawPhone;
  final String? customerId;
  final String? firestoreDocId;
  final VoidCallback? onCallListMutated;
  final VoidCallback? onOpenCustomerDirectory;
  final IconData leadingIcon;
  final Color leadingColor;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final callable =
        enabled && OutboundPhoneDial.isLikelyCallablePhone(rawPhone);

    Widget? belowChips;
    if (selected && callable) {
      final actionStyle = TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );
      belowChips = Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: DesignTokens.space2,
            runSpacing: 6,
            children: [
              TextButton.icon(
                style: actionStyle,
                onPressed: () {
                  unawaited(OutboundPhoneDial.launchDial(rawPhone));
                },
                icon: Icon(Icons.call_rounded, size: 17, color: ext.accent),
                label: Text(
                  'Ara',
                  style: TextStyle(
                    color: ext.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton.icon(
                style: actionStyle,
                onPressed: () {
                  showCallIdentityQuickActionsSheet(
                    context,
                    rawPhone: rawPhone,
                    customerId: customerId,
                    displayLabel: title,
                    firestoreCallDocId: firestoreDocId,
                    onCallListMutated: onCallListMutated,
                    onOpenCustomerDirectory: onOpenCustomerDirectory,
                  );
                },
                icon: Icon(Icons.more_horiz_rounded,
                    size: 17, color: ext.textSecondary),
                label: Text(
                  'İşlemler',
                  style: TextStyle(
                    color: ext.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final cid = customerId?.trim();

    return CrmCallOperatingCard(
      selected: selected,
      rhythm: cardRhythm,
      showPriorityRail: showPriorityRail,
      child: InkWell(
        onTap: enabled ? onSelect : null,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardSecondary),
        child: Padding(
          padding: EdgeInsets.zero,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 6),
                child: CheckboxTheme(
                  data: CheckboxThemeData(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: BorderSide(
                      color: ext.border.withValues(alpha: 0.55),
                      width: 1.1,
                    ),
                  ),
                  child: Checkbox(
                    value: selected,
                    onChanged: enabled ? (_) => onSelect?.call() : null,
                    activeColor: ext.accent,
                  ),
                ),
              ),
              Expanded(
                child: CrmCallRecordListItem(
                  title: title,
                  phoneSubtitle: phoneSubtitle,
                  outcomeLabel: outcome,
                  captureLabel: stateLabel,
                  contextLine: contextLine,
                  notePreview: note,
                  technicalFootnote: technicalMeta,
                  identityFootnote: identityFootnote,
                  contextualInsight: contextualInsight,
                  memoryHint: memoryHint,
                  onOpenCustomerCard: cid != null && cid.isNotEmpty
                      ? () => context.push('/customer/$cid')
                      : null,
                  onIdentityTap: callable
                      ? () => showCallIdentityQuickActionsSheet(
                            context,
                            rawPhone: rawPhone,
                            customerId: customerId,
                            displayLabel: title,
                            firestoreCallDocId: firestoreDocId,
                            onCallListMutated: onCallListMutated,
                            onOpenCustomerDirectory: onOpenCustomerDirectory,
                          )
                      : null,
                  onIdentityLongPress: callable
                      ? () {
                          unawaited(OutboundPhoneDial.launchDial(rawPhone));
                        }
                      : null,
                  belowChipsRow: belowChips,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: leadingColor.withValues(alpha: 0.085),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusSm + 2),
                      border: Border.all(
                        color: leadingColor.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Icon(leadingIcon, color: leadingColor, size: 20),
                  ),
                  trailing: trailing,
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    DesignTokens.space3 + 2,
                    DesignTokens.space4,
                    DesignTokens.space3 + 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
