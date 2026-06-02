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
  /// [message] verilirse sohbet önceden doldurulur (opsiyonel).
  static String urlForTurkishNumber(String phone, {String? message}) {
    final digits = _digitsOnly(phone);
    if (digits.isEmpty) return '';
    String normalized = digits;
    if (normalized.startsWith('0')) normalized = normalized.substring(1);
    if (!normalized.startsWith('90') && normalized.length >= 10) {
      normalized = '90$normalized';
    }
    var url = 'https://wa.me/$normalized';
    if (message != null && message.trim().isNotEmpty) {
      url += '?text=${Uri.encodeComponent(message.trim())}';
    }
    return url;
  }

  /// WhatsApp'ı açar. [message] opsiyonel; sohbet kutusuna önceden doldurulur.
  /// Numara geçersizse false döner.
  ///
  /// `canLaunchUrl` ön-kontrolü yapılmaz (iOS'ta şema sorgu izni olmadan
  /// güvenilmez); doğrudan `launchUrl` denenir, başarısızlıkta `platformDefault`
  /// ile yedeklenir. `wa.me` evrensel bağlantısı WhatsApp kuruluysa uygulamayı,
  /// değilse tarayıcıyı açar.
  static Future<bool> openChat(String phone, {String? message}) async {
    final uriStr = urlForTurkishNumber(phone, message: message);
    if (uriStr.isEmpty) return false;
    final parsed = Uri.parse(uriStr);
    try {
      if (await launchUrl(parsed, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('WhatsAppLauncher.external: $e $st');
    }
    try {
      return await launchUrl(parsed);
    } catch (e, st) {
      if (kDebugMode) debugPrint('WhatsAppLauncher.platformDefault: $e $st');
      return false;
    }
  }
}
