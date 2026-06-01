import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_actions.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_filter.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/account_types.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/providers/account_provider.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/widgets/account_chrome.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/widgets/account_row.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/account/widgets/account_skeleton.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_chrome.dart';
import 'package:emlakmaster_mobile/features/client_portal/presentation/widgets/client_portal_secondary_widgets.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/session_avatar_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hesabım komuta yüzeyi (Screen 24) — premium, dürüst, hızlı hesap merkezi.
/// Yalnızca gerçek hesap sinyalleri; eksik alanlar dürüstçe işaretlenir.
class AccountSurface extends ConsumerStatefulWidget {
  const AccountSurface({super.key});

  @override
  ConsumerState<AccountSurface> createState() => _AccountSurfaceState();
}

class _AccountSurfaceState extends ConsumerState<AccountSurface> {
  AccountFilter _filter = AccountFilter.all;

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(accountSnapshotProvider);
    final reserve = clientPortalDockBottomReserve(context);

    return snapshotAsync.when(
      loading: () => const CustomScrollView(
        slivers: [SliverToBoxAdapter(child: AccountSkeleton())],
      ),
      error: (_, __) => CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: PremiumClientPortalHeader(
              title: 'Hesabım',
              subtitle: 'Hesap durumu ve kayıtlı bilgiler',
              verificationNote: null,
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: EmptyState(
                compact: true,
                grouped: true,
                premiumVisual: true,
                icon: Icons.cloud_off_rounded,
                title: 'Hesap yüklenemedi',
                subtitle: 'Bağlantınızı kontrol edip tekrar deneyin.',
                actionLabel: 'Yeniden dene',
                onAction: () => AccountActions.refresh(ref),
              ),
            ),
          ),
        ],
      ),
      data: (snapshot) => _buildData(context, snapshot, reserve),
    );
  }

  Widget _buildData(
    BuildContext context,
    AccountSnapshot snapshot,
    double reserve,
  ) {
    final filtered = filterAccountEntries(snapshot.entries, filter: _filter);
    final showPartialLane = _filter == AccountFilter.all && snapshot.signedIn;

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: PremiumClientPortalHeader(
          title: 'Hesabım',
          subtitle: snapshot.greetingName.isNotEmpty
              ? '${snapshot.greetingName} · hesap durumu ve kayıtlı bilgiler'
              : 'Hesap durumu ve kayıtlı bilgiler',
          verificationNote: snapshot.coverageNote,
          actions: snapshot.signedIn
              ? const [
                  Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: SessionAvatarButton(size: 38),
                  ),
                ]
              : const [],
        ),
      ),
      SliverToBoxAdapter(child: AccountIdentityCard(snapshot: snapshot)),
      SliverToBoxAdapter(child: AccountSummaryStrip(summary: snapshot.summary)),
      SliverToBoxAdapter(
        child: AccountFilterStrip(
          selected: _filter,
          onSelected: (f) {
            AppFeedback.selectionClick();
            setState(() => _filter = f);
          },
        ),
      ),
    ];

    if (filtered.isEmpty) {
      slivers.add(
        const SliverToBoxAdapter(
          child: AccountInlineNote(
            icon: Icons.filter_alt_off_rounded,
            message: 'Bu kategoride gösterilecek kayıt yok.',
          ),
        ),
      );
    } else {
      // Bölüm ritmi — her bölüm yalnızca filtrede kaydı varsa başlık + satır.
      for (final section in AccountSection.values) {
        final rows =
            filtered.where((e) => e.section == section).toList(growable: false);
        if (rows.isEmpty) continue;
        slivers.add(
          SliverToBoxAdapter(
            child: PremiumClientSectionLabel(
              label: section.label,
              secondary: '${rows.length}',
            ),
          ),
        );
        slivers.add(
          SliverList.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) => AccountRow(
              entry: rows[index],
              onTap: () => AccountActions.handle(context, ref, rows[index]),
            ),
          ),
        );
      }
    }

    // ——— Kayıtlı tercih geçmişi — dürüst kapsam (sunucuda izlenmiyor) ———
    if (showPartialLane) {
      slivers.add(
        const SliverToBoxAdapter(
          child: PremiumClientSectionLabel(
            label: 'Kayıtlı tercihler',
            secondary: 'Henüz sunucuda tutulmuyor',
          ),
        ),
      );
      slivers.add(
        const SliverToBoxAdapter(
          child: AccountInlineNote(
            icon: Icons.history_toggle_off_rounded,
            message:
                'Profil düzenleme, kayıtlı tercih geçmişi ve gelişmiş hesap '
                'ayarları henüz sunucuda tutulmuyor. Altyapı aktifleştiğinde '
                'gerçek bilgileriniz burada görünecek; uydurma bilgi gösterilmez.',
          ),
        ),
      );
    }

    slivers.add(SliverPadding(padding: EdgeInsets.only(bottom: reserve)));

    return CustomScrollView(cacheExtent: 360, slivers: slivers);
  }
}
