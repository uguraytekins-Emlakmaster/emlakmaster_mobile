import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart' as perm;

/// Rehber izni sonucu: başarılı, reddedildi, kalıcı red (ayarlardan açılmalı).
enum ContactPermissionResult {
  granted,
  denied,
  permanentlyDenied,
}

/// Özel rehber izin akışı: istek, durum kontrolü, ayarlara yönlendirme.
class ContactPermissionHelper {
  ContactPermissionHelper._();
  static final ContactPermissionHelper instance = ContactPermissionHelper._();

  /// Rehber iznini iste (flutter_contacts 2.x API).
  Future<ContactPermissionResult> requestContactPermission() async {
    final status = await FlutterContacts.permissions.request(
      PermissionType.readWrite,
    );
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return ContactPermissionResult.granted;
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
        return ContactPermissionResult.permanentlyDenied;
      case PermissionStatus.denied:
      case PermissionStatus.notDetermined:
        // iOS/Android farkı için permission_handler ile kalıcı red teyidi
        final ph = await perm.Permission.contacts.status;
        if (ph.isPermanentlyDenied) {
          return ContactPermissionResult.permanentlyDenied;
        }
        return ContactPermissionResult.denied;
    }
  }

  /// Mevcut rehber izni durumu (soru göstermeden).
  Future<ContactPermissionResult> getContactPermissionStatus() async {
    final status = await FlutterContacts.permissions.check(
      PermissionType.readWrite,
    );
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return ContactPermissionResult.granted;
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
        return ContactPermissionResult.permanentlyDenied;
      default:
        final ph = await perm.Permission.contacts.status;
        if (ph.isPermanentlyDenied) {
          return ContactPermissionResult.permanentlyDenied;
        }
        if (ph.isGranted) return ContactPermissionResult.granted;
        return ContactPermissionResult.denied;
    }
  }

  /// Uygulama ayarlarını açar (kullanıcı rehber iznini manuel açabilsin).
  Future<bool> openSystemSettings() => perm.openAppSettings();
}
