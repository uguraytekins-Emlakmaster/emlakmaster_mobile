import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/resilience/safe_operation.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/utils/whatsapp_launcher.dart';
import 'package:emlakmaster_mobile/core/theme/app_typography.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:emlakmaster_mobile/widgets/premium/premium_ui_kit.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/application/start_crm_outbound_call.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/utils/customer_timeline_filter.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_edit_sheet.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_next_best_action_button.dart';
import 'package:emlakmaster_mobile/shared/models/customer_models.dart';
import 'package:emlakmaster_mobile/features/customer_timeline/domain/entities/timeline_item.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/models/customer_timeline_row.dart';
import 'package:emlakmaster_mobile/core/performance/shell_screen_ready_tracker.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_feed_providers.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_timeline_rows_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_crm_call_strip.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_insight_strip.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_smart_task_strip.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_last_call_signals_section.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_post_call_ai_insight_strip.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_timeline_intelligence_strip.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/customer_revenue_intelligence_strip.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_transcript_hint_strip.dart';
import 'package:emlakmaster_mobile/features/smart_matching_engine/presentation/providers/portfolio_match_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

/// Müşteri detay: üstte bilgi kartı, altta timeline, Not ekle FAB.
class CustomerDetailPage extends ConsumerWidget {
  const CustomerDetailPage({super.key, required this.customerId});
  final String customerId;

  static const List<String> _noteTemplates = [
    'Teklif gönderildi.',
    'Randevu alındı.',
    'Geri arama bırakıldı.',
    'İlan gösterildi.',
    'Müşteri düşündüğünü söyledi.',
    'Fiyat görüşmesi yapıldı.',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: ext.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CustomerDetailReadyProbe(customerId: customerId),
              _CustomerDetailChrome(customerId: customerId),
              Expanded(
                child: TabBarView(
                  children: [
                    _CustomerDetailOverviewTab(customerId: customerId),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(DesignTokens.space4),
                      child: CustomerCrmCallStrip(customerId: customerId),
                    ),
                    _CustomerFlowTab(
                      customerId: customerId,
                      onAddNote: () => _showAddNoteSheet(context, ref, customerId),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddNoteSheet(context, ref, customerId),
          backgroundColor: ext.accent,
          foregroundColor: ext.onBrand,
          tooltip: 'Not ekle',
          icon: const Icon(Icons.note_add_rounded),
          label: Text(
            'Not ekle',
            style: AppTypography.secondaryButton(context).copyWith(
              color: ext.onBrand,
            ),
          ),
        ),
      ),
    );
  }

