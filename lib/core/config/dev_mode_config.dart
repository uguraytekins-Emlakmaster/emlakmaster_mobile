/// Geliştirme / gerçek cihaz testi: ofis oluşturma ve yönlendirme engellerini gevşetir.
/// **Üretim öncesi `false` yapın.**
const bool isDevMode = true;

/// DEV rozeti / debug panel gibi kullanıcıya görünen overlay'ler.
/// Danışman ve CRM ekranlarında kapalı tutulur.
const bool showDevUiOverlays = false;

/// Firestore yazılamadığında kullanılan sabit ofis kimliği (yerel oturum).
const String kLocalDevOfficeId = 'local_dev_office';
