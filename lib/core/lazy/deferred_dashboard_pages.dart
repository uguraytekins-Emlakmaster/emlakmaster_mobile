import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/app_loading.dart';
import '../../features/broker_command/presentation/pages/broker_command_page.dart' deferred as broker_command;
import '../../features/manager_command_center/presentation/pages/command_center_page.dart' deferred as command_center;
import '../../features/war_room/presentation/pages/war_room_page.dart' deferred as war_room;

/// No-Lag Rule: Ağır modüller sadece ilgili sayfa açıldığında yüklenir (deferred loading).

Widget _loadingScreen(BuildContext context) {
  final ext = AppThemeExtension.of(context);
  return Scaffold(
    backgroundColor: ext.background,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLoading(),
          const SizedBox(height: 24),
          Text(
            'Yükleniyor...',
            style: TextStyle(color: ext.textSecondary, fontSize: 14),
          ),
        ],
      ),
    ),
  );
}

/// War Room sayfası — modül ilk açılışta yüklenir.
class LazyWarRoomPage extends StatefulWidget {
  const LazyWarRoomPage({super.key});

  @override
  State<LazyWarRoomPage> createState() => _LazyWarRoomPageState();
}

class _LazyWarRoomPageState extends State<LazyWarRoomPage> {
  bool _loaded = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    war_room.loadLibrary().then((_) {
      if (mounted) setState(() => _loaded = true);
    }).catchError((e, st) {
      if (mounted) setState(() => _error = e);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    if (_error != null) {
      return Scaffold(
        backgroundColor: ext.background,
        body: Center(
          child: Text(
            'Sayfa yüklenemedi.',
            style: TextStyle(color: ext.textSecondary),
          ),
        ),
      );
    }
    if (!_loaded) return _loadingScreen(context);
    return war_room.WarRoomPage();
  }
}

/// Broker Command sayfası — modül ilk açılışta yüklenir.
class LazyBrokerCommandPage extends StatefulWidget {
  const LazyBrokerCommandPage({super.key});

  @override
  State<LazyBrokerCommandPage> createState() => _LazyBrokerCommandPageState();
}

class _LazyBrokerCommandPageState extends State<LazyBrokerCommandPage> {
  bool _loaded = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    broker_command.loadLibrary().then((_) {
      if (mounted) setState(() => _loaded = true);
    }).catchError((e, st) {
      if (mounted) setState(() => _error = e);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    if (_error != null) {
      return Scaffold(
        backgroundColor: ext.background,
        body: Center(
          child: Text(
            'Sayfa yüklenemedi.',
            style: TextStyle(color: ext.textSecondary),
          ),
        ),
      );
    }
    if (!_loaded) return _loadingScreen(context);
    return broker_command.BrokerCommandPage();
  }
}

/// Command Center sayfası — modül ilk açılışta yüklenir.
class LazyCommandCenterPage extends StatefulWidget {
  const LazyCommandCenterPage({super.key});

  @override
  State<LazyCommandCenterPage> createState() => _LazyCommandCenterPageState();
}

class _LazyCommandCenterPageState extends State<LazyCommandCenterPage> {
  bool _loaded = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    command_center.loadLibrary().then((_) {
      if (mounted) setState(() => _loaded = true);
    }).catchError((e, st) {
      if (mounted) setState(() => _error = e);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    if (_error != null) {
      return Scaffold(
        backgroundColor: ext.background,
        body: Center(
          child: Text(
            'Sayfa yüklenemedi.',
            style: TextStyle(color: ext.textSecondary),
          ),
        ),
      );
    }
    if (!_loaded) return _loadingScreen(context);
    return command_center.CommandCenterPage();
  }
}
