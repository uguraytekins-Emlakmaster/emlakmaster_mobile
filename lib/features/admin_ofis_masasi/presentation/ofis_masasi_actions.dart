import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/providers/ofis_masasi_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_ofis_masasi/presentation/utils/ofis_masasi_types.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/providers/connected_platforms_providers.dart';
import 'package:emlakmaster_mobile/features/office/presentation/providers/office_admin_providers.dart';
import 'package:emlakmaster_mobile/features/office/presentation/utils/office_error_ui.dart';
import 'package:emlakmaster_mobile/features/office/services/office_admin_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class OfisMasasiActions {
  OfisMasasiActions._();

  // ——— Navigasyon (yalnızca geçerli, mevcut rotalar) ———

  static void openCreateInvite(BuildContext context) {
    AppFeedback.selectionClick();
    context.push(AppRouter.routeOfficeInviteCreate);
  }

  static void openUyelikler(BuildContext context) {
    AppFeedback.selectionClick();
    context.push(AppRouter.routeAdminMemberships);
  }

  static void openKadro(BuildContext context) {
    AppFeedback.selectionClick();
    context.push(AppRouter.routeAdminConsultants);
  }

  static void openTeams(BuildContext context) {
    AppFeedback.selectionClick();
    context.push(AppRouter.routeAdminTeams);
  }

  static void openAudit(BuildContext context) {
    AppFeedback.selectionClick();
    context.push(AppRouter.routeAdminAudit);
  }

  static void openConnections(BuildContext context) {
    AppFeedback.selectionClick();
    context.push(AppRouter.routeConnectedAccounts);
  }

  static void copyInviteCode(BuildContext context, String? code) {
    if (code == null || code.isEmpty) return;
    AppFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: code));
    _toast(context, 'Davet kodu kopyalandı: $code');
  }

  // ——— Gerçek mutasyonlar (OfficeAdminService) ———

  static Future<void> deactivateInvite(
    BuildContext context,
    WidgetRef ref, {
    required String officeId,
    required String inviteId,
    required String code,
  }) async {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) return;
    final ok = await _confirm(
      context,
      title: 'Daveti pasifleştir',
      message: '"$code" davet kodu artık kullanılamayacak. Onaylıyor musunuz?',
      confirmLabel: 'Pasifleştir',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await OfficeAdminService.deactivateInvite(
        user: auth,
        officeId: officeId,
        inviteId: inviteId,
      );
      if (!context.mounted) return;
      _refresh(ref, officeId);
      _toast(context, 'Davet pasifleştirildi.');
    } catch (e) {
      if (context.mounted) _toast(context, officeErrorUserMessage(e));
    }
  }

  static Future<void> suspendMember(
    BuildContext context,
    WidgetRef ref, {
    required String officeId,
    required String targetUserId,
    required String displayName,
  }) async {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) return;
    final ok = await _confirm(
      context,
      title: 'Üyeyi askıya al',
      message:
          '$displayName askıya alınacak ve ofis erişimi durdurulacak. Onaylıyor musunuz?',
      confirmLabel: 'Askıya al',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await OfficeAdminService.suspendMember(
        user: auth,
        officeId: officeId,
        targetUserId: targetUserId,
      );
      if (!context.mounted) return;
      _refresh(ref, officeId);
      _toast(context, 'Üye askıya alındı.');
    } catch (e) {
      if (context.mounted) _toast(context, officeErrorUserMessage(e));
    }
  }

  static Future<void> removeMember(
    BuildContext context,
    WidgetRef ref, {
    required String officeId,
    required String targetUserId,
    required String displayName,
  }) async {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) return;
    final ok = await _confirm(
      context,
      title: 'Üyeliği kaldır',
      message:
          '$displayName ofis kadrosundan kaldırılacak. Bu işlem üyeliği "kaldırıldı" olarak işaretler. Onaylıyor musunuz?',
      confirmLabel: 'Kaldır',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await OfficeAdminService.removeMember(
        user: auth,
        officeId: officeId,
        targetUserId: targetUserId,
      );
      if (!context.mounted) return;
      _refresh(ref, officeId);
      _toast(context, 'Üyelik kaldırıldı.');
    } catch (e) {
      if (context.mounted) _toast(context, officeErrorUserMessage(e));
    }
  }

  // ——— Detay sayfası ———

  static void showDetailSheet(BuildContext context, OfisRowViewModel row) {
    AppFeedback.selectionClick();
    final kindLabel = switch (row.kind) {
      OfisRowKind.invite => 'Davet',
      OfisRowKind.member => 'Üyelik',
      OfisRowKind.connection => 'Platform bağlantısı',
    };
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _DetailLine(label: 'Tür', value: kindLabel),
                _DetailLine(label: 'Durum', value: row.statusLabel),
                _DetailLine(label: 'Bilgi', value: row.subtitle),
                if (row.detailLine.isNotEmpty)
                  _DetailLine(label: 'Detay', value: row.detailLine),
                _DetailLine(label: 'Zaman', value: row.timestampLabel),
                if (row.kind == OfisRowKind.connection) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Canlı OAuth/otomatik senkron devrede değil; gösterilen durum '
                    'yalnızca ofis kurulum kaydından türetilir.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        openConnections(context);
                      },
                      icon: const Icon(Icons.hub_outlined, size: 18),
                      label: const Text('Bağlantıları aç'),
                    ),
                  ),
                ] else if (row.hasPartialMetadata) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Bazı alanlar kayıtta eksik; yalnızca Firestore\'daki mevcut '
                    'metadata gösterilir.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ——— Yardımcılar ———

  static void _refresh(WidgetRef ref, String officeId) {
    ref.invalidate(officeInvitesStreamProvider(officeId));
    ref.invalidate(officeMembersStreamProvider(officeId));
    ref.invalidate(platformSetupMapProvider(officeId));
    ref.invalidate(ofisMasasiSnapshotProvider(officeId));
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: destructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(ctx).colorScheme.error,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
