import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:emlakmaster_mobile/features/contact_save/data/contact_permission_helper.dart';
import 'package:emlakmaster_mobile/features/contact_save/domain/contact_save_request.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter_contacts/flutter_contacts.dart';

/// Rehbere kaydetme sonucu (özel izin akışı için).
enum SaveToDeviceResult {
  success,
  denied,
  permanentlyDenied,
}

/// Rehbere (cihaz) ve uygulamaya (Firestore) kaydetme.
class SaveContactService {
  SaveContactService._();
  static final SaveContactService instance = SaveContactService._();

  /// iOS’ta rehber notu eklemek ek entitlement ister; 2.x’te atlanır.
  static bool get _skipDeviceNotes =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.iOS;

  /// Cihaz rehberine kişi ekler. Özel izin akışı: reddedilirse veya kalıcı red ise
  /// UI'da "Ayarlara git" gösterilebilir.
  Future<SaveToDeviceResult> saveToDevice(ContactSaveRequest request) async {
    try {
      final permissionResult =
          await ContactPermissionHelper.instance.requestContactPermission();
      if (permissionResult != ContactPermissionResult.granted) {
        if (kDebugMode) debugPrint('SaveContactService: rehber izni yok');
        return permissionResult == ContactPermissionResult.permanentlyDenied
            ? SaveToDeviceResult.permanentlyDenied
            : SaveToDeviceResult.denied;
      }
      final parts = request.fullName.trim().split(RegExp(r'\s+'));
      final first = parts.isNotEmpty ? parts.first : request.fullName;
      final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      final notes = <Note>[];
      if (!_skipDeviceNotes &&
          request.note != null &&
          request.note!.isNotEmpty) {
        notes.add(Note(note: request.note!));
      }

      final contact = Contact(
        name: Name(
          first: first,
          last: last.isEmpty ? null : last,
        ),
        phones: [Phone(number: request.primaryPhone)],
        emails: request.email != null && request.email!.isNotEmpty
            ? [Email(address: request.email!)]
            : const [],
        notes: notes,
      );
      await FlutterContacts.create(contact);
      return SaveToDeviceResult.success;
    } catch (e) {
      if (kDebugMode) debugPrint('SaveContactService saveToDevice: $e');
      return SaveToDeviceResult.denied;
    }
  }

  /// Uygulama (Firestore customers) kaydı. assignedAgentId gerekir.
  Future<String?> saveToApp(
    ContactSaveRequest request, {
    required String assignedAgentId,
    String source = 'uygulama',
  }) async {
    try {
      await FirestoreService.ensureInitialized();
      final id = await FirestoreService.createCustomer(
        assignedAgentId: assignedAgentId,
        fullName: request.fullName,
        primaryPhone: request.primaryPhone,
        email: request.email,
        note: request.note,
        source: source,
      );
      return id;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('SaveContactService saveToApp Firebase: ${e.code} ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('SaveContactService saveToApp: $e');
      return null;
    }
  }
}
