/// Uzak model olmadan üretilen kampanya metni — şablon + segment sayıları.
abstract final class HeuristicCampaignMessage {
  HeuristicCampaignMessage._();

  static String build({
    required int customerCount,
    required int phoneCount,
  }) {
    final n = customerCount;
    final phones = phoneCount;
    if (n <= 0 || phones <= 0) {
      return 'Merhaba, size uygun ilanlar için kısa bir telefon görüşmesi ayarlayabilirsiniz.';
    }
    return 'Merhaba, portföyümüzde bütçenize ve tercih ettiğiniz bölgeye uygun yeni ilanlar oluştu '
        '($n kayıt, $phones ulaşılabilir numara). Uygun olduğunuzda kısa bir telefonla üzerinden birlikte geçebiliriz.';
  }
}
