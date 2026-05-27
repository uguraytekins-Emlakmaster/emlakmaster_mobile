import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_capability.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_truth_kind.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_setup_lifecycle.dart';

enum IntegrationCenterFilter {
  all,
  connected,
  setup,
  preview,
  admin,
  sync,
}

extension IntegrationCenterFilterLabels on IntegrationCenterFilter {
  String get label => switch (this) {
        IntegrationCenterFilter.all => 'Tümü',
        IntegrationCenterFilter.connected => 'Bağlı',
        IntegrationCenterFilter.setup => 'Kurulum',
        IntegrationCenterFilter.preview => 'Önizleme',
        IntegrationCenterFilter.admin => 'Admin',
        IntegrationCenterFilter.sync => 'Senkron',
      };
}

class IntegrationCenterSummary {
  const IntegrationCenterSummary({
    required this.connectedAccounts,
    required this.setupRequired,
    required this.previewOnly,
    required this.adminRequired,
    required this.syncSupported,
  });

  final int connectedAccounts;
  final int setupRequired;
  final int previewOnly;
  final int adminRequired;
  final int syncSupported;

  static const empty = IntegrationCenterSummary(
    connectedAccounts: 0,
    setupRequired: 0,
    previewOnly: 0,
    adminRequired: 0,
    syncSupported: 0,
  );
}

bool integrationIsConnected(IntegrationPlatform row) {
  return row.truthKind == PlatformConnectionTruthKind.liveConnected;
}

bool integrationNeedsSetup(IntegrationPlatform row) {
  return row.truthKind == PlatformConnectionTruthKind.setupIncomplete ||
      row.truthKind == PlatformConnectionTruthKind.preparing;
}

bool integrationIsPreview(IntegrationPlatform row) {
  return row.truthKind == PlatformConnectionTruthKind.mockDemo ||
      row.truthKind == PlatformConnectionTruthKind.experimentalNotLive ||
      row.truthKind == PlatformConnectionTruthKind.liveNotEnabled;
}

bool integrationSupportsSync(IntegrationPlatform row) {
  return row.capabilities.canSync;
}

String integrationSupportLabel(IntegrationSupportLevel support) {
  return switch (support) {
    IntegrationSupportLevel.tier1Official => 'Resmi sağlayıcı',
    IntegrationSupportLevel.tier2UserControlled => 'Kullanıcı kontrollü',
    IntegrationSupportLevel.tier3Experimental => 'Deneysel',
  };
}

String integrationStatusLabelForSearch(IntegrationPlatform row) {
  return row.setupLifecycle?.chipLabelTr ?? row.truthKind.shortLabelTr;
}

bool integrationMatchesSearch(IntegrationPlatform row, String query) {
  if (query.isEmpty) return true;
  final q = query.toLowerCase();
  bool hit(String? s) => s != null && s.toLowerCase().contains(q);
  return hit(row.name) ||
      hit(row.connectedAccountLabel) ||
      hit(integrationSupportLabel(row.supportLevel)) ||
      hit(integrationStatusLabelForSearch(row)) ||
      hit(row.setupLifecycle?.cardSubtitleTr);
}

bool matchesIntegrationCenterFilter(
  IntegrationPlatform row,
  IntegrationCenterFilter filter,
  String searchQuery, {
  required bool canManage,
}) {
  if (!integrationMatchesSearch(row, searchQuery)) return false;
  return switch (filter) {
    IntegrationCenterFilter.all => true,
    IntegrationCenterFilter.connected => integrationIsConnected(row),
    IntegrationCenterFilter.setup => integrationNeedsSetup(row),
    IntegrationCenterFilter.preview => integrationIsPreview(row),
    IntegrationCenterFilter.admin => !canManage,
    IntegrationCenterFilter.sync => integrationSupportsSync(row),
  };
}

IntegrationCenterSummary computeIntegrationCenterSummary(
  Iterable<IntegrationPlatform> rows, {
  required bool canManage,
}) {
  var connected = 0;
  var setup = 0;
  var preview = 0;
  var sync = 0;
  var total = 0;
  for (final row in rows) {
    total++;
    if (integrationIsConnected(row)) connected++;
    if (integrationNeedsSetup(row)) setup++;
    if (integrationIsPreview(row)) preview++;
    if (integrationSupportsSync(row)) sync++;
  }
  return IntegrationCenterSummary(
    connectedAccounts: connected,
    setupRequired: setup,
    previewOnly: preview,
    adminRequired: canManage ? 0 : total,
    syncSupported: sync,
  );
}
