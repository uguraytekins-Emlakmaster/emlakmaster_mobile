import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:csv/csv.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/firebase/user_facing_firebase_message.dart';
import 'package:emlakmaster_mobile/core/storage/storage_paths.dart';
import 'package:emlakmaster_mobile/core/providers/firebase_storage_availability_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firebase_storage_availability.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/widgets/app_toaster.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/office/domain/membership_status.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_role.dart';
import 'package:emlakmaster_mobile/features/listing_import/data/listing_import_functions.dart';
import 'package:emlakmaster_mobile/features/listing_import/data/listing_import_service.dart';
import 'package:emlakmaster_mobile/features/listing_import/data/listing_import_xlsx.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:uuid/uuid.dart';

/// Yönetici mağaza toplu içe aktarma — dosya birincil; URL deneysel ikincil.
class ImportHubPage extends ConsumerStatefulWidget {
  const ImportHubPage({super.key});

  @override
  ConsumerState<ImportHubPage> createState() => _ImportHubPageState();
}

class _ImportHubPageState extends ConsumerState<ImportHubPage> {
  final _urlCtrl = TextEditingController();
  final _manualTitle = TextEditingController();
  final _manualPrice = TextEditingController();
  final _manualLoc = TextEditingController();
  final _manualDesc = TextEditingController();
  bool _busy = false;
  String? _importMode = 'skip_duplicates';
  /// Mağaza dışa aktarımı için kaynak (ilanlar `sourcePlatform` alır).
  String? _storePlatform;

  @override
  void dispose() {
    _urlCtrl.dispose();
    _manualTitle.dispose();
    _manualPrice.dispose();
    _manualLoc.dispose();
    _manualDesc.dispose();
    super.dispose();
  }

  String _officeId(WidgetRef ref, String uid) {
    final fromMem = ref.read(primaryMembershipProvider).valueOrNull?.officeId;
    final fromDoc = ref.read(userDocStreamProvider(uid)).valueOrNull?.officeId;
    return (fromMem != null && fromMem.isNotEmpty) ? fromMem : (fromDoc ?? '');
  }

  /// Sunucu kuyruğu + Storage: ofis yöneticisi / ekip lideri veya süper admin.
  bool _canUploadOfficeImportServer(WidgetRef ref) {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    if (uid == null) return false;
    final doc = ref.read(userDocStreamProvider(uid)).valueOrNull;
    if (doc != null && doc.role == 'super_admin') return true;
    final m = ref.read(primaryMembershipProvider).valueOrNull;
    return m != null &&
        m.status == MembershipStatus.active &&
        (m.role == OfficeRole.owner || m.role == OfficeRole.admin || m.role == OfficeRole.manager);
  }

  Map<String, String> _defaultMapping() => {
        'title': 'title',
        'price': 'price',
        'city': 'city',
        'district': 'district',
        'description': 'description',
        'images': 'images',
        'sourceUrl': 'link',
        'externalListingId': 'externalId',
      };

  Map<String, String> _mappingFromHeaderRow(List<dynamic> headerRow) {
    final headers = headerRow.map((e) => e.toString().trim()).toList();
    String pick(Iterable<String> keys) {
      for (final k in keys) {
        final i = headers.indexWhere((h) => h.toLowerCase() == k.toLowerCase());
        if (i >= 0) return headers[i];
      }
      return headers.isNotEmpty ? headers.first : 'title';
    }

    return {
      'title': pick(['title', 'baslik', 'ilan_basligi', 'name']),
      'price': pick(['price', 'fiyat', 'amount']),
      'city': pick(['city', 'sehir', 'il']),
      'district': pick(['district', 'ilce', 'semte']),
      'description': pick(['description', 'aciklama', 'desc']),
      'images': pick(['images', 'image', 'gorseller', 'foto']),
      'sourceUrl': pick(['link', 'url', 'sourceurl']),
      'externalListingId': pick(['externalid', 'id', 'ilan_id']),
    };
  }

