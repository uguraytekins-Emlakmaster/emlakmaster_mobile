import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/shared/models/pipeline_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Pipeline Kanban: aşama sütunları, premium kartlar, dokun ile aşama değiştir.
class PipelineKanbanPage extends ConsumerStatefulWidget {
  const PipelineKanbanPage({super.key});

  @override
  ConsumerState<PipelineKanbanPage> createState() => _PipelineKanbanPageState();
}

class _PipelineKanbanPageState extends ConsumerState<PipelineKanbanPage> {
  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid ?? '';
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: DesignTokens.backgroundDark,
            foregroundColor: DesignTokens.textPrimaryDark,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: const Text(
                'Pipeline',
                style: TextStyle(
                  color: DesignTokens.textPrimaryDark,
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
                      DesignTokens.primary.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (uid.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'Giriş yapılmamış.',
                  style: TextStyle(color: DesignTokens.textSecondaryDark),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirestoreService.pipelineItemsByAdvisorStream(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                color: DesignTokens.primary,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(height: DesignTokens.space4),
                            Text(
                              'Pipeline yükleniyor...',
                              style: TextStyle(
                                color: DesignTokens.textSecondaryDark,
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
    HapticFeedback.mediumImpact();
    await FirestoreService.updatePipelineItemStage(itemId, stage.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${stage.label} aşamasına taşındı'),
          backgroundColor: DesignTokens.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddToPipelineSheet(
      BuildContext context, WidgetRef ref, String uid) {
    HapticFeedback.lightImpact();
    final customerIdController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: DesignTokens.surfaceDark,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radius2xl),
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.primary.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: DesignTokens.space6,
          right: DesignTokens.space6,
          top: DesignTokens.space6,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + DesignTokens.space6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.space5),
            Text(
              'Pipeline\'a ekle',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    color: DesignTokens.textPrimaryDark,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: DesignTokens.space4),
            TextField(
              controller: customerIdController,
              decoration: InputDecoration(
                labelText: 'Müşteri ID',
                hintText: 'Müşteri detay sayfasından kopyalayın',
                labelStyle: const TextStyle(color: DesignTokens.textSecondaryDark),
                filled: true,
                fillColor: DesignTokens.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusMd),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusMd),
                  borderSide: const BorderSide(
                    color: DesignTokens.primary,
                    width: 1.5,
                  ),
                ),
              ),
              style: const TextStyle(color: DesignTokens.textPrimaryDark),
            ),
            const SizedBox(height: DesignTokens.space6),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'İptal',
                      style: TextStyle(color: DesignTokens.textSecondaryDark),
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
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Pipeline\'a eklendi.'),
                            backgroundColor: DesignTokens.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: DesignTokens.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(DesignTokens.championButtonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusMd),
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
  final void Function(_PipelineCardData item, PipelineStage newStage) onStageTap;
  final void Function(_PipelineCardData item) onCardTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space6,
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
  final void Function(_PipelineCardData item, PipelineStage newStage) onStageTap;
  final void Function(_PipelineCardData item) onCardTap;

  static Color _stageColor(PipelineStage s) {
    switch (s.id) {
      case 'lead':
        return DesignTokens.info;
      case 'qualified':
        return DesignTokens.accent;
      case 'proposal':
        return DesignTokens.secondary;
      case 'negotiation':
        return DesignTokens.warning;
      case 'closed_won':
        return DesignTokens.success;
      case 'closed_lost':
        return DesignTokens.danger;
      default:
        return DesignTokens.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _stageColor(stage);
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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: color.withOpacity(0.4)),
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
                        color: color.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesignTokens.space2),
                Expanded(
                  child: Text(
                    stage.label,
                    style: const TextStyle(
                      color: DesignTokens.textPrimaryDark,
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
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
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
                  onMoveStage: () => _showStagePicker(context, item, onStageTap),
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
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radius2xl),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Aşamayı değiştir',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      color: DesignTokens.textPrimaryDark,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: DesignTokens.space4),
              ...PipelineStage.values.map((stage) {
                final isCurrent = stage.id == item.stage.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.space2),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                    tileColor: isCurrent
                        ? DesignTokens.primary.withOpacity(0.15)
                        : null,
                    leading: Icon(
                      isCurrent ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: isCurrent
                          ? DesignTokens.primary
                          : DesignTokens.textTertiaryDark,
                      size: 22,
                    ),
                    title: Text(
                      stage.label,
                      style: TextStyle(
                        color: DesignTokens.textPrimaryDark,
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
      ),
    );
  }
}

class _PipelineCard extends StatelessWidget {
  const _PipelineCard({
    required this.data,
    required this.onTap,
    required this.onMoveStage,
  });

  final _PipelineCardData data;
  final VoidCallback onTap;
  final VoidCallback onMoveStage;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onMoveStage,
        borderRadius: BorderRadius.circular(DesignTokens.championCardRadius),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.space4),
          decoration: DesignTokens.cardChampion(withGlow: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.customerName ?? 'Müşteri ${data.customerId.substring(0, data.customerId.length > 8 ? 8 : data.customerId.length)}...',
                style: const TextStyle(
                  color: DesignTokens.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: DesignTokens.fontSizeMd,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (data.value != null) ...[
                const SizedBox(height: DesignTokens.space2),
                Text(
                  '${data.value!.toStringAsFixed(0)} ${data.currency}',
                  style: const TextStyle(
                    color: DesignTokens.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: DesignTokens.fontSizeSm,
                  ),
                ),
              ],
              const SizedBox(height: DesignTokens.space2),
              const Row(
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 14,
                    color: DesignTokens.textTertiaryDark,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Uzun bas: aşama değiştir',
                    style: TextStyle(
                      color: DesignTokens.textTertiaryDark,
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

class _ChampionFab extends StatelessWidget {
  const _ChampionFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: DesignTokens.gradientPrimary,
          ),
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.black,
          size: 28,
        ),
      ),
    );
  }
}
