import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/core/platform/file_stub.dart'
    if (dart.library.io) 'dart:io' as io;
import 'package:emlakmaster_mobile/core/providers/firebase_storage_availability_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:emlakmaster_mobile/core/constants/turkish_cities.dart';
import 'package:emlakmaster_mobile/core/widgets/app_toaster.dart';
import 'package:emlakmaster_mobile/core/firebase/user_facing_firebase_message.dart';
import 'package:emlakmaster_mobile/core/services/firebase_storage_availability.dart';
import 'package:flutter/services.dart';
import 'package:emlakmaster_mobile/core/services/logo_storage_service.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/office/data/office_logo_storage_service.dart';
import 'package:emlakmaster_mobile/features/office/data/office_repository.dart';
import 'package:emlakmaster_mobile/features/office/domain/membership_status.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_entity.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_role.dart';
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
  const ListingDisplaySettingsSection({super.key, this.embeddedInSettingsHub = false});

  /// [true]: dış kart/ başlık yok; üst bölümde [İlanlar & Ofis] ile sarılır.
  final bool embeddedInSettingsHub;

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
    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    if (uid == null) return;
    HapticFeedback.mediumImpact();
    final docOfficeId = ref.read(userDocStreamProvider(uid)).valueOrNull?.officeId;
    final hasOfficeContext = docOfficeId != null && docOfficeId.isNotEmpty;
    final mem = ref.read(primaryMembershipProvider).valueOrNull;
    final canManageBranding = mem != null &&
        mem.status == MembershipStatus.active &&
        (mem.role == OfficeRole.owner || mem.role == OfficeRole.admin || mem.role == OfficeRole.manager);
    final displayRole = ref.read(displayRoleOrNullProvider);
    final canGlobalLogo = displayRole != null && displayRole.isManagerTier;
    final office = ref.read(currentOfficeProvider).valueOrNull;
    if (hasOfficeContext && office == null) {
      if (mounted) {
        AppToaster.warning(context, 'Ofis bilgisi yükleniyor; birkaç saniye sonra tekrar deneyin.');
      }
      return;
    }
    if (hasOfficeContext && !canManageBranding) {
      if (mounted) {
        AppToaster.warning(context, 'Ofis logosunu yalnızca ofis yöneticisi veya ekip lideri değiştirebilir.');
      }
      return;
    }
    if (!hasOfficeContext && !canGlobalLogo) {
      if (mounted) {
        AppToaster.warning(context, 'Bu logo ayarı yalnızca yönetici rolleri içindir.');
      }
      return;
    }
    if (!await FirebaseStorageAvailability.checkUsable()) {
      if (mounted) {
        AppToaster.warning(context, FirebaseStorageAvailability.unavailableMessage);
      }
      return;
    }
    try {
      final x = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (x == null || !mounted) return;
      if (hasOfficeContext) {
        final bytes = await x.readAsBytes();
        final result = await OfficeLogoStorageService.instance.uploadOfficeLogoBytes(
          officeId: docOfficeId,
          bytes: bytes,
          previousStoragePath: office?.logoStoragePath,
        );
        if (result == null) {
          if (mounted) {
            AppToaster.warning(context, FirebaseStorageAvailability.unavailableMessage);
          }
          return;
        }
        await OfficeRepository.patchOfficeLogo(
          officeId: docOfficeId,
          upload: result,
          ownerUserId: uid,
        );
        ref.invalidate(currentOfficeProvider);
        if (mounted) {
          AppToaster.success(context, 'Ofis logosu kaydedildi.');
        }
        return;
      }
      final String? url;
      if (kIsWeb) {
        final bytes = await x.readAsBytes();
        url = await LogoStorageService.instance.uploadLogoBytes(bytes);
      } else {
        final file = io.File(x.path);
        url = await LogoStorageService.instance.uploadLogo(file);
      }
      if (url == null || url.isEmpty) {
        if (mounted) {
          AppToaster.warning(context, FirebaseStorageAvailability.unavailableMessage);
        }
        return;
      }
      final settings = ref.read(listingDisplaySettingsProvider).valueOrNull ??
          const ListingDisplaySettingsEntity();
      await ListingDisplaySettingsRepository.set(settings.copyWith(logoUrl: url));
      ref.invalidate(listingDisplaySettingsProvider);
      if (mounted) {
        AppToaster.success(context, 'Logo kaydedildi.');
      }
    } catch (e) {
      if (mounted) {
        if (FirebaseStorageAvailability.isUnavailableError(e)) {
          AppToaster.warning(context, FirebaseStorageAvailability.unavailableMessage);
        } else {
          AppToaster.error(context, userFacingErrorMessage(e, context: 'listing_display_logo'));
        }
      }
    }
  }

  Future<void> _removeLogo({
    required bool hasOfficeContext,
    required bool canManageBranding,
    required bool canGlobalLogo,
    required Office? office,
    required String uid,
    required ListingDisplaySettingsEntity settings,
  }) async {
    if (hasOfficeContext) {
      if (!canManageBranding || office == null) return;
      if (office.logoUrl == null || office.logoUrl!.isEmpty) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Logoyu kaldır'),
          content: const Text('Ofis logosu kaldırılacak. Emin misiniz?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaldır')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      await OfficeLogoStorageService.instance.deleteStoredObject(office.logoStoragePath);
      await OfficeRepository.clearOfficeLogoFields(office.id);
      ref.invalidate(currentOfficeProvider);
      if (mounted) AppToaster.success(context, 'Ofis logosu kaldırıldı.');
      return;
    }
    if (!canGlobalLogo || settings.logoUrl == null || settings.logoUrl!.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logoyu kaldır'),
        content: const Text('Kayıtlı logo kaldırılacak. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaldır')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ListingDisplaySettingsRepository.set(settings.copyWith(clearLogo: true));
    ref.invalidate(listingDisplaySettingsProvider);
    if (mounted) AppToaster.success(context, 'Logo kaldırıldı.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppThemeExtension.of(context).card : AppThemeExtension.of(context).surface;
    final border = isDark ? AppThemeExtension.of(context).border.withValues(alpha: 0.5) : AppThemeExtension.of(context).border;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = onSurface.withValues(alpha: 0.7);
    final onSurfaceDim = onSurface.withValues(alpha: 0.5);
    final async = ref.watch(listingDisplaySettingsProvider);
    final storageAsync = ref.watch(firebaseStorageAvailableProvider);
    final storageOk = storageAsync.maybeWhen(
      data: (ok) => ok,
      orElse: () => true,
    );
    final storageKnownInactive = storageAsync.maybeWhen(
      data: (ok) => !ok,
      orElse: () => false,
    );
    return async.when(
      data: (settings) {
        if (_companyController.text != settings.companyName) {
          _companyController.text = settings.companyName;
          _companyController.selection = TextSelection.collapsed(offset: _companyController.text.length);
        }
        final ext = AppThemeExtension.of(context);
        final hub = widget.embeddedInSettingsHub;
        final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
        final office = ref.watch(currentOfficeProvider).valueOrNull;
        final docOfficeId =
            uid.isEmpty ? null : ref.watch(userDocStreamProvider(uid)).valueOrNull?.officeId;
        final hasOfficeContext = docOfficeId != null && docOfficeId.isNotEmpty;
        final mem = ref.watch(primaryMembershipProvider).valueOrNull;
        final canManageBranding = mem != null &&
            mem.status == MembershipStatus.active &&
            (mem.role == OfficeRole.owner ||
                mem.role == OfficeRole.admin ||
                mem.role == OfficeRole.manager);
        final displayRole = ref.watch(displayRoleOrNullProvider);
        final canGlobalLogo = displayRole != null && displayRole.isManagerTier;
        final effectiveLogoUrl = (office != null && (office.logoUrl?.isNotEmpty ?? false))
            ? office.logoUrl!
            : settings.logoUrl;
        final canUploadLogo = storageOk &&
            ((hasOfficeContext && office != null && canManageBranding) ||
                (!hasOfficeContext && canGlobalLogo));
        final logoSubtitle = storageKnownInactive
            ? '${FirebaseStorageAvailability.unavailableMessage} (logo yüklemesi kapalı.)'
            : storageAsync.isLoading
                ? 'Depolama kontrol ediliyor…'
            : hasOfficeContext && office == null
                ? 'Ofis bilgisi yükleniyor…'
                : hasOfficeContext && !canManageBranding
                    ? 'Logoyu yalnızca ofis yöneticisi veya ekip lideri değiştirebilir.'
                    : !hasOfficeContext && !canGlobalLogo
                        ? 'Yalnızca yönetici rolleri logo yükleyebilir.'
                        : 'Galeriden logo seçin (sahibinden/emlakjet bölge ile kullanılır)';
        final cityTile = ListTile(
          leading: Icon(Icons.location_city_rounded, color: ext.accent),
          title: Text('Şehir', style: TextStyle(color: onSurface)),
          subtitle: Text(
            settings.cityName,
            style: TextStyle(color: onSurfaceVariant, fontSize: 12),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: onSurfaceVariant),
          onTap: () => _showCityPicker(context, ref, settings),
        );
        final districtTile = ListTile(
          leading: Icon(Icons.map_rounded, color: ext.accent),
          title: Text('İlçe', style: TextStyle(color: onSurface)),
          subtitle: Text(
            settings.districtName ?? 'Tümü',
            style: TextStyle(color: onSurfaceVariant, fontSize: 12),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: onSurfaceVariant),
          onTap: () => _showDistrictPicker(context, ref, settings),
        );
        final companyBlock = hub
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Icon(Icons.apartment_rounded, color: ext.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Şirket adı',
                            style: TextStyle(
                              color: onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _companyController,
                            style: TextStyle(color: onSurface, fontSize: 15, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Ofis veya marka adı',
                              hintStyle: TextStyle(color: onSurfaceDim, fontSize: 14),
                              filled: true,
                              fillColor: ext.surface.withValues(alpha: isDark ? 0.5 : 0.65),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                                borderSide: BorderSide(color: ext.border.withValues(alpha: 0.45)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                                borderSide: BorderSide(color: ext.border.withValues(alpha: 0.45)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                                borderSide: BorderSide(color: ext.accent.withValues(alpha: 0.75), width: 1.2),
                              ),
                            ),
                            onSubmitted: (v) => _saveCompanyName(ref, settings, v),
                            onTapOutside: (_) =>
                                _saveCompanyName(ref, settings, _companyController.text),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
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
                      borderSide: BorderSide(color: ext.accent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (v) => _saveCompanyName(ref, settings, v),
                  onTapOutside: (_) =>
                      _saveCompanyName(ref, settings, _companyController.text),
                ),
              );
        final logoTile = ListTile(
          leading: (effectiveLogoUrl != null && effectiveLogoUrl.isNotEmpty)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: effectiveLogoUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const ShimmerPlaceholder(width: 40, height: 40),
                    errorWidget: (_, __, ___) =>
                        Icon(Icons.business_rounded, color: ext.accent),
                  ),
                )
              : Icon(Icons.business_rounded, color: ext.accent),
          title: Text('Ofis logosu', style: TextStyle(color: onSurface)),
          subtitle: Text(
            logoSubtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: onSurfaceVariant, fontSize: 11),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: onSurfaceVariant),
          enabled: canUploadLogo,
          onTap: canUploadLogo ? _pickAndUploadLogo : null,
          onLongPress: canUploadLogo
              ? () => _removeLogo(
                    hasOfficeContext: hasOfficeContext,
                    canManageBranding: canManageBranding,
                    canGlobalLogo: canGlobalLogo,
                    office: office,
                    uid: uid,
                    settings: settings,
                  )
              : null,
        );

        if (hub) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cityTile,
              Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.45)),
              districtTile,
              Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.45)),
              companyBlock,
              Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.45)),
              logoTile,
            ],
          );
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
              cityTile,
              districtTile,
              companyBlock,
              logoTile,
              const SizedBox(height: 8),
            ],
          ),
        );
      },
      loading: () => ListTile(
        title: Text('İlan kaynakları & ofis', style: TextStyle(color: onSurface)),
        trailing: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppThemeExtension.of(context).accent),
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
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.54),
      builder: (ctx) => _CityPickerSheetContent(
        settings: settings,
        onSelected: (code, name) async {
          await ListingDisplaySettingsRepository.set(settings.copyWith(
            cityCode: code,
            cityName: name,
            clearDistrict: true,
          ));
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showDistrictPicker(
      BuildContext context, WidgetRef ref, ListingDisplaySettingsEntity settings) {
    HapticFeedback.lightImpact();
    final districts = TurkishCities.districtsFor(settings.cityCode);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.54),
      builder: (ctx) => _DistrictPickerSheetContent(
        settings: settings,
        districts: districts,
        onClearDistrict: () async {
          await ListingDisplaySettingsRepository.set(settings.copyWith(clearDistrict: true));
          if (ctx.mounted) Navigator.pop(ctx);
        },
        onSelectDistrict: (d) async {
          await ListingDisplaySettingsRepository.set(
            settings.copyWith(districtName: d, districtCode: d),
          );
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }
}

/// Şehir: sabit yükseklik + başlık + arama + [Expanded] liste — taşma yok.
class _CityPickerSheetContent extends StatefulWidget {
  const _CityPickerSheetContent({
    required this.settings,
    required this.onSelected,
  });

  final ListingDisplaySettingsEntity settings;
  final Future<void> Function(String code, String name) onSelected;

  @override
  State<_CityPickerSheetContent> createState() => _CityPickerSheetContentState();
}

class _CityPickerSheetContentState extends State<_CityPickerSheetContent> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final maxH = mq.size.height * 0.88;
    final codes = TurkishCities.cityCodes;
    final q = _search.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? codes
        : codes.where((c) {
            final n = TurkishCities.cities[c]!.toLowerCase();
            return n.contains(q) || c.contains(q);
          }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: ext.surfaceElevated,
          elevation: 8,
          shadowColor: ext.shadowColor.withValues(alpha: 0.35),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusSheet)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxH,
              maxWidth: mq.size.width,
            ),
            child: SizedBox(
              height: maxH,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 6),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ext.textTertiary.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 40),
                        Expanded(
                          child: Text(
                            'Şehir seçin',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: ext.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: ext.textSecondary),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Kapat',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: ext.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'İl ara…',
                        hintStyle: TextStyle(color: ext.textTertiary, fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: ext.accent, size: 22),
                        filled: true,
                        fillColor: ext.surface.withValues(alpha: 0.55),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                          borderSide: BorderSide(color: ext.border.withValues(alpha: 0.45)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                          borderSide: BorderSide(color: ext.border.withValues(alpha: 0.45)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                          borderSide: BorderSide(color: ext.accent.withValues(alpha: 0.65), width: 1.2),
                        ),
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Sonuç yok',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: ext.textTertiary),
                      ),
                    )
                  else
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(8, 0, 8, mq.padding.bottom + 12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.35)),
                          itemBuilder: (context, i) {
                            final code = filtered[i];
                            final name = TurkishCities.cities[code]!;
                            final selected = code == widget.settings.cityCode;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              title: Text(
                                name,
                                style: TextStyle(
                                  color: ext.textPrimary,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                              trailing: selected
                                  ? Icon(Icons.check_rounded, color: ext.accent, size: 22)
                                  : null,
                              selected: selected,
                              selectedTileColor: ext.accent.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                              ),
                              onTap: () => widget.onSelected(code, name),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DistrictPickerSheetContent extends StatefulWidget {
  const _DistrictPickerSheetContent({
    required this.settings,
    required this.districts,
    required this.onClearDistrict,
    required this.onSelectDistrict,
  });

  final ListingDisplaySettingsEntity settings;
  final List<String> districts;
  final Future<void> Function() onClearDistrict;
  final Future<void> Function(String d) onSelectDistrict;

  @override
  State<_DistrictPickerSheetContent> createState() => _DistrictPickerSheetContentState();
}

class _DistrictPickerSheetContentState extends State<_DistrictPickerSheetContent> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final maxH = mq.size.height * 0.72;
    final q = _search.text.trim().toLowerCase();
    final allRows = <({String label, bool isAll})>[
      (label: 'Tümü', isAll: true),
      ...widget.districts.map((d) => (label: d, isAll: false)),
    ];
    final filtered = q.isEmpty
        ? allRows
        : allRows.where((row) {
            if (row.isAll) return 'tümü'.contains(q) || 'tum'.contains(q);
            return row.label.toLowerCase().contains(q);
          }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: ext.surfaceElevated,
          elevation: 8,
          shadowColor: ext.shadowColor.withValues(alpha: 0.35),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusSheet)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxH,
              maxWidth: mq.size.width,
            ),
            child: SizedBox(
              height: maxH,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 6),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ext.textTertiary.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                    child: Row(
                      children: [
                        const SizedBox(width: 40),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'İlçe seçin',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: ext.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Opsiyonel — ${widget.settings.cityName}',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelSmall?.copyWith(color: ext.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: ext.textSecondary),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Kapat',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: ext.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'İlçe ara…',
                        hintStyle: TextStyle(color: ext.textTertiary, fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: ext.accent, size: 22),
                        filled: true,
                        fillColor: ext.surface.withValues(alpha: 0.55),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                          borderSide: BorderSide(color: ext.border.withValues(alpha: 0.45)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                          borderSide: BorderSide(color: ext.border.withValues(alpha: 0.45)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                          borderSide: BorderSide(color: ext.accent.withValues(alpha: 0.65), width: 1.2),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'Sonuç yok',
                              style: theme.textTheme.bodyMedium?.copyWith(color: ext.textTertiary),
                            ),
                          )
                        : Scrollbar(
                            thumbVisibility: true,
                            child: ListView.separated(
                              padding: EdgeInsets.fromLTRB(8, 0, 8, mq.padding.bottom + 12),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.35)),
                              itemBuilder: (context, i) {
                                final row = filtered[i];
                                if (row.isAll) {
                                  final selected = widget.settings.districtName == null;
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                    leading: Icon(Icons.layers_clear_rounded, color: ext.accent, size: 22),
                                    title: Text(
                                      'Tümü',
                                      style: TextStyle(
                                        color: ext.textPrimary,
                                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'İlçe filtresi yok',
                                      style: theme.textTheme.labelSmall?.copyWith(color: ext.textTertiary),
                                    ),
                                    trailing: selected
                                        ? Icon(Icons.check_rounded, color: ext.accent, size: 22)
                                        : null,
                                    selected: selected,
                                    selectedTileColor: ext.accent.withValues(alpha: 0.08),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                                    ),
                                    onTap: widget.onClearDistrict,
                                  );
                                }
                                final d = row.label;
                                final selected = widget.settings.districtName == d;
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  title: Text(
                                    d,
                                    style: TextStyle(
                                      color: ext.textPrimary,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                  trailing: selected
                                      ? Icon(Icons.check_rounded, color: ext.accent, size: 22)
                                      : null,
                                  selected: selected,
                                  selectedTileColor: ext.accent.withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                                  ),
                                  onTap: () => widget.onSelectDistrict(d),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
