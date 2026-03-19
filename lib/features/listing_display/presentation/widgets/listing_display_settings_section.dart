import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/platform/file_stub.dart'
    if (dart.library.io) 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:emlakmaster_mobile/core/constants/turkish_cities.dart';
import 'package:emlakmaster_mobile/core/widgets/app_toaster.dart';
import 'package:flutter/services.dart';
import 'package:emlakmaster_mobile/core/services/logo_storage_service.dart';
import 'package:emlakmaster_mobile/features/listing_display/data/listing_display_settings_repository.dart';
import 'package:emlakmaster_mobile/features/listing_display/domain/entities/listing_display_settings_entity.dart';
import 'package:emlakmaster_mobile/features/listing_display/presentation/providers/listing_display_settings_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emlakmaster_mobile/core/widgets/shimmer_placeholder.dart';
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
      final String url;
      if (kIsWeb) {
        final bytes = await x.readAsBytes();
        url = await LogoStorageService.instance.uploadLogoBytes(bytes);
      } else {
        final file = io.File(x.path);
        url = await LogoStorageService.instance.uploadLogo(file);
      }
      final settings = ref.read(listingDisplaySettingsProvider).valueOrNull ??
          const ListingDisplaySettingsEntity();
      await ListingDisplaySettingsRepository.set(
          settings.copyWith(logoUrl: url));
      if (mounted) {
        AppToaster.success(context, 'Logo kaydedildi');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('storage') || e.toString().contains('Storage')
            ? 'Firebase Storage açılmamış olabilir. Konsoldan Storage\'ı başlatın.'
            : 'Logo yüklenemedi: $e';
        AppToaster.error(context, msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? DesignTokens.surfaceDarkCard : DesignTokens.surfaceLight;
    final border = isDark ? DesignTokens.borderDark.withOpacity(0.5) : DesignTokens.borderLight;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = onSurface.withOpacity(0.7);
    final onSurfaceDim = onSurface.withOpacity(0.5);
    final async = ref.watch(listingDisplaySettingsProvider);
    return async.when(
      data: (settings) {
        if (_companyController.text != settings.companyName) {
          _companyController.text = settings.companyName;
          _companyController.selection = TextSelection.collapsed(offset: _companyController.text.length);
        }
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'İlan kaynakları & ofis',
                      style: TextStyle(
                        color: onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Şehir seçince sahibinden, emlakjet ve hepsi emlak\'tan ilanlar otomatik çekilir.',
                      child: Icon(Icons.info_outline_rounded, size: 16, color: onSurfaceDim),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.location_city_rounded, color: DesignTokens.primary),
                title: Text('Şehir', style: TextStyle(color: onSurface)),
                subtitle: Text(
                  settings.cityName,
                  style: TextStyle(color: onSurfaceVariant, fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: onSurfaceVariant),
                onTap: () => _showCityPicker(context, ref, settings),
              ),
              ListTile(
                leading: const Icon(Icons.map_rounded, color: DesignTokens.primary),
                title: Text('İlçe', style: TextStyle(color: onSurface)),
                subtitle: Text(
                  settings.districtName ?? 'Tümü',
                  style: TextStyle(color: onSurfaceVariant, fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: onSurfaceVariant),
                onTap: () => _showDistrictPicker(context, ref, settings),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _companyController,
                  style: TextStyle(color: onSurface),
                  decoration: InputDecoration(
                    labelText: 'Şirket adı',
                    labelStyle: TextStyle(color: onSurfaceVariant),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: onSurfaceDim),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: DesignTokens.primary),
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
                        child: CachedNetworkImage(
                          imageUrl: settings.logoUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ShimmerPlaceholder(width: 40, height: 40),
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.business_rounded, color: DesignTokens.primary),
                        ),
                      )
                    : const Icon(Icons.business_rounded, color: DesignTokens.primary),
                title: Text('Ofis logosu', style: TextStyle(color: onSurface)),
                subtitle: Text(
                  'Galeriden logo seçin (sahibinden/emlakjet bölge ile kullanılır)',
                  style: TextStyle(color: onSurfaceVariant, fontSize: 11),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: onSurfaceVariant),
                onTap: _pickAndUploadLogo,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
      loading: () => ListTile(
        title: Text('İlan kaynakları & ofis', style: TextStyle(color: onSurface)),
        trailing: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: DesignTokens.primary),
        ),
      ),
      error: (e, _) => ListTile(
        title: Text('İlan kaynakları & ofis', style: TextStyle(color: onSurface)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? DesignTokens.surfaceDarkCard : DesignTokens.surfaceLight;
    final textColor = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: sheetBg,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Şehir seçin',
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
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
                    title: Text(name, style: TextStyle(color: textColor)),
                    trailing: selected ? const Icon(Icons.check_rounded, color: DesignTokens.primary) : null,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? DesignTokens.surfaceDarkCard : DesignTokens.surfaceLight;
    final textColor = isDark ? DesignTokens.textPrimaryDark : DesignTokens.textPrimaryLight;
    final districts = TurkishCities.districtsFor(settings.cityCode);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: sheetBg,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'İlçe seçin (opsiyonel)',
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            ListTile(
              title: Text('Tümü', style: TextStyle(color: textColor)),
              trailing: settings.districtName == null
                  ? const Icon(Icons.check_rounded, color: DesignTokens.primary)
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
                title: Text(d, style: TextStyle(color: textColor)),
                trailing: selected ? const Icon(Icons.check_rounded, color: DesignTokens.primary) : null,
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
