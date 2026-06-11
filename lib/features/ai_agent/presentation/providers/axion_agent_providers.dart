import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:emlakmaster_mobile/features/auth/domain/entities/app_role.dart';
import 'package:emlakmaster_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:emlakmaster_mobile/features/calls/presentation/providers/consultant_calls_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/customer_list_stream_provider.dart';
import 'package:emlakmaster_mobile/features/crm_customers/presentation/providers/office_wide_customers_stream_provider.dart';
import 'package:emlakmaster_mobile/features/revenue_engine/presentation/providers/revenue_engine_providers.dart';
import 'package:emlakmaster_mobile/features/tasks/presentation/providers/advisor_tasks_stream_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/axion_agent_engine.dart';
import '../../application/uncaptured_number_engine.dart';
import '../../data/axion_agent_crm_adapter.dart';
import '../../data/axion_capture_dismiss_store.dart';
import '../../data/axion_device_contact_directory.dart';
import '../../domain/axion_agent_models.dart';
import '../../domain/axion_phone_matcher.dart';
import '../../domain/axion_uncaptured_number.dart';

/// Tek motor örneği — önbellek ve denetim kaydı uygulama ömrü boyunca yaşar.
final axionAgentEngineProvider =
    Provider<AxionAgentEngine>((ref) => AxionAgentEngine());

/// Danışman bağlamı: mevcut stream provider'larından snapshot DTO'ları kurar.
/// Hesaplama yalnızca ekran bu provider'ı izlediğinde yapılır — startup'ta
/// ASLA tetiklenmez, ağ çağrısı yapmaz.
final axionConsultantContextProvider =
    Provider.autoDispose<AxionAgentContext?>((ref) {
  final uid = ref.watch(
    currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''),
  );
  if (uid.isEmpty) return null;

  final officeId =
      ref.watch(userDocStreamProvider(uid)).valueOrNull?.officeId ?? '';

  final customers =
      ref.watch(customerListForAgentProvider).valueOrNull?.entities ??
          const [];
  final taskDocs =
      ref.watch(advisorTasksStreamProvider(uid)).valueOrNull?.docs ?? const [];
  final callDocs =
      ref.watch(consultantCallsStreamProvider).valueOrNull?.docs ?? const [];

  // Henüz hiç veri akmadıysa bağlam üretme (boş sahte plan yerine sessizlik).
  if (customers.isEmpty && taskDocs.isEmpty && callDocs.isEmpty) return null;

  final callSnapshots = <AxionCallSnapshot>[];
  for (final d in callDocs) {
    final call = AxionAgentCrmAdapter.callFromDoc(d.id, d.data());
    if (call != null) callSnapshots.add(call);
  }

  return AxionAgentContext(
    userId: uid,
    role: 'consultant',
    workspaceId: officeId.isEmpty ? uid : officeId,
    now: DateTime.now(),
    customerSnapshots: [
      for (final c in customers) AxionAgentCrmAdapter.customerFrom(c),
    ],
    taskSnapshots: [
      for (final d in taskDocs)
        AxionAgentCrmAdapter.taskFromDoc(d.id, d.data()),
    ],
    callSnapshots: callSnapshots,
  );
});

/// Danışman günlük planı — deterministik, önbellekli, anında.
final axionDailyPlanProvider =
    FutureProvider.autoDispose<AxionDailyPlan?>((ref) async {
  final ctx = ref.watch(axionConsultantContextProvider);
  if (ctx == null) return null;
  final engine = ref.watch(axionAgentEngineProvider);
  return engine.generateDailyPlan(ctx);
});

/// Broker/yönetici bağlamı: ofis geneli müşteri + son çağrılar.
/// Görev verisi ofis genelinde stream edilmediği için bağlama girmez;
/// motor bunu dürüstçe "Görev verisi bulunamadı" notuyla raporlar.
final axionBrokerContextProvider =
    Provider.autoDispose<AxionAgentContext?>((ref) {
  final role = ref.watch(displayRoleOrNullProvider) ?? AppRole.guest;
  if (!role.isManagerTier) return null;

  final uid = ref.watch(
    currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''),
  );
  if (uid.isEmpty) return null;

  final officeId =
      ref.watch(userDocStreamProvider(uid)).valueOrNull?.officeId ?? '';
  if (officeId.isEmpty) return null;

  final customers =
      ref.watch(officeWideCustomerListProvider(officeId)).valueOrNull ??
          const [];
  final callDocs =
      ref.watch(brokerCallsDocumentsProvider).valueOrNull ?? const [];

  if (customers.isEmpty && callDocs.isEmpty) return null;

  final callSnapshots = <AxionCallSnapshot>[];
  for (final d in callDocs) {
    final call = AxionAgentCrmAdapter.callFromDoc(d.id, d.data());
    if (call != null) callSnapshots.add(call);
  }

  return AxionAgentContext(
    userId: uid,
    role: 'broker',
    workspaceId: officeId,
    now: DateTime.now(),
    customerSnapshots: [
      for (final c in customers) AxionAgentCrmAdapter.customerFrom(c),
    ],
    callSnapshots: callSnapshots,
  );
});

