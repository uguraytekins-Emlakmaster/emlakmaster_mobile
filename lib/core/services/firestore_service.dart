import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, defaultTargetPlatform, TargetPlatform;
import 'package:emlakmaster_mobile/firebase_options.dart';

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
      // Çift konfigürasyon addAppToAppDictionary crash'ine yol açar; yalnızca henüz yoksa başlat.
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        } catch (e) {
          // Native tarafta zaten konfigüre edilmiş olabilir (plugin sırası); çökmemek için devam et.
          if (Firebase.apps.isEmpty) rethrow;
          if (kDebugMode) debugPrint('FirestoreService: Firebase zaten konfigüre (native).');
        }
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
      if (kDebugMode) debugPrint('FirestoreService: Offline persistence enabled.');
    } catch (e) {
      if (kDebugMode) debugPrint('FirestoreService init: $e');
    }
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
    yield* FirebaseFirestore.instance.collection('listings').snapshots();
  }

  /// Tek ilan dokümanı (detay sayfası için).
  static Stream<DocumentSnapshot<Map<String, dynamic>>> listingDocStream(String id) async* {
    await ensureInitialized();
    if (!_initialized || id.isEmpty) return;
    yield* FirebaseFirestore.instance.collection('listings').doc(id).snapshots();
  }

  /// agents koleksiyonu (danışmanlar) için stream
  static Stream<QuerySnapshot<Map<String, dynamic>>> agentsStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance.collection('agents').snapshots();
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

  /// Bir çağrı kapandığında, ilgili agent dokümanına özet yazar ve metrikleri günceller.
  static Future<void> saveCallSummary({
    required String agentId,
    required String intentSummary,
    required List<String> criticalNotes,
    required String nextAction,
  }) async {
    await ensureInitialized();
    if (!_initialized) return;

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
    if (!_initialized) return;

    final ref = FirebaseFirestore.instance.collection('agents').doc(agentId);
    await ref.set(
      {
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Tüm müşteriler (kurala göre danışman sadece kendininkileri görür).
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
  }) async {
    await ensureInitialized();
    if (!_initialized) return;

    final ref = FirebaseFirestore.instance.collection('customers').doc(customerId);
    await ref.set(
      {
        'assignedAgentId': assignedAgentId,
        'customerIntent': customerIntent,
        'budgetRange': budgetRange,
        'preferredRegions': preferredRegions,
        'urgency': urgency,
        'lastNextStepSuggestion': nextStepSuggestion,
        'lastSentiment': sentiment,
        if (fullSummary != null) 'lastCallSummary': fullSummary,
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
    if (!_initialized) return;

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

  /// calls koleksiyonu (liste için); yönetici paneli vb. En yeni önce.
  static Stream<QuerySnapshot<Map<String, dynamic>>> callsStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance
        .collection('calls')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();
  }

  /// calls koleksiyonundaki döküman sayısı (Call Traffic için).
  static Stream<int> callsCountStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield 0;
      return;
    }
    yield* FirebaseFirestore.instance
        .collection('calls')
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// deals koleksiyonundaki döküman sayısı (Deal Volume için).
  static Stream<int> dealsCountStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield 0;
      return;
    }
    yield* FirebaseFirestore.instance
        .collection('deals')
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// news koleksiyonu (AI News Insight); yoksa boş liste.
  static Stream<QuerySnapshot<Map<String, dynamic>>> newsStream() async* {
    await ensureInitialized();
    if (!_initialized) {
      yield* const Stream.empty();
      return;
    }
    yield* FirebaseFirestore.instance
        .collection('news')
        .limit(20)
        .snapshots();
  }

  // ---------- Call summaries (AI Call Brain) ----------
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

  static Stream<QuerySnapshot<Map<String, dynamic>>> callSummariesByCustomerStream(
      String customerId) async* {
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
    if (!_initialized) return;
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
    if (!_initialized) return;
    final id = data['id'] as String? ?? FirebaseFirestore.instance.collection('tasks').doc().id;
    await FirebaseFirestore.instance.collection('tasks').doc(id).set({
      ...data,
      'id': id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
    if (!_initialized) return;
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
    if (!_initialized) return;
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
    if (!_initialized) return;
    final col = FirebaseFirestore.instance.collection('notes');
    await col.add({
      'customerId': customerId,
      'content': content,
      'advisorId': advisorId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------- Pipeline items ----------
  static Stream<QuerySnapshot<Map<String, dynamic>>> pipelineItemsByAdvisorStream(
      String advisorId) async* {
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
    if (!_initialized) return;
    final col = FirebaseFirestore.instance.collection('pipeline_items');
    final id = data['id'] as String? ?? col.doc().id;
    await col.doc(id).set({
      ...data,
      'id': id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updatePipelineItemStage(String itemId, String stageId) async {
    await ensureInitialized();
    if (!_initialized) return;
    await FirebaseFirestore.instance.collection('pipeline_items').doc(itemId).update({
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
