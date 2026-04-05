import 'package:emlakmaster_mobile/core/firebase/user_facing_firebase_message.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_connection_mode.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_platform_id.dart';
import 'package:emlakmaster_mobile/features/external_integrations/application/platform_setup_completeness.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/integration_setup_status.dart';
import 'package:emlakmaster_mobile/features/external_integrations/domain/platform_setup_record.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/providers/connected_platforms_providers.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Yönetici: resmi entegrasyon hazırlığı + dosya/manuel geri dönüş yolları (OAuth sahtesi yok).
class PlatformSetupWizardPage extends ConsumerStatefulWidget {
  const PlatformSetupWizardPage({
    super.key,
    this.initialPlatform,
    this.editMode = false,
  });

  final IntegrationPlatformId? initialPlatform;
  final bool editMode;

  @override
  ConsumerState<PlatformSetupWizardPage> createState() => _PlatformSetupWizardPageState();
}

class _PlatformSetupWizardPageState extends ConsumerState<PlatformSetupWizardPage> {
  int _step = 0;
  IntegrationPlatformId? _platform;
  IntegrationConnectionMode? _mode;

  final _storeName = TextEditingController();
  final _email = TextEditingController();
  final _company = TextEditingController();
  final _transferKey = TextEditingController();
  final _integrationRef = TextEditingController();
  final _applicationStatus = TextEditingController();
  final _notes = TextEditingController();
  bool _awaitingVerification = false;
  bool _setupFormCompleted = false;

  _FirstDataChoice _firstData = _FirstDataChoice.bulkFile;

  /// Son başarılı kayıttan sonra 5. adım metni (türetilmiş durum + değerlendirme).
  IntegrationSetupStatus? _lastSavedDerivedStatus;
  PlatformSetupEvaluation? _lastSavedEvaluation;
  bool? _lastSavedDeferImport;

