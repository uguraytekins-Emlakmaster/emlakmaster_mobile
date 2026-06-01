import 'package:emlakmaster_mobile/features/client_portal/presentation/account/widgets/account_surface.dart';
import 'package:emlakmaster_mobile/widgets/premium/v2/premium_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Müşteri Hesabım / Profil — premium, dürüst, hızlı hesap merkezi (Screen 24).
/// Client shell index 4 ('profile'). Yalnızca gerçek hesap sinyalleri: Firebase
/// auth (e-posta/ad/oturum/doğrulama/üyelik) + users/{uid} (ad/tarih). Telefon,
/// profil düzenleme ve tercih geçmişi sunucuda tutulmadığından dürüstçe
/// işaretlenir; uydurma bilgi/doğrulama/analitik gösterilmez. Çıkış akışı,
/// auth/oturum ve gizlilik/destek davranışları korunur.
class ClientPortalProfilePage extends ConsumerWidget {
  const ClientPortalProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PremiumShellBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: AccountSurface(),
        ),
      ),
    );
  }
}
