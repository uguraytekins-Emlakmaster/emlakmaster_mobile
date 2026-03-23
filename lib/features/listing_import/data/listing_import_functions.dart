import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Callable — bölge `europe-west1` (Functions ile uyumlu).
class ListingImportFunctions {
  ListingImportFunctions._();
  static final ListingImportFunctions instance = ListingImportFunctions._();

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<String?> enqueueUrlImport({
    required String url,
    String officeId = '',
    String importMode = 'skip_duplicates',
    bool requireApproval = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('not_signed_in');

    final callable = _functions.httpsCallable('enqueueUrlImport');
    final res = await callable.call<Map<String, dynamic>>({
      'url': url,
      'officeId': officeId,
      'importMode': importMode,
      'requireApproval': requireApproval,
    });
    final data = res.data;
    return data['taskId'] as String?;
  }

  /// [storagePath] örn. `users/{uid}/imports/foo.csv`
  Future<String?> enqueueFileImport({
    required String storagePath,
    required String fileName,
    required Map<String, String> mapping,
    String officeId = '',
    String platform = 'sahibinden',
    String importMode = 'skip_duplicates',
    bool requireApproval = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('not_signed_in');

    final callable = _functions.httpsCallable('enqueueFileImport');
    final res = await callable.call<Map<String, dynamic>>({
      'storagePath': storagePath,
      'fileName': fileName,
      'mapping': mapping,
      'officeId': officeId,
      'platform': platform,
      'importMode': importMode,
      'requireApproval': requireApproval,
    });
    final data = res.data;
    return data['taskId'] as String?;
  }

  /// Tekil ilan senkronu (hash diff — sunucu).
  Future<Map<String, dynamic>> runIntegrationListingSync({
    required String listingDocId,
    required Map<String, dynamic> remoteSnapshot,
  }) async {
    final callable = _functions.httpsCallable('runIntegrationListingSync');
    final res = await callable.call<Map<String, dynamic>>({
      'listingDocId': listingDocId,
      'remoteSnapshot': remoteSnapshot,
    });
    return res.data;
  }
}
