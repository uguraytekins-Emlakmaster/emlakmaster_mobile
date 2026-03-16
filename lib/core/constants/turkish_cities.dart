/// Türkiye illeri ve seçili illerin ilçeleri (Market Pulse / ayarlar şehir–ilçe seçimi).
abstract final class TurkishCities {
  TurkishCities._();

  /// İl kodu (sahibinden URL vb.) → İl adı
  static const Map<String, String> cities = {
    '01': 'Adana', '02': 'Adıyaman', '03': 'Afyonkarahisar', '04': 'Ağrı',
    '05': 'Amasya', '06': 'Ankara', '07': 'Antalya', '08': 'Artvin',
    '09': 'Aydın', '10': 'Balıkesir', '11': 'Bilecik', '12': 'Bingöl',
    '13': 'Bitlis', '14': 'Bolu', '15': 'Burdur', '16': 'Bursa',
    '17': 'Çanakkale', '18': 'Çankırı', '19': 'Çorum', '20': 'Denizli',
    '21': 'Diyarbakır', '22': 'Edirne', '23': 'Elazığ', '24': 'Erzincan',
    '25': 'Erzurum', '26': 'Eskişehir', '27': 'Gaziantep', '28': 'Giresun',
    '29': 'Gümüşhane', '30': 'Hakkari', '31': 'Hatay', '32': 'Isparta',
    '33': 'Mersin', '34': 'İstanbul', '35': 'İzmir', '36': 'Kars',
    '37': 'Kastamonu', '38': 'Kayseri', '39': 'Kırklareli', '40': 'Kırşehir',
    '41': 'Kocaeli', '42': 'Konya', '43': 'Kütahya', '44': 'Malatya',
    '45': 'Manisa', '46': 'Kahramanmaraş', '47': 'Mardin', '48': 'Muğla',
    '49': 'Muş', '50': 'Nevşehir', '51': 'Niğde', '52': 'Ordu',
    '53': 'Rize', '54': 'Sakarya', '55': 'Samsun', '56': 'Siirt',
    '57': 'Sinop', '58': 'Sivas', '59': 'Tekirdağ', '60': 'Tokat',
    '61': 'Trabzon', '62': 'Tunceli', '63': 'Şanlıurfa', '64': 'Uşak',
    '65': 'Van', '66': 'Yozgat', '67': 'Zonguldak', '68': 'Aksaray',
    '69': 'Bayburt', '70': 'Karaman', '71': 'Kırıkkale', '72': 'Batman',
    '73': 'Şırnak', '74': 'Bartın', '75': 'Ardahan', '76': 'Iğdır',
    '77': 'Yalova', '78': 'Karabük', '79': 'Kilis', '80': 'Osmaniye',
    '81': 'Düzce',
  };

  /// İl kodu → ilçe listesi (sahibinden/emlakjet filtre için). Eksik iller boş liste.
  static const Map<String, List<String>> districtsByCity = {
    '21': ['Bağlar', 'Kayapınar', 'Yenişehir', 'Sur', 'Bismil', 'Çermik', 'Çınar', 'Çüngüş', 'Dicle', 'Eğil', 'Ergani', 'Hani', 'Hazro', 'Kocaköy', 'Kulp', 'Lice', 'Silvan'],
    '34': ['Adalar', 'Arnavutköy', 'Ataşehir', 'Avcılar', 'Bağcılar', 'Bahçelievler', 'Bakırköy', 'Başakşehir', 'Bayrampaşa', 'Beşiktaş', 'Beykoz', 'Beylikdüzü', 'Beyoğlu', 'Büyükçekmece', 'Çatalca', 'Çekmeköy', 'Eyüpsultan', 'Fatih', 'Gaziosmanpaşa', 'Güngören', 'Kadıköy', 'Kağıthane', 'Kartal', 'Küçükçekmece', 'Maltepe', 'Pendik', 'Sancaktepe', 'Sarıyer', 'Silivri', 'Sultanbeyli', 'Sultangazi', 'Şile', 'Şişli', 'Tuzla', 'Ümraniye', 'Üsküdar', 'Zeytinburnu'],
    '35': ['Aliağa', 'Balçova', 'Bayındır', 'Bayraklı', 'Bergama', 'Beydağ', 'Bornova', 'Buca', 'Çeşme', 'Çiğli', 'Dikili', 'Foça', 'Gaziemir', 'Güzelbahçe', 'Karabağlar', 'Karaburun', 'Karşıyaka', 'Kemalpaşa', 'Kınık', 'Kiraz', 'Konak', 'Menderes', 'Menemen', 'Narlıdere', 'Ödemiş', 'Seferihisar', 'Selçuk', 'Tire', 'Torbalı', 'Urla'],
    '06': ['Akyurt', 'Altındağ', 'Ayaş', 'Balâ', 'Beypazarı', 'Çamlıdere', 'Çankaya', 'Çubuk', 'Elmadağ', 'Etimesgut', 'Evren', 'Gölbaşı', 'Güdül', 'Haymana', 'Kahramankazan', 'Kalecik', 'Keçiören', 'Kızılcahamam', 'Mamak', 'Nallıhan', 'Polatlı', 'Pursaklar', 'Sincan', 'Şereflikoçhisar', 'Yenimahalle'],
  };

  static List<String> get cityCodes => cities.keys.toList()..sort();
  static List<String> get cityNames => cityCodes.map((c) => cities[c]!).toList();
  static List<String> districtsFor(String cityCode) =>
      districtsByCity[cityCode] ?? [];
}
