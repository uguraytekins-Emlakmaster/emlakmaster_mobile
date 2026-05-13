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
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
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
        (m.role == OfficeRole.owner ||
            m.role == OfficeRole.admin ||
            m.role == OfficeRole.manager);
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
      _snack('Önce oturum açın.');
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
      _snack('Tek ilan içeri alındı. Toplu akış için dosya kullanın.');
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
      _snack('Önce oturum açın.');
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
      _snack('Dosya yolu okunamadı.');
      return;
    }

    setState(() => _busy = true);
    try {
      final ext = (f.extension ?? 'csv').toLowerCase();
      var mapping = _defaultMapping();
      final file = File(path);

      if (ext == 'csv' || ext == 'txt') {
        final text =
            utf8.decode(await file.readAsBytes(), allowMalformed: true);
        final rows = const CsvToListConverter(eol: '\n').convert(text);
        if (rows.isNotEmpty) {
          mapping = _mappingFromHeaderRow(rows.first);
        }
        if (!mounted) return;
        final confirmed = await _showImportConfirmDialog(
          title: 'Sütun uyumu',
          body:
              'Algılanan alan uyumu:\n${mapping.entries.map((e) => '${e.key} → ${e.value}').join('\n')}',
          confirmLabel: 'İçeri al',
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
        final confirmed = await _showImportConfirmDialog(
          title: 'Excel alan uyumu',
          body:
              'Algılanan alan uyumu:\n${mapping.entries.map((e) => '${e.key} → ${e.value}').join('\n')}',
          confirmLabel: 'İçeri al',
        );
        if (confirmed != true) {
          setState(() => _busy = false);
          return;
        }
      } else if (ext == 'json') {
        if (!mounted) return;
        final confirmed = await _showImportConfirmDialog(
          title: 'JSON yapısı',
          body:
              'Kök bir ilan dizisi veya { "rows": [...] } beklenir. Kimlik için id veya externalListingId kullanın.',
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
        'Dosya işlendi. Sonuçları İlanlarım alanında inceleyin.',
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
      _snack('Önce oturum açın.');
      return;
    }
    await showPremiumModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final sheetExt = AppThemeExtension.of(ctx);
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space5,
              DesignTokens.space2,
              DesignTokens.space5,
              DesignTokens.space6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const PremiumBottomSheetHandle(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.post_add_outlined,
                      size: DesignTokens.iconLg,
                      color: sheetExt.accent.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    const Expanded(
                      child: PremiumSheetHeader(
                        compact: true,
                        title: 'Elle ilan girişi',
                        subtitle:
                            'Tek kayıt için hızlı giriş; toplu akış yerine pratik çözüm',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kapat',
                      style: IconButton.styleFrom(
                        foregroundColor: sheetExt.textTertiary,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space4),
                TextField(
                  controller: _manualTitle,
                  style: TextStyle(color: sheetExt.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Başlık',
                    labelStyle: TextStyle(color: sheetExt.textSecondary),
                    filled: true,
                    fillColor: sheetExt.background,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusControl),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.space3),
                TextField(
                  controller: _manualPrice,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: sheetExt.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Fiyat (₺)',
                    labelStyle: TextStyle(color: sheetExt.textSecondary),
                    filled: true,
                    fillColor: sheetExt.background,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusControl),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.space3),
                TextField(
                  controller: _manualLoc,
                  style: TextStyle(color: sheetExt.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Konum (ör. Diyarbakır · Kayapınar)',
                    labelStyle: TextStyle(color: sheetExt.textSecondary),
                    filled: true,
                    fillColor: sheetExt.background,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusControl),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.space3),
                TextField(
                  controller: _manualDesc,
                  maxLines: 3,
                  style: TextStyle(color: sheetExt.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Açıklama',
                    labelStyle: TextStyle(color: sheetExt.textSecondary),
                    filled: true,
                    fillColor: sheetExt.background,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusControl),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.space5),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          final price = double.tryParse(
                                _manualPrice.text
                                    .replaceAll('.', '')
                                    .replaceAll(',', '.')
                                    .trim(),
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
                              location: _manualLoc.text.trim().isEmpty
                                  ? '—'
                                  : _manualLoc.text.trim(),
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
                              _snack(userFacingErrorMessage(
                                e,
                                context: 'import_hub_manual',
                              ));
                            }
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: sheetExt.accent,
                    foregroundColor: sheetExt.onBrand,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusControl,
                      ),
                    ),
                  ),
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showImportConfirmDialog({
    required String title,
    required String body,
    String confirmLabel = 'Sürdür',
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: AppThemeExtension.of(context).shadowColor.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.5 : 0.18,
          ),
      builder: (ctx) {
        final d = AppThemeExtension.of(ctx);
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space5,
            vertical: DesignTokens.space8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          ),
          backgroundColor: d.surface,
          title: Text(title, style: AppTypography.cardHeading(ctx)),
          content: SingleChildScrollView(
            child: Text(body, style: AppTypography.body(ctx)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: d.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: DesignTokens.space5),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusControl),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmLabel),
            ),
          ],
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
      _snack(taskId != null
          ? 'Sunucu kuyruğu (tek URL): $taskId'
          : 'İstek gönderildi.');
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
          'Bu yükleme yalnızca ofis yöneticisi, ekip lideri ya da süper yönetici içindir.',
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
      _snack('Dosya yolu okunamadı.');
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
        final confirmed = await _showImportConfirmDialog(
          title: 'Sütun uyumu',
          body:
              'Algılanan alan uyumu:\n${mapping.entries.map((e) => '${e.key} → ${e.value}').join('\n')}',
          confirmLabel: 'Yükle',
        );
        if (confirmed != true) {
          setState(() => _busy = false);
          return;
        }
      } else if (ext == 'json') {
        if (!mounted) return;
        final confirmed = await _showImportConfirmDialog(
          title: 'JSON yapısı',
          body: 'Kök ilan dizisi veya { "rows": [...] } beklenir.',
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
      await refStorage.putData(
          bytes, SettableMetadata(contentType: _guessMime(ext)));

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
      _snack(taskId != null
          ? 'Toplu dosya sıraya alındı: $taskId (kanal: $platform)'
          : 'İstek gönderildi.');
    } on FirebaseException catch (e) {
      if (!mounted) return;
      if (FirebaseStorageAvailability.isUnavailableError(e)) {
        _snackStorageSoft(FirebaseStorageAvailability.unavailableMessage);
      } else {
        _snackStorageSoft(
            userFacingErrorMessage(e, context: 'import_hub_storage_upload'));
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
    final dropdownDeco = InputDecoration(
      filled: true,
      fillColor: ext.surface,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
        borderSide: BorderSide(color: ext.border.withValues(alpha: 0.5)),
      ),
    );
    final primaryFileStyle = FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
      ),
    );
    final secondaryOutlineStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 46),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
      ),
      side: BorderSide(color: ext.border.withValues(alpha: 0.65)),
    );
    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space5,
            DesignTokens.space3,
            DesignTokens.space5,
            DesignTokens.space6,
          ),
          children: [
            Row(
              children: [
                const AppBackButton(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toplu ilan akışı',
                        style: AppTypography.cardHeading(context).copyWith(
                          color: ext.foreground,
                          fontSize: DesignTokens.fontSizeLg,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.titleSubtitleGap),
                      Text(
                        'Vitrin ilanlarınızı tek hamlede İlanlarım alanına taşıyın',
                        style: AppTypography.body(context).copyWith(
                          color: ext.foregroundSecondary,
                          fontSize: DesignTokens.fontSizeSm,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style:
                      TextButton.styleFrom(foregroundColor: ext.textSecondary),
                  onPressed: _busy
                      ? null
                      : () => context.push(AppRouter.routeMyListings),
                  child: const Text('İlanlarım'),
                ),
                TextButton(
                  style:
                      TextButton.styleFrom(foregroundColor: ext.textSecondary),
                  onPressed: _busy
                      ? null
                      : () => context.push(AppRouter.routeImportHistory),
                  child: const Text('İşlem Geçmişi'),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.space5),
              decoration: BoxDecoration(
                color: ext.surfaceElevated,
                borderRadius:
                    BorderRadius.circular(DesignTokens.radiusCardSecondary),
                border: Border.all(color: ext.border.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Canlı mağaza eşlemesi henüz açık değil. En güvenilir yol, platformdan dışa aktarım alıp CSV, JSON ya da Excel ile tek seferde yüklemektir.',
                style: AppTypography.body(context).copyWith(
                  color: ext.foreground.withValues(alpha: 0.92),
                  fontSize: DesignTokens.fontSizeSm,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.space5),
            _OfficialConnectorCard(ext: ext),
            const SizedBox(height: DesignTokens.space5),
            Text(
              'Veri kaynağı',
              style: AppTypography.metricLabel(context).copyWith(
                color: ext.foreground,
                fontSize: DesignTokens.fontSizeSm,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'İlanlarda sourcePlatform etiketi; boş bırakılırsa dosya türü kullanılır.',
              style: AppTypography.body(context).copyWith(
                fontSize: DesignTokens.fontSizeXs,
                height: 1.35,
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            DropdownButtonFormField<String?>(
              initialValue: _storePlatform,
              decoration: dropdownDeco,
              items: const [
                DropdownMenuItem<String?>(
                  child: Text('Genel'),
                ),
                DropdownMenuItem(
                  value: 'sahibinden',
                  child: Text('Sahibinden dışa aktarımı'),
                ),
                DropdownMenuItem(
                  value: 'hepsiemlak',
                  child: Text('Hepsiemlak dışa aktarımı'),
                ),
                DropdownMenuItem(
                  value: 'emlakjet',
                  child: Text('Emlakjet dışa aktarımı'),
                ),
              ],
              onChanged:
                  _busy ? null : (v) => setState(() => _storePlatform = v),
            ),
            const SizedBox(height: DesignTokens.space5),
            Text(
              'Yinelenen kayıt',
              style: AppTypography.metricLabel(context).copyWith(
                color: ext.foreground,
                fontSize: DesignTokens.fontSizeSm,
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            DropdownButtonFormField<String>(
              initialValue: _importMode,
              decoration: dropdownDeco,
              items: const [
                DropdownMenuItem(
                  value: 'skip_duplicates',
                  child: Text('Çiftleri atla'),
                ),
                DropdownMenuItem(
                  value: 'update_duplicates',
                  child: Text('Çiftleri güncelle'),
                ),
                DropdownMenuItem(
                  value: 'create_new',
                  child: Text('Yalnızca yeni kayıt'),
                ),
              ],
              onChanged: _busy ? null : (v) => setState(() => _importMode = v),
            ),
            const SizedBox(height: DesignTokens.space6),
            Text(
              '1 · Dosyadan içeri al',
              style: AppTypography.cardHeading(context).copyWith(
                color: ext.foreground,
                fontSize: DesignTokens.fontSizeMd,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Önerilen yol: cihazda işlenir, hızlı ve nettir.',
              style: AppTypography.body(context).copyWith(
                fontSize: DesignTokens.fontSizeXs,
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            FilledButton.icon(
              style: primaryFileStyle,
              onPressed: _busy ? null : _runLocalFile,
              icon: _busy
                  ? const SizedBox(
                      width: DesignTokens.iconMd,
                      height: DesignTokens.iconMd,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_rounded),
              label: const Text('Dosya seç (CSV · JSON · Excel)'),
            ),
            const SizedBox(height: DesignTokens.space3),
            OutlinedButton.icon(
              style: secondaryOutlineStyle,
              onPressed: _busy ? null : _openManual,
              icon: const Icon(Icons.edit_note_rounded,
                  size: DesignTokens.iconMd),
              label: const Text('Tek ilan girişi'),
            ),
            const SizedBox(height: DesignTokens.space6),
            Text(
              '2 · Sunucu sırası',
              style: AppTypography.cardHeading(context).copyWith(
                color: ext.foreground,
                fontSize: DesignTokens.fontSizeMd,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Büyük dosyalar için; ilerleme İşlem Geçmişi’nde görünür.',
              style: AppTypography.body(context).copyWith(
                fontSize: DesignTokens.fontSizeXs,
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            OutlinedButton(
              style: secondaryOutlineStyle,
              onPressed: (_busy || !storageOk) ? null : _pickAndUploadServer,
              child: const Text('Dosyayı yükle ve sıraya al'),
            ),
            if (storageAsync.isLoading)
              Padding(
                padding: const EdgeInsets.only(top: DesignTokens.space3),
                child: Text(
                  'Depolama kontrol ediliyor…',
                  maxLines: 2,
                  style: AppTypography.body(context).copyWith(
                    fontSize: DesignTokens.fontSizeXs,
                    color: ext.foreground.withValues(alpha: 0.5),
                  ),
                ),
              )
            else if (storageKnownInactive)
              Padding(
                padding: const EdgeInsets.only(top: DesignTokens.space3),
                child: Text(
                  FirebaseStorageAvailability.unavailableMessage,
                  maxLines: 3,
                  style: AppTypography.body(context).copyWith(
                    fontSize: DesignTokens.fontSizeXs,
                    color: ext.foreground.withValues(alpha: 0.65),
                  ),
                ),
              ),
            const SizedBox(height: DesignTokens.space5),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              collapsedIconColor: ext.textSecondary,
              iconColor: ext.textSecondary,
              title: Text(
                'Tek ilan bağlantısı (deneysel)',
                style: AppTypography.bodyStrong(context).copyWith(
                  fontSize: DesignTokens.fontSizeSm,
                ),
              ),
              subtitle: Text(
                'Toplu vitrin akışı için uygun değildir.',
                style: AppTypography.body(context).copyWith(
                  fontSize: DesignTokens.fontSizeXs,
                ),
              ),
              children: [
                TextField(
                  controller: _urlCtrl,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    hintText: 'https://…',
                    filled: true,
                    fillColor: ext.surface,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusControl),
                    ),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: DesignTokens.space3),
                FilledButton.tonal(
                  onPressed: _busy ? null : _runLocalUrl,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusControl),
                    ),
                  ),
                  child: const Text('Bağlantıyı cihazda dene'),
                ),
                const SizedBox(height: DesignTokens.space2),
                FilledButton.tonal(
                  onPressed: _busy ? null : _submitUrlServer,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusControl),
                    ),
                  ),
                  child: const Text('Sıraya gönder'),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space5),
            Text(
              'Chrome eklentisiyle tarayıcıdan hızlı aktarım — ${AppConstants.appName} dokümantasyonu.',
              style: AppTypography.body(context).copyWith(
                fontSize: DesignTokens.fontSizeXs,
                height: 1.35,
              ),
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
      padding: const EdgeInsets.all(DesignTokens.space5),
      decoration: BoxDecoration(
        color: ext.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(DesignTokens.radiusCardSecondary),
        border: Border.all(color: ext.accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.hub_outlined,
            color: ext.accent.withValues(alpha: 0.85),
            size: DesignTokens.iconLg,
          ),
          const SizedBox(width: DesignTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resmi mağaza bağı',
                  style: AppTypography.cardHeading(context).copyWith(
                    color: ext.foreground,
                    fontSize: DesignTokens.fontSizeMd,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: DesignTokens.titleSubtitleGap),
                Text(
                  'Canlı OAuth vitrin eşlemesi hazırlanıyor. Şimdilik dosya akışı en güvenilir seçenek.',
                  style: AppTypography.body(context).copyWith(
                    fontSize: DesignTokens.fontSizeSm,
                    height: 1.4,
                  ),
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
    final d = AppThemeExtension.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
    );
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      backgroundColor: d.surface,
      title: Text(
        'Excel sütunları',
        style: AppTypography.cardHeading(context),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: InputDecoration(
              labelText: 'Başlık sütunu',
              filled: true,
              fillColor: d.background,
              border: border,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          TextField(
            controller: _price,
            decoration: InputDecoration(
              labelText: 'Fiyat',
              filled: true,
              fillColor: d.background,
              border: border,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          TextField(
            controller: _city,
            decoration: InputDecoration(
              labelText: 'Şehir',
              filled: true,
              fillColor: d.background,
              border: border,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'İptal',
            style:
                TextStyle(color: d.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
            ),
          ),
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
          child: const Text('Uygula'),
        ),
      ],
    );
  }
}
