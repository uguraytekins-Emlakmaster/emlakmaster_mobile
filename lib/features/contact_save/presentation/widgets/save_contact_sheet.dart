import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/contact_save/data/contact_permission_helper.dart';
import 'package:emlakmaster_mobile/features/contact_save/data/save_contact_service.dart';
import 'package:emlakmaster_mobile/features/contact_save/domain/contact_save_request.dart';
import 'package:emlakmaster_mobile/features/contact_save/domain/extract_contact_from_voice.dart'
    show logVoiceContactParseDebug, parseVoiceContact;
import 'package:emlakmaster_mobile/features/monetization/presentation/providers/usage_providers.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/widgets/upgrade_bottom_sheet.dart';
import 'package:emlakmaster_mobile/features/monetization/presentation/widgets/usage_limit_banner.dart';
import 'package:emlakmaster_mobile/features/monetization/services/usage_service.dart';
import 'package:emlakmaster_mobile/features/voice_crm/presentation/widgets/push_to_talk_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rehbere ve uygulamaya kaydet: sesli komut (AI yardımı) + manuel giriş.
/// Pro: tam AI asistan; Normal: sesli komut ile rehber + uygulama kaydı.
void showSaveContactSheet(
  BuildContext context, {
  String? initialName,
  String? initialPhone,
  String? initialEmail,
  String? initialNote,
  String source = 'uygulama',
}) {
  showPremiumModalBottomSheet<void>(
    context: context,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(ctx).bottom,
      ),
      child: _SaveContactSheetContent(
        initialName: initialName,
        initialPhone: initialPhone,
        initialEmail: initialEmail,
        initialNote: initialNote,
        source: source,
      ),
    ),
  );
}

class _SaveContactSheetContent extends ConsumerStatefulWidget {
  const _SaveContactSheetContent({
    this.initialName,
    this.initialPhone,
    this.initialEmail,
    this.initialNote,
    this.source = 'uygulama',
  });

  final String? initialName;
  final String? initialPhone;
  final String? initialEmail;
  final String? initialNote;
  final String source;

  @override
  ConsumerState<_SaveContactSheetContent> createState() =>
      _SaveContactSheetContentState();
}