  static void _showAddNoteSheet(
      BuildContext context, WidgetRef ref, String customerId) {
    final ext = AppThemeExtension.of(context);
    final controller = TextEditingController();
    showPremiumModalBottomSheet<void>(
      context: context,
      builder: (ctx) => PremiumScrollableBottomSheetShell(
        title: 'Not ekle',
        subtitle: 'Şablon seçin veya doğrudan yazın',
        bottomActions: FilledButton.icon(
          onPressed: () async {
            Future<void> attemptSave() async {
              final content = controller.text.trim();
              if (content.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: const Text('Lütfen not içeriği girin.'),
                    backgroundColor: ext.danger,
                  ),
                );
                return;
              }
              final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
              if (uid.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: const Text('Giriş yapılmamış.'),
                    backgroundColor: ext.danger,
                  ),
                );
                return;
              }
              try {
                await runWithResilienceWidget(
                  () => FirestoreService.saveNote(
                    customerId: customerId,
                    content: content,
                    advisorId: uid,
                  ),
                  ref: ref,
                );
                AppFeedback.mediumImpact();
                ref.invalidate(customerTimelineRowsProvider(customerId));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: const Text('Not kaydedildi.'),
                      backgroundColor: ext.accent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (!ctx.mounted) return;
                showPremiumModalBottomSheet<void>(
                  context: ctx,
                  useRootNavigator: true,
                  builder: (panelCtx) => PremiumScrollableBottomSheetShell(
                    title: 'Kayıt tamamlanamadı',
                    subtitle: FirestoreService.userFacingErrorMessage(e),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Kayıtlı notlar',
                          style: AppTypography.cardHeading(context).copyWith(
                            fontSize: DesignTokens.fontSizeSm,
                            color: ext.textSecondary,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space2),
                        SizedBox(
                          height: 140,
                          child: _CustomerNotesPreview(
                            customerId: customerId,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space4),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(panelCtx);
                            attemptSave();
                          },
                          child: const Text('Tekrar dene'),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }

            await attemptSave();
          },
          icon: const Icon(Icons.save_rounded),
          label: const Text('Kaydet'),
          style: FilledButton.styleFrom(
            backgroundColor: ext.accent,
            foregroundColor: ext.onBrand,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              Wrap(
                spacing: DesignTokens.space2,
                runSpacing: DesignTokens.space2,
                children: _noteTemplates.map((t) {
                  return ActionChip(
                    label: Text(
                      t,
                      style: AppTypography.body(context).copyWith(
                        fontSize: DesignTokens.fontSizeSm,
                        color: ext.textPrimary,
                      ),
                    ),
                    backgroundColor: ext.surfaceElevated,
                    side: BorderSide(color: ext.borderSubtle),
                    onPressed: () {
                      controller.text = controller.text.isEmpty
                          ? t
                          : '${controller.text}\n$t';
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: DesignTokens.space4),
              TextField(
                controller: controller,
                maxLines: 4,
                style: TextStyle(color: ext.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Not metni…',
                  hintStyle: TextStyle(color: ext.textPassive),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusControl),
                  ),
                  filled: true,
                  fillColor: ext.background,
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _CustomerDetailOverviewTab extends ConsumerWidget {
  const _CustomerDetailOverviewTab({required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomerRevenueIntelligenceStrip(customerId: customerId),
          CustomerTimelineIntelligenceStrip(customerId: customerId),
          CustomerInsightStrip(customerId: customerId),
          CustomerNextBestActionButton(customerId: customerId),
          Consumer(
            builder: (context, ref, _) {
              final role =
                  ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
              if (!role.isManagerTier) return const SizedBox.shrink();
              return CustomerSmartTaskStrip(customerId: customerId);
            },
          ),
          CustomerLastCallSignalsSection(customerId: customerId),
          CustomerPostCallAiInsightStrip(customerId: customerId),
          CustomerTranscriptHintStrip(customerId: customerId),
          const SizedBox(height: DesignTokens.space5),
          _PortfolioMatchSection(customerId: customerId),
        ],
      ),
    );
  }
}


class _PortfolioMatchSection extends ConsumerWidget {
  const _PortfolioMatchSection({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final entity = ref.watch(customerEntityByIdProvider(customerId)).valueOrNull;
    final phone = entity?.primaryPhone?.trim() ?? '';
    final async = ref.watch(topMatchedListingsForCustomerProvider(customerId));
    return async.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(DesignTokens.space4),
          decoration: BoxDecoration(
            color: ext.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(color: ext.accent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: ext.accent),
                  const SizedBox(width: DesignTokens.space2),
                  Text(
                    'Bu müşteri için uygun ${list.length} ilan bulundu.',
                    style: TextStyle(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: DesignTokens.fontSizeSm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space3),
              ...list.take(3).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.space2),
                    child: Row(
                      children: [
                        Icon(Icons.home_rounded,
                            size: 16, color: ext.textSecondary),
                        const SizedBox(width: DesignTokens.space2),
                        Expanded(
                          child: Text(
                            e.title,
                            style: TextStyle(
                              color: ext.textSecondary,
                              fontSize: DesignTokens.fontSizeXs,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '%${e.score.round()}',
                          style: TextStyle(
                            color: ext.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: DesignTokens.fontSizeXs,
                          ),
                        ),
                      ],
                    ),
                  )),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.space3),
                OutlinedButton.icon(
                  onPressed: () async {
                    final msg =
                        'Merhaba, size uygun ${list.length} ilan seçtik. Detay paylaşayım mı?';
                    final ok =
                        await WhatsAppLauncher.openChat(phone, message: msg);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('WhatsApp açılamadı.'),
                          backgroundColor: ext.danger,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.chat_rounded,
                      size: 18, color: Color(0xFF25D366)),
                  label: const Text('Eşleşen ilanları WhatsApp ile gönder'),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CustomerNotesPreview extends ConsumerWidget {
  const _CustomerNotesPreview({required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final notesAsync = ref.watch(customerNotesDisplayProvider(customerId));
    return notesAsync.when(
      loading: () => Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: ext.accent),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (docs) {
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'Henüz not yok. Kayıt tamamlanınca burada görünür.',
              textAlign: TextAlign.center,
              style: AppTypography.body(context).copyWith(
                color: ext.textTertiary,
                fontSize: DesignTokens.fontSizeSm,
              ),
            ),
          );
        }
        return ListView.separated(
          itemCount: docs.length > 5 ? 5 : docs.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: DesignTokens.space2),
          itemBuilder: (_, i) {
            final c = docs[i].data()['content'] as String? ?? '—';
            return Container(
              padding: const EdgeInsets.all(DesignTokens.space3),
              decoration: BoxDecoration(
                color: ext.background,
                borderRadius:
                    BorderRadius.circular(DesignTokens.radiusControl),
                border: Border.all(color: ext.border.withValues(alpha: 0.45)),
              ),
              child: Text(
                c,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(context).copyWith(
                  color: ext.textSecondary,
                  fontSize: DesignTokens.fontSizeSm,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CustomerDetailReadyProbe extends ConsumerStatefulWidget {
  const _CustomerDetailReadyProbe({required this.customerId});
  final String customerId;

  @override
  ConsumerState<_CustomerDetailReadyProbe> createState() =>
      _CustomerDetailReadyProbeState();
}

class _CustomerDetailReadyProbeState
    extends ConsumerState<_CustomerDetailReadyProbe> {
  final _readyTracker = ShellScreenReadyTracker('customer_detail');

  @override
  Widget build(BuildContext context) {
    ref.listen(customerEntityByIdProvider(widget.customerId), (previous, next) {
      if (next.hasValue && next.value != null) {
        _readyTracker.onContentReady();
      }
    });
    return const SizedBox.shrink();
  }
}

class _CustomerDetailChrome extends ConsumerWidget {
  const _CustomerDetailChrome({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final entityAsync = ref.watch(customerEntityByIdProvider(customerId));
    return entityAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumPageHeader(
            title: 'Müşteri',
            subtitle: 'Yükleniyor…',
            showNavigation: true,
          ),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ),
      error: (_, __) => PremiumPageHeader(
        title: 'Müşteri',
        subtitle: 'Yüklenemedi',
        showNavigation: true,
      ),
      data: (entity) {
        final fullName = entity?.fullName?.trim().isNotEmpty == true
            ? entity!.fullName!.trim()
            : 'Müşteri';
        final phone = entity?.primaryPhone?.trim() ?? '';
        final subtitle = phone.isNotEmpty
            ? phone
            : (entity?.email?.trim().isNotEmpty == true
                ? entity!.email!.trim()
                : null);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumPageHeader(
              title: fullName,
              subtitle: subtitle,
              showNavigation: true,
              trailing: [
                if (entity != null)
                  IconButton(
                    tooltip: 'Düzenle',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => showCustomerEditSheet(
                      context,
                      ref,
                      customerId: customerId,
                      entity: entity,
                    ),
                  ),
                IconButton(
                  tooltip: 'Ara',
                  icon: const Icon(Icons.call_rounded),
                  onPressed: () {
                    if (phone.isNotEmpty) {
                      startCrmOutboundCall(
                        context,
                        phone: phone,
                        customerId: customerId,
                        startedFromScreen: 'customer_detail_header',
                      );
                    } else {
                      context.push(
                        AppRouter.routeCall,
                        extra: {
                          'customerId': customerId,
                          'startedFromScreen': 'customer_detail',
                        },
                      );
                    }
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space4,
              ),
              child: _CustomerQuickActionsRow(
                customerId: customerId,
                phone: phone,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            if (entity != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space4,
                ),
                child: _CustomerSummaryCard(entity: entity),
              ),
            TabBar(
              labelColor: ext.accent,
              unselectedLabelColor: ext.textSecondary,
              indicatorColor: ext.accent,
              tabs: const [
                Tab(text: 'Özet'),
                Tab(text: 'Görüşmeler'),
                Tab(text: 'Akış'),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _CustomerQuickActionsRow extends ConsumerWidget {
  const _CustomerQuickActionsRow({
    required this.customerId,
    required this.phone,
  });

  final String customerId;
  final String phone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space3),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: Icons.call_rounded,
              label: 'Ara',
              onTap: () {
                if (phone.isNotEmpty) {
                  startCrmOutboundCall(
                    context,
                    phone: phone,
                    customerId: customerId,
                    startedFromScreen: 'customer_detail_quick',
                  );
                } else {
                  context.push(
                    AppRouter.routeCall,
                    extra: {
                      'customerId': customerId,
                      'startedFromScreen': 'customer_detail',
                    },
                  );
                }
              },
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.chat_rounded,
              label: 'WhatsApp',
              iconColor: const Color(0xFF25D366),
              onTap: () async {
                if (phone.isEmpty) return;
                final ok = await WhatsAppLauncher.openChat(phone);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('WhatsApp açılamadı.'),
                      backgroundColor: ext.danger,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.task_alt_rounded,
              label: 'Görev',
              onTap: () async {
                final uid =
                    ref.read(currentUserProvider).valueOrNull?.uid ?? '';
                if (uid.isEmpty) return;
                final entity = ref
                    .read(customerEntityByIdProvider(customerId))
                    .valueOrNull;
                await FirestoreService.setTask({
                  'advisorId': uid,
                  'customerId': customerId,
                  'title':
                      'Takip — ${entity?.fullName?.trim().isNotEmpty == true ? entity!.fullName!.trim() : customerId}',
                  'dueAt': Timestamp.fromDate(
                    DateTime.now().add(const Duration(days: 1)),
                  ),
                  'done': false,
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Görev eklendi.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.handshake_rounded,
              label: 'Teklif',
              onTap: () =>
                  _TimelineActions._showAddOfferSheet(context, ref, customerId),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: ext.surface,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: ext.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: iconColor ?? ext.accent),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: ext.textPrimary,
                  fontSize: DesignTokens.fontSizeXs,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerSummaryCard extends StatelessWidget {
  const _CustomerSummaryCard({required this.entity});
  final CustomerEntity entity;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final nextStep = entity.nextSuggestedAction;
    final temp = entity.leadTemperature;
    final updatedAt = entity.updatedAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space3),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.space4),
        decoration: BoxDecoration(
          color: ext.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(color: ext.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (temp != null)
              Text(
                'Sıcaklık göstergesi: ${(temp * 100).toInt()}%',
                style: AppTypography.meta(context),
              ),
            if (nextStep != null && nextStep.isNotEmpty) ...[
              if (temp != null) const SizedBox(height: DesignTokens.space2),
              Text(
                'Sonraki adım: $nextStep',
                style: AppTypography.body(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Son güncelleme: ${updatedAt.day}.${updatedAt.month}.${updatedAt.year}',
              style: AppTypography.meta(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineActions extends ConsumerWidget {
  const _TimelineActions({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _ActionChip(
            icon: Icons.handshake_rounded,
            label: 'Teklif ekle',
            onTap: () => _showAddOfferSheet(context, ref, customerId),
          ),
        ),
        const SizedBox(width: DesignTokens.space3),
        Expanded(
          child: _ActionChip(
            icon: Icons.calendar_today_rounded,
            label: 'Ziyaret ekle',
            onTap: () => _showAddVisitSheet(context, ref, customerId),
          ),
        ),
      ],
    );
  }

  static void _showAddOfferSheet(
      BuildContext context, WidgetRef ref, String customerId) {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    showPremiumModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final ext = AppThemeExtension.of(ctx);
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space5,
              DesignTokens.space2,
              DesignTokens.space5,
              DesignTokens.space6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PremiumBottomSheetHandle(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.handshake_outlined,
                      size: DesignTokens.iconLg,
                      color: ext.accent.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    const Expanded(
                      child: PremiumSheetHeader(
                        compact: true,
                        title: 'Yeni teklif',
                        subtitle: 'Tutar (TRY) ve isteğe bağlı not',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kapat',
                      style: IconButton.styleFrom(
                        foregroundColor: ext.textTertiary,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space4),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Tutar (TRY)',
                    labelStyle: TextStyle(color: ext.textSecondary),
                    filled: true,
                    fillColor: ext.background,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusControl),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusControl),
                      borderSide: BorderSide(color: ext.accent, width: 1.5),
                    ),
                  ),
                  style: TextStyle(color: ext.textPrimary),
                ),
                const SizedBox(height: DesignTokens.space3),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Not (opsiyonel)',
                    labelStyle: TextStyle(color: ext.textSecondary),
                    filled: true,
                    fillColor: ext.background,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusControl),
                    ),
                  ),
                  style: TextStyle(color: ext.textPrimary),
                  maxLines: 2,
                ),
                const SizedBox(height: DesignTokens.space5),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'İptal',
                          style: TextStyle(color: ext.textSecondary),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () async {
                          final amountStr =
                              amountController.text.trim().replaceAll(',', '.');
                          final amount = double.tryParse(amountStr);
                          if (amount == null || amount <= 0) return;
                          Navigator.pop(ctx);
                          await FirestoreService.saveOffer(
                            customerId: customerId,
                            advisorId: uid,
                            amount: amount,
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                          );
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: const Text('Teklif eklendi.'),
                                backgroundColor: ext.accent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: ext.accent,
                          foregroundColor: ext.onBrand,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusControl,
                            ),
                          ),
                        ),
                        child: const Text('Kaydet'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showAddVisitSheet(
      BuildContext context, WidgetRef ref, String customerId) {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    DateTime? pickedDate = DateTime.now().add(const Duration(days: 1));
    final notesController = TextEditingController();
    showPremiumModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: StatefulBuilder(
          builder: (ctx, setModalState) {
            final ext = AppThemeExtension.of(ctx);
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space5,
                DesignTokens.space2,
                DesignTokens.space5,
                DesignTokens.space6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PremiumBottomSheetHandle(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: DesignTokens.iconLg,
                        color: ext.accent.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: DesignTokens.space3),
                      const Expanded(
                        child: PremiumSheetHeader(
                          compact: true,
                          title: 'Yeni ziyaret',
                          subtitle: 'Tarih ve isteğe bağlı not',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Kapat',
                        style: IconButton.styleFrom(
                          foregroundColor: ext.textTertiary,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.space4),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: pickedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setModalState(() => pickedDate = date);
                      }
                    },
                    icon: Icon(
                      Icons.calendar_today_rounded,
                      size: DesignTokens.iconMd,
                      color: ext.accent,
                    ),
                    label: Text(
                      pickedDate != null
                          ? '${pickedDate!.day}.${pickedDate!.month}.${pickedDate!.year}'
                          : 'Tarih seç',
                      style: TextStyle(color: ext.accent),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ext.accent,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusControl,
                        ),
                      ),
                      side: BorderSide(color: ext.accent),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Not (opsiyonel)',
                      labelStyle: TextStyle(color: ext.textSecondary),
                      filled: true,
                      fillColor: ext.background,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusControl),
                      ),
                    ),
                    style: TextStyle(color: ext.textPrimary),
                    maxLines: 2,
                  ),
                  const SizedBox(height: DesignTokens.space5),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'İptal',
                            style: TextStyle(color: ext.textSecondary),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () async {
                            if (pickedDate == null) return;
                            Navigator.pop(ctx);
                            await FirestoreService.saveVisit(
                              customerId: customerId,
                              advisorId: uid,
                              scheduledAt: pickedDate!,
                              notes: notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                            );
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: const Text('Ziyaret eklendi.'),
                                  backgroundColor: ext.accent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: ext.accent,
                            foregroundColor: ext.onBrand,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusControl,
                              ),
                            ),
                          ),
                          child: const Text('Kaydet'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: DesignTokens.space3, horizontal: DesignTokens.space4),
          decoration: BoxDecoration(
            color: ext.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: ext.border),
            boxShadow: [
              BoxShadow(
                  color: ext.shadowColor.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: ext.accent),
              const SizedBox(width: DesignTokens.space2),
              Text(label,
                  style: TextStyle(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: DesignTokens.fontSizeSm)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerFlowTab extends StatelessWidget {
  const _CustomerFlowTab({
    required this.customerId,
    required this.onAddNote,
  });

  final String customerId;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Zaman çizelgesi',
            style: AppTypography.cardHeading(context).copyWith(
              color: ext.textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          _TimelineActions(customerId: customerId),
          const SizedBox(height: DesignTokens.space3),
          _CustomerTimeline(
            customerId: customerId,
            onAddNote: onAddNote,
          ),
        ],
      ),
    );
  }
}

class _CustomerTimeline extends ConsumerStatefulWidget {
  const _CustomerTimeline({
    required this.customerId,
    required this.onAddNote,
  });

  final String customerId;
  final VoidCallback onAddNote;

  static const int _pageSize = 20;

  @override
  ConsumerState<_CustomerTimeline> createState() => _CustomerTimelineState();
}

class _CustomerTimelineState extends ConsumerState<_CustomerTimeline> {
  CustomerTimelineFilter _filter = CustomerTimelineFilter.all;
  int _visibleCount = _CustomerTimeline._pageSize;

  @override
  Widget build(BuildContext context) {
    final timelineAsync =
        ref.watch(customerTimelineRowsProvider(widget.customerId));
    final ext = AppThemeExtension.of(context);
    return timelineAsync.when(
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space6),
          child: CircularProgressIndicator(
              strokeWidth: 2, color: ext.accent),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        final filtered = items
            .where((e) => CustomerTimelineFilterLogic.matches(e, _filter))
            .toList();
        final visible = filtered.take(_visibleCount).toList();
        final hasMore = filtered.length > _visibleCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CustomerTimelineFilter.values.map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: DesignTokens.space2),
                    child: FilterChip(
                      label: Text(f.labelTr),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _filter = f;
                          _visibleCount = _CustomerTimeline._pageSize;
                        });
                      },
                      selectedColor: ext.accent.withValues(alpha: 0.2),
                      checkmarkColor: ext.accent,
                      labelStyle: TextStyle(
                        color: selected ? ext.accent : ext.textSecondary,
                        fontSize: DesignTokens.fontSizeSm,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            if (items.isEmpty)
              _buildEmptyAll(context, ext)
            else ...[
              if (filtered.isEmpty)
                _buildEmptyFilter(context, ext)
              else ...[
                ...visible.map((e) => _TimelineTile(row: e)),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: DesignTokens.space2),
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _visibleCount += _CustomerTimeline._pageSize;
                        });
                      },
                      child: Text(
                        'Daha fazla göster (${filtered.length - _visibleCount} kaldı)',
                      ),
                    ),
                  ),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyAll(BuildContext context, AppThemeExtension ext) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space6),
      decoration: BoxDecoration(
        color: ext.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: ext.border),
      ),
      child: Column(
        children: [
          Icon(Icons.timeline_rounded, size: 40, color: ext.textTertiary),
          const SizedBox(height: DesignTokens.space3),
          Text(
            'Henüz kayıt yok',
            style: TextStyle(
              color: ext.textSecondary,
              fontSize: DesignTokens.fontSizeSm,
            ),
          ),
          Text(
            'Çağrı özeti, not, ziyaret veya teklif eklendikçe burada görünecek.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ext.textTertiary,
              fontSize: DesignTokens.fontSizeXs,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          FilledButton.icon(
            onPressed: widget.onAddNote,
            icon: const Icon(Icons.note_add_rounded, size: 18),
            label: const Text('İlk notu ekle'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilter(BuildContext context, AppThemeExtension ext) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space5),
      decoration: BoxDecoration(
        color: ext.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: ext.border),
      ),
      child: Column(
        children: [
          Text(
            'Bu filtrede kayıt yok',
            style: TextStyle(
              color: ext.textSecondary,
              fontSize: DesignTokens.fontSizeSm,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          TextButton(
            onPressed: () {
              setState(() {
                _filter = CustomerTimelineFilter.all;
                _visibleCount = _CustomerTimeline._pageSize;
              });
            },
            child: const Text('Tümünü göster'),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.row});
  final CustomerTimelineRow row;

  IconData get _icon {
    switch (row.type) {
      case TimelineItemType.callSummary:
        return Icons.call_rounded;
      case TimelineItemType.note:
        return Icons.note_rounded;
      case TimelineItemType.visit:
        return Icons.calendar_today_rounded;
      case TimelineItemType.offer:
        return Icons.handshake_rounded;
      default:
        return Icons.circle_rounded;
    }
  }

  Color _accentColor(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    switch (row.type) {
      case TimelineItemType.offer:
        return ext.accent;
      case TimelineItemType.visit:
        return ext.accent;
      case TimelineItemType.callSummary:
        return ext.info;
      default:
        return ext.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final color = _accentColor(context);
    final dateStr =
        '${row.at.day}.${row.at.month}.${row.at.year} ${row.at.hour.toString().padLeft(2, '0')}:${row.at.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: color.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Icon(_icon, size: 20, color: color),
          ),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.space4),
              decoration: BoxDecoration(
                color: ext.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                border: Border.all(color: color.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        row.title,
                        style: TextStyle(
                          color: ext.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: DesignTokens.fontSizeSm,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateStr,
                        style: TextStyle(color: ext.textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                  if (row.subtitle.isNotEmpty && row.subtitle != '—') ...[
                    const SizedBox(height: 6),
                    Text(
                      row.subtitle,
                      style: TextStyle(
                          color: ext.textSecondary,
                          fontSize: DesignTokens.fontSizeXs),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
