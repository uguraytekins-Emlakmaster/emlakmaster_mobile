import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:emlakmaster_mobile/widgets/account_session_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ana ekran başlığındaki profil avatarı — dokununca hesap / oturum paneli.
class SessionAvatarButton extends ConsumerWidget {
  const SessionAvatarButton({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final uid = user?.uid ?? '';
    final fallback = user?.displayName ?? user?.email ?? '?';
    final avatarUrl = uid.isEmpty
        ? null
        : ref.watch(userDocStreamProvider(uid).select((a) => a.valueOrNull?.avatarUrl));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showAccountSessionSheet(context, ref),
        customBorder: const CircleBorder(),
        child: Semantics(
          label: 'Hesap ve oturum',
          button: true,
          child: ProfileAvatar(
            size: size,
            imageUrl: avatarUrl,
            fallbackText: fallback,
          ),
        ),
      ),
    );
  }
}
