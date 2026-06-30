import 'package:emlakmaster_mobile/core/platform/io_platform_stub.dart'
    if (dart.library.io) 'dart:io' as io;
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Çağrı odaklı akış için zorunlu izin kapısı.
///
/// Android'de çağrı kaçırmamak için:
/// - phone (READ_PHONE_STATE / READ_CALL_LOG)
/// - contacts
/// - notifications (Android 13+)
class RequiredPermissionsGate extends StatefulWidget {
  const RequiredPermissionsGate({super.key});

  @override
  State<RequiredPermissionsGate> createState() => _RequiredPermissionsGateState();
}

class _RequiredPermissionsGateState extends State<RequiredPermissionsGate> {
  bool _loading = true;
  bool _ready = false;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    if (!io.Platform.isAndroid) {
      setState(() {
        _ready = true;
        _loading = false;
      });
      return;
    }
    final phone = await Permission.phone.status;
    final contacts = await Permission.contacts.status;
    final notif = await Permission.notification.status;
    final ok = phone.isGranted &&
        contacts.isGranted &&
        (notif.isGranted || notif.isDenied || notif.isRestricted);
    if (!mounted) return;
    setState(() {
      _ready = ok;
      _loading = false;
    });
  }

  Future<void> _requestAll() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    await Permission.phone.request();
    await Permission.contacts.request();
    await Permission.notification.request();
    await _refresh();
    if (mounted) setState(() => _requesting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _ready) return const SizedBox.shrink();
    final ext = AppThemeExtension.of(context);
    return Material(
      color: ext.background.withValues(alpha: 0.94),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ext.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ext.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: ext.accent),
                        const SizedBox(width: 8),
                        Text(
                          'Operasyon izinleri gerekli',
                          style: TextStyle(
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Çağrı kaçırmamak ve numaraları anında yakalamak için '
                      'telefon, rehber ve bildirim izinlerini açın.',
                      style: TextStyle(color: ext.textSecondary, height: 1.35),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _requesting ? null : _requestAll,
                      icon: const Icon(Icons.shield_rounded),
                      label: Text(_requesting ? 'İzinler isteniyor…' : 'İzinleri aç'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ext.accent,
                        foregroundColor: ext.onBrand,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => openAppSettings(),
                      child: const Text('Ayarları aç'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

