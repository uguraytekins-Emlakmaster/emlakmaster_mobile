import 'dart:io';

import 'package:emlakmaster_mobile/core/constants/turkish_cities.dart';
import 'package:flutter/services.dart';
import 'package:emlakmaster_mobile/core/services/logo_storage_service.dart';
import 'package:emlakmaster_mobile/features/listing_display/data/listing_display_settings_repository.dart';
import 'package:emlakmaster_mobile/features/listing_display/domain/entities/listing_display_settings_entity.dart';
import 'package:emlakmaster_mobile/features/listing_display/presentation/providers/listing_display_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Ayarlar sayfasında: şehir, ilçe, şirket adı, logo (Market Pulse ilan kaynakları & ofis).
class ListingDisplaySettingsSection extends ConsumerStatefulWidget {
  const ListingDisplaySettingsSection({super.key});

  @override
  ConsumerState<ListingDisplaySettingsSection> createState() =>
      _ListingDisplaySettingsSectionState();
}

class _ListingDisplaySettingsSectionState
    extends ConsumerState<ListingDisplaySettingsSection> {
  final _companyController = TextEditingController();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    HapticFeedback.mediumImpact();
    try {
      final x = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (x == null || !mounted) return;
      final file = File(x.path);
      final url = await LogoStorageService.instance.uploadLogo(file);
      final settings = ref.read(listingDisplaySettingsProvider).valueOrNull ??
          const ListingDisplaySettingsEntity();
      await ListingDisplaySettingsRepository.set(
          settings.copyWith(logoUrl: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logo kaydedildi'),
            backgroundColor: Color(0xFF00FF41),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('storage') || e.toString().contains('Storage')
            ? 'Firebase Storage açılmamış olabilir. Konsoldan Storage\'ı başlatın.'
            : 'Logo yüklenemedi: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(listingDisplaySettingsProvider);
    return async.when(
      data: (settings) {
        if (_companyController.text != settings.companyName) {
          _companyController.text = settings.companyName;
          _companyController.selection = TextSelection.collapsed(offset: _companyController.text.length);
        }
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      'İlan kaynakları & ofis',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Şehir seçince sahibinden, emlakjet ve hepsi emlak\'tan ilanlar otomatik çekilir.',
                      child: Icon(Icons.info_outline_rounded, size: 16, color: Colors.white38),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.location_city_rounded, color: Color(0xFF00FF41)),
                title: const Text('Şehir', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  settings.cityName,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                onTap: () => _showCityPicker(context, ref, settings),
              ),
              ListTile(
                leading: const Icon(Icons.map_rounded, color: Color(0xFF00FF41)),
                title: const Text('İlçe', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  settings.districtName ?? 'Tümü',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                onTap: () => _showDistrictPicker(context, ref, settings),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _companyController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Şirket adı',
                    labelStyle: const TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF00FF41)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (v) => _saveCompanyName(ref, settings, v),
                  onTapOutside: (_) =>
                      _saveCompanyName(ref, settings, _companyController.text),
                ),
              ),
              ListTile(
                leading: settings.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          settings.logoUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.business_rounded, color: Color(0xFF00FF41)),
                        ),
                      )
                    : const Icon(Icons.business_rounded, color: Color(0xFF00FF41)),
                title: const Text('Ofis logosu', style: TextStyle(color: Colors.white)),
                subtitle: const Text(
                  'Galeriden logo seçin (sahibinden/emlakjet bölge ile kullanılır)',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                onTap: _pickAndUploadLogo,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
      loading: () => const ListTile(
        title: Text('İlan kaynakları & ofis', style: TextStyle(color: Colors.white)),
        trailing: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00FF41)),
        ),
      ),
      error: (e, _) => ListTile(
        title: const Text('İlan kaynakları & ofis', style: TextStyle(color: Colors.white)),
        subtitle: Text('Yüklenemedi: $e', style: const TextStyle(color: Colors.red, fontSize: 12)),
      ),
    );
  }

  Future<void> _saveCompanyName(
      WidgetRef ref, ListingDisplaySettingsEntity settings, String name) async {
    await ListingDisplaySettingsRepository.set(settings.copyWith(companyName: name.trim()));
  }

  void _showCityPicker(
      BuildContext context, WidgetRef ref, ListingDisplaySettingsEntity settings) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Şehir seçin',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.5,
              child: ListView.builder(
                itemCount: TurkishCities.cityCodes.length,
                itemBuilder: (_, i) {
                  final code = TurkishCities.cityCodes[i];
                  final name = TurkishCities.cities[code]!;
                  final selected = code == settings.cityCode;
                  return ListTile(
                    title: Text(name, style: const TextStyle(color: Colors.white)),
                    trailing: selected ? const Icon(Icons.check_rounded, color: Color(0xFF00FF41)) : null,
                    onTap: () async {
                      await ListingDisplaySettingsRepository.set(settings.copyWith(
                        cityCode: code,
                        cityName: name,
                        clearDistrict: true,
                      ));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDistrictPicker(
      BuildContext context, WidgetRef ref, ListingDisplaySettingsEntity settings) {
    final districts = TurkishCities.districtsFor(settings.cityCode);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'İlçe seçin (opsiyonel)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            ListTile(
              title: const Text('Tümü', style: TextStyle(color: Colors.white)),
              trailing: settings.districtName == null
                  ? const Icon(Icons.check_rounded, color: Color(0xFF00FF41))
                  : null,
              onTap: () async {
                await ListingDisplaySettingsRepository.set(
                    settings.copyWith(clearDistrict: true));
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ...districts.map((d) {
              final selected = settings.districtName == d;
              return ListTile(
                title: Text(d, style: const TextStyle(color: Colors.white)),
                trailing: selected ? const Icon(Icons.check_rounded, color: Color(0xFF00FF41)) : null,
                onTap: () async {
                  await ListingDisplaySettingsRepository.set(
                      settings.copyWith(districtName: d, districtCode: d));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
