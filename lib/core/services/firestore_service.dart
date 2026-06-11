import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:emlakmaster_mobile/core/constants/app_constants.dart';
import 'package:emlakmaster_mobile/core/logging/app_logger.dart';
import 'package:emlakmaster_mobile/core/models/invite_doc.dart';
import 'package:emlakmaster_mobile/core/models/team_doc.dart';
import 'package:emlakmaster_mobile/core/services/app_lifecycle_power_service.dart';
import 'package:emlakmaster_mobile/features/auth/data/user_repository.dart';

/// Cache-first Firestore: önce önbellek (persistence), arayüz takılmaz.
/// Offline-first: veri cihazda saklanır; internet gelince otomatik senkronize edilir.
class FirestoreService {
  static bool _initialized = false;
  static bool _initStarted = false;

  static final List<String> _defaultTickerItems = [
    'Yeni ilan: 3+1 Nişantaşı - 18.500.000₺',
    'Fiyat düşüşü: 2+1 Kozyatağı - %5',
    'Gösterim başladı: Bebek Boğaz manzaralı',
  ];

  static List<String> get defaultTickerItems =>
      List<String>.unmodifiable(_defaultTickerItems);

  /// Uygulama açılışını bloklamadan Firebase başlatır.
  /// Offline persistence açık: sahada/bodrumda girilen veriler internet gelince uçmaz.
  static Future<void> ensureInitialized() async {
    if (_initialized || _initStarted) return;
    _initStarted = true;
    try {
      // Firebase yalnızca main.dart içinde initialize edilir; burada sadece store ayarları yapılır.
      if (Firebase.apps.isEmpty) {
        _initStarted = false;
        return;
      }
      final store = FirebaseFirestore.instance;
      // Offline-first: sınırsız cache + persistence (web/mobile). Veri kaybı önlenir.
      try {
        store.settings = const Settings(
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          persistenceEnabled: true,
        );
      } catch (_) {
        store.settings = const Settings(
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }
      _initialized = true;
      if (kDebugMode) {
        debugPrint('FirestoreService: Offline persistence enabled.');
      }
    } catch (e) {
      _initStarted = false; // Hata durumunda yeniden denemeye izin ver.
      if (kDebugMode) debugPrint('FirestoreService init: $e');
    }
  }

  /// Firestore önbellek ayarları uygulandı mı (Firebase [DEFAULT] mevcut).
  static bool get isFirestoreReady => _initialized;

  /// Yazma işlemleri: sessiz no-op yerine hata fırlatır (UI geri bildirim verebilir).
  static void _requireFirestoreReady() {
    if (!_initialized) {
      throw StateError(
        'Firestore başlatılamadı. Uygulamayı yeniden başlatıp tekrar deneyin.',
      );
    }
  }

  /// SnackBar / diyalog için kısa Türkçe mesaj (FirebaseException, StateError).
  static String userFacingErrorMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Erişim reddedildi. Oturum veya Firestore kurallarını kontrol edin.';
        case 'unauthenticated':
          return 'Oturum gerekli. Lütfen tekrar giriş yapın.';
        case 'unavailable':
        case 'deadline-exceeded':
          return 'Sunucuya şu an ulaşılamıyor. Bağlantıyı kontrol edip tekrar deneyin.';
        case 'failed-precondition':
          return 'İstek önkoşulları sağlanmadı. Veriyi kontrol edin.';
        default:
          final m = error.message;
          if (m != null && m.isNotEmpty) return m;
          return 'İşlem tamamlanamadı (${error.code}).';
      }
    }
    if (error is StateError) return error.message;
    return 'İşlem tamamlanamadı.';
  }

  static Stream<List<String>>? _tickerStream;

  /// Ofis ticker stream (tek örnek, broadcast): birden fazla dinleyici güvenle bağlanabilir.
  static Stream<List<String>> get officeTickerStream {
    _tickerStream ??= _officeTickerStream().asBroadcastStream();
    return _tickerStream!;
  }

  static Stream<List<String>> _officeTickerStream() async* {
    yield _defaultTickerItems;
    await ensureInitialized();
    if (!_initialized) return;
    try {
      await for (final snap in FirebaseFirestore.instance
          .collection('office_activity')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots()) {
        if (snap.docs.isEmpty) continue;
        final items = snap.docs
            .map((d) => d.data()['text'] as String? ?? d.id)
            .where((s) => s.isNotEmpty)
            .toList();
        if (items.isNotEmpty) yield items;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('FirestoreService ticker: $e');
    }
  }

  /// listings koleksiyonu (emlak ilanları) için stream
  static Stream<QuerySnapshot<Map<String, dynamic>>> listingsStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield* const Stream.empty();
      return;
    }
    // Güvenlik sınırı: sınırsız global dinleyici büyük koleksiyonlarda tüm
    // veriyi indirir (ölçeklenebilirlik kuralı).
    yield* FirebaseFirestore.instance
        .collection('listings')
        .limit(500)
        .snapshots();
  }

  /// Tek ilan dokümanı (detay sayfası için).
  static Stream<DocumentSnapshot<Map<String, dynamic>>> listingDocStream(
      String id) async* {
    await ensureInitialized();
    if (!_initialized || id.isEmpty) return;
    yield* FirebaseFirestore.instance
        .collection('listings')
        .doc(id)
        .snapshots();
  }

  /// agents koleksiyonu (danışmanlar) için stream
  static Stream<QuerySnapshot<Map<String, dynamic>>> agentsStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance
        .collection('agents')
        .limit(500)
        .snapshots();
  }

  /// Tek bir agent dokümanını dinlemek için (konum, durum vb.)
  static Stream<DocumentSnapshot<Map<String, dynamic>>> agentDocStream(
      String agentId) async* {
    await ensureInitialized();
    if (!_initialized) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance
        .collection('agents')
        .doc(agentId)
        .snapshots();
  }

  // ---------- Teams (flat team: name, managerId, memberIds) ----------
  /// Tüm ekipler stream. Admin ekip yönetimi için.
  static Stream<List<TeamDoc>> teamsStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance
        .collection(AppConstants.colTeams)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TeamDoc.fromFirestore(d.id, d.data()))
            .whereType<TeamDoc>()
            .toList());
  }

  /// Tek ekip dokümanı stream (detay sayfası için).
  static Stream<TeamDoc?> teamDocStream(String teamId) async* {
    await ensureInitialized();
    if (!_initialized || teamId.isEmpty) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance
        .collection(AppConstants.colTeams)
        .doc(teamId)
        .snapshots()
        .map((snap) => snap.exists && snap.data() != null
            ? TeamDoc.fromFirestore(snap.id, snap.data())
            : null);
  }

  /// Yeni ekip oluşturur. Doc id döner.
  static Future<String> createTeam({
    required String name,
    required String managerId,
  }) async {
    await ensureInitialized();
    if (!_initialized) throw StateError('Firestore not initialized');
    final col = FirebaseFirestore.instance.collection(AppConstants.colTeams);
    final ref = col.doc();
    final now = FieldValue.serverTimestamp();
    await ref.set({
      'name': name,
      'managerId': managerId,
      'memberIds': <String>[],
      'createdAt': now,
      'updatedAt': now,
    });
    return ref.id;
  }

  /// Ekip yöneticisini günceller; üyelerin managerId alanı bu fonksiyonla güncellenmez (tek tek assign ile).
  static Future<void> updateTeamManager(String teamId, String managerId) async {
    await ensureInitialized();
    if (!_initialized || teamId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection(AppConstants.colTeams)
        .doc(teamId)
        .update({
      'managerId': managerId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Danışmanı ekibe atar: users.teamId/managerId ve teams.memberIds senkron.
  static Future<void> assignAgentToTeam(String agentId, String teamId) async {
    await ensureInitialized();
    if (!_initialized || agentId.isEmpty || teamId.isEmpty) return;
    final teamRef = FirebaseFirestore.instance
        .collection(AppConstants.colTeams)
        .doc(teamId);
    final teamSnap = await teamRef.get();
    if (!teamSnap.exists || teamSnap.data() == null) return;
    final managerId = teamSnap.data()!['managerId'] as String? ?? '';
    await UserRepository.updateUserTeamFields(agentId, teamId, managerId);
    await teamRef.update({
      'memberIds': FieldValue.arrayUnion([agentId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Danışmanı ekipten çıkarır: users.teamId/managerId null, teams.memberIds'den kaldırır.
  static Future<void> removeAgentFromTeam(String agentId, String teamId) async {
    await ensureInitialized();
    if (!_initialized || agentId.isEmpty || teamId.isEmpty) return;
    await UserRepository.updateUserTeamFields(agentId, null, null);
    await FirebaseFirestore.instance
        .collection(AppConstants.colTeams)
        .doc(teamId)
        .update({
      'memberIds': FieldValue.arrayRemove([agentId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------- Invites (danışman daveti: ilk girişte rol ve ekip atanır) ----------
  /// Davet oluşturur. Yönetici panelinden "Yeni Danışman" ile kaydedilir.
  static Future<String> createInvite({
    required String email,
    required String role,
    required String createdBy,
    String? teamId,
    String? name,
  }) async {
    await ensureInitialized();
    if (!_initialized) throw StateError('Firestore not initialized');
    final normalizedEmail = email.trim().toLowerCase();
    final col = FirebaseFirestore.instance.collection(AppConstants.colInvites);
    // Doküman, e-posta ile anahtarlanır; Firestore kuralları users.create sırasında
    // ayrıcalıklı rolü `invites/{email}` üzerinden doğrulayabilir (yetki yükseltme önlenir).
    final ref = col.doc(normalizedEmail);
    final now = FieldValue.serverTimestamp();
    await ref.set({
      'email': normalizedEmail,
      'role': role,
      'createdBy': createdBy,
      if (teamId != null && teamId.isNotEmpty) 'teamId': teamId,
      if (name != null && name.isNotEmpty) 'name': name,
      'createdAt': now,
      'updatedAt': now,
    });
    return ref.id;
  }

  /// E-posta ile bekleyen davet arar (ilk girişte kullanıcı doc oluşturulurken).
  ///
  /// Davet dokümanı yoksa Firestore kuralı `resource.data.email` kontrolünde
  /// PERMISSION_DENIED döndürür (NOT_FOUND yerine). Bu beklenen bir durumdur:
  /// davetsiz kullanıcı = davet yok. Hata yutulup null dönülür; aksi halde
  /// rol seçimi sayfası sonsuz yükleme ekranında kalır.
  static Future<InviteDoc?> getInviteByEmail(String email) async {
    await ensureInitialized();
    if (!_initialized || email.trim().isEmpty) return null;
    final normalized = email.trim().toLowerCase();
    // E-posta ile anahtarlanmış doküman (kural-doğrulanabilir). Eski rastgele-id
    // davetler bu şemada bulunmaz; yöneticinin daveti yeniden oluşturması gerekir.
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.colInvites)
          .doc(normalized)
          .get();
      if (!doc.exists) return null;
      return InviteDoc.fromFirestore(doc.id, doc.data());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  /// Daveti siler (kullanıldıktan sonra veya iptal için).
  static Future<void> deleteInvite(String inviteId) async {
    await ensureInitialized();
    if (!_initialized || inviteId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection(AppConstants.colInvites)
        .doc(inviteId)
        .delete();
  }

  /// Danışman-tier kullanıcılar (agent, team_lead, office_manager, general_manager, broker_owner). Admin listesi için.
  static Stream<List<UserDoc>> consultantsStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield* const Stream.empty();
      return;
    }
    const consultantRoles = [
      'agent',
      'team_lead',
      'office_manager',
      'general_manager',
      'broker_owner',
    ];
    yield* FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .where('role', whereIn: consultantRoles)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => UserDoc.fromFirestore(d.id, d.data()))
            .whereType<UserDoc>()
            .toList());
  }

  /// Bir çağrı kapandığında, ilgili agent dokümanına özet yazar ve metrikleri günceller.
  static Future<void> saveCallSummary({
    required String agentId,
    required String intentSummary,
    required List<String> criticalNotes,
    required String nextAction,
  }) async {
    await ensureInitialized();
    _requireFirestoreReady();

    final ref = FirebaseFirestore.instance.collection('agents').doc(agentId);
    await ref.set(
      {
        'lastCallSummary': intentSummary,
        'lastNextAction': nextAction,
        'criticalNotes': criticalNotes,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        // Basit bir model: her çağrı için yaklaşık +5 dk ve +1 arama sayısı
        'todayCallMinutes': FieldValue.increment(5),
        'totalCalls': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );
  }

  /// Agent durumunu günceller (ör: 'Görüşmede', 'Müsait').
  static Future<void> setAgentStatus({
    required String agentId,
    required String status,
  }) async {
    await ensureInitialized();
    _requireFirestoreReady();

    final ref = FirebaseFirestore.instance.collection('agents').doc(agentId);
    await ref.set(
      {
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Tüm müşteriler (yönetici / eski ekranlar; tercihen [customersByAssignedAgentStream]).
  static Stream<QuerySnapshot<Map<String, dynamic>>> customersStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance
        .collection('customers')
        .limit(200)
        .snapshots();
  }

  /// Müşteri listesi ilk sayfa boyutu (Firestore maliyeti + ilk boyama).
  static const int customerListPageSize = 40;

  /// Danışman çağrı geçmişi — advisorId + agentId stream başına limit.
  static const int callsListPageSize = 60;

  /// Komuta merkezi canlı çağrı penceresi (ofis veya tüm ofisler). Bu limitin
  /// üstündeki eski kayıtlar "Daha fazla yükle" sayfalamasıyla getirilir.
  static const int callsLiveStreamLimit = 500;

  /// Komuta merkezi sayfa boyutu ("Daha fazla yükle" başına).
  static const int callsCommandPageSize = 200;

  /// advisorId → officeId çözümü için hafif önbellek (çağrı yazımında tek okuma).
  static final Map<String, String> _advisorOfficeIdCache = {};

  /// Çağrı dokümanına yazılacak `officeId`'yi çözer.
  ///
  /// [provided] doluysa onu kullanır; aksi halde danışmanın `users/{advisorId}.officeId`
  /// alanını okur (önbellekli). Çözülemezse `''` döner — çağrı oluşturma asla bloklanmaz.
  static Future<String> _officeIdForAdvisor(
    String advisorId, [
    String provided = '',
  ]) async {
    final trimmed = provided.trim();
    if (trimmed.isNotEmpty) return trimmed;
    if (advisorId.isEmpty) return '';
    final cached = _advisorOfficeIdCache[advisorId];
    if (cached != null) return cached;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(advisorId)
          .get();
      final oid = (snap.data()?['officeId'] as String? ?? '').trim();
      if (oid.isNotEmpty) _advisorOfficeIdCache[advisorId] = oid;
      return oid;
    } catch (_) {
      return '';
    }
  }

  /// Danışmana atanan müşteriler, en yeni kayıt önce. Üretim CRM listesi bunu kullanır.
  static Stream<QuerySnapshot<Map<String, dynamic>>>
      customersByAssignedAgentStream(
    String agentId,
  ) async* {
    await ensureInitialized();
    if (!_initialized || agentId.isEmpty) {
      yield* const Stream.empty();
      return;
    }
    try {
      yield* FirebaseFirestore.instance
          .collection(AppConstants.colCustomers)
          .where('assignedAgentId', isEqualTo: agentId)
          .orderBy('createdAt', descending: true)
          .limit(customerListPageSize)
          .snapshots();
    } catch (e, st) {
      if (kDebugMode) debugPrint('customersByAssignedAgentStream: $e $st');
      yield* const Stream.empty();
    }
  }

  /// Müşteri listesi — sonraki sayfa (stream ilk sayfadan sonra).
  static Future<QuerySnapshot<Map<String, dynamic>>>
      fetchCustomersByAssignedAgentPage(
    String agentId, {
    required DocumentSnapshot<Map<String, dynamic>> startAfter,
  }) async {
    await ensureInitialized();
    if (!_initialized || agentId.isEmpty) {
      return FirebaseFirestore.instance
          .collection(AppConstants.colCustomers)
          .limit(0)
          .get();
    }
    return FirebaseFirestore.instance
        .collection(AppConstants.colCustomers)
        .where('assignedAgentId', isEqualTo: agentId)
        .orderBy('createdAt', descending: true)
        .startAfterDocument(startAfter)
        .limit(customerListPageSize)
        .get();
  }

  /// War Room Lead Pulse: son eklenen lead'ler (updatedAt desc fallback; index gerekebilir).
  static Stream<QuerySnapshot<Map<String, dynamic>>>
      recentLeadsStream() async* {
    await ensureInitialized();
    if (!_initialized) yield* const Stream.empty();
    try {
      yield* FirebaseFirestore.instance
          .collection('customers')
          .orderBy('updatedAt', descending: true)
          .limit(25)
          .snapshots();
    } catch (e) {
      if (kDebugMode) debugPrint('recentLeadsStream: $e');
      yield* const Stream.empty();
    }
  }

  /// War Room: ofis aylık satış hedefi (app_settings/office_targets.monthlySalesTarget).
  static Stream<int> officeMonthlyTargetStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield 10;
      return;
    }
    yield* FirebaseFirestore.instance
        .collection('app_settings')
        .doc('office_targets')
        .snapshots()
        .map((s) => (s.data()?['monthlySalesTarget'] as num?)?.toInt() ?? 10);
  }

  /// Müşteri verisini dinlemek için (örnek: customers/demoCustomer1)
  static Stream<DocumentSnapshot<Map<String, dynamic>>> customerStream(
      String customerId) async* {
    await ensureInitialized();
    if (!_initialized) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance
        .collection('customers')
        .doc(customerId)
        .snapshots();
  }

  /// Çağrı özeti sihirbazından çıkarılan veriyi customers tablosuna yazar (yeni veya güncelleme).
  /// Veri izolasyonu: assignedAgentId ile danışman sadece kendi müşterisini yazabilir (Firestore rules).
  static Future<void> saveCallExtractionToCustomer({
    required String customerId,
    required String assignedAgentId,
    required String customerIntent,
    required String budgetRange,
    required String preferredRegions,
    required String urgency,
    required String nextStepSuggestion,
    required String sentiment,
    String? fullSummary,

    /// Kural tabanlı özet sinyalleri (`interestLevel`, `nextActionHint`, …).
    Map<String, dynamic>? lastCallSummarySignals,
  }) async {
    await ensureInitialized();
    _requireFirestoreReady();

    final ref =
        FirebaseFirestore.instance.collection('customers').doc(customerId);
    final Map<String, dynamic> data = {
      'assignedAgentId': assignedAgentId,
      'customerIntent': customerIntent,
      'budgetRange': budgetRange,
      'preferredRegions': preferredRegions,
      'urgency': urgency,
      'lastNextStepSuggestion': nextStepSuggestion,
      'lastSentiment': sentiment,
      if (fullSummary != null) 'lastCallSummary': fullSummary,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (lastCallSummarySignals != null && lastCallSummarySignals.isNotEmpty) {
      data['lastCallSummarySignals'] = {
        ...lastCallSummarySignals,
        'extractedAt': FieldValue.serverTimestamp(),
      };
    }
    await ref.set(data, SetOptions(merge: true));
  }

  /// Son görüşme transkript meta verisi (STT hazırlığı). `saveCallExtractionToCustomer` ile çakışmaz; merge.
  /// [snapshot] tam metin içeriyorsa Firestore belge boyutunu göz önünde bulundurun (büyük metinler için alt koleksiyon sonrası).
  static Future<void> mergeCustomerLastCallTranscript(
    String customerId,
    Map<String, dynamic> transcriptPayload,
  ) async {
    await ensureInitialized();
    _requireFirestoreReady();
    if (customerId.isEmpty) return;
    final ref = FirebaseFirestore.instance
        .collection(AppConstants.colCustomers)
        .doc(customerId);
    await ref.set(
      {
        'lastCallTranscript': transcriptPayload,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Müşteriye bağlı görev **tamamlandığında** (done: false → true): `lastInteractionAt` güncellenir.
  /// Böylece hatırlatıcılar, broker uyarıları ve sıcaklıktaki “son temas” girdileri deterministik olarak yenilenir.
  /// Sinyal alanlarına (çağrı özeti, skor) dokunulmaz. Görev yeniden açılırsa geri alınmaz.
  static Future<void> mergeCustomerCrmAfterTaskCompleted(
      String customerId) async {
    await ensureInitialized();
    _requireFirestoreReady();
    if (customerId.isEmpty) return;
    final ref = FirebaseFirestore.instance
        .collection(AppConstants.colCustomers)
        .doc(customerId);
    await ref.set(
      {
        'lastInteractionAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Özet kaydedildiğinde agent metriklerini artırır; dashboard Call Traffic & Deal Volume anlık güncellenir.
  static Future<void> incrementAgentStatsAfterSummary({
    required String agentId,
    int callMinutes = 5,
    double dealVolumeIncrement = 0.5,
  }) async {
    await ensureInitialized();
    _requireFirestoreReady();

    final ref = FirebaseFirestore.instance.collection('agents').doc(agentId);
    await ref.set(
      {
        'todayCallMinutes': FieldValue.increment(callMinutes),
        'totalCalls': FieldValue.increment(1),
        'activeDealsVolume': FieldValue.increment(dealVolumeIncrement),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Rehber/aramadan gelen yeni kişiyi uygulamaya (customers) kaydeder.
  /// assignedAgentId: giriş yapan danışman; source: 'rehber_aramasi' | 'uygulama'.
  static Future<String> createCustomer({
    required String assignedAgentId,
    required String fullName,
    required String primaryPhone,
    String? email,
    String? note,
    String source = 'uygulama',
  }) async {
    await ensureInitialized();
    if (!_initialized) throw StateError('Firestore not initialized');

    final col = FirebaseFirestore.instance.collection('customers');
    final ref = col.doc();
    final now = FieldValue.serverTimestamp();
    await ref.set({
      'assignedAgentId': assignedAgentId,
      'fullName': fullName,
      'primaryPhone': primaryPhone,
      if (email != null && email.isNotEmpty) 'email': email,
      'source': source,
      'createdAt': now,
      'updatedAt': now,
      'lastContactAt': now,
      if (note != null && note.isNotEmpty) 'lastCallSummary': note,
    });
    return ref.id;
  }

  /// calls koleksiyonu (liste için); SADECE super_admin "tüm ofisler" görünümü.
  /// Filtresiz olduğu için kurallar yalnızca super_admin'e izin verir. En yeni önce.
  static Stream<QuerySnapshot<Map<String, dynamic>>> callsStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance
        .collection('calls')
        .orderBy('createdAt', descending: true)
        .limit(callsLiveStreamLimit)
        .snapshots();
  }

  /// Ofise göre çağrı akışı (yönetici komuta merkezi — kendi ofisi). En yeni önce.
  ///
  /// Composite index: `calls`: officeId ASC, createdAt DESC.
  /// Kurallar: ofis yöneticisi `resource.data.officeId == users.officeId` ise okuyabilir.
  static Stream<QuerySnapshot<Map<String, dynamic>>> callsByOfficeStream(
    String officeId,
  ) async* {
    await ensureInitialized();
    if (!_initialized || officeId.isEmpty) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance
        .collection('calls')
        .where('officeId', isEqualTo: officeId)
        .orderBy('createdAt', descending: true)
        .limit(callsLiveStreamLimit)
        .snapshots();
  }

  /// Süper admin "tüm ofisler": filtresiz eski sayfa (Daha fazla yükle).
  static Future<QuerySnapshot<Map<String, dynamic>>> fetchAllCallsPage({
    required DocumentSnapshot<Map<String, dynamic>> startAfter,
  }) async {
    await ensureInitialized();
    if (!_initialized) {
      return FirebaseFirestore.instance.collection('calls').limit(0).get();
    }
    return FirebaseFirestore.instance
        .collection('calls')
        .orderBy('createdAt', descending: true)
        .startAfterDocument(startAfter)
        .limit(callsCommandPageSize)
        .get();
  }

  /// Ofis görünümü: eski sayfa (Daha fazla yükle).
  static Future<QuerySnapshot<Map<String, dynamic>>> fetchCallsByOfficePage(
    String officeId, {
    required DocumentSnapshot<Map<String, dynamic>> startAfter,
  }) async {
    await ensureInitialized();
    if (!_initialized || officeId.isEmpty) {
      return FirebaseFirestore.instance.collection('calls').limit(0).get();
    }
    return FirebaseFirestore.instance
        .collection('calls')
        .where('officeId', isEqualTo: officeId)
        .orderBy('createdAt', descending: true)
        .startAfterDocument(startAfter)
        .limit(callsCommandPageSize)
        .get();
  }

  /// Ofise göre `handoff_pending` — sistem telefonuna devredildi, sonuç girilmedi.
  ///
  /// Composite index: `calls`: officeId ASC, outcome ASC, createdAt DESC.
  static Stream<QuerySnapshot<Map<String, dynamic>>>
      callsHandoffPendingByOfficeStream(String officeId) async* {
    await ensureInitialized();
    if (!_initialized || officeId.isEmpty) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance
        .collection(AppConstants.colCalls)
        .where('officeId', isEqualTo: officeId)
        .where('outcome', isEqualTo: 'handoff_pending')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();
  }

  /// `app_config/superAdminGate.codeSha256` — süper admin "tüm ofisler" kapı kodu (hash).
  /// Kurallar: yalnızca super_admin okuyabilir/yazabilir. Yoksa null döner.
  static Future<String?> fetchSuperAdminGateHash() async {
    await ensureInitialized();
    if (!_initialized) return null;
    final snap = await FirebaseFirestore.instance
        .collection('app_config')
        .doc('superAdminGate')
        .get();
    final v = snap.data()?['codeSha256'];
    return v is String && v.isNotEmpty ? v : null;
  }

  /// Süper admin kapı kodu hash'ini yazar (yalnızca super_admin — kurallarla korunur).
  static Future<void> setSuperAdminGateHash(String codeSha256) async {
    await ensureInitialized();
    _requireFirestoreReady();
    await FirebaseFirestore.instance
        .collection('app_config')
        .doc('superAdminGate')
        .set({
      'codeSha256': codeSha256,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// `handoff_pending` — sistem telefonuna devredildi, danışman henüz sonuç girmedi.
  static Stream<QuerySnapshot<Map<String, dynamic>>>
      callsHandoffPendingStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance
        .collection(AppConstants.colCalls)
        .where('outcome', isEqualTo: 'handoff_pending')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();
  }

  /// Müşteriye bağlı CRM çağrı kayıtları (yönetici görünürlüğü).
  static Stream<QuerySnapshot<Map<String, dynamic>>> callsByCustomerStream(
    String customerId,
  ) async* {
    await ensureInitialized();
    if (!_initialized || customerId.isEmpty) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance
        .collection(AppConstants.colCalls)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(25)
        .snapshots();
  }

  /// Danışmana ait tüm çağrılar (gelen + giden), en yeni önce. Toplu SMS / CSV için.
  ///
  /// Composite index (deploy: `firebase deploy --only firestore:indexes`):
  /// collection `calls`: advisorId ASC, createdAt DESC — see repo `firestore.indexes.json`.
  static Stream<QuerySnapshot<Map<String, dynamic>>> callsByAdvisorStream(
      String advisorId) async* {
    await ensureInitialized();
    if (!_initialized || advisorId.isEmpty) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance
        .collection(AppConstants.colCalls)
        .where('advisorId', isEqualTo: advisorId)
        .orderBy('createdAt', descending: true)
        .limit(callsListPageSize)
        .snapshots();
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> fetchCallsByAdvisorPage(
    String advisorId, {
    required DocumentSnapshot<Map<String, dynamic>> startAfter,
  }) async {
    await ensureInitialized();
    if (!_initialized || advisorId.isEmpty) {
      return FirebaseFirestore.instance
          .collection(AppConstants.colCalls)
          .limit(0)
          .get();
    }
    return FirebaseFirestore.instance
        .collection(AppConstants.colCalls)
        .where('advisorId', isEqualTo: advisorId)
        .orderBy('createdAt', descending: true)
        .startAfterDocument(startAfter)
        .limit(callsListPageSize)
        .get();
  }

  /// Kayıtsız numaradan müşteri oluşturulduktan sonra ilgili çağrı
  /// dokümanlarını yeni müşteriye bağlar (Axion Agent hızlı kayıt akışı).
  /// En fazla 20 doküman tek batch'te güncellenir; hata tek tek yutulmaz,
  /// çağıran taraf kullanıcıya dürüst geri bildirim verir.
  static Future<void> linkCallsToCustomer({
    required List<String> callDocIds,
    required String customerId,
  }) async {
    if (callDocIds.isEmpty || customerId.isEmpty) return;
    await ensureInitialized();
    _requireFirestoreReady();
    final col = FirebaseFirestore.instance.collection(AppConstants.colCalls);
    final batch = FirebaseFirestore.instance.batch();
    for (final id in callDocIds.take(20)) {
      batch.set(
        col.doc(id),
        {
          'customerId': customerId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  /// Cihaz çağrı günlüğünden senkronize edilen kayıt (tekilleştirme için doc id verilir, merge).
  static Future<void> setCallRecordFromDevice({
    required String documentId,
    required String advisorId,
    required String direction,
    required int timestampMillis,
    int? durationSeconds,
    String? phoneNumber,
    String? contactDisplayName,
    String outcome = 'connected',
  }) async {
    await ensureInitialized();
    _requireFirestoreReady();
    final col = FirebaseFirestore.instance.collection(AppConstants.colCalls);
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    final ts = Timestamp.fromDate(dt);
    final resolvedOfficeId = await _officeIdForAdvisor(advisorId);
    await col.doc(documentId).set({
      'officeId': resolvedOfficeId,
      'advisorId': advisorId,
      'agentId': advisorId,
      'direction': direction,
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        'phoneNumber': phoneNumber,
      if (contactDisplayName != null && contactDisplayName.trim().isNotEmpty)
        'contactDisplayName': contactDisplayName.trim(),
      'startedAt': ts,
      'endedAt': ts,
      if (durationSeconds != null) 'durationSec': durationSeconds,
      'outcome': outcome,
      'createdAt': ts,
      'updatedAt': ts,
      'source': 'device',
    }, SetOptions(merge: true));
  }

  /// Sistem telefonuna geçmeden önce hafif CRM oturumu (gerçek GSM süresi burada ölçülmez).
  static Future<String?> createOutboundCallHandoffSession({
    required String advisorId,
    String? customerId,
    required String phoneNumber,
    required String startedFromScreen,
    Map<String, dynamic>? metadata,
    String officeId = '',
  }) async {
    await ensureInitialized();
    _requireFirestoreReady();
    final col = FirebaseFirestore.instance.collection(AppConstants.colCalls);
    final now = FieldValue.serverTimestamp();
    final resolvedOfficeId = await _officeIdForAdvisor(advisorId, officeId);
    final doc = await col.add({
      'officeId': resolvedOfficeId,
      'advisorId': advisorId,
      'agentId': advisorId,
      if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
      'phoneNumber': phoneNumber,
      'direction': 'outgoing',
      'source': 'system_handoff',
      'startedFromScreen': startedFromScreen,
      'startedAt': now,
      'createdAt': now,
      'updatedAt': now,
      'outcome': 'handoff_pending',
      'handoffMode': true,
      if (metadata != null && metadata.isNotEmpty) ...metadata,
    });
    return doc.id;
  }

  /// Handoff oturumuna hızlı sonuç (süre iddiası yok; gerçek görüşme cihazda).
  static Future<void> mergeOutboundCallQuickCapture({
    required String callSessionId,
    required String quickOutcomeCode,
    required String quickOutcomeLabelTr,
    String? quickNote,
    DateTime? followUpReminderAt,
  }) async {
    await ensureInitialized();
    _requireFirestoreReady();
    final doc = FirebaseFirestore.instance
        .collection(AppConstants.colCalls)
        .doc(callSessionId);
    if (kDebugMode) {
      AppLogger.d(
        '[fs] mergeOutboundCallQuickCapture path=${AppConstants.colCalls}/$callSessionId',
      );
    }
    await doc.set({
      'quickOutcomeCode': quickOutcomeCode,
      'quickOutcomeLabelTr': quickOutcomeLabelTr,
      if (quickNote != null && quickNote.trim().isNotEmpty)
        'quickCaptureNote': quickNote.trim(),
      'captureCompletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'outcome': quickOutcomeCode,
      'handoffMode': true,
      'quickCapturePending': false,
      'autoFallbackMinRecord': false,
      if (followUpReminderAt != null)
        'followUpReminderAt': Timestamp.fromDate(followUpReminderAt),
    }, SetOptions(merge: true));
  }

  /// Var olan `calls/{id}` belgesine kısa not ekler (hızlı kısayol; mevcut nota ekler).
  static Future<void> appendQuickCaptureNoteSnippet({
    required String callId,
    required String snippet,
  }) async {
    await ensureInitialized();
    _requireFirestoreReady();
    final line = snippet.trim();
    if (line.isEmpty) return;
    final ref =
        FirebaseFirestore.instance.collection(AppConstants.colCalls).doc(callId);
    final snap = await ref.get();
    if (!snap.exists) {
      AppLogger.w('appendQuickCaptureNoteSnippet: doc missing $callId');
      return;
    }
    final data = snap.data() ?? {};
    final existing = (data['quickCaptureNote'] as String? ?? '').trim();
    final merged = existing.isEmpty ? line : '$existing · $line';
    await ref.set(
      {
        'quickCaptureNote': merged,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static const int _callDedupeWindowMs = 2 * 60 * 1000;

  /// Aynı danışman + telefon + [createdAtMs] ±2 dk içinde oluşturulmuş çağrı (çift kayıt önleme).
  /// Index: `firestore.indexes.json` — advisorId + phoneNumber + createdAt.
  ///
  /// İndeks henüz deploy edilmediyse veya sorgu başarısızsa **null** döner; uygulama
  /// normal şekilde yeni doküman oluşturmaya devam eder (çökme yok).
  static Future<String?> findExistingCallInDedupeWindow({
    required String advisorId,
    required String phoneNumber,
    required int createdAtMs,
  }) async {
    try {
      await ensureInitialized();
      _requireFirestoreReady();
      final col = FirebaseFirestore.instance.collection(AppConstants.colCalls);
      final start = Timestamp.fromMillisecondsSinceEpoch(
          createdAtMs - _callDedupeWindowMs);
      final end = Timestamp.fromMillisecondsSinceEpoch(
          createdAtMs + _callDedupeWindowMs);
      final q = await col
          .where('advisorId', isEqualTo: advisorId)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThanOrEqualTo: end)
          .limit(1)
          .get();
      if (q.docs.isEmpty) return null;
      return q.docs.first.id;
    } on FirebaseException catch (e, st) {
      final msg = e.message?.toLowerCase() ?? '';
      final isIndexIssue = e.code == 'failed-precondition' ||
          e.code == 'unimplemented' ||
          msg.contains('index') ||
          msg.contains('requires an index');
      if (isIndexIssue) {
        AppLogger.w(
          'findExistingCallInDedupeWindow: indeks/sorgu hazır değil, dedupe atlanıyor (${e.code})',
          e,
          st,
        );
      } else {
        AppLogger.w('findExistingCallInDedupeWindow', e, st);
      }
      return null;
    } catch (e, st) {
      AppLogger.w('findExistingCallInDedupeWindow (dedupe atlandı)', e, st);
      return null;
    }
  }

  /// Handoff sırasında CRM oturumu oluşturulamadıysa tek `add` ile çağrı + hızlı sonuç (merge yok).
  static Future<String> createCallRecordWithQuickCapture({
    required String advisorId,
    String? customerId,
    required String phoneNumber,
    required String startedFromScreen,
    required String quickOutcomeCode,
    required String quickOutcomeLabelTr,
    String? quickNote,
    DateTime? followUpReminderAt,
  }) async {
    await ensureInitialized();
    _requireFirestoreReady();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final existingId = await findExistingCallInDedupeWindow(
      advisorId: advisorId,
      phoneNumber: phoneNumber,
      createdAtMs: nowMs,
    );
    if (existingId != null) {
      await mergeOutboundCallQuickCapture(
        callSessionId: existingId,
        quickOutcomeCode: quickOutcomeCode,
        quickOutcomeLabelTr: quickOutcomeLabelTr,
        quickNote: quickNote,
        followUpReminderAt: followUpReminderAt,
      );
      return existingId;
    }
    final now = FieldValue.serverTimestamp();
    final col = FirebaseFirestore.instance.collection(AppConstants.colCalls);
    final resolvedOfficeId = await _officeIdForAdvisor(advisorId);
    final doc = await col.add({
      'officeId': resolvedOfficeId,
      'advisorId': advisorId,
      'agentId': advisorId,
      if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
      'phoneNumber': phoneNumber,
      'direction': 'outgoing',
      'source': 'system_handoff',
      'crmSessionCreationFailed': true,
      'startedFromScreen': startedFromScreen,
      'startedAt': now,
      'createdAt': now,
      'updatedAt': now,
      'outcome': quickOutcomeCode,
      'handoffMode': true,
      'quickOutcomeCode': quickOutcomeCode,
      'quickOutcomeLabelTr': quickOutcomeLabelTr,
      if (quickNote != null && quickNote.trim().isNotEmpty)
        'quickCaptureNote': quickNote.trim(),
      'captureCompletedAt': now,
      if (followUpReminderAt != null)
        'followUpReminderAt': Timestamp.fromDate(followUpReminderAt),
    });
    return doc.id;
  }

  /// [localDraftId] + [advisorId] ile deterministik `calls/{id}` — tekrar yazımda çift kayıt oluşmaz.
  static String stableFallbackCallDocumentId(
      String localDraftId, String advisorId) {
    final digest = sha256.convert(utf8.encode('$localDraftId|$advisorId'));
    return 'hf_${digest.toString()}';
  }

  /// Minimum handoff satırı — [documentId] sabit kaldığı için çevrimdışı tekrar denemelerde idempotent.
  static Future<String> upsertMinimalFallbackCallRecord({
    required String documentId,
    required String advisorId,
    String? customerId,
    required String phoneNumber,
    required String startedFromScreen,
    bool flushedFromOfflineQueue = false,
  }) async {
    await ensureInitialized();
    _requireFirestoreReady();
    final now = FieldValue.serverTimestamp();
    final col = FirebaseFirestore.instance.collection(AppConstants.colCalls);
    final resolvedOfficeId = await _officeIdForAdvisor(advisorId);
    await col.doc(documentId).set({
      'officeId': resolvedOfficeId,
      'advisorId': advisorId,
      'agentId': advisorId,
      if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
      'phoneNumber': phoneNumber,
      'direction': 'outgoing',
      'source': 'system_handoff',
      'crmSessionCreationFailed': true,
      'autoFallbackMinRecord': true,
      'startedFromScreen': startedFromScreen,
      'startedAt': now,
      'createdAt': now,
      'updatedAt': now,
      'outcome': 'no_capture',
      'handoffMode': true,
      'quickCapturePending': true,
      if (flushedFromOfflineQueue) 'syncedFromOfflineFallbackQueue': true,
    }, SetOptions(merge: true));
    return documentId;
  }

  /// CRM handoff başarısız + kullanıcı hızlı kayıt yapmadan önce: minimum `calls` satırı (veri kaybını önler).
  static Future<String> createMinimalFallbackCallRecord({
    required String advisorId,
    required String localDraftId,
    String? customerId,
    required String phoneNumber,
    required String startedFromScreen,
  }) async {
    final docId = stableFallbackCallDocumentId(localDraftId, advisorId);
    return upsertMinimalFallbackCallRecord(
      documentId: docId,
      advisorId: advisorId,
      customerId: customerId,
      phoneNumber: phoneNumber,
      startedFromScreen: startedFromScreen,
    );
  }

  /// Müşteri kartına hızlı temas + not (sıcaklık sinyali opsiyonel).
  static Future<void> mergeCustomerAfterQuickCallCapture({
    required String customerId,
    required String advisorId,
    required String noteLine,
    Map<String, dynamic>? lastCallSummarySignalsPayload,
  }) async {
    await ensureInitialized();
    _requireFirestoreReady();
    final ref = FirebaseFirestore.instance
        .collection(AppConstants.colCustomers)
        .doc(customerId);
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'lastInteractionAt': FieldValue.serverTimestamp(),
    };
    if (lastCallSummarySignalsPayload != null &&
        lastCallSummarySignalsPayload.isNotEmpty) {
      data['lastCallSummarySignals'] = {
        ...lastCallSummarySignalsPayload,
        'extractedAt': FieldValue.serverTimestamp(),
      };
    }
    await ref.set(data, SetOptions(merge: true));
    await saveNote(
        customerId: customerId, content: noteLine, advisorId: advisorId);
  }

  /// Arama bittiğinde danışmanın "Tüm Çağrılar" listesinde görünmesi için calls koleksiyonuna kayıt ekler.
  static Future<void> createCallRecord({
    required String advisorId,
    required String direction,
    required String outcome,
    int? durationSeconds,
    String? phoneNumber,
    String? customerId,
    String officeId = '',
  }) async {
    await ensureInitialized();
    _requireFirestoreReady();
    final col = FirebaseFirestore.instance.collection(AppConstants.colCalls);
    final now = FieldValue.serverTimestamp();
    final resolvedOfficeId = await _officeIdForAdvisor(advisorId, officeId);
    await col.add({
      'officeId': resolvedOfficeId,
      'advisorId': advisorId,
      'agentId': advisorId,
      if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
      'direction': direction,
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        'phoneNumber': phoneNumber,
      'startedAt': now,
      'endedAt': now,
      if (durationSeconds != null) 'durationSec': durationSeconds,
      'outcome': outcome,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  /// Aynı veri, agentId alanı kullanılıyorsa (geriye uyumluluk).
  ///
  /// Composite index: collection `calls`: agentId ASC, createdAt DESC — `firestore.indexes.json`.
  static Stream<QuerySnapshot<Map<String, dynamic>>> callsByAgentIdStream(
      String agentId) async* {
    await ensureInitialized();
    if (!_initialized || agentId.isEmpty) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance
        .collection(AppConstants.colCalls)
        .where('agentId', isEqualTo: agentId)
        .orderBy('createdAt', descending: true)
        .limit(callsListPageSize)
        .snapshots();
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> fetchCallsByAgentIdPage(
    String agentId, {
    required DocumentSnapshot<Map<String, dynamic>> startAfter,
  }) async {
    await ensureInitialized();
    if (!_initialized || agentId.isEmpty) {
      return FirebaseFirestore.instance
          .collection(AppConstants.colCalls)
          .limit(0)
          .get();
    }
    return FirebaseFirestore.instance
        .collection(AppConstants.colCalls)
        .where('agentId', isEqualTo: agentId)
        .orderBy('createdAt', descending: true)
        .startAfterDocument(startAfter)
        .limit(callsListPageSize)
        .get();
  }

  /// KPI sayaç yenileme aralığı: aggregate count sorgusu ile periyodik tazeleme.
  /// Tam koleksiyon listener'ına göre ağ/batarya/okuma maliyeti dramatik düşük
  /// (count() sunucuda sayar; dokümanlar istemciye inmez).
  static const Duration _countRefreshInterval = Duration(minutes: 2);

  /// Aggregate count() tabanlı sayaç stream'i.
  /// - İlk değeri hemen verir, sonra ön plandayken periyodik tazeler.
  /// - Arka planda sorgu atmaz (batarya disiplini).
  /// - Hata durumunda son değeri korur, sonraki turda yeniden dener.
  static Stream<int> _aggregateCountStream(
    Query<Map<String, dynamic>> Function() queryBuilder,
  ) async* {
    var hasEmitted = false;
    while (true) {
      if (!AppLifecyclePowerService.isInBackground.value) {
        try {
          final snap = await queryBuilder().count().get();
          yield snap.count ?? 0;
          hasEmitted = true;
        } catch (e) {
          AppLogger.w('[firestore] aggregate count failed: $e');
          if (!hasEmitted) {
            yield 0;
            hasEmitted = true;
          }
        }
      }
      await Future<void>.delayed(_countRefreshInterval);
    }
  }

  /// calls koleksiyonundaki döküman sayısı (Call Traffic için).
  static Stream<int> callsCountStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield 0;
      return;
    }
    yield* _aggregateCountStream(
      () => FirebaseFirestore.instance.collection('calls'),
    );
  }

  /// Bugünkü çağrı sayısı (createdAt >= bugün 00:00). KPI "Çağrı" chip'i için anlamlı.
  static Stream<int> todayCallsCountStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield 0;
      return;
    }
    // Sorgu her tazelemede yeniden kurulur: gece yarısı geçişinde "bugün"
    // otomatik güncellenir (eski sürümde gün sabitti).
    yield* _aggregateCountStream(() {
      final now = DateTime.now();
      final startTs = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
      return FirebaseFirestore.instance
          .collection(AppConstants.colCalls)
          .where('createdAt', isGreaterThanOrEqualTo: startTs);
    });
  }

  /// Açık görev sayısı (done == false). KPI "Follow-up" için.
  static Stream<int> openTasksCountStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield 0;
      return;
    }
    yield* _aggregateCountStream(
      () => FirebaseFirestore.instance
          .collection(AppConstants.colTasks)
          .where('done', isEqualTo: false),
    );
  }

  /// deals koleksiyonundaki döküman sayısı (Deal Volume için).
  static Stream<int> dealsCountStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield 0;
      return;
    }
    yield* _aggregateCountStream(
      () => FirebaseFirestore.instance.collection('deals'),
    );
  }

  /// Raporlar ekranı: en az bir çağrı özeti var mı (örnek, limit 1).
  static Stream<QuerySnapshot<Map<String, dynamic>>>
      callSummariesSampleStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance
        .collection('call_summaries')
        .limit(1)
        .snapshots();
  }

  /// Raporlar ekranı: en az bir işlem kaydı var mı (örnek, limit 1).
  static Stream<QuerySnapshot<Map<String, dynamic>>>
      dealsSampleStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance.collection('deals').limit(1).snapshots();
  }

  // ---------- Call summaries ----------
  static Stream<QuerySnapshot<Map<String, dynamic>>> callSummariesByCallStream(
      String callId) async* {
    await ensureInitialized();
    if (!_initialized) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance
        .collection('call_summaries')
        .where('callId', isEqualTo: callId)
        .limit(5)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      callSummariesByCustomerStream(String customerId) async* {
    await ensureInitialized();
    if (!_initialized) yield* const Stream.empty();
    yield* FirebaseFirestore.instance
        .collection('call_summaries')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Bu hafta (Pazartesi 00:00’dan itibaren) danışmanın kaydettiği çağrı özeti sayısı.
  /// Haftalık hedef kartı için canlı veri.
  static Stream<int> agentWeeklyCallCountStream(String agentId) async* {
    await ensureInitialized();
    if (!_initialized || agentId.isEmpty) {
      yield 0;
      return;
    }
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final startTimestamp = Timestamp.fromDate(startOfWeek);
    yield* FirebaseFirestore.instance
        .collection('call_summaries')
        .where('assignedAgentId', isEqualTo: agentId)
        .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Kaydetme başarısız olursa retry ile tekrar dene (Self-healing / AI Call Brain).
  static Future<void> saveCallSummaryDoc(
    Map<String, dynamic> data, {
    int retries = 3,
  }) async {
    await ensureInitialized();
    _requireFirestoreReady();
    final col = FirebaseFirestore.instance.collection('call_summaries');
    Exception? last;
    for (var i = 0; i < retries; i++) {
      try {
        final id = data['id'] as String? ?? col.doc().id;
        await col.doc(id).set({
          ...data,
          'id': id,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      } catch (e, st) {
        last = e is Exception ? e : Exception(e.toString());
        if (kDebugMode) debugPrint('saveCallSummaryDoc retry ${i + 1}: $e $st');
        if (i < retries - 1) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
    }
    if (last != null) throw last;
  }

  static Future<String> saveStructuredCallSummaryDoc({
    String? id,
    required String assignedAgentId,
    String? callId,
    String? customerId,
    String? phoneNumber,
    required String customerIntent,
    required String budgetRange,
    required String preferredRegions,
    required String urgency,
    required String nextStepSuggestion,
    required String sentiment,
    required String fullSummary,
    required bool detachedFromCustomer,
  }) async {
    final summaryId = id ??
        FirebaseFirestore.instance
            .collection(AppConstants.colCallSummaries)
            .doc()
            .id;
    await saveCallSummaryDoc({
      'id': summaryId,
      'callId': callId,
      if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        'phoneNumber': phoneNumber,
      'agentId': assignedAgentId,
      'assignedAgentId': assignedAgentId,
      'customerIntent': customerIntent,
      'budgetRange': budgetRange,
      'preferredRegions': preferredRegions,
      'urgency': urgency,
      'nextStepSuggestion': nextStepSuggestion,
      'sentiment': sentiment,
      'shortSummary': fullSummary,
      'longSummary': fullSummary,
      'detachedFromCustomer': detachedFromCustomer,
      'source': 'post_call_wizard',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return summaryId;
  }

  static Future<void> mergePostCallSummaryIntoCallRecord({
    required String callSessionId,
    required String fullSummary,
    required String nextStepSuggestion,
    required String sentiment,
    bool detachedFromCustomer = false,
    String? customerId,
  }) async {
    await ensureInitialized();
    _requireFirestoreReady();
    if (callSessionId.trim().isEmpty) return;
    await FirebaseFirestore.instance
        .collection(AppConstants.colCalls)
        .doc(callSessionId.trim())
        .set({
      'postCallSummaryText': fullSummary,
      'postCallNextStepSuggestion': nextStepSuggestion,
      'postCallSentiment': sentiment,
      'postCallSummarySavedAt': FieldValue.serverTimestamp(),
      'postCallSummaryDetached': detachedFromCustomer,
      if (customerId != null && customerId.trim().isNotEmpty)
        'customerId': customerId.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------- Tasks ----------
  static Stream<QuerySnapshot<Map<String, dynamic>>> tasksByAdvisorStream(
      String advisorId) async* {
    await ensureInitialized();
    if (!_initialized) yield* const Stream.empty();
    yield* FirebaseFirestore.instance
        .collection('tasks')
        .where('advisorId', isEqualTo: advisorId)
        .orderBy('dueAt', descending: false)
        .limit(100)
        .snapshots();
  }

  static Future<void> setTask(Map<String, dynamic> data) async {
    await ensureInitialized();
    _requireFirestoreReady();
    final id = data['id'] as String? ??
        FirebaseFirestore.instance.collection('tasks').doc().id;
    final advisorId = data['advisorId'] as String?;
    final merged = <String, dynamic>{
      ...data,
      'id': id,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (advisorId != null && advisorId.isNotEmpty) {
      merged['userId'] = advisorId;
    }
    final due = merged['dueAt'] ?? merged['dueDate'];
    if (due != null) {
      merged['dueDate'] = due;
      merged['dueAt'] = due;
    }
    final done = merged['done'];
    if (done != null) {
      merged['completed'] = done == true;
    }
    if (!merged.containsKey('createdAt')) {
      merged['createdAt'] = FieldValue.serverTimestamp();
    }
    await FirebaseFirestore.instance
        .collection(AppConstants.colTasks)
        .doc(id)
        .set(
          merged,
          SetOptions(merge: true),
        );
  }

  static Future<void> deleteTask(String taskId) async {
    await ensureInitialized();
    _requireFirestoreReady();
    final id = taskId.trim();
    if (id.isEmpty) {
      throw StateError('Silinecek görev bulunamadı.');
    }
    await FirebaseFirestore.instance
        .collection(AppConstants.colTasks)
        .doc(id)
        .delete();
  }

  /// Müşteriye bağlı açık görev sayısı (`customerId` + done/completed değil).
  static Future<int> countOpenTasksForCustomer(String customerId) async {
    await ensureInitialized();
    if (!_initialized || customerId.isEmpty) return 0;
    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.colTasks)
          .where('customerId', isEqualTo: customerId)
          .limit(100)
          .get();
      return snap.docs.where((d) {
        final data = d.data();
        final done = data['done'] ?? data['completed'];
        return done != true;
      }).length;
    } catch (e, st) {
      if (kDebugMode) debugPrint('countOpenTasksForCustomer: $e $st');
      return 0;
    }
  }

  /// Son [days] gün içinde eklenen not sayısı (sıcaklık skoru için).
  static Future<int> countRecentNotesForCustomer(String customerId,
      {int days = 30}) async {
    await ensureInitialized();
    if (!_initialized || customerId.isEmpty) return 0;
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.colNotes)
          .where('customerId', isEqualTo: customerId)
          .limit(100)
          .get();
      return snap.docs.where((d) {
        final t = d.data()['createdAt'];
        if (t is Timestamp) return t.toDate().isAfter(cutoff);
        return false;
      }).length;
    } catch (e, st) {
      if (kDebugMode) debugPrint('countRecentNotesForCustomer: $e $st');
      return 0;
    }
  }

  /// Manuel ilan ekleme (CRM portföyü; içe aktarma motorundan ayrı).
  static Future<String> createListingManual({
    required String ownerUserId,
    required String title,
    required String price,
    required String location,
    String source = 'manual',
  }) async {
    await ensureInitialized();
    if (!_initialized) throw StateError('Firestore not initialized');
    final ref =
        FirebaseFirestore.instance.collection(AppConstants.colListings).doc();
    final now = FieldValue.serverTimestamp();
    await ref.set({
      'ownerUserId': ownerUserId,
      'title': title,
      'price': price,
      'location': location,
      'source': source,
      'sourcePlatform': 'internal',
      'sourceListingId': ref.id,
      'isOwnedByOffice': true,
      'syncStatus': 'synced',
      'createdAt': now,
      'updatedAt': now,
    });
    return ref.id;
  }

  // ---------- Visits ----------
  static Stream<QuerySnapshot<Map<String, dynamic>>> visitsByCustomerStream(
      String customerId) async* {
    await ensureInitialized();
    if (!_initialized) yield* const Stream.empty();
    yield* FirebaseFirestore.instance
        .collection('visits')
        .where('customerId', isEqualTo: customerId)
        .orderBy('scheduledAt', descending: true)
        .limit(50)
        .snapshots();
  }

  static Future<void> saveVisit({
    required String customerId,
    required String advisorId,
    required DateTime scheduledAt,
    String? notes,
    String? listingId,
  }) async {
    await ensureInitialized();
    _requireFirestoreReady();
    final col = FirebaseFirestore.instance.collection('visits');
    await col.add({
      'customerId': customerId,
      'advisorId': advisorId,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (listingId != null && listingId.isNotEmpty) 'listingId': listingId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------- Offers ----------
  static Stream<QuerySnapshot<Map<String, dynamic>>> offersByCustomerStream(
      String customerId) async* {
    await ensureInitialized();
    if (!_initialized) yield* const Stream.empty();
    yield* FirebaseFirestore.instance
        .collection('offers')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  static Future<void> saveOffer({
    required String customerId,
    required String advisorId,
    required double amount,
    String? currency,
    String? listingId,
    String? notes,
  }) async {
    await ensureInitialized();
    _requireFirestoreReady();
    final col = FirebaseFirestore.instance.collection('offers');
    await col.add({
      'customerId': customerId,
      'advisorId': advisorId,
      'amount': amount,
      'price': amount,
      'currency': currency ?? 'TRY',
      if (listingId != null && listingId.isNotEmpty) 'listingId': listingId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------- Notes (Customer Timeline) ----------
  static Stream<QuerySnapshot<Map<String, dynamic>>> notesByCustomerStream(
      String customerId) async* {
    await ensureInitialized();
    if (!_initialized) yield* const Stream.empty();
    yield* FirebaseFirestore.instance
        .collection('notes')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Müşteriye not ekler. advisorId giriş yapan kullanıcı uid olmalı (Firestore rules).
  static Future<void> saveNote({
    required String customerId,
    required String content,
    required String advisorId,
  }) async {
    await ensureInitialized();
    _requireFirestoreReady();
    final col = FirebaseFirestore.instance.collection('notes');
    await col.add({
      'customerId': customerId,
      'content': content,
      'advisorId': advisorId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------- Pipeline items ----------
  static Stream<QuerySnapshot<Map<String, dynamic>>>
      pipelineItemsByAdvisorStream(String advisorId) async* {
    await ensureInitialized();
    if (!_initialized) yield* const Stream.empty();
    yield* FirebaseFirestore.instance
        .collection('pipeline_items')
        .where('advisorId', isEqualTo: advisorId)
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .snapshots();
  }

  static Future<void> setPipelineItem(Map<String, dynamic> data) async {
    await ensureInitialized();
    _requireFirestoreReady();
    final col = FirebaseFirestore.instance.collection('pipeline_items');
    final id = data['id'] as String? ?? col.doc().id;
    await col.doc(id).set({
      ...data,
      'id': id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updatePipelineItemStage(
      String itemId, String stageId) async {
    await ensureInitialized();
    _requireFirestoreReady();
    await FirebaseFirestore.instance
        .collection('pipeline_items')
        .doc(itemId)
        .update({
      'stage': stageId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------- Notifications (in-app) ----------
  static Stream<QuerySnapshot<Map<String, dynamic>>> notificationsByUserStream(
      String userId) async* {
    await ensureInitialized();
    if (!_initialized) yield* const Stream.empty();
    yield* FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }
}