  Future<void> _runLocalUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    if (uid == null) {
      _snack('Önce giriş yapın.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ListingImportService.instance.runUrlImport(
        uid: uid,
        officeId: _officeId(ref, uid),
        url: url,
        importMode: _importMode ?? 'skip_duplicates',
      );
      if (!mounted) return;
      _snack(
        'Deneysel URL: içe aktarma tamamlandı (tek ilan). Mağaza ölçeği için dosya yolunu kullanın.',
      );
      _urlCtrl.clear();
      context.push(AppRouter.routeMyListings);
    } catch (e) {
      if (mounted) {
        _snack(userFacingErrorMessage(e, context: 'import_hub_local_url'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runLocalFile() async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    if (uid == null) {
      _snack('Önce giriş yapın.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'json', 'txt', 'xlsx', 'xls'],
    );
    if (result == null || result.files.isEmpty) return;

    final f = result.files.single;
    final path = f.path;
    if (path == null) {
      _snack('Dosya yolu alınamadı.');
      return;
    }

    setState(() => _busy = true);
    try {
      final ext = (f.extension ?? 'csv').toLowerCase();
      var mapping = _defaultMapping();
      final file = File(path);

      if (ext == 'csv' || ext == 'txt') {
        final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
        final rows = const CsvToListConverter(eol: '\n').convert(text);
        if (rows.isNotEmpty) {
          mapping = _mappingFromHeaderRow(rows.first);
        }
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sütun eşlemesi'),
            content: SingleChildScrollView(
              child: Text(
                'Algılanan eşleme:\n${mapping.entries.map((e) => '${e.key} → ${e.value}').join('\n')}',
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('İçe aktar')),
            ],
          ),
        );
        if (confirmed != true) {
          setState(() => _busy = false);
          return;
        }
      } else if (ext == 'xlsx' || ext == 'xls') {
        final bytes = await file.readAsBytes();
        final rows = decodeXlsxBytesToRows(bytes);
        if (rows.isNotEmpty) {
          mapping = _mappingFromHeaderRow(rows.first);
        }
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Excel sütun eşlemesi'),
            content: SingleChildScrollView(
              child: Text(
                'Algılanan eşleme:\n${mapping.entries.map((e) => '${e.key} → ${e.value}').join('\n')}',
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('İçe aktar')),
            ],
          ),
        );
        if (confirmed != true) {
          setState(() => _busy = false);
          return;
        }
      } else if (ext == 'json') {
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('JSON'),
            content: const Text(
              'JSON kökü ilan dizisi veya { "rows": [...] } olmalı. İlan kimliği için id / externalListingId kullanılabilir.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Devam')),
            ],
          ),
        );
        if (confirmed != true) {
          setState(() => _busy = false);
          return;
        }
      }

      await ListingImportService.instance.runFileImport(
        uid: uid,
        officeId: _officeId(ref, uid),
        filePath: path,
        extension: ext,
        mapping: mapping,
        importMode: _importMode ?? 'skip_duplicates',
        storeSourcePlatform: _storePlatform,
      );
      if (!mounted) return;
      _snack(
        'Toplu dosya işlendi. Kaynak: ${_storePlatform ?? 'dosya türü (import_*)'}. '
        'Benim İlanlarım’da doğrulayın.',
      );
      context.push(AppRouter.routeMyListings);
    } catch (e) {
      if (mounted) {
        _snack(userFacingErrorMessage(e, context: 'import_hub_local_file'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openManual() async {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    if (uid == null) {
      _snack('Önce giriş yapın.');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Manuel ilan', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Tek tek ekleme — mağaza dışa aktarımı yerine portföy girişi.',
                  style: TextStyle(color: AppThemeExtension.of(ctx).foregroundSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _manualTitle,
                  decoration: const InputDecoration(labelText: 'Başlık', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _manualPrice,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Fiyat (₺)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _manualLoc,
                  decoration: const InputDecoration(
                    labelText: 'Konum (ör. Diyarbakır · Kayapınar)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _manualDesc,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Açıklama', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          final price = double.tryParse(
                                _manualPrice.text.replaceAll('.', '').replaceAll(',', '.').trim(),
                              ) ??
                              0;
                          if (_manualTitle.text.trim().isEmpty) return;
                          Navigator.pop(ctx);
                          setState(() => _busy = true);
                          try {
                            await ListingImportService.instance.runManualImport(
                              uid: uid,
                              officeId: _officeId(ref, uid),
                              title: _manualTitle.text.trim(),
                              price: price,
                              location: _manualLoc.text.trim().isEmpty ? '—' : _manualLoc.text.trim(),
                              description: _manualDesc.text.trim(),
                            );
                            _manualTitle.clear();
                            _manualPrice.clear();
                            _manualLoc.clear();
                            _manualDesc.clear();
                            if (!mounted) return;
                            _snack('Manuel ilan eklendi.');
                            context.push(AppRouter.routeMyListings);
                          } catch (e) {
                            if (mounted) {
                              _snack(userFacingErrorMessage(e, context: 'import_hub_manual'));
                            }
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _snackStorageSoft(String msg) {
    AppToaster.warning(context, msg);
  }

  Future<void> _submitUrlServer() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() => _busy = true);
    try {
      final taskId = await ListingImportFunctions.instance.enqueueUrlImport(
        url: url,
        importMode: _importMode ?? 'skip_duplicates',
      );
      if (!mounted) return;
      _snack(taskId != null ? 'Sunucu kuyruğu (tek URL): $taskId' : 'İstek gönderildi.');
      _urlCtrl.clear();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      _snack(userFacingErrorMessage(e, context: 'import_hub_enqueue_url'));
    } catch (e) {
      if (!mounted) return;
      _snack(userFacingErrorMessage(e, context: 'import_hub_enqueue_url'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAndUploadServer() async {
    final usable = await FirebaseStorageAvailability.checkUsable();
    if (!usable) {
      if (mounted) {
        _snackStorageSoft(FirebaseStorageAvailability.unavailableMessage);
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!_canUploadOfficeImportServer(ref)) {
      if (mounted) {
        _snackStorageSoft(
          'Toplu dosya yüklemesi yalnızca ofis yöneticisi, ekip lideri veya süper yönetici içindir.',
        );
      }
      return;
    }
    final oid = _officeId(ref, user.uid);
    if (oid.isEmpty) {
      if (mounted) {
        _snackStorageSoft('Önce bir ofise bağlanın.');
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'json', 'xlsx', 'xls', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;

    final f = result.files.single;
    final path = f.path;
    if (path == null) {
      if (!mounted) return;
      _snack('Dosya yolu alınamadı.');
      return;
    }

    setState(() => _busy = true);
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      final ext = (f.extension ?? 'csv').toLowerCase();
      var mapping = _defaultMapping();

      if (ext == 'csv' || ext == 'txt') {
        final text = utf8.decode(bytes, allowMalformed: true);
        final rows = const CsvToListConverter(eol: '\n').convert(text);
        if (rows.isNotEmpty) {
          mapping = _mappingFromHeaderRow(rows.first);
        }

        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sütun eşlemesi'),
            content: SingleChildScrollView(
              child: Text(
                'Algılanan eşleme:\n${mapping.entries.map((e) => '${e.key} → ${e.value}').join('\n')}',
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yükle')),
            ],
          ),
        );
        if (confirmed != true) {
          setState(() => _busy = false);
          return;
        }
      } else if (ext == 'json') {
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('JSON'),
            content: const Text(
              'JSON kökü ilan dizisi veya { "rows": [...] } olmalı.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Devam')),
            ],
          ),
        );
        if (confirmed != true) {
          setState(() => _busy = false);
          return;
        }
      } else {
        if (!mounted) return;
        final manual = await showDialog<Map<String, String>?>(
          context: context,
          builder: (ctx) => const _ManualMappingDialog(),
        );
        if (manual == null) {
          setState(() => _busy = false);
          return;
        }
        mapping = manual;
      }

      final safeName = f.name.isEmpty ? 'import.bin' : f.name;
      final sessionId = const Uuid().v4();
      final objectName = StoragePaths.officeImport(oid, sessionId, safeName);
      final refStorage = FirebaseStorage.instance.ref(objectName);
      await refStorage.putData(bytes, SettableMetadata(contentType: _guessMime(ext)));

      final platform = _storePlatform ?? 'sahibinden';

      final taskId = await ListingImportFunctions.instance.enqueueFileImport(
        storagePath: objectName,
        fileName: safeName,
        mapping: mapping,
        officeId: oid,
        importMode: _importMode ?? 'skip_duplicates',
        platform: platform,
      );
      if (!mounted) return;
      _snack(taskId != null ? 'Toplu dosya kuyrukta: $taskId (platform: $platform)' : 'İstek gönderildi.');
    } on FirebaseException catch (e) {
      if (!mounted) return;
      if (FirebaseStorageAvailability.isUnavailableError(e)) {
        _snackStorageSoft(FirebaseStorageAvailability.unavailableMessage);
      } else {
        _snackStorageSoft(userFacingErrorMessage(e, context: 'import_hub_storage_upload'));
      }
    } catch (e) {
      if (!mounted) return;
      if (FirebaseStorageAvailability.isUnavailableError(e)) {
        _snackStorageSoft(FirebaseStorageAvailability.unavailableMessage);
      } else {
        _snack(userFacingErrorMessage(e, context: 'import_hub_server_file'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _guessMime(String ext) {
    switch (ext) {
      case 'json':
        return 'application/json';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'xls':
        return 'application/vnd.ms-excel';
      default:
        return 'text/csv';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final storageAsync = ref.watch(firebaseStorageAvailableProvider);
    final storageOk = storageAsync.maybeWhen(
      data: (ok) => ok,
      orElse: () => true,
    );
    final storageKnownInactive = storageAsync.maybeWhen(
      data: (ok) => !ok,
      orElse: () => false,
    );
    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                const AppBackButton(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mağaza toplu içe aktarma',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: ext.foreground,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'Tüm vitrin ilanlarınızı tek seferde «Benim İlanlarım»a alın',
                        style: TextStyle(color: ext.foregroundSecondary, fontSize: 12, height: 1.3),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : () => context.push(AppRouter.routeMyListings),
                  child: const Text('İlanlarım'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => context.push(AppRouter.routeImportHistory),
                  child: const Text('Geçmiş'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ext.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ext.border.withValues(alpha: 0.45)),
              ),
              child: Text(
                'Canlı mağaza OAuth / otomatik tam senkron henüz yok. Bugün için güvenilir yol: '
                'platformdan dışa aktardığınız CSV, JSON veya Excel dosyasını yükleyin. '
                'Bu, «tüm ilanları» tek işlemde içeri almanın üretim yoludur.',
                style: TextStyle(color: ext.foreground.withValues(alpha: 0.9), height: 1.4, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            _OfficialConnectorCard(ext: ext),
            const SizedBox(height: 16),
            Text('Mağaza kaynağı (etiket)', style: TextStyle(color: ext.foreground, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'İlanların sourcePlatform alanına yazılır; boşsa dosya türü (import_csv vb.) kullanılır.',
              style: TextStyle(color: ext.foregroundSecondary, fontSize: 11, height: 1.35),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _storePlatform,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              items: const [
                DropdownMenuItem(child: Text('Genel / belirtmiyorum')),
                DropdownMenuItem(value: 'sahibinden', child: Text('Sahibinden vitrin dışa aktarımı')),
                DropdownMenuItem(value: 'hepsiemlak', child: Text('Hepsiemlak dışa aktarımı')),
                DropdownMenuItem(value: 'emlakjet', child: Text('Emlakjet dışa aktarımı')),
              ],
              onChanged: _busy ? null : (v) => setState(() => _storePlatform = v),
            ),
            const SizedBox(height: 16),
            Text('Yinelenen kayıt modu', style: TextStyle(color: ext.foreground, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _importMode,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              items: const [
                DropdownMenuItem(value: 'skip_duplicates', child: Text('Çiftleri atla')),
                DropdownMenuItem(value: 'update_duplicates', child: Text('Çiftleri güncelle')),
                DropdownMenuItem(value: 'create_new', child: Text('Yalnızca yeni (çift yok)')),
              ],
              onChanged: _busy ? null : (v) => setState(() => _importMode = v),
            ),
            const SizedBox(height: 22),
            Text(
              '1 · Dosyadan toplu içe aktar (önerilen)',
              style: TextStyle(color: ext.foreground, fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _runLocalFile,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_rounded),
              label: const Text('CSV / JSON / XLSX seç (cihazda işle)'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : _openManual,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Manuel tek tek ilan ekle'),
            ),
            const SizedBox(height: 20),
            Text(
              '2 · Sunucu kuyruğu (Storage + Cloud Functions)',
              style: TextStyle(color: ext.foreground, fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Büyük dosyalar için; ilerleme «Geçmiş» ekranında.',
              style: TextStyle(color: ext.foregroundSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: (_busy || !storageOk) ? null : _pickAndUploadServer,
              child: const Text('Dosyayı Storage’a yükle ve kuyruğa al'),
            ),
            if (storageAsync.isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Depolama durumu kontrol ediliyor…',
                  maxLines: 2,
                  style: TextStyle(color: ext.foreground.withValues(alpha: 0.5), fontSize: 12),
                ),
              )
            else if (storageKnownInactive)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  FirebaseStorageAvailability.unavailableMessage,
                  maxLines: 3,
                  style: TextStyle(color: ext.foreground.withValues(alpha: 0.65), fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Tek ilan URL’si (deneysel — ikincil)', style: TextStyle(color: ext.foreground)),
              subtitle: Text(
                'Mağaza ölçeği için uygun değildir; tek URL başına çalışır.',
                style: TextStyle(color: ext.foreground.withValues(alpha: 0.65), fontSize: 12),
              ),
              children: [
                TextField(
                  controller: _urlCtrl,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    hintText: 'https://www.sahibinden.com/ilan/...',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: _busy ? null : _runLocalUrl,
                  child: const Text('URL’yi yerelde dene'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: _busy ? null : _submitUrlServer,
                  child: const Text('URL’yi sunucu kuyruğuna gönder'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Uzantı: tarayıcıda «İlanları içe aktar» — ${AppConstants.appName} Chrome eklentisi (doc: extension/chrome/README.md).',
              style: TextStyle(fontSize: 12, color: ext.foreground.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficialConnectorCard extends StatelessWidget {
  const _OfficialConnectorCard({required this.ext});

  final AppThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ext.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, color: ext.accent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resmi entegrasyon (otomatik mağaza senkronu)',
                  style: TextStyle(
                    color: ext.foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hazırlanıyor — canlı OAuth ile vitrinin tamamını arka planda çekme şu an kapalı. '
                  'Açıldığında bu kart «etkin» olacak; şimdilik dosya ile toplu içe aktarın.',
                  style: TextStyle(color: ext.foregroundSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualMappingDialog extends StatefulWidget {
  const _ManualMappingDialog();

  @override
  State<_ManualMappingDialog> createState() => _ManualMappingDialogState();
}

class _ManualMappingDialogState extends State<_ManualMappingDialog> {
  final _title = TextEditingController(text: 'title');
  final _price = TextEditingController(text: 'price');
  final _city = TextEditingController(text: 'city');

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sütun adları (Excel)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Başlık sütunu')),
          TextField(controller: _price, decoration: const InputDecoration(labelText: 'Fiyat')),
          TextField(controller: _city, decoration: const InputDecoration(labelText: 'Şehir')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'title': _title.text.trim(),
              'price': _price.text.trim(),
              'city': _city.text.trim(),
              'district': 'district',
              'description': 'description',
              'images': 'images',
              'sourceUrl': 'link',
              'externalListingId': 'id',
            });
          },
          child: const Text('Tamam'),
        ),
      ],
    );
  }
}
