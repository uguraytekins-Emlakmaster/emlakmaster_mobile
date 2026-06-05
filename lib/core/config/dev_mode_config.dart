import 'package:flutter/foundation.dart' show kReleaseMode;

/// Geliştirme / gerçek cihaz testi: ofis oluşturma ve yönlendirme engellerini gevşetir,
/// yerel dev fallback ve örnek verilere izin verir.
///
/// Release derlemelerinde **otomatik olarak kapalıdır** — elle `false` yapmaya gerek yok
/// (insan hatasına karşı güvenli). Debug/profile'da açıktır; istenirse debug'da da
/// `--dart-define=EM_FORCE_PROD=true` ile kapatılıp üretim davranışı test edilebilir.
const bool isDevMode =
    !kReleaseMode && !bool.fromEnvironment('EM_FORCE_PROD');

/// DEV rozeti / debug panel gibi kullanıcıya görünen overlay'ler.
/// Danışman ve CRM ekranlarında kapalı tutulur.
const bool showDevUiOverlays = false;

/// Firestore yazılamadığında kullanılan sabit ofis kimliği (yerel oturum).
const String kLocalDevOfficeId = 'local_dev_office';
