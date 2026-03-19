import 'package:emlakmaster_mobile/core/platform/io_platform_stub.dart'
    if (dart.library.io) 'dart:io' as io;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/utils/csv_export.dart';
import 'package:emlakmaster_mobile/core/utils/sms_launcher.dart';
import 'package:emlakmaster_mobile/core/utils/whatsapp_launcher.dart';
import 'package:emlakmaster_mobile/core/services/analytics_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/data/device_call_log_sync_service.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Danışmanın tüm çağrıları (gelen/giden), numaralar, toplu veri export ve toplu SMS.
class ConsultantCallsPage extends ConsumerStatefulWidget {
  const ConsultantCallsPage({super.key});

  @override
  ConsumerState<ConsultantCallsPage> createState() => _ConsultantCallsPageState();
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

  List<String> _phonesFromDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> list) {
    final phones = <String>[];
    for (final d in list) {
      final data = d.data();
      final p = data['phoneNumber'] as String? ?? data['phone'] as String? ?? '';
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
          content: Text('CSV panoya kopyalandı (${list.length} satır). Excel\'e yapıştırabilirsiniz.'),
          duration: const Duration(seconds: 2),
        ),
      );
      AnalyticsService.instance.logEvent('calls_export_csv', {
        'count': list.length,
      });
    }
  }

  Future<void> _openBulkSms() async {
    final list = _selectedIds.isEmpty ? _docs : _selectedDocs();
    final phones = _phonesFromDocs(list);
    if (phones.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS göndermek için en az bir geçerli numara seçin.')),
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
      AnalyticsService.instance.logEvent('calls_bulk_sms', {
        'count': phones.length,
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
          const SnackBar(content: Text('WhatsApp için en az bir geçerli numara seçin.')),
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
        final dSurface = dIsDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
        final dBg = dIsDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight;
        final dFg = dIsDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
        final dSecondary = dIsDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;
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
                  style: TextStyle(color: dSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Merhaba, ...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: dBg,
                  ),
                  style: TextStyle(color: dFg),
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
              style: FilledButton.styleFrom(backgroundColor: DesignTokens.primary),
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
    final opened = await WhatsAppLauncher.openChat(phones.first, message: _whatsappMessage.trim().isEmpty ? null : _whatsappMessage);
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp açılamadı. Uygulama yüklü mü kontrol edin.')),
      );
    }
    setState(() => _whatsappIndex = 1);
    if (_whatsappIndex >= _whatsappQueue!.length) {
      setState(() {
        _whatsappQueue = null;
        _whatsappIndex = 0;
      });
    }
    AnalyticsService.instance.logEvent('calls_bulk_whatsapp_start', {'count': phones.length});
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

  Widget _buildIosInfoBanner(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final textSecondary = isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;
    return Material(
      color: surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space2),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'iOS\'ta sadece uygulama içi (Magic Call) aramaları listelenir. Telefon günlüğü Apple politikası gereği eklenemez.',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
            ),
          ],
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
            content: Text('Telefon çağrı günlüğü sadece Android\'de desteklenir. iOS\'ta uygulama içi aramalar listelenir.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    setState(() => _isSyncingDeviceCalls = true);
    final result = await DeviceCallLogSyncService.instance.syncCallLogToFirestore(uid);
    if (!mounted) return;
    setState(() => _isSyncingDeviceCalls = false);
    AnalyticsService.instance.logEvent('calls_device_sync_result', {
      'result': result.name,
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
            content: const Text('Çağrı günlüğü izni kapalı. Ayarlardan açabilirsiniz.'),
            action: SnackBarAction(
              label: 'Ayarlar',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        break;
      case DeviceCallLogSyncResult.notSupported:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu cihazda çağrı günlüğü desteklenmiyor.')),
        );
        break;
      case DeviceCallLogSyncResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senkronizasyon sırasında hata oluştu.')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? DesignTokens.backgroundDark : DesignTokens.backgroundLight;
    final fg = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    final surface = isDark ? DesignTokens.surfaceDark : DesignTokens.surfaceLight;
    final textSecondary = isDark ? DesignTokens.textSecondaryDark : DesignTokens.textSecondaryLight;
    final callsAsync = ref.watch(consultantCallsStreamProvider);

    final queue = _whatsappQueue;
    final hasQueue = queue != null && queue.isNotEmpty && _whatsappIndex < queue.length;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Tüm Çağrılar'),
        backgroundColor: theme.appBarTheme.backgroundColor ?? bg,
        foregroundColor: theme.appBarTheme.foregroundColor ?? fg,
        actions: [
          if (io.Platform.isAndroid)
            IconButton(
              icon: _isSyncingDeviceCalls
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: DesignTokens.primary),
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, color: textSecondary, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Çağrılar yüklenemedi.',
                  style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('$e', style: TextStyle(color: textSecondary, fontSize: 12), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        data: (docs) {
          _docs = docs;
          if (_docs.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (io.Platform.isIOS) _buildIosInfoBanner(context),
                const Expanded(
                  child: Center(
                    child: EmptyState(
                      icon: Icons.call_rounded,
                      title: 'Henüz çağrı yok',
                      subtitle: 'Arama yaptığınızda veya gelen çağrılar kaydedildiğinde burada listelenecek.',
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
              Material(
                color: surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space2),
                  child: Row(
                    children: [
                      Text(
                        '${_docs.length} çağrı',
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _selectAll(true),
                        style: TextButton.styleFrom(foregroundColor: DesignTokens.primary),
                        child: const Text('Tümünü seç'),
                      ),
                      TextButton(
                        onPressed: () => _selectAll(false),
                        style: TextButton.styleFrom(foregroundColor: textSecondary),
                        child: const Text('Seçimi kaldır'),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(DesignTokens.space2),
                  itemCount: _docs.length,
                  cacheExtent: 300,
                  itemBuilder: (context, index) {
                    final doc = _docs[index];
                    final data = doc.data();
                    final id = doc.id;
                    final direction = data['direction'] as String? ?? data['callDirection'] as String? ?? '';
                    final isIncoming = direction == 'incoming';
                    final phone = data['phoneNumber'] as String? ?? data['phone'] as String? ?? '—';
                    final duration = data['durationSec'] as num?;
                    final durationStr = duration != null ? '${duration.toInt()} sn' : '—';
                    final outcomeRaw = data['outcome'] as String? ?? data['callOutcome'] as String?;
                    final outcomeStr = outcomeRaw != null ? (_outcomeLabels[outcomeRaw] ?? outcomeRaw) : '—';
                    final createdAt = data['createdAt'];
                    String dateStr = '—';
                    if (createdAt is Timestamp) {
                      final dt = createdAt.toDate();
                      dateStr = '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                    }
                    final selected = _selectedIds.contains(id);
                    final hasPhone = (data['phoneNumber'] as String? ?? data['phone'] as String?).toString().trim().isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.only(bottom: DesignTokens.space2),
                      color: surface,
                      child: CheckboxListTile(
                        value: selected,
                        onChanged: hasPhone ? (_) => _toggleSelection(id) : null,
                        title: Row(
                          children: [
                            Icon(
                              isIncoming ? Icons.call_received_rounded : Icons.call_made_rounded,
                              size: 18,
                              color: isIncoming ? DesignTokens.success : DesignTokens.info,
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
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$dateStr · $durationStr · $outcomeStr',
                            style: TextStyle(color: textSecondary, fontSize: 12),
                          ),
                        ),
                        activeColor: DesignTokens.primary,
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
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space2),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_rounded, color: DesignTokens.primary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sıradakini aç (${_whatsappIndex + 1}/${queue.length})',
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _openNextWhatsApp,
                        style: TextButton.styleFrom(foregroundColor: DesignTokens.primary),
                        child: const Text('Sıradakini aç'),
                      ),
                      TextButton(
                        onPressed: _clearWhatsAppQueue,
                        style: TextButton.styleFrom(foregroundColor: textSecondary),
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