  void _onWizardFieldChanged() {
    if (_step == 3) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _platform = widget.initialPlatform;
    for (final c in [
      _storeName,
      _email,
      _company,
      _transferKey,
      _integrationRef,
      _applicationStatus,
      _notes,
    ]) {
      c.addListener(_onWizardFieldChanged);
    }
    if (widget.editMode && widget.initialPlatform != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  Future<void> _loadExisting() async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    final p = widget.initialPlatform;
    if (uid == null || p == null) return;
    final officeId = _officeId();
    if (officeId.isEmpty) return;
    PlatformSetupRecord? rec;
    try {
      rec = await ref.read(platformSetupRepositoryProvider).get(officeId, p);
    } on FirebaseException catch (e) {
      logFirebaseException('platform_setup_wizard.load', e);
      rec = null;
    }
    final loaded = rec;
    if (!mounted || loaded == null) return;
    setState(() {
      _platform = loaded.platform;
      _mode = loaded.connectionMode;
      _storeName.text = loaded.storeName ?? '';
      _email.text = loaded.contactEmail ?? '';
      _company.text = loaded.companyInfo ?? '';
      _transferKey.text = loaded.transferKey ?? '';
      _integrationRef.text = loaded.integrationReference ?? '';
      _applicationStatus.text = loaded.applicationStatus ?? '';
      _notes.text = loaded.notes ?? '';
      _awaitingVerification = loaded.awaitingVerification;
      _setupFormCompleted = loaded.setupCompleted;
      _firstData =
          loaded.deferImportWorkflow ? _FirstDataChoice.verifyLater : _FirstDataChoice.bulkFile;
    });
  }

  @override
  void dispose() {
    for (final c in [
      _storeName,
      _email,
      _company,
      _transferKey,
      _integrationRef,
      _applicationStatus,
      _notes,
    ]) {
      c.removeListener(_onWizardFieldChanged);
    }
    _storeName.dispose();
    _email.dispose();
    _company.dispose();
    _transferKey.dispose();
    _integrationRef.dispose();
    _applicationStatus.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _officeId() {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    if (uid == null) return '';
    final fromMem = ref.read(primaryMembershipProvider).valueOrNull?.officeId;
    final fromDoc = ref.read(userDocStreamProvider(uid)).valueOrNull?.officeId;
    return (fromMem != null && fromMem.isNotEmpty) ? fromMem : (fromDoc ?? '');
  }

  PlatformSetupRecord _draftRecordForSave({
    required String uid,
    required String officeId,
    required String ownerUserId,
    required PlatformSetupRecord? existing,
    required DateTime now,
  }) {
    final p = _platform!;
    final mode = _mode!;
    final defer = _firstData == _FirstDataChoice.verifyLater;
    final eval = evaluatePlatformSetup(
      PlatformSetupRecord(
        platform: p,
        officeId: officeId,
        ownerUserId: ownerUserId,
        connectionMode: mode,
        setupStatus: IntegrationSetupStatus.inProgress,
        storeName: _storeName.text.trim().isEmpty ? null : _storeName.text.trim(),
        contactEmail: _email.text.trim().isEmpty ? null : _email.text.trim(),
        companyInfo: _company.text.trim().isEmpty ? null : _company.text.trim(),
        transferKey: _transferKey.text.trim().isEmpty ? null : _transferKey.text.trim(),
        integrationReference: _integrationRef.text.trim().isEmpty ? null : _integrationRef.text.trim(),
        applicationStatus: _applicationStatus.text.trim().isEmpty ? null : _applicationStatus.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        setupCompleted: _setupFormCompleted,
        awaitingVerification: _awaitingVerification,
        deferImportWorkflow: defer,
        oauthVerified: existing?.oauthVerified ?? false,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        lastVerifiedAt: _awaitingVerification ? null : existing?.lastVerifiedAt,
        lastSyncAt: existing?.lastSyncAt,
      ),
    );
    final effectiveAwaiting =
        _awaitingVerification && eval.isVerificationReady && !defer;

    final preDerive = PlatformSetupRecord(
      platform: p,
      officeId: officeId,
      ownerUserId: ownerUserId,
      connectionMode: mode,
      setupStatus: IntegrationSetupStatus.inProgress,
      storeName: _storeName.text.trim().isEmpty ? null : _storeName.text.trim(),
      contactEmail: _email.text.trim().isEmpty ? null : _email.text.trim(),
      companyInfo: _company.text.trim().isEmpty ? null : _company.text.trim(),
      transferKey: _transferKey.text.trim().isEmpty ? null : _transferKey.text.trim(),
      integrationReference: _integrationRef.text.trim().isEmpty ? null : _integrationRef.text.trim(),
      applicationStatus: _applicationStatus.text.trim().isEmpty ? null : _applicationStatus.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      setupCompleted: _setupFormCompleted,
      awaitingVerification: effectiveAwaiting,
      deferImportWorkflow: defer,
      oauthVerified: existing?.oauthVerified ?? false,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      lastVerifiedAt: effectiveAwaiting ? null : existing?.lastVerifiedAt,
      lastSyncAt: existing?.lastSyncAt,
    );

    final derived = deriveSetupStatusForRecord(preDerive);
    return preDerive.copyWith(setupStatus: derived);
  }

  PlatformSetupEvaluation _evaluateCurrentFields() {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    final officeId = _officeId();
    return evaluatePlatformSetup(
      PlatformSetupRecord(
        platform: _platform!,
        officeId: officeId,
        ownerUserId: uid,
        connectionMode: _mode!,
        setupStatus: IntegrationSetupStatus.inProgress,
        storeName: _storeName.text.trim().isEmpty ? null : _storeName.text.trim(),
        contactEmail: _email.text.trim().isEmpty ? null : _email.text.trim(),
        companyInfo: _company.text.trim().isEmpty ? null : _company.text.trim(),
        transferKey: _transferKey.text.trim().isEmpty ? null : _transferKey.text.trim(),
        integrationReference: _integrationRef.text.trim().isEmpty ? null : _integrationRef.text.trim(),
        applicationStatus: _applicationStatus.text.trim().isEmpty ? null : _applicationStatus.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        setupCompleted: _setupFormCompleted,
        awaitingVerification: _awaitingVerification,
        deferImportWorkflow: _firstData == _FirstDataChoice.verifyLater,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _saveAndFinish() async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    final p = _platform;
    if (uid == null || p == null || _mode == null) return;

    final now = DateTime.now();
    final officeId = _officeId();
    if (officeId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ofis bağlamı yok; kurulum kaydedilemedi.')),
        );
      }
      return;
    }

    PlatformSetupRecord? existing;
    try {
      existing = await ref.read(platformSetupRepositoryProvider).get(officeId, p);
    } on FirebaseException catch (e) {
      logFirebaseException('platform_setup_wizard.prefetch', e);
      existing = null;
    }

    // Firestore güncelleme kuralı ownerUserId değişimine izin vermez; ilk oluşturan korunur.
    final ownerUserId = existing?.ownerUserId ?? uid;

    final record = _draftRecordForSave(
      uid: uid,
      officeId: officeId,
      ownerUserId: ownerUserId,
      existing: existing,
      now: now,
    );

    try {
      await ref.read(platformSetupRepositoryProvider).upsert(record);
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingFirebaseMessage(e))),
        );
      }
      return;
    }

    final derived = deriveSetupStatusForRecord(record);
    final eval = evaluatePlatformSetup(record);

    HapticFeedback.mediumImpact();
    if (mounted) {
      final snack = _snackMessageForSave(derived, eval, record.deferImportWorkflow);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snack)));
      setState(() {
        _lastSavedDerivedStatus = derived;
        _lastSavedEvaluation = eval;
        _lastSavedDeferImport = record.deferImportWorkflow;
        _step = 4;
      });
    }
  }

  String _snackMessageForSave(
    IntegrationSetupStatus derived,
    PlatformSetupEvaluation eval,
    bool deferImport,
  ) {
    if (derived == IntegrationSetupStatus.awaitingVerification) {
      return 'Kurulum kaydı alındı. Doğrulama bekleniyor.';
    }
    if (derived == IntegrationSetupStatus.inProgress &&
        (deferImport || !eval.isComplete)) {
      return 'Taslak kaydedildi. Kurulum henüz tamamlanmadı.';
    }
    return 'Kurulum kaydı alındı. Değişiklikler kaydedildi.';
  }

  @override
  Widget build(BuildContext context) {
    final canManage = ref.watch(canManagePlatformIntegrationsProvider);
    if (!canManage) {
      return Scaffold(
        body: Center(
          child: Text(
            'Bu sihirbaz yalnızca ofis yöneticileri içindir.',
            style: TextStyle(color: AppThemeExtension.of(context).foreground),
          ),
        ),
      );
    }

    final ext = AppThemeExtension.of(context);

    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  const AppBackButton(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform kurulum sihirbazı',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: ext.foreground,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          'Mağaza ilanlarını güvenle sisteme alma',
                          style: TextStyle(color: ext.foregroundSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_step + 1}/5',
                    style: TextStyle(color: ext.foregroundMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 5,
                  backgroundColor: ext.border,
                  color: ext.accent,
                  minHeight: 4,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  if (_step == 0) _step1(ext),
                  if (_step == 1) _step2(ext),
                  if (_step == 2) _step3(ext),
                  if (_step == 3) _step4(ext),
                  if (_step == 4) _step5(ext),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  if (_step > 0 && _step < 4)
                    TextButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Geri'),
                    ),
                  const Spacer(),
                  if (_step < 3)
                    FilledButton(
                      onPressed: _canNext() ? () => _onNext() : null,
                      child: Text(_step == 2 ? 'Devam' : 'İleri'),
                    ),
                  if (_step == 3)
                    FilledButton(
                      onPressed: _canFinish()
                          ? () async {
                              await _saveAndFinish();
                            }
                          : null,
                      child: const Text('Kaydet ve sonuç'),
                    ),
                  if (_step == 4)
                    FilledButton(
                      onPressed: () => context.pop(),
                      child: const Text('Kapat'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canNext() {
    switch (_step) {
      case 0:
        return _platform != null;
      case 1:
        return _mode != null;
      case 2:
        return true;
      default:
        return false;
    }
  }

  bool _canFinish() {
    if (_platform == null || _mode == null) return false;
    return _evaluateCurrentFields().isComplete;
  }

  void _onNext() {
    if (_step == 2) {
      setState(() => _step = 3);
      return;
    }
    setState(() => _step++);
  }

  Widget _step1(AppThemeExtension ext) {
    return _StepSection(
      title: '1 · Platform seçin',
      subtitle: 'Resmi entegrasyon hedefi; canlı OAuth ayrıca doğrulanır.',
      child: Column(
        children: IntegrationPlatformId.values.map((id) {
          final selected = _platform == id;
          final hint = _platformHint(id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: selected ? ext.accent.withValues(alpha: 0.12) : ext.surfaceElevated,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _platform = id);
                },
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    border: Border.all(
                      color: selected ? ext.accent.withValues(alpha: 0.6) : ext.border.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        id.displayName,
                        style: TextStyle(
                          color: ext.foreground,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(hint, style: TextStyle(color: ext.foregroundSecondary, fontSize: 12, height: 1.35)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _platformHint(IntegrationPlatformId id) {
    switch (id) {
      case IntegrationPlatformId.sahibinden:
        return 'Resmi entegrasyon hedefi · transfer anahtarı / mağaza eşlemesi. Henüz canlı otomatik senkron yok.';
      case IntegrationPlatformId.hepsiemlak:
        return 'Kullanıcı kontrollü senkron hedefi · partner onayı gerekebilir. Hazırlanıyor.';
      case IntegrationPlatformId.emlakjet:
        return 'Deneysel kanal · kurulum tamamlanana kadar dosya ile toplu içe aktarma önerilir.';
    }
  }

  Widget _step2(AppThemeExtension ext) {
    return _StepSection(
      title: '2 · Kurulum yöntemi',
      subtitle: 'Canlı resmi API şu an kapalı olabilir; seçtiğiniz yöntem kayda geçer.',
      child: Column(
        children: [
          _modeTile(
            ext,
            IntegrationConnectionMode.officialSetup,
            'Resmi entegrasyon kurulumu',
            'Partner / API başvurusu ve mağaza bilgileri — doğrulama sonrası devam.',
          ),
          _modeTile(
            ext,
            IntegrationConnectionMode.transferKey,
            'Transfer anahtarı veya partner referansı',
            'Platformun verdiği anahtar / referans ile eşleme (OAuth değildir).',
          ),
          _modeTile(
            ext,
            IntegrationConnectionMode.fileImport,
            'CSV / JSON / XLSX ile toplu içe aktar',
            'Önerilen güvenli yol: mağaza dışa aktarım dosyası.',
          ),
          _modeTile(
            ext,
            IntegrationConnectionMode.manualOnly,
            'Manuel portföy ile başla',
            'Tek tek ilan girişi; otomatik senkron beklenmez.',
          ),
        ],
      ),
    );
  }

  Widget _modeTile(
    AppThemeExtension ext,
    IntegrationConnectionMode mode,
    String title,
    String sub,
  ) {
    final selected = _mode == mode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? ext.accent.withValues(alpha: 0.1) : ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _mode = mode);
          },
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(
                color: selected ? ext.accent.withValues(alpha: 0.55) : ext.border.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: ext.foreground, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(sub, style: TextStyle(color: ext.foregroundSecondary, fontSize: 12, height: 1.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _step3(AppThemeExtension ext) {
    return _StepSection(
      title: '3 · Kurulum bilgileri',
      subtitle: 'Bu alanlar ofis kaydında saklanır; OAuth başlatılmaz.',
      child: Column(
        children: [
          TextField(
            controller: _storeName,
            decoration: const InputDecoration(
              labelText: 'Mağaza / ofis adı',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'İletişim e-postası',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _company,
            decoration: const InputDecoration(
              labelText: 'Firma / vergi bilgisi (isteğe bağlı)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _transferKey,
            decoration: const InputDecoration(
              labelText: 'Transfer anahtarı / entegrasyon kodu',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _integrationRef,
            decoration: const InputDecoration(
              labelText: 'Partner referansı',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _applicationStatus,
            decoration: const InputDecoration(
              labelText: 'Başvuru durumu',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notlar',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Doğrulama / onay bekleniyor', style: TextStyle(color: ext.foreground, fontSize: 14)),
            subtitle: Text(
              'Partner veya platform tarafı incelemede ise işaretleyin.',
              style: TextStyle(color: ext.foregroundSecondary, fontSize: 12),
            ),
            value: _awaitingVerification,
            onChanged: (v) => setState(() => _awaitingVerification = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Kurulum formu tamamlandı', style: TextStyle(color: ext.foreground, fontSize: 14)),
            value: _setupFormCompleted,
            onChanged: (v) => setState(() => _setupFormCompleted = v),
          ),
        ],
      ),
    );
  }

  Widget _step4(AppThemeExtension ext) {
    return _StepSection(
      title: '4 · İlk veri yolu',
      subtitle: 'Mağaza ilanlarını güvenle almak için önerilen sıra.',
      child: Column(
        children: [
          _dataChoice(
            ext,
            _FirstDataChoice.bulkFile,
            'Toplu dosya yükle',
            'Mağaza içe aktarma — CSV / JSON / Excel (önerilir).',
          ),
          _dataChoice(
            ext,
            _FirstDataChoice.startImport,
            'İlk içe aktarmayı başlat',
            'İçe aktarma ekranına git (dosya seçimi).',
          ),
          _dataChoice(
            ext,
            _FirstDataChoice.verifyLater,
            'Önce kurulum kaydını sakla',
            'Senkron ve içe aktarma sonra; şimdilik yalnızca kayıt.',
          ),
        ],
      ),
    );
  }

  Widget _dataChoice(AppThemeExtension ext, _FirstDataChoice c, String title, String sub) {
    final selected = _firstData == c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? ext.accent.withValues(alpha: 0.08) : ext.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: InkWell(
          onTap: () => setState(() => _firstData = c),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(
                color: selected ? ext.accent.withValues(alpha: 0.5) : ext.border.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: ext.foreground, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(sub, style: TextStyle(color: ext.foregroundSecondary, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _step5(AppThemeExtension ext) {
    final derived = _lastSavedDerivedStatus ?? IntegrationSetupStatus.inProgress;
    final eval = _lastSavedEvaluation ?? _evaluateCurrentFields();
    final copy = _resultCopy(derived, eval);
    return _StepSection(
      title: '5 · Sonuç',
      subtitle: copy.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ext.surfaceElevated,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: ext.border.withValues(alpha: 0.45)),
            ),
            child: Text(
              copy.body,
              style: TextStyle(color: ext.foregroundSecondary, height: 1.45, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          if (_firstData == _FirstDataChoice.bulkFile || _firstData == _FirstDataChoice.startImport) ...[
            FilledButton.icon(
              onPressed: () {
                context.pop();
                context.push(AppRouter.routeImportHub);
              },
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Mağaza toplu içe aktarmayı aç'),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: () {
              context.pop();
              context.push(AppRouter.routeConnectedAccounts);
            },
            icon: const Icon(Icons.hub_outlined),
            label: const Text('Bağlı platformlara dön'),
          ),
        ],
      ),
    );
  }

  _ResultCopy _resultCopy(IntegrationSetupStatus derived, PlatformSetupEvaluation eval) {
    if (derived == IntegrationSetupStatus.awaitingVerification && eval.isComplete) {
      return _ResultCopy(
        title: 'Kurulum kaydı alındı',
        body: 'Doğrulama bekleniyor. Partner / platform onayı sonrası canlı adımlar açılacaktır. '
            'Bu arada mağaza dışa aktarım dosyası ile toplu içe aktarma kullanabilirsiniz.',
      );
    }
    if (derived == IntegrationSetupStatus.inProgress && eval.isComplete && (_lastSavedDeferImport == true)) {
      return _ResultCopy(
        title: 'Taslak kaydedildi',
        body: 'Kurulum henüz tamamlanmadı. İçe aktarma veya doğrulama adımlarını başlatmadınız; '
            'eksik alanları tamamlamak için sihirbaza dönebilirsiniz.',
      );
    }
    if (derived == IntegrationSetupStatus.inProgress && (!eval.isComplete)) {
      return _ResultCopy(
        title: 'Taslak kaydedildi',
        body: 'Kurulum henüz tamamlanmadı. '
            '${eval.missingHints.isEmpty ? 'Temel bilgileri tamamlayın.' : 'Eksik: ${eval.missingHints.join(', ')}'}',
      );
    }
    switch (derived) {
      case IntegrationSetupStatus.readyForImport:
        return _ResultCopy(
          title: 'İçe aktarıma hazır (dosya önerilir)',
          body: 'Otomatik canlı senkron henüz zorunlu değil. CSV / JSON / XLSX ile tüm ilanları güvenle aktarın.',
        );
      case IntegrationSetupStatus.inProgress:
        return _ResultCopy(
          title: 'Kurulum kaydedildi',
          body: 'Taslak güncellendi. İsterseniz toplu dosya veya manuel portföy ile devam edin.',
        );
      default:
        return _ResultCopy(
          title: derived.shortLabelTr,
          body: 'Kayıt güncellendi.',
        );
    }
  }
}

class _ResultCopy {
  _ResultCopy({required this.title, required this.body});
  final String title;
  final String body;
}

enum _FirstDataChoice { bulkFile, startImport, verifyLater }

class _StepSection extends StatelessWidget {
  const _StepSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: ext.foreground,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(color: ext.foregroundSecondary, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}
