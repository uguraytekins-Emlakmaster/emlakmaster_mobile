import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Toplu SMS: sms: URI ile varsayılan mesaj uygulamasını açar.
/// Türkiye numaraları 90/0 normalize edilir.
class SmsLauncher {
  SmsLauncher._();

  static String _digitsOnly(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  /// Tek veya çoklu numara için sms: URI. Numara boşsa boş string.
  static String uriForNumbers(List<String> numbers, {String body = ''}) {
    final normalized = <String>[];
    for (final n in numbers) {
      final digits = _digitsOnly(n);
      if (digits.isEmpty) continue;
      String num = digits;
      if (num.startsWith('0')) num = num.substring(1);
      if (!num.startsWith('90') && num.length >= 10) num = '90$num';
      normalized.add(num);
    }
    if (normalized.isEmpty) return '';
    final uri = 'sms:${normalized.join(',')}';
    if (body.isNotEmpty) {
      return '$uri?body=${Uri.encodeComponent(body)}';
    }
    return uri;
  }

  /// Toplu SMS açar. Seçili numaralara mesaj gönderilir. Başarısızsa false.
  static Future<bool> openBulkSms(List<String> numbers, {String body = ''}) async {
    final uriStr = uriForNumbers(numbers, body: body);
    if (uriStr.isEmpty) return false;
    try {
      final uri = Uri.parse(uriStr);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e, st) {
      if (kDebugMode) debugPrint('SmsLauncher: $e $st');
      return false;
    }
  }
}
