import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_entity_provider.dart';
import 'package:emlakmaster_mobile/features/lead_temperature_engine/presentation/providers/lead_temperature_provider.dart';
import 'package:emlakmaster_mobile/shared/models/lead_temperature.dart';
import 'package:emlakmaster_mobile/shared/models/pipeline_models.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:emlakmaster_mobile/shared/widgets/empty_state.dart';
import 'package:emlakmaster_mobile/widgets/premium_bottom_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';

/// Pipeline Kanban: aşama sütunları, premium kartlar, dokun ile aşama değiştir.
class PipelineKanbanPage extends ConsumerStatefulWidget {
  const PipelineKanbanPage({super.key});

  @override
  ConsumerState<PipelineKanbanPage> createState() => _PipelineKanbanPageState();
}

class _PipelineKanbanPageState extends ConsumerState<PipelineKanbanPage> {
  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final uid =
        ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''));
    return Scaffold(
      backgroundColor: ext.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: ext.background,
            foregroundColor: ext.textPrimary,
            leading: context.canPop() ? const AppBackButton() : null,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                'Pipeline',
                style: TextStyle(
                  color: ext.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ext.accent.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (uid.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: EmptyState(
                  compact: true,
                  grouped: true,
                  anchorAboveCenter: true,
                  anchorAlignmentY: -0.42,
                  icon: Icons.lock_outline_rounded,
                  title: 'Oturum gerekli',
                  subtitle: 'Pipeline\'ı görmek için giriş yapın.',
                  actionLabel: 'Giriş',
                  onAction: () => context.push(AppRouter.routeLogin),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirestoreService.pipelineItemsByAdvisorStream(uid),
                builder: (context, snapshot) {
                  final sheetExt = ext;
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                color: sheetExt.accent,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.space4),
                            Text(
                              'Pipeline yükleniyor...',
                              style: TextStyle(
                                color: sheetExt.textSecondary,
                                fontSize: DesignTokens.fontSizeSm,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];
                  final items = docs.map((d) {
                    final data = d.data();
                    return _PipelineCardData(
                      id: d.id,
                      customerId: data['customerId'] as String? ?? '',
                      listingId: data['listingId'] as String?,
                      stage: PipelineStage.fromId(data['stage'] as String?),
                      value: (data['value'] as num?)?.toDouble(),
                      currency: data['currency'] as String? ?? 'TRY',
                      customerName: data['customerName'] as String?,
                      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
                    );
                  }).toList();

                  if (items.isEmpty) {
                    return _PipelineEmptyState(
                      onAddTap: () =>
                          _showAddToPipelineSheet(context, ref, uid),
                    );
                  }

                  return _KanbanBoard(
                    items: items,
                    onStageTap: (item, newStage) =>
                        _moveToStage(item.id, newStage),
                    onCardTap: (item) => context.push(
                      AppRouter.routeCustomerDetail
                          .replaceFirst(':id', item.customerId),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: uid.isEmpty
          ? null
          : _ChampionFab(
              onTap: () => _showAddToPipelineSheet(context, ref, uid),
            ),
    );
  }

  Future<void> _moveToStage(String itemId, PipelineStage stage) async {
    AppFeedback.mediumImpact();
    await FirestoreService.updatePipelineItemStage(itemId, stage.id);
    if (mounted) {
      final ext = AppThemeExtension.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${stage.label} aşamasına taşındı'),
          backgroundColor: ext.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddToPipelineSheet(
      BuildContext context, WidgetRef ref, String uid) {
    AppFeedback.lightImpact();
    final customerIdController = TextEditingController();
    showPremiumModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final sheetExt = AppThemeExtension.of(ctx);
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
                      Icons.view_kanban_outlined,
                      size: DesignTokens.iconLg,
                      color: sheetExt.accent.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    const Expanded(
                      child: PremiumSheetHeader(
                        compact: true,
                        title: 'Pipeline\'a ekle',
                        subtitle:
                            'Müşteri ID’sini müşteri detayından kopyalayın',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kapat',
                      style: IconButton.styleFrom(
                        foregroundColor: sheetExt.textTertiary,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space4),
                TextField(
                  controller: customerIdController,
                  decoration: InputDecoration(
                    labelText: 'Müşteri ID',
                    hintText: 'Müşteri detayından yapıştırın',
                    labelStyle: TextStyle(color: sheetExt.textSecondary),
                    filled: true,
                    fillColor: sheetExt.background,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusControl),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusControl),
                      borderSide: BorderSide(
                        color: sheetExt.accent,
                        width: 1.5,
                      ),
                    ),
                  ),
                  style: TextStyle(color: sheetExt.textPrimary),
                ),
                const SizedBox(height: DesignTokens.space5),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'İptal',
                          style: TextStyle(color: sheetExt.textSecondary),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () async {
                          final customerId = customerIdController.text.trim();
                          if (customerId.isEmpty) return;
                          Navigator.pop(ctx);
                          await FirestoreService.setPipelineItem({
                            'advisorId': uid,
                            'customerId': customerId,
                            'stage': PipelineStage.lead.id,
                          });
                          if (ctx.mounted) {
                            final snackExt = AppThemeExtension.of(ctx);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: const Text('Pipeline\'a eklendi.'),
                                backgroundColor: snackExt.accent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: sheetExt.accent,
                          foregroundColor: sheetExt.onBrand,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusControl,
                            ),
                          ),
                        ),
                        child: const Text('Ekle'),
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
}

/// Veri yokken: paylaşılan EmptyState ile premium boş yüzey.
class _PipelineEmptyState extends StatelessWidget {
  const _PipelineEmptyState({required this.onAddTap});

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space5,
        DesignTokens.space4,
        DesignTokens.space5,
        DesignTokens.space8,
      ),
      child: Column(
        children: [
          EmptyState(
            icon: Icons.view_kanban_outlined,
            title: 'Henüz pipeline kaydı yok',
            subtitle:
                'Müşterileri aşamalara taşıyın. İlk kaydı ekleyin veya sağ alttaki + ile hızlıca ekleyin.',
            actionLabel: 'Pipeline\'a müşteri ekle',
            onAction: onAddTap,
            grouped: true,
            premiumVisual: true,
          ),
          const SizedBox(height: DesignTokens.space4),
          Text(
            'Veri geldikten sonra sütunlar yatay kaydırılır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ext.textTertiary,
              fontSize: DesignTokens.fontSizeXs,
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineCardData {
  _PipelineCardData({
    required this.id,
    required this.customerId,
    this.listingId,
    required this.stage,
    this.value,
    this.currency = 'TRY',
    this.customerName,
    this.updatedAt,
  });
  final String id;
  final String customerId;
  final String? listingId;
  final PipelineStage stage;
  final double? value;
  final String currency;
  final String? customerName;
  final DateTime? updatedAt;
}

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard({
    required this.items,
    required this.onStageTap,
    required this.onCardTap,
  });

  final List<_PipelineCardData> items;
  final void Function(_PipelineCardData item, PipelineStage newStage)
      onStageTap;
  final void Function(_PipelineCardData item) onCardTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space3,
        DesignTokens.space4,
        DesignTokens.space8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: PipelineStage.values.map((stage) {
          final stageItems =
              items.where((e) => e.stage.id == stage.id).toList();
          return SizedBox(
            width: 280,
            child: _StageColumn(
              stage: stage,
              count: stageItems.length,
              items: stageItems,
              onStageTap: onStageTap,
              onCardTap: onCardTap,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StageColumn extends StatelessWidget {
  const _StageColumn({
    required this.stage,
    required this.count,
    required this.items,
    required this.onStageTap,
    required this.onCardTap,
  });

  final PipelineStage stage;
  final int count;
  final List<_PipelineCardData> items;
  final void Function(_PipelineCardData item, PipelineStage newStage)
      onStageTap;
  final void Function(_PipelineCardData item) onCardTap;

  static Color _stageColor(PipelineStage s, AppThemeExtension ext) {
    switch (s.id) {
      case 'lead':
        return ext.info;
      case 'qualified':
        return ext.accent;
      case 'proposal':
        return ext.accent;
      case 'negotiation':
        return ext.warning;
      case 'closed_won':
        return ext.success;
      case 'closed_lost':
        return ext.danger;
      default:
        return ext.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final color = _stageColor(stage, ext);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space4,
              vertical: DesignTokens.space3,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesignTokens.space2),
                Expanded(
                  child: Text(
                    stage.label,
                    style: TextStyle(
                      color: ext.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: DesignTokens.fontSizeMd,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: DesignTokens.fontSizeSm,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.space3),
                child: _PipelineCard(
                  data: item,
                  onTap: () => onCardTap(item),
                  onMoveStage: () =>
                      _showStagePicker(context, item, onStageTap),
                ),
              )),
        ],
      ),
    );
  }

  void _showStagePicker(
    BuildContext context,
    _PipelineCardData item,
    void Function(_PipelineCardData, PipelineStage) onStageTap,
  ) {
    AppFeedback.lightImpact();
    showPremiumModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final sheetExt = AppThemeExtension.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space5,
              DesignTokens.space2,
              DesignTokens.space5,
              DesignTokens.space5,
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
                      Icons.swap_horiz_rounded,
                      size: DesignTokens.iconLg,
                      color: sheetExt.accent.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    Expanded(
                      child: PremiumSheetHeader(
                        compact: true,
                        title: 'Aşamayı değiştir',
                        subtitle: item.customerName ?? item.customerId,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kapat',
                      style: IconButton.styleFrom(
                        foregroundColor: sheetExt.textTertiary,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space3),
                ...PipelineStage.values.map((stage) {
                  final isCurrent = stage.id == item.stage.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.space2),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space2,
                        vertical: DesignTokens.space1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusControl),
                      ),
                      tileColor: isCurrent
                          ? sheetExt.accent.withValues(alpha: 0.12)
                          : null,
                      leading: Icon(
                        isCurrent
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color:
                            isCurrent ? sheetExt.accent : sheetExt.textTertiary,
                        size: DesignTokens.iconMd,
                      ),
                      title: Text(
                        stage.label,
                        style: TextStyle(
                          color: sheetExt.textPrimary,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        onStageTap(item, stage);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PipelineCard extends ConsumerWidget {
  const _PipelineCard({
    required this.data,
    required this.onTap,
    required this.onMoveStage,
  });

  final _PipelineCardData data;
  final VoidCallback onTap;
  final VoidCallback onMoveStage;

  static String _heatEmoji(LeadTemperatureLevel level) {
    switch (level) {
      case LeadTemperatureLevel.urgent:
      case LeadTemperatureLevel.hot:
        return '🔥';
      case LeadTemperatureLevel.warm:
      case LeadTemperatureLevel.reactivationCandidate:
        return '🟡';
      default:
        return '⚪';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onMoveStage,
        borderRadius: BorderRadius.circular(DesignTokens.championCardRadius),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.space4),
          decoration: ext.championCardDecoration(withGlow: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.customerName ??
                          'Müşteri ${data.customerId.length > 8 ? "${data.customerId.substring(0, 8)}..." : data.customerId}',
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: DesignTokens.fontSizeMd,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _PipelineHeatChip(customerId: data.customerId),
                ],
              ),
              if (data.value != null) ...[
                const SizedBox(height: DesignTokens.space2),
                Text(
                  '${data.value!.toStringAsFixed(0)} ${data.currency}',
                  style: TextStyle(
                    color: ext.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: DesignTokens.fontSizeSm,
                  ),
                ),
              ],
              const SizedBox(height: DesignTokens.space2),
              Row(
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 14,
                    color: ext.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Uzun bas: aşama değiştir',
                    style: TextStyle(
                      color: ext.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PipelineHeatChip extends ConsumerWidget {
  const _PipelineHeatChip({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = AppThemeExtension.of(context);
    final customerAsync = ref.watch(customerEntityByIdProvider(customerId));
    return customerAsync.when(
      data: (customer) {
        if (customer == null) return const SizedBox.shrink();
        final score = ref.watch(leadTemperatureForCustomerProvider(customer));
        final emoji = _PipelineCard._heatEmoji(score.level);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: ext.surfaceElevated,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 2),
              Text(
                '${score.score.round()}',
                style: TextStyle(
                  color: ext.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ChampionFab extends StatelessWidget {
  const _ChampionFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ext.accent.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: ext.gradientPrimary,
          ),
        ),
        child: Icon(
          Icons.add_rounded,
          color: ext.onBrand,
          size: 28,
        ),
      ),
    );
  }
}