class _SaveContactSheetContentState
    extends ConsumerState<_SaveContactSheetContent> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();

  bool _saveToDevice = true;
  bool _saveToApp = true;
  bool _saving = false;
  String? _error;
  String _voiceStatus = '';
  bool _highlightName = false;
  bool _highlightPhone = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _phoneController.text = widget.initialPhone ?? '';
    _emailController.text = widget.initialEmail ?? '';
    _noteController.text = widget.initialNote ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  ContactSaveRequest get _request => ContactSaveRequest(
        fullName: _nameController.text.trim(),
        primaryPhone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

  void _showContactPermissionSettingsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppThemeExtension.of(context).background,
        title: const Text(
          'Rehber izni kapalı',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Rehbere kaydetmek için izin gerekiyor. Ayarlardan rehber erişimini açabilirsiniz.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ContactPermissionHelper.instance.openSystemSettings();
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppThemeExtension.of(context).accent),
            child: const Text('Ayarlara git',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _onSpeechResult(PushToTalkSpeechResult r) {
    final text = r.text;
    if (text == null || text.isEmpty) {
      // İlk boş sonuçta PushToTalk sessizce bir kez yeniden dinler; burada yalnızca ikinci kez boşsa mesaj.
      if (r.noSpeechAfterRetries && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sizi duyamadım, tekrar deneyebilirsiniz. İsterseniz alanları elle de doldurabilirsiniz.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final parsed = parseVoiceContact(text);
    logVoiceContactParseDebug(
      rawText: text,
      extraction: parsed,
      shouldReviewStt: r.shouldReview,
    );
    if (parsed == null) {
      setState(() {
        _noteController.text = text;
        _highlightName = false;
        _highlightPhone = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'İsim/telefon çıkarılamadı; metin not alanına yazıldı. Düzenleyebilirsiniz.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final contact = parsed.request;
    final combinedReview = r.shouldReview ||
        parsed.parseNeedsReview ||
        parsed.nameMissing ||
        parsed.phoneMissing;
    setState(() {
      _nameController.text = contact.fullName;
      _phoneController.text = contact.primaryPhone;
      if (contact.email != null) _emailController.text = contact.email!;
      if (contact.note != null) _noteController.text = contact.note!;
      _highlightName = parsed.nameMissing;
      _highlightPhone = parsed.phoneMissing;
    });
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    final ext = AppThemeExtension.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          combinedReview
              ? 'Sesli giriş alındı. Eksik veya belirsiz alanları kontrol edin (sarı çerçeve).'
              : 'Sesli giriş alındı. Gerekirse düzenleyip kaydedin.',
        ),
        backgroundColor: ext.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onSave() async {
    if (!_request.isValid) {
      setState(() => _error = 'İsim ve telefon zorunludur.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final agentId = ref.read(currentUserProvider).valueOrNull?.uid ?? '';

    SaveToDeviceResult deviceResult = SaveToDeviceResult.success;
    bool okApp = false;
    var customerTrackingLimited = false;
    if (_saveToDevice) {
      deviceResult = await SaveContactService.instance.saveToDevice(_request);
    }
    final okDevice = deviceResult == SaveToDeviceResult.success;
    if (_saveToApp && agentId.isNotEmpty) {
      final usageService = ref.read(usageServiceProvider);
      await usageService.warmUp();
      if (!usageService.canTrackCustomer()) {
        customerTrackingLimited = true;
        if (mounted) {
          await showUpgradeBottomSheet(
            context,
            feature: 'customer_limit',
          );
        }
      } else {
        await usageService.incrementCustomerUsage();
        final id = await SaveContactService.instance.saveToApp(
          _request,
          assignedAgentId: agentId,
          source: widget.source,
        );
        okApp = id != null;
      }
    } else if (_saveToApp && agentId.isEmpty) {
      okApp = false;
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (_saveToDevice && !okDevice) {
      if (deviceResult == SaveToDeviceResult.permanentlyDenied) {
        _showContactPermissionSettingsDialog(context);
        return;
      }
      setState(
          () => _error = 'Rehbere kayıt için izin verin veya tekrar deneyin.');
      return;
    }
    if (_saveToApp && !okApp) {
      if (customerTrackingLimited && okDevice) {
        Navigator.of(context).pop();
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Rehbere kaydedildi. Uygulamada daha fazla müşteri için PRO gerekir.'),
            backgroundColor: AppThemeExtension.of(context).accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (customerTrackingLimited) {
        return;
      }
      setState(
          () => _error = 'Uygulamaya kayıt başarısız. İnternet kontrol edin.');
      return;
    }
    if (okApp) {
      ref.invalidate(customerListForAgentProvider);
    }
    Navigator.of(context).pop();
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          (okDevice && okApp)
              ? 'Rehbere ve uygulamaya kaydedildi.'
              : okDevice
                  ? 'Rehbere kaydedildi.'
                  : 'Uygulamaya kaydedildi.',
        ),
        backgroundColor: AppThemeExtension.of(context).accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final showCustomerLimitBanner = ref.watch(
      usageTrackerProvider.select(
        (u) => u.isFree && u.isNearCustomerLimit,
      ),
    );
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.96,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.space6,
          0,
          DesignTokens.space6,
          DesignTokens.space6,
        ),
        child: ListView(
          controller: scrollController,
          children: [
            const PremiumBottomSheetHandle(),
            const SizedBox(height: DesignTokens.space4),
            const PremiumSheetHeader(
              title: 'Rehbere ve uygulamaya kaydet',
              subtitle:
                  'Sesli komut veya manuel giriş. Kayıtlar CRM ile eşlenir; rehber izni ayrıca sorulur.',
            ),
            if (showCustomerLimitBanner) ...[
              const SizedBox(height: DesignTokens.space3),
              const UsageLimitBanner(
                subtitle:
                    '30 müşteri sınırına yaklaşıyorsunuz. CRM takibini kesintisiz sürdürmek için PRO açabilirsiniz.',
              ),
            ],
            const SizedBox(height: DesignTokens.space5),
            DecoratedBox(
              decoration: BoxDecoration(
                color: ext.surfaceElevated,
                borderRadius: BorderRadius.circular(DesignTokens.radiusControl),
                border: Border.all(color: ext.border.withValues(alpha: 0.55)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sesli giriş',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Basılı tutun, ad ve telefon söyleyin',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: ext.textSecondary,
                                      height: 1.3,
                                    ),
                          ),
                        ),
                        PushToTalkButton(
                          size: 48,
                          onSpeechResult: _onSpeechResult,
                          onPhaseChanged: (phase) {
                            if (mounted) setState(() => _voiceStatus = phase);
                          },
                        ),
                      ],
                    ),
                    if (_voiceStatus.isNotEmpty) ...[
                      const SizedBox(height: DesignTokens.space2),
                      Text(
                        _voiceStatus,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: ext.textTertiary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.space5),
            TextField(
              controller: _nameController,
              onChanged: (_) {
                if (_highlightName) setState(() => _highlightName = false);
              },
              decoration: InputDecoration(
                labelText: 'İsim',
                hintText: 'Ad Soyad',
                labelStyle: TextStyle(color: ext.textSecondary),
                helperText: _highlightName
                    ? 'Sesli girişte eksik veya belirsiz — lütfen doğrulayın'
                    : null,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusControl),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusControl),
                  borderSide: BorderSide(
                    color: _highlightName ? ext.warning : ext.border,
                    width: _highlightName ? 1.5 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusControl),
                  borderSide: BorderSide(
                    color: _highlightName ? ext.warning : ext.accent,
                    width: _highlightName ? 1.5 : 2,
                  ),
                ),
                filled: true,
                fillColor: ext.surfaceElevated,
              ),
              style: TextStyle(color: ext.textPrimary),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: DesignTokens.space3),
            TextField(
              controller: _phoneController,
              onChanged: (_) {
                if (_highlightPhone) setState(() => _highlightPhone = false);
              },
              decoration: InputDecoration(
                labelText: 'Telefon',
                hintText: '05xx xxx xx xx',
                labelStyle: TextStyle(color: ext.textSecondary),
                helperText: _highlightPhone
                    ? 'Numara algılanamadı veya belirsiz — lütfen doğrulayın'
                    : null,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusControl),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusControl),
                  borderSide: BorderSide(
                    color: _highlightPhone ? ext.warning : ext.border,
                    width: _highlightPhone ? 1.5 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusControl),
                  borderSide: BorderSide(
                    color: _highlightPhone ? ext.warning : ext.accent,
                    width: _highlightPhone ? 1.5 : 2,
                  ),
                ),
                filled: true,
                fillColor: ext.surfaceElevated,
              ),
              style: TextStyle(color: ext.textPrimary),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: DesignTokens.space3),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'E-posta (isteğe bağlı)',
                labelStyle: TextStyle(color: ext.textSecondary),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusControl),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusControl),
                  borderSide: BorderSide(color: ext.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusControl),
                  borderSide: BorderSide(color: ext.accent, width: 1.5),
                ),
                filled: true,
                fillColor: ext.surfaceElevated,
              ),
              style: TextStyle(color: ext.textPrimary),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: DesignTokens.space3),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Not (isteğe bağlı)',
                hintText: 'Arama notu, bütçe vb.',
                labelStyle: TextStyle(color: ext.textSecondary),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusControl),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusControl),
                  borderSide: BorderSide(color: ext.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusControl),
                  borderSide: BorderSide(color: ext.accent, width: 1.5),
                ),
                filled: true,
                fillColor: ext.surfaceElevated,
              ),
              style: TextStyle(color: ext.textPrimary),
              maxLines: 2,
            ),
            const SizedBox(height: DesignTokens.space5),
            CheckboxListTile(
              value: _saveToDevice,
              onChanged: (v) => setState(() => _saveToDevice = v ?? true),
              title: Text(
                'Rehbere kaydet (telefon rehberi)',
                style: TextStyle(color: ext.textPrimary, fontSize: 14),
              ),
              activeColor: ext.accent,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              value: _saveToApp,
              onChanged: (v) => setState(() => _saveToApp = v ?? true),
              title: Text(
                'Uygulamaya kaydet (CRM müşteri)',
                style: TextStyle(color: ext.textPrimary, fontSize: 14),
              ),
              activeColor: ext.accent,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                    color: AppThemeExtension.of(context).danger, fontSize: 13),
              ),
            ],
            const SizedBox(height: DesignTokens.space5),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: ext.accent,
                  foregroundColor: ext.onBrand,
                  padding:
                      const EdgeInsets.symmetric(vertical: DesignTokens.space4),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusControl),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ext.onBrand,
                        ),
                      )
                    : Text(
                        'Kaydet',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: ext.onBrand,
                            ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
