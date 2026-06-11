import 'package:emlakmaster_mobile/core/navigation/sheet_back_behavior.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/contact_save/data/contact_permission_helper.dart';
import 'package:emlakmaster_mobile/features/contact_save/data/save_contact_service.dart';
import 'package:emlakmaster_mobile/features/contact_save/domain/contact_save_request.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rehbere ve uygulamaya kaydet: manuel giriş; rehber + uygulama (CRM) kaydı.
void showSaveContactSheet(
  BuildContext context, {
  String? initialName,
  String? initialPhone,
  String? initialEmail,
  String? initialNote,
  String source = 'uygulama',
}) {
  showPremiumScrollableBottomSheet<void>(
    context: context,
    builder: (ctx) => _SaveContactSheetContent(
      initialName: initialName,
      initialPhone: initialPhone,
      initialEmail: initialEmail,
      initialNote: initialNote,
      source: source,
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

  bool get _isDirty {
    String norm(String? v) => (v ?? '').trim();
    return norm(_nameController.text) != norm(widget.initialName) ||
        norm(_phoneController.text) != norm(widget.initialPhone) ||
        norm(_emailController.text) != norm(widget.initialEmail) ||
        norm(_noteController.text) != norm(widget.initialNote);
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
      builder: (ctx) {
        final ext = AppThemeExtension.of(ctx);
        return AlertDialog(
          backgroundColor: ext.surface,
          title: Text(
            'Rehber izni kapalı',
            style: TextStyle(color: ext.textPrimary),
          ),
          content: Text(
            'Rehbere kaydetmek için izin gerekiyor. Ayarlardan rehber erişimini açabilirsiniz.',
            style: TextStyle(color: ext.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('İptal', style: TextStyle(color: ext.textSecondary)),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ContactPermissionHelper.instance.openSystemSettings();
              },
              style: FilledButton.styleFrom(
                backgroundColor: ext.accent,
                foregroundColor: ext.onBrand,
              ),
              child: const Text('Ayarlara git'),
            ),
          ],
        );
      },
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
    if (_saveToDevice) {
      deviceResult = await SaveContactService.instance.saveToDevice(_request);
    }
    final okDevice = deviceResult == SaveToDeviceResult.success;
    if (_saveToApp && agentId.isNotEmpty) {
      final id = await SaveContactService.instance.saveToApp(
        _request,
        assignedAgentId: agentId,
        source: widget.source,
      );
      okApp = id != null;
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
      setState(
          () => _error = 'Uygulamaya kayıt başarısız. İnternet kontrol edin.');
      return;
    }
    if (okApp) {
      ref.invalidate(customerListForAgentProvider);
    }
    Navigator.of(context).pop();
    AppFeedback.mediumImpact();
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
    return sheetBackWrapper(
      isDirty: _isDirty && !_saving,
      child: PremiumScrollableBottomSheetShell(
      title: 'Rehbere ve uygulamaya kaydet',
      subtitle:
          'Bilgileri girin. CRM eşlemesi korunur; rehber izni ayrı sorulur.',
      bottomActions: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _saving ? null : _onSave,
          style: FilledButton.styleFrom(
            backgroundColor: ext.accent,
            foregroundColor: ext.onBrand,
            minimumSize: const Size(double.infinity, 48),
            padding:
                const EdgeInsets.symmetric(vertical: DesignTokens.space3),
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
                  style: AppTypography.bodyStrong(context).copyWith(
                    color: ext.onBrand,
                    fontSize: DesignTokens.fontSizeMd,
                  ),
                ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'İsim',
                hintText: 'Ad Soyad',
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
                  borderSide: BorderSide(color: ext.accent, width: 2),
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
              decoration: InputDecoration(
                labelText: 'Telefon',
                hintText: '05xx xxx xx xx',
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
                  borderSide: BorderSide(color: ext.accent, width: 2),
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
                style: AppTypography.bodyStrong(context)
                    .copyWith(fontSize: DesignTokens.fontSizeBase),
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
                style: AppTypography.bodyStrong(context)
                    .copyWith(fontSize: DesignTokens.fontSizeBase),
              ),
              activeColor: ext.accent,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_error != null) ...[
              const SizedBox(height: DesignTokens.space2),
              Text(
                _error!,
                style: AppTypography.body(context).copyWith(
                  color: ext.danger,
                  fontSize: DesignTokens.fontSizeSm,
                ),
              ),
            ],
          ],
        ),
    ),
    );
  }
}
