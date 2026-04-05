import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:csv/csv.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/providers/firebase_storage_availability_provider.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firebase_storage_availability.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/widgets/app_toaster.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/listing_import/data/listing_import_functions.dart';
import 'package:emlakmaster_mobile/features/listing_import/data/listing_import_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';

/// İçe aktarma — Phase 1.5 yerel motor (mock parse) + isteğe bağlı sunucu kuyruğu.
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
        'Yerel deneysel motor: içe aktarma tamamlandı (mock veri; canlı parse değil). '
        'Listeyi doğrulayın.',
      );
      _urlCtrl.clear();
      context.push(AppRouter.routeMyListings);
    } catch (e) {
      if (mounted) _snack('$e');
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
      allowedExtensions: const ['csv', 'json', 'txt'],
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
      Map<String, String> mapping = {
        'title': 'title',
        'price': 'price',
        'city': 'city',
        'district': 'district',
        'description': 'description',
        'images': 'images',
        'sourceUrl': 'link',
        'externalListingId': 'externalId',
      };

      if (ext == 'csv' || ext == 'txt') {
        final file = File(path);
        final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
        final rows = const CsvToListConverter(eol: '\n').convert(text);
        if (rows.isNotEmpty) {
          final headers = rows.first.map((e) => e.toString().trim()).toList();
          String pick(Iterable<String> keys) {
            for (final k in keys) {
              final i = headers.indexWhere((h) => h.toLowerCase() == k.toLowerCase());
              if (i >= 0) return headers[i];
            }
            return headers.isNotEmpty ? headers.first : 'title';
          }

          mapping = {
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
      }

      await ListingImportService.instance.runFileImport(
        uid: uid,
        officeId: _officeId(ref, uid),
        filePath: path,
        extension: ext,
        mapping: mapping,
        importMode: _importMode ?? 'skip_duplicates',
      );
      if (!mounted) return;
      _snack('Dosya işlendi (yerel motor).');
      context.push(AppRouter.routeMyListings);
    } catch (e) {
      if (mounted) _snack('$e');
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
                            if (mounted) _snack('$e');
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

  /// Opsiyonel: Firebase Callable + Storage (üretim kuyruğu).
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
      _snack(taskId != null ? 'Sunucu kuyruğu: $taskId' : 'İstek gönderildi.');
      _urlCtrl.clear();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      _snack(e.message ?? e.code);
    } catch (e) {
      if (!mounted) return;
      _snack('$e');
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
      Map<String, String> mapping = {
        'title': 'title',
        'price': 'price',
        'city': 'city',
        'district': 'district',
        'description': 'description',
        'images': 'images',
        'sourceUrl': 'link',
        'externalListingId': 'externalId',
      };

      if (ext == 'csv' || ext == 'txt') {
        final text = utf8.decode(bytes, allowMalformed: true);
        final rows = const CsvToListConverter(eol: '\n').convert(text);
        if (rows.isNotEmpty) {
          final headers = rows.first.map((e) => e.toString().trim()).toList();
          String pick(Iterable<String> keys) {
            for (final k in keys) {
              final i = headers.indexWhere((h) => h.toLowerCase() == k.toLowerCase());
              if (i >= 0) return headers[i];
            }
            return headers.isNotEmpty ? headers.first : 'title';
          }

          mapping = {
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
      final objectName = 'users/${user.uid}/imports/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final refStorage = FirebaseStorage.instance.ref(objectName);
      await refStorage.putData(bytes, SettableMetadata(contentType: _guessMime(ext)));

      final taskId = await ListingImportFunctions.instance.enqueueFileImport(
        storagePath: objectName,
        fileName: safeName,
        mapping: mapping,
        importMode: _importMode ?? 'skip_duplicates',
      );
      if (!mounted) return;
      _snack(taskId != null ? 'Dosya kuyruğa alındı: $taskId' : 'İstek gönderildi.');
    } on FirebaseException catch (e) {
      if (!mounted) return;
      if (FirebaseStorageAvailability.isUnavailableError(e)) {
        _snackStorageSoft(FirebaseStorageAvailability.unavailableMessage);
      } else {
        _snackStorageSoft('Storage: ${e.message ?? e.code}');
      }
    } catch (e) {
      if (!mounted) return;
      if (FirebaseStorageAvailability.isUnavailableError(e)) {
        _snackStorageSoft(FirebaseStorageAvailability.unavailableMessage);
      } else {
        _snack('$e');
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
    final storageOk = storageAsync.when(
      data: (ok) => ok,
      loading: () => true,
      error: (_, __) => false,
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
                  child: Text(
                    'İçe aktarma motoru',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: ext.foreground,
                          fontWeight: FontWeight.w700,
                        ),
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
            const SizedBox(height: 12),
            Text(
              'Resmi platform OAuth ve güvenilir HTML parse henüz tam canlı değil. '
              '«Yerel URL» deneyseldir (heuristik/mock): başlık, fiyat, konum veya görsel '
              'güvenilir çıkmazsa kayıt oluşturulmaz. Güvenilir veri için CSV/JSON veya manuel giriş kullanın. '
              'Sunucu kuyruğu, kalite eşiğini geçen sonuçları yazar.',
              style: TextStyle(color: ext.foreground.withValues(alpha: 0.85), height: 1.35),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 24),
            Text('İlan URL’si', style: TextStyle(color: ext.foreground, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _urlCtrl,
              enabled: !_busy,
              decoration: const InputDecoration(
                hintText: 'https://www.sahibinden.com/ilan/...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _runLocalUrl,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link),
              label: const Text('URL’yi içe aktar (yerel)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _runLocalFile,
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('CSV / JSON dosyası (yerel)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _openManual,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Manuel ilan ekle'),
            ),
            const SizedBox(height: 28),
            ExpansionTile(
              title: Text('Gelişmiş: sunucu kuyruğu', style: TextStyle(color: ext.foreground)),
              subtitle: Text(
                'Cloud Functions + Storage — ayrı izleme için «Geçmiş».',
                style: TextStyle(color: ext.foreground.withValues(alpha: 0.65), fontSize: 12),
              ),
              children: [
                FilledButton.tonal(
                  onPressed: _busy ? null : _submitUrlServer,
                  child: const Text('URL’yi sunucuya gönder'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: (_busy || !storageOk) ? null : _pickAndUploadServer,
                  child: const Text('Dosyayı Storage’a yükle ve kuyruğa al'),
                ),
                if (!storageOk)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      FirebaseStorageAvailability.unavailableMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext.foreground.withValues(alpha: 0.65),
                        fontSize: 12,
                      ),
                    ),
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
