import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/l10n/app_localizations.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/theme/dashboard_layout_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/local_call_records_provider.dart';
import 'package:emlakmaster_mobile/features/contact_save/presentation/widgets/save_contact_sheet.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/office_customer_name_lookup_provider.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/models/command_center_feed_data.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/models/command_center_feed_filters.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/providers/command_center_calls_display_provider.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/providers/command_center_stream_providers.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_kpi_period.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/utils/call_list_sort.dart';
import 'package:emlakmaster_mobile/features/manager_command_center/presentation/utils/command_center_call_filter.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

typedef CommandCenterSliversBuilder = List<Widget> Function(
  BuildContext context,
  CommandCenterFeedData data,
  double listBottomInset,
);

/// Çağrı akışı + filtre — iç içe StreamBuilder yerine Riverpod.
class CommandCenterCallsFeed extends ConsumerStatefulWidget {
  const CommandCenterCallsFeed({
    super.key,
    required this.filters,
    required this.onFilteredDocsChanged,
    required this.chromeSliversBuilder,
    required this.scopeSliversBuilder,
    required this.onClearFilters,
    required this.fg,
  });

  final CommandCenterFeedFilters filters;
  final void Function(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered,
  ) onFilteredDocsChanged;
  final CommandCenterSliversBuilder chromeSliversBuilder;
  final CommandCenterSliversBuilder scopeSliversBuilder;
  final VoidCallback onClearFilters;
  final Color fg;

  @override
  ConsumerState<CommandCenterCallsFeed> createState() =>
      _CommandCenterCallsFeedState();
}

class _CommandCenterCallsFeedState extends ConsumerState<CommandCenterCallsFeed> {
  final _readyTracker = ShellScreenReadyTracker('command_center');

  @override
  Widget build(BuildContext context) {
    final filters = widget.filters;
    final onFilteredDocsChanged = widget.onFilteredDocsChanged;
    final chromeSliversBuilder = widget.chromeSliversBuilder;
    final scopeSliversBuilder = widget.scopeSliversBuilder;
    final onClearFilters = widget.onClearFilters;
    final fg = widget.fg;

    final callsScope = filters.callsStreamScope;
    final agentNames =
        ref.watch(commandCenterAgentNamesProvider).valueOrNull ??
            const <String, String>{};
    final callsAsync =
        ref.watch(commandCenterCallsDisplayProvider(callsScope));

    ref.listen(commandCenterCallsDisplayProvider(callsScope), (previous, next) {
      if (next.hasValue) {
        _readyTracker.onContentReady(itemCount: next.value!.length);
      }
    });

    return callsAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(
            color: AppThemeExtension.of(context).accent),
      ),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: AppThemeExtension.of(context).textSecondary,
                  size: 48),
              const SizedBox(height: 16),
              Text(
                'Çağrılar yüklenemedi.',
                style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Lütfen tekrar deneyin.',
                style: TextStyle(
                  color: AppThemeExtension.of(context).textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  ref.invalidate(commandCenterCallsStreamProvider(callsScope));
                  ref.invalidate(commandCenterCallsStaleCacheProvider(callsScope));
                },
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Tekrar dene'),
                style: TextButton.styleFrom(
                  foregroundColor: AppThemeExtension.of(context).accent,
                ),
              ),
            ],
          ),
        ),
      ),
      data: (docs) {
        final currentUid = ref.watch(
          currentUserProvider.select((a) => a.valueOrNull?.uid),
        );
        final officeId = currentUid == null || currentUid.isEmpty
            ? ''
            : ref.watch(
                userDocStreamProvider(currentUid).select(
                  (a) => (a.valueOrNull?.officeId ?? '').trim(),
                ),
              );
        final customerFullNameById =
            ref.watch(officeCustomerNameLookupProvider(officeId));
        final locals =
            ref.watch(localCallRecordsStreamProvider).valueOrNull ?? [];

        var filtered = filterCommandCenterCalls(
          docs: docs,
          filters: filters,
          customerFullNameById: customerFullNameById,
        );
        if (filters.kpiPeriod == CallKpiPeriod.thisMonth) {
          filtered =
              CallKpiPeriodLogic.filterDocs(filtered, filters.kpiPeriod).toList();
        }
        CallListSortLogic.sortFirestoreDocs(filtered, filters.sortMode);
        onFilteredDocsChanged(filtered);

        final listBottomInset =
            DashboardLayoutTokens.contentScrollBottomInset(context);
        final feedData = CommandCenterFeedData(
          docs: docs,
          filtered: filtered,
          agentNames: agentNames,
          locals: locals,
          currentUid: currentUid,
          customerFullNameById: customerFullNameById,
        );
        final chrome = chromeSliversBuilder(context, feedData, listBottomInset);

        if (filtered.isEmpty) {
          final hasAnyDocs = docs.isNotEmpty;
          final l10n = AppLocalizations.of(context);
          return RefreshIndicator(
            color: AppThemeExtension.of(context).accent,
            onRefresh: () async {
              ref.invalidate(commandCenterCallsStreamProvider(callsScope));
              ref.invalidate(
                  commandCenterCallsStaleCacheProvider(callsScope));
            },
            child: CustomScrollView(
            slivers: [
              ...chrome,
              SliverFillRemaining(
                // EmptyState kendi SingleChildScrollView'ını taşır; varsayılan
                // hasScrollBody:true LayoutBuilder intrinsic ölçüm çökmesini önler.
                child: hasAnyDocs
                    ? EmptyState(
                        compact: true,
                        anchorAboveCenter: true,
                        anchorAlignmentY: -0.52,
                        grouped: true,
                        icon: Icons.call_rounded,
                        title: 'Uygun çağrı yok',
                        subtitle:
                            'Arama veya filtrelere uygun kayıt bulunamadı.',
                        outlinedActionLabel: 'Filtreleri temizle',
                        onOutlinedAction: onClearFilters,
                        actionLabel: 'Yeni arama başlat',
                        onAction: () => context.push(
                          AppRouter.routeCall,
                          extra: const {
                            'startedFromScreen':
                                'command_center_filter_empty',
                          },
                        ),
                      )
                    : EmptyState(
                        premiumVisual: true,
                        grouped: true,
                        anchorAboveCenter: true,
                        anchorAlignmentY: -0.52,
                        icon: Icons.call_rounded,
                        title: l10n.t('empty_calls_title'),
                        subtitle: l10n.t('empty_calls_sub'),
                        outlinedActionLabel: 'Portföye kaydet',
                        onOutlinedAction: () => showSaveContactSheet(
                          context,
                          source: 'command_center_calls_empty',
                        ),
                        actionLabel: l10n.t('empty_calls_cta'),
                        onAction: () => context.push(
                          AppRouter.routeCall,
                          extra: const {
                            'startedFromScreen': 'command_center',
                          },
                        ),
                      ),
              ),
            ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppThemeExtension.of(context).accent,
          onRefresh: () async {
            ref.invalidate(commandCenterCallsStreamProvider(callsScope));
            ref.invalidate(commandCenterCallsStaleCacheProvider(callsScope));
          },
          child: CustomScrollView(
          cacheExtent: 480,
          slivers: [
            ...chrome,
            ...scopeSliversBuilder(context, feedData, listBottomInset),
          ],
          ),
        );
      },
    );
  }
}
