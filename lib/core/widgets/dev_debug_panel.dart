import 'dart:math' as math;

import 'package:emlakmaster_mobile/core/config/dev_mode_config.dart';
import 'package:emlakmaster_mobile/core/debug/debug_diagnostics_store.dart';
import 'package:emlakmaster_mobile/core/dev/dev_office_fallback.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// DEV banner’dan açılan yüzen bilgi paneli (yalnızca dev).
class DevDebugPanel {
  DevDebugPanel._();

  static Future<void> show(BuildContext context) async {
    const show = !kReleaseMode && isDevMode;
    if (!show || !context.mounted) return;

    final mq = MediaQuery.of(context);
    final panelHeight = math.min(
      mq.size.height * 0.72,
      420.0,
    );

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Debug panel',
      barrierColor: Colors.black54,
      pageBuilder: (ctx, _, __) {
        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: mq.padding.bottom + 12,
              top: 48,
            ),
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF1E293B),
              child: SizedBox(
                width: 360,
                height: panelHeight,
                child: const _DevDebugPanelBody(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DevDebugPanelBody extends ConsumerStatefulWidget {
  const _DevDebugPanelBody();

  @override
  ConsumerState<_DevDebugPanelBody> createState() => _DevDebugPanelBodyState();
}

class _DevDebugPanelBodyState extends ConsumerState<_DevDebugPanelBody> {
  @override
  void initState() {
    super.initState();
    DebugDiagnosticsStore.instance.addListener(_onStore);
  }

  @override
  void dispose() {
    DebugDiagnosticsStore.instance.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final uid = user?.uid ?? '—';
    final doc = user != null
        ? ref.watch(userDocStreamProvider(user.uid)).valueOrNull
        : null;
    String officeLine;
    if (DevOfficeFallback.isActive) {
      officeLine =
          '$kLocalDevOfficeId (yerel)\n«${DevOfficeFallback.officeName}»';
    } else {
      final oid = doc?.officeId;
      officeLine = (oid == null || oid.isEmpty) ? '—' : oid;
    }
    final fallback = DevOfficeFallback.isActive ? 'Evet (yerel ofis)' : 'Hayır';
    final store = DebugDiagnosticsStore.instance;
    final apiErr = store.lastApiError;
    final apiAt = store.lastApiErrorAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          child: Row(
            children: [
              const Icon(Icons.bug_report_outlined, color: Color(0xFFFBBF24), size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Debug panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Kapat',
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF334155)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DefaultTextStyle(
              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12.5, height: 1.35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionTitle(title: 'Kullanıcı UID'),
                  _CopyRow(text: uid),
                  const SizedBox(height: 14),
                  const _SectionTitle(title: 'Ofis ID'),
                  _CopyRow(text: officeLine),
                  const SizedBox(height: 14),
                  const _SectionTitle(title: 'Dev fallback (yerel ofis)'),
                  Text(
                    fallback,
                    style: TextStyle(
                      color: DevOfficeFallback.isActive
                          ? const Color(0xFFFB923C)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(child: _SectionTitle(title: 'Son API hatası')),
                      if (apiErr != null)
                        TextButton(
                          onPressed: () {
                            DebugDiagnosticsStore.instance.clearLastApiError();
                            setState(() {});
                          },
                          child: const Text('Temizle', style: TextStyle(fontSize: 11)),
                        ),
                    ],
                  ),
                  if (apiAt != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _formatTime(apiAt),
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: SelectableText(
                      apiErr ?? 'Henüz kayıtlı API hatası yok (traceHttpCall).',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10.5,
                        color: apiErr != null ? const Color(0xFFFECACA) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatTime(DateTime t) {
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SelectableText(
            text,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11.5,
              color: Color(0xFFE2E8F0),
            ),
          ),
        ),
        IconButton(
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF94A3B8)),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: text));
            if (!context.mounted) return;
            HapticFeedback.lightImpact();
            final messenger = ScaffoldMessenger.maybeOf(context);
            messenger?.showSnackBar(
              const SnackBar(
                content: Text('Panoya kopyalandı'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          },
          tooltip: 'Kopyala',
        ),
      ],
    );
  }
}
