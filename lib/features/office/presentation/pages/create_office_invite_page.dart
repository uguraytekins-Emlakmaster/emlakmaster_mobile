import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/services/auth_service.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_exception.dart';
import 'package:emlakmaster_mobile/features/office/domain/office_role.dart';
import 'package:emlakmaster_mobile/features/office/presentation/utils/office_error_ui.dart';
import 'package:emlakmaster_mobile/features/office/services/office_setup_service.dart';
import 'package:emlakmaster_mobile/shared/widgets/emlak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
/// Owner / admin / manager: yeni davet kodu üretir (UI).
class CreateOfficeInvitePage extends ConsumerStatefulWidget {
  const CreateOfficeInvitePage({super.key});

  @override
  ConsumerState<CreateOfficeInvitePage> createState() =>
      _CreateOfficeInvitePageState();
}

class _CreateOfficeInvitePageState extends ConsumerState<CreateOfficeInvitePage> {
  OfficeRole _role = OfficeRole.consultant;
  final _maxUsesController = TextEditingController(text: '5');
  bool _busy = false;
  String? _error;
  String? _createdCode;

  @override
  void dispose() {
    _maxUsesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _error = null;
      _createdCode = null;
    });
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    final doc = ref.read(userDocStreamProvider(user.uid)).valueOrNull;
    final oid = doc?.officeId;
    if (oid == null || oid.isEmpty) {
      setState(() =>
          _error = AppLocalizations.of(context).t('office_invite_need_office'));
      return;
    }
    final maxUses = int.tryParse(_maxUsesController.text.trim()) ?? 5;
    if (maxUses < 1) {
      setState(() =>
          _error = AppLocalizations.of(context).t('office_invite_min_uses'));
      return;
    }
    AppFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final result = await OfficeSetupService.createInviteForOffice(
        user: user,
        officeId: oid,
        roleToAssign: _role,
        maxUses: maxUses,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _createdCode = result.code;
      });
    } on OfficeException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.userMessage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = officeErrorUserMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ext.background,
      appBar: emlakAppBar(
        context,
        backgroundColor: ext.background,
        foregroundColor: ext.foreground,
        title: Text(l10n.t('office_invite_create_title')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              l10n.t('office_invite_desc'),
              style: TextStyle(color: ext.foregroundSecondary, height: 1.45, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Text(l10n.t('office_invite_role_label'), style: TextStyle(color: ext.foregroundSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<OfficeRole>(
              // ignore: deprecated_member_use
              value: _role,
              dropdownColor: ext.surfaceElevated,
              style: TextStyle(color: ext.foreground),
              decoration: InputDecoration(
                filled: true,
                fillColor: ext.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
              ),
              items: [
                DropdownMenuItem(value: OfficeRole.consultant, child: Text(l10n.t('office_role_consultant'))),
                DropdownMenuItem(value: OfficeRole.manager, child: Text(l10n.t('office_role_manager'))),
                DropdownMenuItem(value: OfficeRole.admin, child: Text(l10n.t('office_role_admin'))),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _role = v);
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _maxUsesController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: ext.foreground),
              decoration: InputDecoration(
                labelText: l10n.t('office_invite_max_uses'),
                labelStyle: TextStyle(color: ext.foregroundSecondary),
                filled: true,
                fillColor: ext.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(
                  color: ext.danger.withValues(alpha: 0.95),
                  fontSize: 13,
                ),
              ),
            ],
            if (_createdCode != null) ...[
              const SizedBox(height: 16),
              SelectableText(
                l10n.tArgs('office_invite_code_result', [_createdCode!]),
                style: TextStyle(
                  color: ext.success.withValues(alpha: 0.95),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: ext.accent,
                foregroundColor: ext.onBrand,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _busy
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ext.onBrand,
                      ),
                    )
                  : Text(l10n.t('office_invite_generate')),
            ),
          ],
        ),
      ),
    );
  }
}
