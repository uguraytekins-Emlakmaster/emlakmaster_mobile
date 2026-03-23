import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:csv/csv.dart';
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/listing_import/data/listing_import_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';

/// URL ve dosya ile içe aktarma giriş noktası — işlem sunucuda kuyruğa alınır (UI bloklanmaz).
class ImportHubPage extends StatefulWidget {
  const ImportHubPage({super.key});

  @override
  State<ImportHubPage> createState() => _ImportHubPageState();
}

class _ImportHubPageState extends State<ImportHubPage> {
  final _urlCtrl = TextEditingController();
  bool _busy = false;
  String? _importMode = 'skip_duplicates';

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() => _busy = true);
    try {
      final taskId = await ListingImportFunctions.instance.enqueueUrlImport(
        url: url,
        importMode: _importMode ?? 'skip_duplicates',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(taskId != null ? 'Kuyruğa alındı: $taskId' : 'İstek gönderildi.')),
      );
      _urlCtrl.clear();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? e.code)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAndUploadFile() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya yolu alınamadı (masaüstü sürümünde yeniden deneyin).')),
      );
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
              'JSON kökü ilan dizisi veya { "rows": [...] } olmalı. title alanı için mapping varsayılan "title" kabul edilir.',
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
      final ref = FirebaseStorage.instance.ref(objectName);
      await ref.putData(
        bytes,
        SettableMetadata(contentType: _guessMime(ext)),
      );

      final taskId = await ListingImportFunctions.instance.enqueueFileImport(
        storagePath: objectName,
        fileName: safeName,
        mapping: mapping,
        importMode: _importMode ?? 'skip_duplicates',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(taskId != null ? 'Dosya kuyruğa alındı: $taskId' : 'İstek gönderildi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
                  onPressed: _busy ? null : () => context.push(AppRouter.routeImportHistory),
                  child: const Text('Geçmiş'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'URL yapıştırın veya CSV/Excel/JSON dosyası yükleyin. İşlem arka planda işlenir; «Geçmiş» ekranından durumu izleyin.',
              style: TextStyle(color: ext.foreground.withValues(alpha: 0.85)),
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
              onPressed: _busy ? null : _submitUrl,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link),
              label: const Text('URL’yi kuyruğa al'),
            ),
            const SizedBox(height: 32),
            Text('Dosya', style: TextStyle(color: ext.foreground, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickAndUploadFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('CSV / JSON / Excel seç ve yükle'),
            ),
            const SizedBox(height: 24),
            Text(
              'Uzantı: tarayıcıda oturum açıkken «İlanları içe aktar» — ${AppConstants.appName} Chrome eklentisi (doc: extension/chrome/README.md).',
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