/// Broker/Admin operasyon özeti — yalnızca gerçek sayımlar.
final axionBrokerBriefProvider =
    FutureProvider.autoDispose<AxionBrokerBrief?>((ref) async {
  final ctx = ref.watch(axionBrokerContextProvider);
  if (ctx == null) return null;
  final engine = ref.watch(axionAgentEngineProvider);
  return engine.generateBrokerBrief(ctx);
});

/// Cihaz rehberi isimleri (`normalizedKey → isim`).
///
/// İzin İSTEMEZ; yalnızca verilmişse sessizce okur. 10 dk önbellekli.
final axionDeviceContactNamesProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) {
  return AxionDeviceContactDirectory.instance.namesByPhoneKey();
});

/// CRM'de kayıtlı olmayan numaralar (çağrı geçmişinden, son 14 gün).
///
/// Asıl amaç: yoğunlukta hiçbir numara kaybolmasın. Yalnızca gerçek
/// çağrı verisi; deterministik gruplama; ağ çağrısı yok. Rehberde kayıtlı
/// isim varsa numarayla birlikte gelir (kayıt formu isimle dolar).
final axionUncapturedNumbersProvider =
    Provider.autoDispose<List<AxionUncapturedNumber>>((ref) {
  final uid = ref.watch(
    currentUserProvider.select((a) => a.valueOrNull?.uid ?? ''),
  );
  if (uid.isEmpty) return const [];

  final callDocs =
      ref.watch(consultantCallsStreamProvider).valueOrNull?.docs ?? const [];
  if (callDocs.isEmpty) return const [];

  final customers =
      ref.watch(customerListForAgentProvider).valueOrNull?.entities ??
          const [];

  final deviceNames =
      ref.watch(axionDeviceContactNamesProvider).valueOrNull ?? const {};

  final calls = <AxionCallSnapshot>[];
  for (final d in callDocs) {
    final call = AxionAgentCrmAdapter.callFromDoc(d.id, d.data());
    if (call != null) calls.add(call);
  }

  return UncapturedNumberEngine.detect(
    calls: calls,
    knownPhoneKeys:
        AxionPhoneMatcher.buildKnownSet([for (final c in customers) c.primaryPhone]),
    now: DateTime.now(),
    fallbackNames: deviceNames,
  );
});

/// "Benim Günüm" kayıtsız numara şeridi görünür mü? (X ile gün sonuna
/// kadar kapatılabilir; ertesi gün otomatik geri gelir.)
final axionUncapturedStripVisibleProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final hidden = await AxionCaptureDismissStore.instance.isStripHidden();
  return !hidden;
});

/// Önemli bildirim pop-up'ı adayı: son 24 saatte aranan, kayıtsız,
/// snöz/yoksay edilmemiş en güncel numara. Bildirim ayarlarına saygılıdır
/// (ana anahtar + Axion Agent kategorisi + sessiz saatler).
final axionCapturePopupCandidateProvider =
    FutureProvider.autoDispose<AxionUncapturedNumber?>((ref) async {
  final numbers = ref.watch(axionUncapturedNumbersProvider);
  if (numbers.isEmpty) return null;

  final allowed = await SettingsService.instance.isNotificationAllowed('agent');
  if (!allowed) return null;

  final now = DateTime.now();
  final cutoff = now.subtract(const Duration(hours: 24));
  for (final n in numbers) {
    if (n.lastCallAt.isBefore(cutoff)) continue;
    final suppressed = await AxionCaptureDismissStore.instance
        .isSuppressed(n.normalizedKey, now: now);
    if (!suppressed) return n;
  }
  return null;
});
