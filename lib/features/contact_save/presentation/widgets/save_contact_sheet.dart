import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/contact_save/data/contact_permission_helper.dart';
import 'package:emlakmaster_mobile/features/contact_save/data/save_contact_service.dart';
import 'package:emlakmaster_mobile/features/contact_save/domain/contact_save_request.dart';
import 'package:emlakmaster_mobile/features/contact_save/domain/extract_contact_from_voice.dart';
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
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppThemeExtension.of(context).background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
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

class _SaveContactSheetContentState extends ConsumerState<_SaveContactSheetContent> {
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
            style: FilledButton.styleFrom(backgroundColor: AppThemeExtension.of(context).accent),
            child: const Text('Ayarlara git', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _onVoiceResult(String? text) async {
    if (text == null || text.isEmpty) return;
    final contact = extractContactFromVoice(text);
    if (contact == null) return;
    setState(() {
      _nameController.text = contact.fullName;
      _phoneController.text = contact.primaryPhone;
      if (contact.email != null) _emailController.text = contact.email!;
      if (contact.note != null) _noteController.text = contact.note!;
    });
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sesli giriş alındı. Gerekirse düzenleyip kaydedin.'),
          backgroundColor: AppThemeExtension.of(context).accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
    final agentId =
        ref.read(currentUserProvider).valueOrNull?.uid ?? '';

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
      setState(() => _error = 'Rehbere kayıt için izin verin veya tekrar deneyin.');
      return;
    }
    if (_saveToApp && !okApp) {
      setState(() => _error = 'Uygulamaya kayıt başarısız. İnternet kontrol edin.');
      return;
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
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rehbere ve uygulamaya kaydet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sesli komut (AI) veya manuel giriş. Normal üyelikte de sesli kayıt kullanılabilir.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Sesli komut',
                  style: TextStyle(
                    color: AppThemeExtension.of(context).textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                PushToTalkButton(
                  size: 44,
                  onResult: _onVoiceResult,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'İsim',
                hintText: 'Ad Soyad',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white12,
              ),
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                hintText: '05xx xxx xx xx',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white12,
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta (isteğe bağlı)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white12,
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Not (isteğe bağlı)',
                hintText: 'Arama notu, bütçe vb.',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white12,
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              value: _saveToDevice,
              onChanged: (v) => setState(() => _saveToDevice = v ?? true),
              title: const Text(
                'Rehbere kaydet (telefon rehberi)',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              activeColor: AppThemeExtension.of(context).accent,
            ),
            CheckboxListTile(
              value: _saveToApp,
              onChanged: (v) => setState(() => _saveToApp = v ?? true),
              title: const Text(
                'Uygulamaya kaydet (EmlakMaster müşteri)',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              activeColor: AppThemeExtension.of(context).accent,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: AppThemeExtension.of(context).danger, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: AppThemeExtension.of(context).accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Kaydet',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
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
