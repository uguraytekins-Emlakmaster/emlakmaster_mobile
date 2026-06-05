import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/features/admin_baglantilar/presentation/providers/baglantilar_snapshot_provider.dart';
import 'package:emlakmaster_mobile/features/admin_consultants/presentation/providers/admin_consultants_providers.dart';
import 'package:emlakmaster_mobile/features/admin_raporlar/presentation/utils/raporlar_types.dart';
import 'package:emlakmaster_mobile/features/external_integrations/presentation/providers/connected_platforms_providers.dart';
import 'package:emlakmaster_mobile/features/office/presentation/providers/office_admin_providers.dart';
import 'package:emlakmaster_mobile/screens/admin_shell_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class RaporlarActions {
  RaporlarActions._();

  /// Yüzeyi aç — rota veya kabuk sekmesi (dead button yok).
  static void open(BuildContext context, RaporEntryViewModel entry) {
    AppFeedback.selectionClick();
    switch (entry.actionKind) {
      case RaporActionKind.route:
        final route = entry.route;
        if (route != null) context.push(route);
      case RaporActionKind.commandCenterTab:
        AdminShellNav.goToCommandCenterTab(context);
      case RaporActionKind.warRoomTab:
        AdminShellNav.goToWarRoomTab(context);
    }
  }

  /// Canlı snapshot kaynaklarını tazele (grounded sayımlar yenilensin).
  static void refresh(WidgetRef ref) {
    final officeId = ref.read(baglantilarOfficeIdProvider);
    ref.invalidate(adminConsultantsTeamsProvider);
    ref.invalidate(officeInvitesStreamProvider(officeId));
    ref.invalidate(officeMembersStreamProvider(officeId));
    ref.invalidate(platformSetupMapProvider(officeId));
  }

  static void showDetailSheet(BuildContext context, RaporEntryViewModel entry) {
    AppFeedback.selectionClick();
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
                  entry.title,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _DetailLine(label: 'Kapsam', value: entry.scope),
                _DetailLine(label: 'Açıklama', value: entry.description),
                _DetailLine(label: 'Durum', value: entry.readinessLabel),
                if (entry.attentionLabel != null)
                  _DetailLine(label: 'Dikkat', value: entry.attentionLabel!),
                const SizedBox(height: 12),
                Text(
                  'Sayımlar yalnızca canlı snapshot verisinden türetilir; '
                  'uydurma rapor toplamı veya trend gösterilmez.',
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
                      open(context, entry);
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Yüzeyi aç'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
