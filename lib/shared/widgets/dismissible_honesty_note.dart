import 'package:emlakmaster_mobile/core/feedback/app_feedback.dart';
import 'package:emlakmaster_mobile/core/theme/app_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kapatılabilir dürüstlük/bilgi notu.
///
/// Sayfa başlıklarındaki açıklama bantları için ortak bileşen: kullanıcı
/// X ile kapattığında kalıcı olarak gizlenir (SharedPreferences) ve ekran
/// özet/aksiyonlara kalır. Not bilgilendirme amaçlıdır; bir kez okunması
/// yeterlidir.
class DismissibleHonestyNote extends StatefulWidget {
  const DismissibleHonestyNote({
    super.key,
    required this.message,
    required this.prefsKey,
  });

  final String message;

  /// Yüzey başına benzersiz anahtar (ör. `honesty_note_calls_v1`).
  final String prefsKey;

  @override
  State<DismissibleHonestyNote> createState() => _DismissibleHonestyNoteState();
}

class _DismissibleHonestyNoteState extends State<DismissibleHonestyNote> {
  // Varsayılan görünür: not bilgilendiricidir, prefs yüklenene kadar
  // gizlemek içerik sıçramasına ve "kayıp not" hissine yol açar.
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    bool dismissed = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      dismissed = prefs.getBool(widget.prefsKey) ?? false;
    } catch (_) {
      dismissed = false;
    }
    if (mounted && dismissed) setState(() => _visible = false);
  }

  Future<void> _dismiss() async {
    AppFeedback.selectionClick();
    setState(() => _visible = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(widget.prefsKey, true);
    } catch (_) {
      // Kalıcılık başarısız olsa bile oturum boyunca gizli kalır.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final ext = AppThemeExtension.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 9, 4, 9),
      decoration: BoxDecoration(
        color: ext.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.border.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: ext.textTertiary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              widget.message,
              style: TextStyle(
                color: ext.textSecondary,
                fontSize: 10.5,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: _dismiss,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: ext.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
