import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/resilience/safe_operation.dart';
import 'package:emlakmaster_mobile/core/router/app_router.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/core/utils/whatsapp_launcher.dart';
import 'package:emlakmaster_mobile/core/theme/design_tokens.dart';
import 'package:emlakmaster_mobile/shared/widgets/app_back_button.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/customer_timeline/domain/entities/timeline_item.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/domain/permissions/feature_permission.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/manager_customer_crm_call_strip.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_insight_strip.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_smart_task_strip.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_last_call_signals_section.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_post_call_ai_insight_strip.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_timeline_intelligence_strip.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/widgets/customer_revenue_intelligence_strip.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/widgets/customer_transcript_hint_strip.dart';
import 'package:emlakmaster_mobile/features/smart_matching_engine/presentation/providers/portfolio_match_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    return Scaffold(
      backgroundColor: ext.background,
      appBar: AppBar(
        title: const Text('Müşteri'),
        backgroundColor: ext.background,
        foregroundColor: ext.textPrimary,
        leading: const AppBackButton(),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded),
            onPressed: () => context.push(
              AppRouter.routeCall,
              extra: {
                'customerId': customerId,
                'startedFromScreen': 'customer_detail',
              },
            ),
            tooltip: 'Ara',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DesignTokens.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CustomerHeader(customerId: customerId),
                    CustomerRevenueIntelligenceStrip(customerId: customerId),
                    CustomerTimelineIntelligenceStrip(customerId: customerId),
                    CustomerInsightStrip(customerId: customerId),
                    Consumer(
                      builder: (context, ref, _) {
                        final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
                        if (!role.isManagerTier) return const SizedBox.shrink();
                        return CustomerSmartTaskStrip(customerId: customerId);
                      },
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final role = ref.watch(displayRoleProvider).valueOrNull ?? AppRole.guest;
                        if (!FeaturePermission.canViewAllCalls(role)) {
                          return const SizedBox.shrink();
                        }
                        return ManagerCustomerCrmCallStrip(customerId: customerId);
                      },
                    ),
                    CustomerLastCallSignalsSection(customerId: customerId),
                    CustomerPostCallAiInsightStrip(customerId: customerId),
                    CustomerTranscriptHintStrip(customerId: customerId),
                    const SizedBox(height: DesignTokens.space5),
                    _PortfolioMatchSection(customerId: customerId),
                    const SizedBox(height: DesignTokens.space5),
                    Text(
                      'Zaman çizelgesi',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: ext.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    _TimelineActions(customerId: customerId),
                    const SizedBox(height: DesignTokens.space3),
                    _CustomerTimeline(customerId: customerId),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteSheet(context, ref, customerId),
        backgroundColor: ext.accent,
        foregroundColor: Colors.black,
        tooltip: 'Not ekle',
        child: const Icon(Icons.note_add_rounded),
      ),
    );
  }

  static void _showAddNoteSheet(BuildContext context, WidgetRef ref, String customerId) {
    final ext = AppThemeExtension.of(context);
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ext.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: DesignTokens.space4,
          right: DesignTokens.space4,
          top: DesignTokens.space4,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + DesignTokens.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Not ekle',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Wrap(
              spacing: DesignTokens.space2,
              runSpacing: DesignTokens.space2,
              children: _noteTemplates.map((t) {
                return ActionChip(
                  label: Text(t, style: TextStyle(fontSize: 12, color: ext.textPrimary)),
                  backgroundColor: ext.surfaceElevated,
                  side: BorderSide(color: ext.border),
                  onPressed: () {
                    controller.text = controller.text.isEmpty ? t : '${controller.text}\n$t';
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
                hintText: 'Not içeriği...',
                hintStyle: TextStyle(color: ext.textTertiary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                filled: true,
                fillColor: ext.background,
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            FilledButton.icon(
              onPressed: () async {
                Future<void> attemptSave() async {
                  final content = controller.text.trim();
                  if (content.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: const Text('Lütfen not içeriği girin.'), backgroundColor: ext.danger),
                    );
                    return;
                  }
                  final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
                  if (uid.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: const Text('Giriş yapılmamış.'), backgroundColor: ext.danger),
                    );
                    return;
                  }
                  try {
                    await runWithResilience(
                      () => FirestoreService.saveNote(customerId: customerId, content: content, advisorId: uid),
                      ref: ref as Ref<Object?>,
                    );
                    HapticFeedback.mediumImpact();
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
                    showModalBottomSheet<void>(
                      context: ctx,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      backgroundColor: ext.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
                      ),
                      builder: (panelCtx) {
                        return SafeArea(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: DesignTokens.space5,
                              right: DesignTokens.space5,
                              top: DesignTokens.space4,
                              bottom: MediaQuery.viewInsetsOf(panelCtx).bottom + DesignTokens.space5,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Not kaydı',
                                  style: TextStyle(
                                    color: ext.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Kayıt şu an tamamlanamadı',
                                  style: Theme.of(panelCtx).textTheme.titleMedium?.copyWith(
                                        color: ext.textPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  FirestoreService.userFacingErrorMessage(e),
                                  style: TextStyle(
                                    color: ext.textSecondary,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: DesignTokens.space5),
                                Text(
                                  'Bu müşterinin kayıtlı notları',
                                  style: TextStyle(
                                    color: ext.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 140,
                                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                    stream: FirestoreService.notesByCustomerStream(customerId),
                                    builder: (context, snap) {
                                      final docs = snap.data?.docs ?? [];
                                      if (snap.connectionState == ConnectionState.waiting && docs.isEmpty) {
                                        return Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: ext.accent,
                                            ),
                                          ),
                                        );
                                      }
                                      if (docs.isEmpty) {
                                        return Center(
                                          child: Text(
                                            'Henüz not yok — kayıt başarılı olunca burada görünür.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: ext.textTertiary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      }
                                      return ListView.separated(
                                        itemCount: docs.length > 5 ? 5 : docs.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                                        itemBuilder: (_, i) {
                                          final c = docs[i].data()['content'] as String? ?? '—';
                                          return Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: ext.background,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: ext.border.withValues(alpha: 0.5)),
                                            ),
                                            child: Text(
                                              c,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: ext.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: DesignTokens.space5),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pop(panelCtx);
                                    attemptSave();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: ext.accent,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text('Tekrar dene'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                }

                await attemptSave();
              },
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text('Kaydet'),
              style: FilledButton.styleFrom(
                backgroundColor: ext.accent,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
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
                        Icon(Icons.home_rounded, size: 16, color: ext.textSecondary),
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
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CustomerHeader extends StatelessWidget {
  const _CustomerHeader({required this.customerId});
  final String customerId;

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.customerStream(customerId),
      builder: (context, snapshot) {
        final ext = AppThemeExtension.of(context);
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return Container(
            padding: const EdgeInsets.all(DesignTokens.space5),
            decoration: BoxDecoration(
              color: ext.surface,
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              border: Border.all(color: ext.border),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: ext.accent),
                ),
                const SizedBox(width: DesignTokens.space4),
                Text('Yükleniyor...', style: TextStyle(color: ext.textSecondary)),
              ],
            ),
          );
        }
        final data = snapshot.data!.data()!;
        final fullName = data['fullName'] as String? ?? data['customerIntent'] as String? ?? 'Müşteri';
        final phone = data['primaryPhone'] as String? ?? data['phone'] as String? ?? '—';
        final email = data['email'] as String? ?? '—';
        final nextStep = data['lastNextStepSuggestion'] as String?;
        final temp = (data['leadTemperature'] as num?)?.toDouble();
        final updatedAt = _parseDate(data['updatedAt']);
        return Container(
          padding: const EdgeInsets.all(DesignTokens.space5),
          decoration: BoxDecoration(
            color: ext.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(color: ext.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: ext.accent.withValues(alpha: 0.2),
                    radius: 28,
                    child: Text(
                      fullName.trim().isEmpty ? '?' : fullName.trim().substring(0, 1).toUpperCase(),
                      style: TextStyle(color: ext.accent, fontWeight: FontWeight.w700, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: TextStyle(
                            color: ext.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: DesignTokens.fontSizeLg,
                          ),
                        ),
                        if (phone != '—')
                          Text(
                            phone,
                            style: TextStyle(color: ext.textSecondary, fontSize: DesignTokens.fontSizeSm),
                          ),
                        if (email != '—')
                          Text(
                            email,
                            style: TextStyle(color: ext.textTertiary, fontSize: DesignTokens.fontSizeXs),
                          ),
                      ],
                    ),
                  ),
                  if (temp != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ext.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                      ),
                      child: Text(
                        '${(temp * 100).toInt()}%',
                        style: TextStyle(color: ext.accent, fontSize: DesignTokens.fontSizeXs, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              if (nextStep != null && nextStep.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.space3),
                Text(
                  'Sonraki adım: $nextStep',
                  style: TextStyle(color: ext.textTertiary, fontSize: DesignTokens.fontSizeSm),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (updatedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: DesignTokens.space2),
                  child: Text(
                    'Son güncelleme: ${updatedAt.day}.${updatedAt.month}.${updatedAt.year}',
                    style: TextStyle(color: ext.textTertiary, fontSize: 11),
                  ),
                ),
              if (phone != '—' && phone.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.space4),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final ok = await WhatsAppLauncher.openChat(phone);
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('WhatsApp açılamadı. Numarayı kontrol edin.'),
                              backgroundColor: ext.danger,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.chat_rounded, size: 18, color: Color(0xFF25D366)),
                      label: Text('WhatsApp\'ta aç', style: TextStyle(color: ext.accent)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
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

  static void _showAddOfferSheet(BuildContext context, WidgetRef ref, String customerId) {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final ext = AppThemeExtension.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: ext.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radius2xl)),
            boxShadow: [BoxShadow(color: ext.accent.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, -4))],
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
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: ext.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: DesignTokens.space4),
              Text('Yeni teklif', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(color: ext.textPrimary, fontWeight: FontWeight.w800)),
              const SizedBox(height: DesignTokens.space4),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Tutar (TRY)',
                  labelStyle: TextStyle(color: ext.textSecondary),
                  filled: true,
                  fillColor: ext.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd), borderSide: BorderSide(color: ext.accent, width: 1.5)),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                ),
                style: TextStyle(color: ext.textPrimary),
                maxLines: 2,
              ),
              const SizedBox(height: DesignTokens.space6),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text('İptal', style: TextStyle(color: ext.textSecondary)))),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () async {
                        final amountStr = amountController.text.trim().replaceAll(',', '.');
                        final amount = double.tryParse(amountStr);
                        if (amount == null || amount <= 0) return;
                        Navigator.pop(ctx);
                        await FirestoreService.saveOffer(customerId: customerId, advisorId: uid, amount: amount, notes: notesController.text.trim().isEmpty ? null : notesController.text.trim());
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: const Text('Teklif eklendi.'), backgroundColor: ext.accent, behavior: SnackBarBehavior.floating));
                      },
                      style: FilledButton.styleFrom(backgroundColor: ext.accent, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd))),
                      child: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showAddVisitSheet(BuildContext context, WidgetRef ref, String customerId) {
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    DateTime? pickedDate = DateTime.now().add(const Duration(days: 1));
    final notesController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final ext = AppThemeExtension.of(ctx);
          return Container(
            decoration: BoxDecoration(
              color: ext.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radius2xl)),
              boxShadow: [BoxShadow(color: ext.accent.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, -4))],
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
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: ext.border, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: DesignTokens.space4),
                Text('Yeni ziyaret', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(color: ext.textPrimary, fontWeight: FontWeight.w800)),
                const SizedBox(height: DesignTokens.space4),
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(context: ctx, initialDate: pickedDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (date != null) setModalState(() => pickedDate = date);
                  },
                  icon: Icon(Icons.calendar_today_rounded, size: 18, color: ext.accent),
                  label: Text(pickedDate != null ? '${pickedDate!.day}.${pickedDate!.month}.${pickedDate!.year}' : 'Tarih seç', style: TextStyle(color: ext.accent)),
                  style: OutlinedButton.styleFrom(foregroundColor: ext.accent, side: BorderSide(color: ext.accent)),
                ),
                const SizedBox(height: DesignTokens.space3),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Not (opsiyonel)',
                    labelStyle: TextStyle(color: ext.textSecondary),
                    filled: true,
                    fillColor: ext.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                  ),
                  style: TextStyle(color: ext.textPrimary),
                  maxLines: 2,
                ),
                const SizedBox(height: DesignTokens.space6),
                Row(
                  children: [
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text('İptal', style: TextStyle(color: ext.textSecondary)))),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () async {
                          if (pickedDate == null) return;
                          Navigator.pop(ctx);
                          await FirestoreService.saveVisit(customerId: customerId, advisorId: uid, scheduledAt: pickedDate!, notes: notesController.text.trim().isEmpty ? null : notesController.text.trim());
                          if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: const Text('Ziyaret eklendi.'), backgroundColor: ext.accent, behavior: SnackBarBehavior.floating));
                        },
                        style: FilledButton.styleFrom(backgroundColor: ext.accent, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd))),
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
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap});
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
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.space3, horizontal: DesignTokens.space4),
          decoration: BoxDecoration(
            color: ext.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: ext.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: ext.accent),
              const SizedBox(width: DesignTokens.space2),
              Text(label, style: TextStyle(color: ext.textPrimary, fontWeight: FontWeight.w600, fontSize: DesignTokens.fontSizeSm)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerTimeline extends StatelessWidget {
  const _CustomerTimeline({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.callSummariesByCustomerStream(customerId),
      builder: (context, callSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService.notesByCustomerStream(customerId),
          builder: (context, noteSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.visitsByCustomerStream(customerId),
              builder: (context, visitSnap) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirestoreService.offersByCustomerStream(customerId),
                  builder: (context, offerSnap) {
                    final ext = AppThemeExtension.of(context);
                    final items = <_TimelineRow>[];
                    add(String id, TimelineItemType type, String title, String subtitle, DateTime at) {
                      items.add(_TimelineRow(id: id, type: type, title: title, subtitle: subtitle, at: at));
                    }
                    for (final d in callSnap.data?.docs ?? []) {
                      final d2 = d.data();
                      final at = (d2['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                      add(d.id, TimelineItemType.callSummary, 'Çağrı özeti', d2['customerIntent'] as String? ?? '—', at);
                    }
                    for (final d in noteSnap.data?.docs ?? []) {
                      final d2 = d.data();
                      final at = (d2['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                      add(d.id, TimelineItemType.note, 'Not', d2['content'] as String? ?? '—', at);
                    }
                    for (final d in visitSnap.data?.docs ?? []) {
                      final d2 = d.data();
                      final at = (d2['scheduledAt'] as Timestamp?)?.toDate() ?? (d2['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                      add(d.id, TimelineItemType.visit, 'Ziyaret', d2['notes'] as String? ?? '—', at);
                    }
                    for (final d in offerSnap.data?.docs ?? []) {
                      final d2 = d.data();
                      final amount = d2['amount'] ?? d2['price'];
                      final at = (d2['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                      add(d.id, TimelineItemType.offer, 'Teklif', amount != null ? '$amount' : '—', at);
                    }
                    items.sort((a, b) => b.at.compareTo(a.at));
                    if (items.isEmpty) {
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
                              style: TextStyle(color: ext.textSecondary, fontSize: DesignTokens.fontSizeSm),
                            ),
                            Text(
                              'Çağrı özeti, not, ziyaret veya teklif eklendikçe burada görünecek.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: ext.textTertiary, fontSize: DesignTokens.fontSizeXs),
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: items.map((e) => _TimelineTile(row: e)).toList(),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TimelineRow {
  _TimelineRow({required this.id, required this.type, required this.title, required this.subtitle, required this.at});
  final String id;
  final TimelineItemType type;
  final String title;
  final String subtitle;
  final DateTime at;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.row});
  final _TimelineRow row;

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
    final dateStr = '${row.at.day}.${row.at.month}.${row.at.year} ${row.at.hour.toString().padLeft(2, '0')}:${row.at.minute.toString().padLeft(2, '0')}';
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
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
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
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 2))],
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
                      style: TextStyle(color: ext.textSecondary, fontSize: DesignTokens.fontSizeXs),
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
