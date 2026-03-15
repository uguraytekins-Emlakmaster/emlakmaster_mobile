import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// WhatsApp wa.me link oluşturur ve açar. Türkiye için 90 ön eki.
/// Telefon: 5XX XXX XX XX veya 05XXXXXXXXX formatında olabilir.
class WhatsAppLauncher {
  WhatsAppLauncher._();

  /// Sadece rakamları alır (0, boşluk vb. kaldırılır).
  static String _digitsOnly(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  /// Türkiye numarası için wa.me URL: 90 + 5XXXXXXXXX (baştaki 0 atılır).
  static String urlForTurkishNumber(String phone) {
    final digits = _digitsOnly(phone);
    if (digits.isEmpty) return '';
    String normalized = digits;
    if (normalized.startsWith('0')) normalized = normalized.substring(1);
    if (!normalized.startsWith('90') && normalized.length >= 10) {
      normalized = '90$normalized';
    }
    return 'https://wa.me/$normalized';
  }

  /// WhatsApp'ı açar. Numara geçersizse false döner.
  static Future<bool> openChat(String phone) async {
    final uri = urlForTurkishNumber(phone);
    if (uri.isEmpty) return false;
    try {
      final parsed = Uri.parse(uri);
      if (await canLaunchUrl(parsed)) {
        return await launchUrl(parsed, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e, st) {
      if (kDebugMode) debugPrint('WhatsAppLauncher: $e $st');
      return false;
    }
  }
}
