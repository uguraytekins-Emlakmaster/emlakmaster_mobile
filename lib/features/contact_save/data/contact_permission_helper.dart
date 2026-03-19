import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

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

  /// Rehber iznini iste. Önce flutter_contacts ile ister; reddedilirse
  /// permission_handler ile kalıcı red kontrolü yapar.
  Future<ContactPermissionResult> requestContactPermission() async {
    final granted = await FlutterContacts.requestPermission();
    if (granted) return ContactPermissionResult.granted;

    final status = await Permission.contacts.status;
    if (status.isPermanentlyDenied) {
      return ContactPermissionResult.permanentlyDenied;
    }
    return ContactPermissionResult.denied;
  }

  /// Mevcut rehber izni durumu (soru göstermeden).
  Future<ContactPermissionResult> getContactPermissionStatus() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) return ContactPermissionResult.granted;
    if (status.isPermanentlyDenied) return ContactPermissionResult.permanentlyDenied;
    return ContactPermissionResult.denied;
  }

  /// Uygulama ayarlarını açar (kullanıcı rehber iznini manuel açabilsin).
  Future<bool> openSystemSettings() => openAppSettings();
}
