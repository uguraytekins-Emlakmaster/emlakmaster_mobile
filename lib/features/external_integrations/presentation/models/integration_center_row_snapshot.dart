import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_truth_kind.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_setup_lifecycle.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/utils/integration_center_filter.dart';

class IntegrationCenterRowSnapshot {
  const IntegrationCenterRowSnapshot({
    required this.platformName,
    required this.providerLine,
    required this.descriptionLine,
    required this.healthBadge,
    required this.healthToneKey,
    required this.syncBadge,
    required this.roleBadge,
    required this.metaLine,
    required this.previewMessage,
    required this.emphasizeSetup,
    required this.canConnect,
    required this.canConfigure,
    required this.canOpen,
    required this.canRetry,
    required this.canLearnMore,
  });

  final String platformName;
  final String providerLine;
  final String descriptionLine;
  final String healthBadge;
  final String healthToneKey;
  final String? syncBadge;
  final String? roleBadge;
  final String metaLine;
  final String previewMessage;
  final bool emphasizeSetup;

  final bool canConnect;
  final bool canConfigure;
  final bool canOpen;
  final bool canRetry;
  final bool canLearnMore;

  factory IntegrationCenterRowSnapshot.fromPlatform(
    IntegrationPlatform row, {
    required bool canManage,
  }) {
    final status = _statusLabel(row.truthKind);
    final support = integrationSupportLabel(row.supportLevel);
    final rawDesc = row.setupLifecycle?.cardSubtitleTr ??
        row.errorState?.shortMessage ??
        row.truthKind.shortLabelTr;
    final desc = _compact(rawDesc, max: 64);
    final previewMsg = switch (row.truthKind) {
      PlatformConnectionTruthKind.liveConnected => 'Canlı bağlantı doğrulandı.',
      PlatformConnectionTruthKind.preparing =>
        'Bağlantı altyapısı hazırlanıyor.',
      PlatformConnectionTruthKind.setupIncomplete =>
        'Kanal bağlantısı gerekli.',
      PlatformConnectionTruthKind.experimentalNotLive =>
        'Önizleme akışı: canlı entegrasyon aktif değil.',
      PlatformConnectionTruthKind.liveNotEnabled =>
        'Bu ortamda canlı bağlantı henüz açık değil.',
      PlatformConnectionTruthKind.mockDemo =>
        'Önizleme kartı: gerçek bağlantı bilgisi bekleniyor.',
    };

    final account = row.connectedAccountLabel?.trim();
    final meta = <String>[
      if (account != null && account.isNotEmpty) account,
      if (row.lastSyncAt != null) 'Son güncelleme var',
      if (row.errorState?.hint != null) _compact(row.errorState!.hint!, max: 42),
    ];

    return IntegrationCenterRowSnapshot(
      platformName: row.name,
      providerLine: support,
      descriptionLine: desc,
      healthBadge: status,
      healthToneKey: _healthToneKey(row),
      syncBadge: row.capabilities.canSync ? 'Senkron destekli' : null,
      roleBadge: canManage ? null : 'Admin gerekli',
      metaLine: meta.isEmpty ? _compact(previewMsg, max: 50) : meta.join(' · '),
      previewMessage: previewMsg,
      emphasizeSetup: integrationNeedsSetup(row),
      canConnect: canManage && !integrationIsConnected(row),
      canConfigure: canManage,
      canOpen: row.capabilities.canImportListings,
      canRetry: canManage,
      canLearnMore: true,
    );
  }

  static String _healthToneKey(IntegrationPlatform row) {
    return switch (row.truthKind) {
      PlatformConnectionTruthKind.liveConnected => 'connected',
      PlatformConnectionTruthKind.setupIncomplete => 'setup',
      PlatformConnectionTruthKind.preparing => 'setup',
      PlatformConnectionTruthKind.experimentalNotLive => 'preview',
      PlatformConnectionTruthKind.mockDemo => 'preview',
      PlatformConnectionTruthKind.liveNotEnabled => 'unavailable',
    };
  }

  static String _statusLabel(PlatformConnectionTruthKind truth) {
    return switch (truth) {
      PlatformConnectionTruthKind.liveConnected => 'Connected',
      PlatformConnectionTruthKind.setupIncomplete => 'Setup required',
      PlatformConnectionTruthKind.preparing => 'Setup required',
      PlatformConnectionTruthKind.experimentalNotLive => 'Preview only',
      PlatformConnectionTruthKind.mockDemo => 'Preview only',
      PlatformConnectionTruthKind.liveNotEnabled => 'Not available',
    };
  }

  static String _compact(String value, {required int max}) {
    final s = value.trim();
    if (s.length <= max) return s;
    return '${s.substring(0, max - 1)}…';
  }
}
