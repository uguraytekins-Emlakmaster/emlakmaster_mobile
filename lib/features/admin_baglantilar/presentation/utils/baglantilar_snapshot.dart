import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/utils/baglantilar_types.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_connection_truth_kind.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_setup_lifecycle.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/utils/integration_center_filter.dart';

/// Ham platform listesi → tek seferde türetilmiş, önceden hesaplanmış snapshot.
/// Build() içinde pahalı eşleme yapılmaması için tüm etiket/ton/aksiyon bayrakları
/// burada hesaplanır.
BaglantilarSnapshot computeBaglantilarSnapshot({
  required List<IntegrationPlatform> platforms,
  required bool canManage,
  required bool officeGrounded,
}) {
  final rows = <BaglantiRowViewModel>[];

  var connected = 0;
  var ready = 0;
  var setupRequired = 0;
  var previewOnly = 0;
  var syncSupported = 0;
  var intervention = 0;

  for (final p in platforms) {
    final lifecycle = p.setupLifecycle;

    final isConnected = integrationIsConnected(p) ||
        lifecycle == PlatformSetupLifecycleState.liveEnabled;
    final isReady =
        isConnected || lifecycle == PlatformSetupLifecycleState.readyForImport;
    final needsAction = lifecycle != null &&
        (lifecycle.countsAsAttentionForDashboard ||
            lifecycle == PlatformSetupLifecycleState.blocked ||
            lifecycle == PlatformSetupLifecycleState.error);
    final needsSetup = !isConnected &&
        !isReady &&
        !needsAction &&
        (integrationNeedsSetup(p) ||
            lifecycle == PlatformSetupLifecycleState.notStarted ||
            lifecycle == PlatformSetupLifecycleState.draft);
    final isPreview = !isConnected && !isReady && integrationIsPreview(p);
    final supportsSync = p.capabilities.canSync;
    final needsAdmin = !canManage;

    if (isConnected) connected++;
    if (isReady) ready++;
    if (needsSetup) setupRequired++;
    if (isPreview) previewOnly++;
    if (supportsSync) syncSupported++;
    if (needsAction) intervention++;

    final tone = _tone(
      isConnected: isConnected,
      isReady: isReady,
      needsAction: needsAction,
      needsSetup: needsSetup,
      isPreview: isPreview,
      lifecycle: lifecycle,
      truth: p.truthKind,
    );
    final statusLabel = _statusLabel(
      isConnected: isConnected,
      isReady: isReady,
      needsAction: needsAction,
      needsSetup: needsSetup,
      isPreview: isPreview,
      lifecycle: lifecycle,
      truth: p.truthKind,
    );

    final account = p.connectedAccountLabel?.trim();
    final detailLine = _compact(
      (account != null && account.isNotEmpty)
          ? account
          : (lifecycle?.cardSubtitleTr ?? p.truthKind.shortLabelTr),
      max: 64,
    );
    final providerLine = integrationSupportLabel(p.supportLevel);

    final pills = <String>[
      if (p.capabilities.canImportListings) 'İçe aktarma',
      if (supportsSync) 'Senkron',
      if (p.capabilities.canUpdatePrice) 'Fiyat',
      if (p.capabilities.canManageMessages) 'Mesaj',
    ];

    final searchText = <String>[
      p.name,
      providerLine,
      statusLabel,
      detailLine,
      lifecycle?.chipLabelTr ?? '',
      p.truthKind.shortLabelTr,
      if (account != null) account,
    ].join(' ').toLowerCase();

    rows.add(
      BaglantiRowViewModel(
        platformId: p.id,
        platformName: p.name,
        providerLine: providerLine,
        detailLine: detailLine,
        statusLabel: statusLabel,
        tone: tone,
        capabilityPills: pills,
        needsAdmin: needsAdmin,
        searchText: searchText,
        isConnected: isConnected,
        isReady: isReady,
        needsSetup: needsSetup,
        isPreview: isPreview,
        supportsSync: supportsSync,
        needsAction: needsAction,
        canConnect: canManage && !isConnected && !isReady,
        canConfigure: canManage,
        canImport: p.capabilities.canImportListings,
        canRetry: canManage,
      ),
    );
  }

  rows.sort((a, b) {
    final ra = _sortRank(a);
    final rb = _sortRank(b);
    if (ra != rb) return ra.compareTo(rb);
    return a.platformName.toLowerCase().compareTo(b.platformName.toLowerCase());
  });

  final total = platforms.length;
  final summary = BaglantilarSummary(
    connected: connected,
    ready: ready,
    setupRequired: setupRequired,
    previewOnly: previewOnly,
    adminRequired: canManage ? 0 : total,
    syncSupported: syncSupported,
    intervention: intervention,
    total: total,
  );

  final note = StringBuffer(
    'Durumlar yalnızca gerçek platform kurulum kayıtlarından türetilir.',
  );
  if (!officeGrounded) {
    note.write(' Ofis kimliği çözülene kadar ofis bazlı kapsam sınırlıdır.');
  }
  note.write(
    ' Canlı OAuth/otomatik senkron yalnızca doğrulandığında “Bağlı” sayılır; '
    'önizleme kartları yalnızca arayüz örneğidir.',
  );

  return BaglantilarSnapshot(
    rows: rows,
    summary: summary,
    coverageNote: note.toString(),
    officeGrounded: officeGrounded,
    isEmpty: rows.isEmpty,
  );
}

int _sortRank(BaglantiRowViewModel r) {
  if (r.needsAction) return 0;
  if (r.needsSetup) return 1;
  if (r.isConnected || r.isReady) return 2;
  return 3;
}

BaglantiTone _tone({
  required bool isConnected,
  required bool isReady,
  required bool needsAction,
  required bool needsSetup,
  required bool isPreview,
  required PlatformSetupLifecycleState? lifecycle,
  required PlatformConnectionTruthKind truth,
}) {
  if (isConnected || (isReady && lifecycle == PlatformSetupLifecycleState.readyForImport)) {
    return BaglantiTone.success;
  }
  if (needsAction) {
    if (lifecycle == PlatformSetupLifecycleState.error ||
        lifecycle == PlatformSetupLifecycleState.blocked) {
      return BaglantiTone.danger;
    }
    return BaglantiTone.warning;
  }
  if (needsSetup) return BaglantiTone.warning;
  if (isPreview) {
    return truth == PlatformConnectionTruthKind.liveNotEnabled
        ? BaglantiTone.neutral
        : BaglantiTone.info;
  }
  return BaglantiTone.neutral;
}

String _statusLabel({
  required bool isConnected,
  required bool isReady,
  required bool needsAction,
  required bool needsSetup,
  required bool isPreview,
  required PlatformSetupLifecycleState? lifecycle,
  required PlatformConnectionTruthKind truth,
}) {
  if (isConnected) return 'Bağlı (canlı)';
  if (isReady && lifecycle == PlatformSetupLifecycleState.readyForImport) {
    return 'İçe aktarmaya hazır';
  }
  if (needsAction) {
    return lifecycle?.chipLabelTr ?? 'Müdahale gerekli';
  }
  if (needsSetup) return 'Kurulum gerekli';
  if (isPreview) {
    return truth == PlatformConnectionTruthKind.liveNotEnabled
        ? 'Aktif değil'
        : 'Önizleme';
  }
  return lifecycle?.chipLabelTr ?? truth.shortLabelTr;
}

String _compact(String value, {required int max}) {
  final s = value.trim();
  if (s.length <= max) return s;
  return '${s.substring(0, max - 1)}…';
}
